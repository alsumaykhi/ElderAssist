enum CareChatMessageType {
  text('text'),
  voiceMemo('voice_memo'),
  image('image'),
  video('video'),
  medicationProposal('med_proposal'),
  medicationEditProposal('med_edit_proposal');

  const CareChatMessageType(this.firestoreValue);

  final String firestoreValue;

  static CareChatMessageType fromFirestore(String? value) {
    return CareChatMessageType.values.firstWhere(
      (type) => type.firestoreValue == value,
      orElse: () => CareChatMessageType.text,
    );
  }
}
