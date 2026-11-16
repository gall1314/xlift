// Automatic FlutterFlow imports
import '/backend/schema/structs/index.dart';
import '/backend/supabase/supabase.dart';
import '/backend/sqlite/sqlite_manager.dart';
import '/actions/actions.dart' as action_blocks;
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom widgets
import '/custom_code/actions/index.dart'; // Imports custom actions
import '/flutter_flow/custom_functions.dart'; // Imports custom functions
import 'package:flutter/material.dart' hide RepeatMode;
// Begin custom widget code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:purchases_flutter/purchases_flutter.dart' as rc;
import '/flutter_flow/revenue_cat_util.dart' as revenue_cat;

/// The whole "upgrade to Premium" screen as one self-managed widget.
///
/// What it does on its own:
/// - Loads the current RevenueCat offering and shows the store's own
///   localized prices (yearly + monthly). Savings % and the per-month price
///   are computed from the real prices, never hard-coded.
/// - Yearly is selected by default. The free-trial wording appears only when
///   the selected product has a free intro period the user is eligible for.
/// - Buys the selected package, restores purchases, and shows a short
///   "Premium is active" screen afterwards.
/// - States: prices loading, prices failed (with retry), purchase running.
/// - Sets light status-bar icons (the screen is dark).
///
/// Parameters:
/// - source (optional String): where the user came from. One of
///   'analysis', 'aiWorkout', 'customExercise', 'history', 'stats'.
///   Shows a small line above the title ("5 of 5 analyses used this month").
///   Leave empty for the generic screen.
///
/// Callbacks:
/// - onPurchased: fired once, right after a successful purchase or restore.
///   Update your premium state here.
/// - onClose: the X button, and "Continue" on the success screen.
/// - onOpenTerms / onOpenPrivacy: open the two links.
///
/// Localization: reads the app language from FFLocalizations (no parameter).
class PaywallView extends StatefulWidget {
  const PaywallView({
    super.key,
    this.width,
    this.height,
    this.source,
    this.onClose,
    this.onPurchased,
    this.onOpenTerms,
    this.onOpenPrivacy,
  });

  final double? width;
  final double? height;
  final String? source;
  final Future Function()? onClose;
  final Future Function()? onPurchased;
  final Future Function()? onOpenTerms;
  final Future Function()? onOpenPrivacy;

  @override
  State<PaywallView> createState() => _PaywallViewState();
}

// Free-tier limits shown on the screen. Keep in sync with the real gates.
const int _kFreeAnalysesPerMonth = 5;
const int _kFreeAiWorkoutsPerWeek = 3;
const int _kFreeCustomExercises = 3;
const int _kFreeHistoryDays = 30;

const Color _cBgTop = Color(0xFF0A1614);
const Color _cBgBottom = Color(0xFF0E201C);
const Color _cCard = Color(0xFF0D1F1B);
const Color _cCardOn = Color(0xFF162C28);
const Color _cBorder = Color(0xFF253632);
const Color _cDivider = Color(0xFF1C2E2A);
const Color _cAccent = Color(0xFF2DD4BF);
const Color _cMint = Color(0xFF5EEAD4);
const Color _cTint = Color(0xFF11352F);
const Color _cMuted = Color(0xFF9FB0AC);
const Color _cRingOff = Color(0xFF5A6D69);
const Color _cCta = Color(0xFF14B8A6);
const Color _cCtaText = Color(0xFF04201C);
const Color _cCtaOff = Color(0xFF1C3A35);
const Color _cCtaOffText = Color(0xFF9CC2BB);
const Color _cNotice = Color(0xFFF5C063);

const Set<String> _kRtl = {'he', 'ar'};

