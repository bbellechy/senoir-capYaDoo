String? toThaiIntakeTimingLabel(String? intakeTiming) {
  if (intakeTiming == null) return null;

  final normalized = intakeTiming.trim();
  if (normalized.isEmpty) return null;

  switch (normalized.toUpperCase()) {
    case 'BEFORE_MEAL':
      return 'ก่อนอาหาร';
    case 'AFTER_MEAL':
      return 'หลังอาหาร';
    case 'WITH_MEAL':
      return 'พร้อมอาหาร';
    case 'IMMEDIATE':
      return 'ทานทันที';
  }

  // Preserve already-localized values coming from backend.
  if (normalized == 'ก่อนอาหาร' ||
      normalized == 'หลังอาหาร' ||
      normalized == 'พร้อมอาหาร' ||
      normalized == 'ทานทันที') {
    return normalized;
  }

  return null;
}
