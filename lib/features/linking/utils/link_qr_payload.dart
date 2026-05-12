/// QR content for caregiver-senior linking. Matches [LinkingService] 6-digit codes.
abstract final class LinkQrPayload {
  static const String prefix = 'elderassist:link:';

  /// Value embedded in the QR (caregiver display).
  static String encode(String sixDigitCode) => '$prefix$sixDigitCode';

  /// Parses [raw] from a scan. Returns null if no valid 6-digit ElderAssist link.
  static String? parse(String? raw) {
    if (raw == null) return null;
    final trimmed = raw.trim();
    final prefixed = RegExp('${RegExp.escape(prefix)}(\\d{6})\$').firstMatch(trimmed);
    if (prefixed != null) return prefixed.group(1);
    if (RegExp(r'^\d{6}$').hasMatch(trimmed)) return trimmed;
    return null;
  }
}