const Map<String, Map<String, String>> _kStrings = {
  "premium": {
    "en": "PREMIUM",
    "es": "PREMIUM",
    "he": "פרימיום",
    "de": "PREMIUM",
    "fr": "PREMIUM",
  },
  "title": {
    "en": "Train without limits",
    "es": "Entrena sin límites",
    "he": "להתאמן בלי מגבלות",
    "de": "Trainieren ohne Limits",
    "fr": "S'entraîner sans limites",
  },
  "sub": {
    "en": "Every tool unlocked. No quotas.",
    "es": "Todo desbloqueado. Sin cuotas.",
    "he": "כל הכלים פתוחים, בלי מכסות.",
    "de": "Alles freigeschaltet. Ohne Limits.",
    "fr": "Tout est débloqué. Sans quotas.",
  },
  "pillAnalysis": {
    "en": "{n} of {n} analyses used this month",
    "es": "{n} de {n} análisis usados este mes",
    "he": "נוצלו {n} מתוך {n} ניתוחים החודש",
    "de": "{n} von {n} Analysen diesen Monat genutzt",
    "fr": "{n} analyses sur {n} utilisées ce mois-ci",
  },
  "pillAi": {
    "en": "{n} of {n} AI workouts used this week",
    "es": "{n} de {n} entrenos con IA esta semana",
    "he": "נוצלו {n} מתוך {n} אימוני AI השבוע",
    "de": "{n} von {n} KI-Workouts diese Woche genutzt",
    "fr": "{n} séances IA sur {n} cette semaine",
  },
  "pillCustom": {
    "en": "{n} of {n} custom exercises used",
    "es": "{n} de {n} ejercicios propios usados",
    "he": "נוצלו {n} מתוך {n} תרגילים מותאמים",
    "de": "{n} von {n} eigenen Übungen genutzt",
    "fr": "{n} exercices perso sur {n} utilisés",
  },
  "pillHistory": {
    "en": "Full history is a Premium feature",
    "es": "Historial completo solo en Premium",
    "he": "היסטוריה מלאה רק בפרימיום",
    "de": "Kompletter Verlauf nur mit Premium",
    "fr": "Historique complet avec Premium",
  },
  "pillStats": {
    "en": "All-time range is a Premium feature",
    "es": "Todo el periodo solo en Premium",
    "he": "כל התקופה רק בפרימיום",
    "de": "Gesamter Zeitraum nur mit Premium",
    "fr": "Toute la période avec Premium",
  },
  "b1": {
    "en": "Unlimited form analysis",
    "es": "Análisis de técnica ilimitado",
    "he": "ניתוח טכניקה ללא הגבלה",
    "de": "Technikanalyse unbegrenzt",
    "fr": "Analyse technique illimitée",
  },
  "b1s": {
    "en": "Instead of {n} a month",
    "es": "En lugar de {n} al mes",
    "he": "במקום {n} בחודש",
    "de": "Statt {n} pro Monat",
    "fr": "Au lieu de {n} par mois",
  },
  "b2": {
    "en": "Unlimited AI workouts",
    "es": "Entrenos con IA ilimitados",
    "he": "אימוני AI ללא הגבלה",
    "de": "KI-Workouts unbegrenzt",
    "fr": "Séances IA illimitées",
  },
  "b2s": {
    "en": "Instead of {n} a week",
    "es": "En lugar de {n} por semana",
    "he": "במקום {n} בשבוע",
    "de": "Statt {n} pro Woche",
    "fr": "Au lieu de {n} par semaine",
  },
  "b3": {
    "en": "Unlimited custom exercises",
    "es": "Ejercicios propios ilimitados",
    "he": "תרגילים מותאמים ללא הגבלה",
    "de": "Eigene Übungen unbegrenzt",
    "fr": "Exercices perso illimités",
  },
  "b3s": {
    "en": "Instead of {n}",
    "es": "En lugar de {n}",
    "he": "במקום {n}",
    "de": "Statt {n}",
    "fr": "Au lieu de {n}",
  },
  "b4": {
    "en": "Your full workout history",
    "es": "Historial completo",
    "he": "כל היסטוריית האימונים",
    "de": "Kompletter Verlauf",
    "fr": "Historique complet",
  },
  "b5": {
    "en": "All-time statistics",
    "es": "Estadísticas de todo el periodo",
    "he": "סטטיסטיקות לכל התקופה",
    "de": "Statistiken ohne Zeitlimit",
    "fr": "Statistiques sur toute la période",
  },
  "daysSub": {
    "en": "Instead of the last {n} days",
    "es": "En lugar de los últimos {n} días",
    "he": "במקום {n} הימים האחרונים",
    "de": "Statt der letzten {n} Tage",
    "fr": "Au lieu des {n} derniers jours",
  },
  "yearly": {
    "en": "Yearly",
    "es": "Anual",
    "he": "שנתי",
    "de": "Jährlich",
    "fr": "Annuel",
  },
  "monthly": {
    "en": "Monthly",
    "es": "Mensual",
    "he": "חודשי",
    "de": "Monatlich",
    "fr": "Mensuel",
  },
  "save": {
    "en": "Save {n}%",
    "es": "Ahorra {n}%",
    "he": "חיסכון {n}%",
    "de": "{n}% sparen",
    "fr": "−{n} %",
  },
  "perYear": {
    "en": "/ year",
    "es": "/ año",
    "he": "לשנה",
    "de": "/ Jahr",
    "fr": "/ an",
  },
  "perMonth": {
    "en": "/ month",
    "es": "/ mes",
    "he": "לחודש",
    "de": "/ Monat",
    "fr": "/ mois",
  },
  "monthLine": {
    "en": "{p} / month",
    "es": "{p} / mes",
    "he": "{p} לחודש",
    "de": "{p} / Monat",
    "fr": "{p} / mois",
  },
  "ctaTrial": {
    "en": "Start {n}-day free trial",
    "es": "Probar {n} días gratis",
    "he": "התחלת {n} ימי ניסיון בחינם",
    "de": "{n} Tage gratis testen",
    "fr": "Essayer {n} jours gratuits",
  },
  "ctaPlain": {
    "en": "Upgrade to Premium",
    "es": "Pasar a Premium",
    "he": "שדרוג לפרימיום",
    "de": "Auf Premium upgraden",
    "fr": "Passer à Premium",
  },
  "trialPrefix": {
    "en": "{n} days free, then ",
    "es": "{n} días gratis, luego ",
    "he": "{n} ימים בחינם, אחר כך ",
    "de": "{n} Tage gratis, danach ",
    "fr": "{n} jours gratuits, puis ",
  },
  "legalYear": {
    "en": "{p} per year. Renews automatically. Cancel anytime.",
    "es": "{p} al año. Renovación automática. Cancela cuando quieras.",
    "he": "{p} לשנה בחידוש אוטומטי. ביטול בכל רגע.",
    "de": "{p} pro Jahr. Verlängert sich automatisch. Jederzeit kündbar.",
    "fr": "{p} par an. Renouvellement automatique. Annulable à tout moment.",
  },
  "legalMonth": {
    "en": "{p} per month. Renews automatically. Cancel anytime.",
    "es": "{p} al mes. Renovación automática. Cancela cuando quieras.",
    "he": "{p} לחודש בחידוש אוטומטי. ביטול בכל רגע.",
    "de": "{p} pro Monat. Verlängert sich automatisch. Jederzeit kündbar.",
    "fr": "{p} par mois. Renouvellement automatique. Annulable à tout moment.",
  },
  "restore": {
    "en": "Restore purchases",
    "es": "Restaurar compras",
    "he": "שחזור רכישות",
    "de": "Käufe wiederherstellen",
    "fr": "Restaurer les achats",
  },
  "terms": {
    "en": "Terms",
    "es": "Términos",
    "he": "תנאי שימוש",
    "de": "AGB",
    "fr": "Conditions",
  },
  "privacy": {
    "en": "Privacy",
    "es": "Privacidad",
    "he": "מדיניות פרטיות",
    "de": "Datenschutz",
    "fr": "Confidentialité",
  },
  "loading": {
    "en": "Loading prices…",
    "es": "Cargando precios…",
    "he": "המחירים נטענים…",
    "de": "Preise werden geladen…",
    "fr": "Chargement des prix…",
  },
  "errTitle": {
    "en": "Couldn't load prices",
    "es": "No se cargaron los precios",
    "he": "המחירים לא נטענו",
    "de": "Preise nicht geladen",
    "fr": "Prix non chargés",
  },
  "errBody": {
    "en": "Check your connection and try again.",
    "es": "Revisa tu conexión e inténtalo de nuevo.",
    "he": "בדקו את החיבור לאינטרנט ונסו שוב.",
    "de": "Prüfe deine Verbindung und versuch es erneut.",
    "fr": "Vérifiez votre connexion et réessayez.",
  },
  "retry": {
    "en": "Try again",
    "es": "Reintentar",
    "he": "ניסיון חוזר",
    "de": "Erneut versuchen",
    "fr": "Réessayer",
  },
  "purchasing": {
    "en": "Processing…",
    "es": "Procesando…",
    "he": "הרכישה מתבצעת…",
    "de": "Wird verarbeitet…",
    "fr": "Traitement…",
  },
  "notCompleted": {
    "en": "The purchase didn't go through. You can try again.",
    "es": "La compra no se completó. Puedes intentarlo de nuevo.",
    "he": "הרכישה לא הושלמה. אפשר לנסות שוב.",
    "de": "Der Kauf wurde nicht abgeschlossen. Versuch es erneut.",
    "fr": "L'achat n'a pas abouti. Vous pouvez réessayer.",
  },
  "restoreNone": {
    "en": "No purchase found to restore.",
    "es": "No hay compras para restaurar.",
    "he": "לא נמצאה רכישה לשחזור.",
    "de": "Kein Kauf zum Wiederherstellen gefunden.",
    "fr": "Aucun achat à restaurer.",
  },
  "restoreFailed": {
    "en": "Restore failed. Try again.",
    "es": "No se pudo restaurar. Inténtalo de nuevo.",
    "he": "השחזור לא הצליח. נסו שוב.",
    "de": "Wiederherstellen fehlgeschlagen. Versuch es erneut.",
    "fr": "Échec de la restauration. Réessayez.",
  },
  "okTitle": {
    "en": "Premium is active",
    "es": "Premium activado",
    "he": "הפרימיום פעיל",
    "de": "Premium ist aktiv",
    "fr": "Premium est actif",
  },
  "okTrial": {
    "en": "Your {n}-day trial has started. Cancel anytime.",
    "es": "Tu prueba de {n} días ha empezado. Cancela cuando quieras.",
    "he": "{n} ימי הניסיון התחילו. אפשר לבטל בכל רגע.",
    "de": "Deine {n} Testtage laufen. Jederzeit kündbar.",
    "fr": "Vos {n} jours d'essai ont commencé. Annulable à tout moment.",
  },
  "okPlain": {
    "en": "Everything is unlocked. Enjoy your training.",
    "es": "Todo está desbloqueado. Buen entrenamiento.",
    "he": "הכול פתוח. אימון מוצלח.",
    "de": "Alles ist freigeschaltet. Gutes Training.",
    "fr": "Tout est débloqué. Bon entraînement.",
  },
  "okOpen": {
    "en": "Unlocked now",
    "es": "Ya disponible",
    "he": "נפתח עכשיו",
    "de": "Jetzt freigeschaltet",
    "fr": "Désormais débloqué",
  },
  "rForm": {
    "en": "Form analysis",
    "es": "Análisis de técnica",
    "he": "ניתוח טכניקה",
    "de": "Technikanalyse",
    "fr": "Analyse technique",
  },
  "rAi": {
    "en": "AI workouts",
    "es": "Entrenos con IA",
    "he": "אימוני AI",
    "de": "KI-Workouts",
    "fr": "Séances IA",
  },
  "rCustom": {
    "en": "Custom exercises",
    "es": "Ejercicios propios",
    "he": "תרגילים מותאמים",
    "de": "Eigene Übungen",
    "fr": "Exercices perso",
  },
  "rHistory": {
    "en": "History",
    "es": "Historial",
    "he": "היסטוריה",
    "de": "Verlauf",
    "fr": "Historique",
  },
  "rStats": {
    "en": "Statistics",
    "es": "Estadísticas",
    "he": "סטטיסטיקות",
    "de": "Statistiken",
    "fr": "Statistiques",
  },
  "unlimited": {
    "en": "Unlimited",
    "es": "Ilimitado",
    "he": "ללא הגבלה",
    "de": "Unbegrenzt",
    "fr": "Illimité",
  },
  "allTime": {
    "en": "All time",
    "es": "Todo",
    "he": "כל התקופה",
    "de": "Gesamt",
    "fr": "Tout",
  },
  "continue": {
    "en": "Continue",
    "es": "Continuar",
    "he": "המשך",
    "de": "Weiter",
    "fr": "Continuer",
  },
  "close": {
    "en": "Close",
    "es": "Cerrar",
    "he": "סגירה",
    "de": "Schließen",
    "fr": "Fermer",
  },
};

