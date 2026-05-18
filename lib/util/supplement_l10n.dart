// lib/util/supplement_l10n.dart
import '../generated/app_localizations.dart';
import '../features/supplements/domain/models/supplement.dart';

/// Localizes the name of a [Supplement] using its internal code.
String localizeSupplementName(Supplement s, AppLocalizations l10n) {
  switch (s.code) {
    case 'caffeine':
      return l10n.supplement_caffeine;
    case 'creatine_monohydrate':
      return l10n.supplement_creatine_monohydrate;
    default:
      return s.name;
  }
}
