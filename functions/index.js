const {VertexAI} = require("@google-cloud/vertexai");
const {onCall, HttpsError} = require("firebase-functions/v2/https");
const {onSchedule} = require("firebase-functions/v2/scheduler");
const {setGlobalOptions} = require("firebase-functions/v2");
const admin = require("firebase-admin");
const fs = require("fs");
const path = require("path");

admin.initializeApp();
setGlobalOptions({region: "us-central1"});

/** Vertex model id (override with GEMINI_MODEL env if needed). */
const VERTEX_MODEL = process.env.GEMINI_MODEL || "gemini-2.5-flash";

const VERTEX_LOCATION = process.env.VERTEX_LOCATION || "us-central1";

const AI_RULES_TEXT = fs.readFileSync(
    path.join(__dirname, "ai_rules.txt"),
    "utf8",
).trim();

/** Global persona and safety rules for the health assistant (Vertex systemInstruction). */
const HEALTH_ASSISTANT_SYSTEM_INSTRUCTION = {
  role: "system",
  parts: [{text: AI_RULES_TEXT}],
};

/**
 * Expected JSON shape from Gemini (enforced via responseMimeType + prompt).
 * @typedef {Object} AssistantJson
 * @property {string} replyText
 * @property {boolean} emergency
 * @property {{name: string, dosage: string, safetyNote?: string}[]} suggestedSupplements
 * @property {string} [symptomSummary]
 */

/**
 * @param {unknown} data
 * @returns {AssistantJson}
 */
function normalizeAssistantPayload(data) {
  const obj = data && typeof data === "object" ? data : {};
  const replyText =
    typeof obj.replyText === "string" && obj.replyText.trim().length > 0 ?
      obj.replyText.trim() :
      "I could not form a detailed reply. Please try again or contact your clinician.";
  const emergency = Boolean(obj.emergency);
  const rawList = Array.isArray(obj.suggestedSupplements) ? obj.suggestedSupplements : [];
  const suggestedSupplements = rawList
      .map((s) => {
        if (!s || typeof s !== "object") return null;
        const name = typeof s.name === "string" ? s.name.trim() : "";
        const dosage = typeof s.dosage === "string" ? s.dosage.trim() : "";
        const safetyNote =
          typeof s.safetyNote === "string" ? s.safetyNote.trim() : undefined;
        if (!name) return null;
        return {name, dosage: dosage || "Discuss with clinician", safetyNote};
      })
      .filter(Boolean);
  const symptomSummary =
    typeof obj.symptomSummary === "string" ? obj.symptomSummary.trim() : undefined;
  return {replyText, emergency, suggestedSupplements, symptomSummary};
}

/**
 * @param {string} text
 * @returns {AssistantJson}
 */
function tryParseAssistantJson(text) {
  const trimmed = (text || "").trim();
  if (!trimmed) {
    return normalizeAssistantPayload({});
  }
  try {
    const parsed = JSON.parse(trimmed);
    return normalizeAssistantPayload(parsed);
  } catch (_) {
    return normalizeAssistantPayload({replyText: trimmed, emergency: false});
  }
}

/**
 * @param {string} profileJson
 * @param {string} medsJson
 * @param {string} userMessage
 * @returns {string}
 */
function buildPrompt(profileJson, medsJson, userMessage) {
  return `
${AI_RULES_TEXT}

USER PROFILE (JSON):
${profileJson}

MEDICATIONS AND SUPPLEMENTS (JSON):
${medsJson}

USER MESSAGE:
${userMessage}
`.trim();
}

/**
 * @param {{response?: {candidates?: Array<{content?: {parts?: Array<{text?: string}>}}>}}} result
 * @returns {string}
 */
function extractTextFromVertexResult(result) {
  const parts = result?.response?.candidates?.[0]?.content?.parts;
  if (!parts || !parts[0]) return "";
  const t = parts[0].text;
  return typeof t === "string" ? t : "";
}

/**
 * @returns {string}
 */
function resolveProjectId() {
  return (
    process.env.GCLOUD_PROJECT ||
    process.env.GCP_PROJECT ||
    process.env.GOOGLE_CLOUD_PROJECT ||
    admin.app().options.projectId ||
    ""
  );
}