String _tr(String lang, String key, {int? n, String? p}) {
  final m = _kStrings[key];
  var s = m == null ? key : (m[lang] ?? m['en'] ?? key);
  if (n != null) s = s.replaceAll('{n}', '$n');
  if (p != null) s = s.replaceAll('{p}', p);
  return s;
}

/// Keeps a price (digits + currency sign) intact inside RTL text.
String _iso(String s) => '\u2066$s\u2069';

enum _Stage { loading, ready, failed, success }

class _PaywallViewState extends State<PaywallView> {
  _Stage _stage = _Stage.loading;
  bool _busy = false;
  String? _noticeKey;
  rc.Package? _yearly;
  rc.Package? _monthly;
  bool _yearSelected = true;
  int _trialYear = 0;
  int _trialMonth = 0;
  int _startedTrialDays = 0;
  int _token = 0;
  String _lang = 'en';

  @override
  void initState() {
    super.initState();
    _load();
  }

  String _t(String key, {int? n, String? p}) => _tr(_lang, key, n: n, p: p);

  // ---------- selection ----------
  rc.Package? get _selected =>
      _yearSelected ? (_yearly ?? _monthly) : (_monthly ?? _yearly);

  bool get _selIsYear => _yearly != null && identical(_selected, _yearly);

  int get _selTrial => _selIsYear ? _trialYear : _trialMonth;

  // ---------- data ----------
  /// Days of a FREE intro period on the product, 0 when there is none.
  static int _introDays(rc.Package p) {
    try {
      final intro = p.storeProduct.introductoryPrice;
      if (intro == null || intro.price > 0) return 0;
      final int n = intro.periodNumberOfUnits;
      final String u = intro.periodUnit.toString().toLowerCase();
      if (u.contains('day')) return n;
      if (u.contains('week')) return n * 7;
      if (u.contains('month')) return n * 30;
      if (u.contains('year')) return n * 365;
    } catch (_) {}
    return 0;
  }

  /// Product ids the store says are NOT eligible for the intro offer
  /// (someone who already used the trial). Unknown counts as eligible.
  static Future<Set<String>> _ineligible(List<String> ids) async {
    final Set<String> out = {};
    if (ids.isEmpty) return out;
    try {
      final Map<String, dynamic> res =
          await rc.Purchases.checkTrialOrIntroductoryPriceEligibility(ids)
              .timeout(const Duration(seconds: 6));
      res.forEach((id, v) {
        final String s = (v as dynamic).status.toString().toLowerCase();
        if (s.contains('ineligible')) out.add(id);
      });
    } catch (_) {}
    return out;
  }

  Future<void> _load() async {
    final int token = ++_token;
    if (mounted) {
      setState(() {
        _stage = _Stage.loading;
        _noticeKey = null;
      });
    }

    rc.Package? y;
    rc.Package? m;
    int ty = 0;
    int tm = 0;

    try {
      final offerings = await rc.Purchases.getOfferings()
          .timeout(const Duration(seconds: 15));
      final cur = offerings.current;
      if (cur != null) {
        y = cur.annual;
        m = cur.monthly;
        // Packages that are not the standard annual / monthly types.
        if (y == null || m == null) {
          for (final p in cur.availablePackages) {
            final String period =
                (p.storeProduct.subscriptionPeriod ?? '').toUpperCase();
            if (y == null && period == 'P1Y') y = p;
            if (m == null && period == 'P1M') m = p;
          }
        }
      }

      if (y != null) ty = _introDays(y);
      if (m != null) tm = _introDays(m);
      if (ty > 0 || tm > 0) {
        final bad = await _ineligible([
          if (y != null && ty > 0) y.storeProduct.identifier,
          if (m != null && tm > 0) m.storeProduct.identifier,
        ]);
        if (y != null && bad.contains(y.storeProduct.identifier)) ty = 0;
        if (m != null && bad.contains(m.storeProduct.identifier)) tm = 0;
      }
    } catch (_) {}

    if (!mounted || token != _token) return;
    setState(() {
      _yearly = y;
      _monthly = m;
      _trialYear = ty;
      _trialMonth = tm;
      _yearSelected = y != null;
      _stage = (y == null && m == null) ? _Stage.failed : _Stage.ready;
    });
  }