// Gen2 runs on Cloud Run: `invoker: "public"` so clients can call; auth enforced below.
// Grant the function's service account `roles/aiplatform.user` (Vertex AI User) on the project.
exports.generateHealthAssistantResponse = onCall(
    {invoker: "public"},
    async (request) => {
      if (!request.auth) {
        throw new HttpsError(
            "unauthenticated",
            "User must be logged in",
        );
      }

      const data = request.data || {};
      const uid = typeof data.uid === "string" ? data.uid : "";
      const message = typeof data.message === "string" ? data.message.trim() : "";

      if (!uid || !message) {
        throw new HttpsError(
            "invalid-argument",
            "uid and message are required",
        );
      }
      if (uid !== request.auth.uid) {
        throw new HttpsError(
            "permission-denied",
            "uid does not match signed-in user",
        );
      }

      const projectId = resolveProjectId();
      if (!projectId) {
        console.error("Could not resolve GCP project id for Vertex AI");
        throw new HttpsError("failed-precondition", "Server configuration error");
      }

      const db = admin.firestore();
      let profileSnap;
      let medsSnap;
      try {
        [profileSnap, medsSnap] = await Promise.all([
          db.collection("users").doc(uid).get(),
          db.collection("users").doc(uid).collection("medications").get(),
        ]);
      } catch (e) {
        console.error("Firestore read error", e);
        throw new HttpsError("internal", "Failed to load user data");
      }

      const profileData = profileSnap.exists ? profileSnap.data() : {};
      const profileJson = JSON.stringify(profileData || {});
      const meds = medsSnap.docs.map((d) => ({id: d.id, ...d.data()}));
      const medsJson = JSON.stringify(meds);

      const prompt = buildPrompt(profileJson, medsJson, message);

      let geminiText = "";
      try {
        const vertexAI = new VertexAI({
          project: projectId,
          location: VERTEX_LOCATION,
        });
        const model = vertexAI.getGenerativeModel({
          model: VERTEX_MODEL,
          systemInstruction: HEALTH_ASSISTANT_SYSTEM_INSTRUCTION,
          generationConfig: {
            temperature: 0.35,
            responseMimeType: "application/json",
          },
        });
        const result = await model.generateContent({
          contents: [
            {
              role: "user",
              parts: [{text: prompt}],
            },
          ],
        });
        geminiText = extractTextFromVertexResult(result);
      } catch (e) {
        if (e instanceof HttpsError) throw e;
        console.error("Vertex AI error", e);
        throw new HttpsError("internal", "Assistant request failed");
      }

      const assistant = tryParseAssistantJson(geminiText);

      const historyCol = db.collection("users").doc(uid).collection("chatHistory");
      const userRef = historyCol.doc();
      const asstRef = historyCol.doc();
      const batch = db.batch();
      batch.set(userRef, {
        role: "user",
        text: message,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      batch.set(asstRef, {
        role: "assistant",
        text: assistant.replyText,
        emergency: assistant.emergency,
        suggestedSupplements: assistant.suggestedSupplements,
        symptomSummary: assistant.symptomSummary || null,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      try {
        await batch.commit();
      } catch (e) {
        console.error("Failed to persist chat history", e);
        throw new HttpsError("internal", "Failed to save chat history");
      }

      return {
        replyText: assistant.replyText,
        emergency: assistant.emergency,
        suggestedSupplements: assistant.suggestedSupplements,
        symptomSummary: assistant.symptomSummary || null,
        messageIds: {userMessageId: userRef.id, assistantMessageId: asstRef.id},
      };
    },
);

exports.expireCareChatProposals = onSchedule(
    "every 15 minutes",
    async () => {
      const db = admin.firestore();
      const now = admin.firestore.Timestamp.now();
      const batchSize = 300;

      // Process in windows to stay under Firestore batch limits.
      let hasMore = true;
      while (hasMore) {
        const snapshot = await db.collectionGroup("messages")
            .where("status", "==", "pending")
            .where("expiresAt", "<=", now)
            .limit(batchSize)
            .get();

        if (snapshot.empty) {
          hasMore = false;
          continue;
        }

        const batch = db.batch();
        for (const doc of snapshot.docs) {
          const data = doc.data() || {};
          const type = data.type || "";
          if (type !== "med_proposal" && type !== "med_edit_proposal") {
            continue;
          }
          batch.update(doc.ref, {
            status: "expired",
            expiredAt: admin.firestore.FieldValue.serverTimestamp(),
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          });
        }
        await batch.commit();

        hasMore = snapshot.size >= batchSize;
      }
    },
);

exports.careChatProposalStatusNotify = require("firebase-functions/v2/firestore")
    .onDocumentUpdated(
        "caregiver_senior_chats/{chatId}/messages/{messageId}",
        async (event) => {
          const before = event.data.before.data();
          const after = event.data.after.data();
          if (!before || !after) return;

          const prevStatus = before.status;
          const nextStatus = after.status;
          if (prevStatus === nextStatus) return;
          if (before.type !== "med_proposal" &&
              before.type !== "med_edit_proposal") {
            return;
          }

          let title;
          if (nextStatus === "accepted") {
            title = "Medication proposal accepted";
          } else if (nextStatus === "declined") {
            title = "Medication proposal declined";
          } else if (nextStatus === "expired") {
            title = "Medication proposal expired";
          } else {
            return;
          }

          const db = admin.firestore();
          const chatSnap = await db
              .collection("caregiver_senior_chats")
              .doc(event.params.chatId)
              .get();
          if (!chatSnap.exists) return;
          const chat = chatSnap.data() || {};
          const participants = chat.participants || [];

          if (!Array.isArray(participants) || participants.length === 0) return;

          const userSnaps = await Promise.all(
              participants.map((uid) =>
                db.collection("users").doc(uid).get(),
              ),
          );

          /** @type {string[]} */
          const tokens = [];
          for (const snap of userSnaps) {
            if (!snap.exists) continue;
            const data = snap.data() || {};
            const t = data.fcmToken;
            if (typeof t === "string" && t.trim()) {
              tokens.push(t.trim());
            }
          }

          if (tokens.length === 0) return;

          const body = after.payload && after.payload.name ?
            after.payload.name :
            "A caregiver-senior medication proposal has been updated.";

          await admin.messaging().sendMulticast({
            tokens,
            notification: {
              title,
              body,
            },
            data: {
              chatId: event.params.chatId,
              messageId: event.params.messageId,
              proposalStatus: nextStatus,
            },
          });
        },
    );