  /// Yearly price divided by 12, written in the same format as the store's
  /// own price string (same symbol, side and decimal separator).
  static String _perMonth(rc.Package yearly) {
    final sp = yearly.storeProduct;
    final double v = sp.price / 12;
    final String s = sp.priceString;
    final m = RegExp(r'\d[\d.,\u00A0\u202F\s]*\d|\d').firstMatch(s);
    if (m == null) return '${sp.currencyCode} ${v.toStringAsFixed(2)}';
    final String num = m.group(0)!;
    final dm = RegExp(r'[.,](\d{1,2})$').firstMatch(num);
    String out;
    if (dm != null) {
      final String sep = num[dm.start];
      out = v.toStringAsFixed(dm.group(1)!.length).replaceAll('.', sep);
    } else {
      out = v.round().toString();
    }
    return s.replaceRange(m.start, m.end, out);
  }

  /// How much cheaper yearly is than 12 monthly payments, in %. 0 = hide.
  int _savePct() {
    final y = _yearly?.storeProduct;
    final m = _monthly?.storeProduct;
    if (y == null || m == null) return 0;
    if (y.currencyCode != m.currencyCode) return 0;
    final double full = m.price * 12;
    if (full <= 0) return 0;
    final int pct = ((1 - y.price / full) * 100).round();
    return pct >= 5 ? pct : 0;
  }

  // ---------- actions ----------
  /// Keeps FlutterFlow's own RevenueCat state in step with the purchase.
  Future<void> _syncCustomerInfo() async {
    try {
      final info = await rc.Purchases.getCustomerInfo();
      revenue_cat.customerInfo = info;
    } catch (_) {}
  }

  Future<void> _buy() async {
    final pkg = _selected;
    if (pkg == null || _busy) return;
    final int trialDays = _selTrial;
    setState(() {
      _busy = true;
      _noticeKey = null;
    });

    bool ok = false;
    bool cancelled = false;
    try {
      await rc.Purchases.purchasePackage(pkg);
      ok = true;
    } on PlatformException catch (e) {
      try {
        cancelled = rc.PurchasesErrorHelper.getErrorCode(e) ==
            rc.PurchasesErrorCode.purchaseCancelledError;
      } catch (_) {}
    } catch (_) {}

    if (ok) await _syncCustomerInfo();
    if (!mounted) return;

    if (ok) {
      setState(() {
        _busy = false;
        _startedTrialDays = trialDays;
        _stage = _Stage.success;
      });
      await widget.onPurchased?.call();
    } else {
      setState(() {
        _busy = false;
        // Closing the store sheet on purpose is not an error.
        _noticeKey = cancelled ? null : 'notCompleted';
      });
    }
  }

  Future<void> _restore() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _noticeKey = null;
    });

    bool active = false;
    bool failed = false;
    try {
      final info = await rc.Purchases.restorePurchases();
      active = info.entitlements.active.isNotEmpty;
      try {
        revenue_cat.customerInfo = info;
      } catch (_) {}
    } catch (_) {
      failed = true;
    }

    if (!mounted) return;
    if (active) {
      setState(() {
        _busy = false;
        _startedTrialDays = 0;
        _stage = _Stage.success;
      });
      await widget.onPurchased?.call();
    } else {
      setState(() {
        _busy = false;
        _noticeKey = failed ? 'restoreFailed' : 'restoreNone';
      });
    }
  }

  // ---------- styling ----------
  TextStyle _st(double size, FontWeight w, Color c,
      {double? height, double spacing = 0}) {
    final th = FlutterFlowTheme.of(context);
    return th.bodyMedium
        .override(
          fontFamily: th.bodyMediumFamily,
          color: c,
          fontSize: size,
          fontWeight: w,
          letterSpacing: spacing,
          useGoogleFonts: GoogleFonts.asMap().containsKey(th.bodyMediumFamily),
        )
        .copyWith(height: height);
  }

  // ---------- header + benefits ----------
  String? _pillText() {
    switch ((widget.source ?? '').trim()) {
      case 'analysis':
        return _t('pillAnalysis', n: _kFreeAnalysesPerMonth);
      case 'aiWorkout':
        return _t('pillAi', n: _kFreeAiWorkoutsPerWeek);
      case 'customExercise':
        return _t('pillCustom', n: _kFreeCustomExercises);
      case 'history':
        return _t('pillHistory');
      case 'stats':
        return _t('pillStats');
    }
    return null;
  }

  Widget _header() {
    final String? pill = _pillText();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (pill != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF152824),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline_rounded,
                    size: 14, color: Color(0xFFC4D1CE)),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    pill,
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    style: _st(12.5, FontWeight.w500, const Color(0xFFC4D1CE)),
                  ),
                ),
              ],
            ),
          )
        else
          Text(
            _t('premium'),
            style: _st(12.5, FontWeight.w700, _cAccent, spacing: 1.2),
          ),
        const SizedBox(height: 8),
        Text(
          _t('title'),
          textAlign: TextAlign.center,
          style: _st(30, FontWeight.w700, Colors.white, height: 1.25),
        ),
        const SizedBox(height: 6),
        Text(
          _t('sub'),
          textAlign: TextAlign.center,
          style: _st(15, FontWeight.w400, _cMuted, height: 1.45),
        ),
      ],
    );
  }

  Widget _benefit(String title, String sub) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration:
              const BoxDecoration(color: _cTint, shape: BoxShape.circle),
          child: const Icon(Icons.check_rounded, size: 16, color: _cAccent),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: _st(16, FontWeight.w600, Colors.white, height: 1.35)),
              const SizedBox(height: 1),
              Text(sub, style: _st(13, FontWeight.w400, _cMuted, height: 1.4)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _benefits() {
    final String days = _t('daysSub', n: _kFreeHistoryDays);
    final items = <List<String>>[
      [_t('b1'), _t('b1s', n: _kFreeAnalysesPerMonth)],
      [_t('b2'), _t('b2s', n: _kFreeAiWorkoutsPerWeek)],
      [_t('b3'), _t('b3s', n: _kFreeCustomExercises)],
      [_t('b4'), days],
      [_t('b5'), days],
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < items.length; i++) ...[
            if (i > 0) const SizedBox(height: 18),
            _benefit(items[i][0], items[i][1]),
          ],
        ],
      ),
    );
  }

  // ---------- plans ----------
  Widget _radio(bool selected) {
    return Container(
      width: 22,
      height: 22,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: selected ? _cAccent : _cRingOff, width: 2),
      ),
      child: selected
          ? Container(
              width: 10,
              height: 10,
              decoration:
                  const BoxDecoration(color: _cAccent, shape: BoxShape.circle),
            )
          : null,
    );
  }

  Widget _planRow({
    required bool selected,
    required String name,
    String? badge,
    required String price,
    required String unit,
    String? small,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 62),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? _cCardOn : _cCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? _cAccent : _cBorder, width: 1.5),
        ),
        child: Row(
          children: [
            _radio(selected),
            const SizedBox(width: 12),
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _st(16, FontWeight.w600, Colors.white),
                    ),
                  ),
                  if (badge != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _cTint,
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Text(
                        badge,
                        maxLines: 1,
                        style: _st(12, FontWeight.w600, _cMint),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      price,
                      textDirection: ui.TextDirection.ltr,
                      style: _st(19, FontWeight.w700, Colors.white),
                    ),
                    const SizedBox(width: 4),
                    Text(unit, style: _st(12.5, FontWeight.w400, _cMuted)),
                  ],
                ),
                if (small != null) ...[
                  const SizedBox(height: 2),
                  Text(small, style: _st(12, FontWeight.w400, _cMuted)),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _plans() {
    final y = _yearly;
    final m = _monthly;
    final int pct = _savePct();
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (y != null)
          _planRow(
            selected: _selIsYear,
            name: _t('yearly'),
            badge: pct > 0 ? _t('save', n: pct) : null,
            price: y.storeProduct.priceString,
            unit: _t('perYear'),
            small: _t('monthLine', p: _iso(_perMonth(y))),
            onTap: () => setState(() => _yearSelected = true),
          ),
        if (y != null && m != null) const SizedBox(height: 8),
        if (m != null)
          _planRow(
            selected: !_selIsYear,
            name: _t('monthly'),
            price: m.storeProduct.priceString,
            unit: _t('perMonth'),
            onTap: () => setState(() => _yearSelected = false),
          ),
      ],
    );
  }

  Widget _skeletonRow(String name, bool selected) {
    return Container(
      height: 62,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: selected ? _cCardOn : _cCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: selected ? _cAccent : _cBorder, width: 1.5),
      ),
      child: Row(
        children: [
          _radio(selected),
          const SizedBox(width: 12),
          Expanded(
            child: Text(name, style: _st(16, FontWeight.w600, Colors.white)),
          ),
          Container(
            width: 76,
            height: 16,
            decoration: BoxDecoration(
              color: const Color(0xFF2A423D),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _cCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cBorder),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.error_outline_rounded,
                  size: 20, color: _cNotice),
              const SizedBox(width: 8),
              Expanded(
                child: Text(_t('errTitle'),
                    style: _st(15, FontWeight.w700, Colors.white)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(_t('errBody'),
              style: _st(13, FontWeight.w400, _cMuted, height: 1.4)),
          const SizedBox(height: 10),
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: _load,
              child: Container(
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _cAccent, width: 1.5),
                ),
                child:
                    Text(_t('retry'), style: _st(15, FontWeight.w700, _cMint)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------- buttons ----------
  Widget _cta({
    required String label,
    VoidCallback? onTap,
    bool spinner = false,
  }) {
    final bool live = onTap != null || spinner;
    final Color fg = live ? _cCtaText : _cCtaOffText;
    return Material(
      color: live ? _cCta : _cCtaOff,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          height: 54,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (spinner) ...[
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    valueColor: AlwaysStoppedAnimation<Color>(fg),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _st(17, FontWeight.w700, fg),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _link(String label, Future Function()? action) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: _busy || action == null ? null : () => action(),
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        alignment: Alignment.center,
        child: Text(label, style: _st(12.5, FontWeight.w500, _cMuted)),
      ),
    );
  }

  Widget _footer() {
    return Material(
      color: Colors.transparent,
      child: Wrap(
        alignment: WrapAlignment.center,
        children: [
          _link(_t('restore'), _restore),
          _link(_t('terms'), widget.onOpenTerms),
          _link(_t('privacy'), widget.onOpenPrivacy),
        ],
      ),
    );
  }

  // ---------- bottom panel ----------
  Widget _bottom() {
    final List<Widget> c = [];

    if (_stage == _Stage.loading) {
      c.add(_skeletonRow(_t('yearly'), true));
      c.add(const SizedBox(height: 8));
      c.add(_skeletonRow(_t('monthly'), false));
      c.add(const SizedBox(height: 16));
      c.add(_cta(label: _t('loading')));
      c.add(const SizedBox(height: 40));
    } else if (_stage == _Stage.failed) {
      c.add(_errorCard());
      c.add(const SizedBox(height: 16));
      c.add(_cta(label: _t('ctaPlain')));
      c.add(const SizedBox(height: 40));
    } else {
      final sel = _selected;
      final int trial = _selTrial;
      final String price = _iso(sel?.storeProduct.priceString ?? '');
      final String legal = (trial > 0 ? _t('trialPrefix', n: trial) : '') +
          _t(_selIsYear ? 'legalYear' : 'legalMonth', p: price);

      c.add(IgnorePointer(
        ignoring: _busy,
        child: Opacity(opacity: _busy ? 0.65 : 1, child: _plans()),
      ));
      if (_noticeKey != null) {
        c.add(const SizedBox(height: 10));
        c.add(Text(
          _t(_noticeKey!),
          textAlign: TextAlign.center,
          style: _st(13, FontWeight.w500, _cNotice, height: 1.35),
        ));
        c.add(const SizedBox(height: 10));
      } else {
        c.add(const SizedBox(height: 16));
      }
      c.add(_cta(
        label: _busy
            ? _t('purchasing')
            : (trial > 0 ? _t('ctaTrial', n: trial) : _t('ctaPlain')),
        spinner: _busy,
        onTap: _busy ? null : _buy,
      ));
      c.add(const SizedBox(height: 8));
      c.add(ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 32),
        child: Text(
          legal,
          textAlign: TextAlign.center,
          style: _st(12, FontWeight.w400, _cMuted, height: 1.35),
        ),
      ));
    }

    c.add(_footer());

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: c,
      ),
    );
  }

  // ---------- screens ----------
  Widget _paywall() {
    return Stack(
      children: [
        Column(
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (ctx, box) => SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 48, 24, 16),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: math.max(0, box.maxHeight - 64),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _header(),
                        const SizedBox(height: 32),
                        _benefits(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            _bottom(),
          ],
        ),
        Positioned(
          top: 0,
          left: 8,
          child: IconButton(
            tooltip: _t('close'),
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            onPressed: _busy ? null : () => widget.onClose?.call(),
            icon: const Icon(Icons.close_rounded, size: 24, color: _cMuted),
          ),
        ),
      ],
    );
  }

  Widget _successRow(IconData icon, String name, String value, bool first) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        border: first
            ? null
            : const Border(top: BorderSide(color: _cDivider, width: 1)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: _cAccent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _st(15, FontWeight.w600, Colors.white),
            ),
          ),
          const SizedBox(width: 8),
          Text(value, style: _st(13.5, FontWeight.w700, _cMint)),
        ],
      ),
    );
  }

  Widget _success() {
    final String unlimited = _t('unlimited');
    final String allTime = _t('allTime');
    return Column(
      children: [
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 104,
                      height: 104,
                      decoration: BoxDecoration(
                        color: _cTint,
                        shape: BoxShape.circle,
                        border: Border.all(color: _cAccent, width: 5),
                      ),
                      child: const Icon(Icons.check_rounded,
                          size: 56, color: _cAccent),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    _t('okTitle'),
                    textAlign: TextAlign.center,
                    style: _st(30, FontWeight.w700, Colors.white, height: 1.25),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _startedTrialDays > 0
                        ? _t('okTrial', n: _startedTrialDays)
                        : _t('okPlain'),
                    textAlign: TextAlign.center,
                    style: _st(14.5, FontWeight.w400, _cMuted, height: 1.4),
                  ),
                  const SizedBox(height: 28),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(_t('okOpen'),
                        style: _st(12.5, FontWeight.w600, _cMuted)),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: _cCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _cBorder),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _successRow(Icons.videocam_outlined, _t('rForm'),
                            unlimited, true),
                        _successRow(Icons.auto_awesome_outlined, _t('rAi'),
                            unlimited, false),
                        _successRow(Icons.add_box_outlined, _t('rCustom'),
                            unlimited, false),
                        _successRow(Icons.history_rounded, _t('rHistory'),
                            allTime, false),
                        _successRow(Icons.bar_chart_rounded, _t('rStats'),
                            allTime, false),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: _cta(
            label: _t('continue'),
            onTap: () => widget.onClose?.call(),
          ),
        ),
      ],
    );
  }

  // ---------- build ----------
  @override
  Widget build(BuildContext context) {
    _lang = 'en';
    try {
      final l = FFLocalizations.of(context).languageCode.trim().toLowerCase();
      if (l.isNotEmpty) _lang = l;
    } catch (_) {}
    final bool rtl = _kRtl.contains(_lang);
    final EdgeInsets safe = MediaQuery.of(context).padding;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Directionality(
        textDirection: rtl ? ui.TextDirection.rtl : ui.TextDirection.ltr,
        child: Container(
          width: widget.width,
          height: widget.height,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [_cBgTop, _cBgBottom],
            ),
          ),
          child: Padding(
            padding: EdgeInsets.only(top: safe.top, bottom: safe.bottom),
            child: _stage == _Stage.success ? _success() : _paywall(),
          ),
        ),
      ),
    );
  }
}
// Set your widget name, define your parameter, and then add the
// boilerplate code using the `</>` button on the right!
