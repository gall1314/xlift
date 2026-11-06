import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kLocaleStorageKey = '__locale_key__';

class FFLocalizations {
  FFLocalizations(this.locale);

  final Locale locale;

  static FFLocalizations of(BuildContext context) =>
      Localizations.of<FFLocalizations>(context, FFLocalizations)!;

  static List<String> languages() => ['en', 'es', 'de', 'fr', 'he'];

  static late SharedPreferences _prefs;
  static Future initialize() async =>
      _prefs = await SharedPreferences.getInstance();
  static Future storeLocale(String locale) =>
      _prefs.setString(_kLocaleStorageKey, locale);
  static Locale? getStoredLocale() {
    final locale = _prefs.getString(_kLocaleStorageKey);
    return locale != null && locale.isNotEmpty ? createLocale(locale) : null;
  }

  String get languageCode => locale.toString();
  String? get languageShortCode =>
      _languagesWithShortCode.contains(locale.toString())
          ? '${locale.toString()}_short'
          : null;
  int get languageIndex => languages().contains(languageCode)
      ? languages().indexOf(languageCode)
      : 0;

  String getText(String key) =>
      (kTranslationsMap[key] ?? {})[locale.toString()] ?? '';

  String getVariableText({
    String? enText = '',
    String? esText = '',
    String? deText = '',
    String? frText = '',
    String? heText = '',
  }) =>
      [enText, esText, deText, frText, heText][languageIndex] ?? '';

  static const Set<String> _languagesWithShortCode = {
    'ar',
    'az',
    'ca',
    'cs',
    'da',
    'de',
    'dv',
    'en',
    'es',
    'et',
    'fi',
    'fr',
    'gr',
    'he',
    'hi',
    'hu',
    'it',
    'km',
    'ku',
    'mn',
    'ms',
    'no',
    'pt',
    'ro',
    'ru',
    'rw',
    'sv',
    'th',
    'uk',
    'vi',
  };
}

/// Used if the locale is not supported by GlobalMaterialLocalizations.
class FallbackMaterialLocalizationDelegate
    extends LocalizationsDelegate<MaterialLocalizations> {
  const FallbackMaterialLocalizationDelegate();

  @override
  bool isSupported(Locale locale) => _isSupportedLocale(locale);

  @override
  Future<MaterialLocalizations> load(Locale locale) async =>
      SynchronousFuture<MaterialLocalizations>(
        const DefaultMaterialLocalizations(),
      );

  @override
  bool shouldReload(FallbackMaterialLocalizationDelegate old) => false;
}

/// Used if the locale is not supported by GlobalCupertinoLocalizations.
class FallbackCupertinoLocalizationDelegate
    extends LocalizationsDelegate<CupertinoLocalizations> {
  const FallbackCupertinoLocalizationDelegate();

  @override
  bool isSupported(Locale locale) => _isSupportedLocale(locale);

  @override
  Future<CupertinoLocalizations> load(Locale locale) =>
      SynchronousFuture<CupertinoLocalizations>(
        const DefaultCupertinoLocalizations(),
      );

  @override
  bool shouldReload(FallbackCupertinoLocalizationDelegate old) => false;
}

class FFLocalizationsDelegate extends LocalizationsDelegate<FFLocalizations> {
  const FFLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => _isSupportedLocale(locale);

  @override
  Future<FFLocalizations> load(Locale locale) =>
      SynchronousFuture<FFLocalizations>(FFLocalizations(locale));

  @override
  bool shouldReload(FFLocalizationsDelegate old) => false;
}

Locale createLocale(String language) => language.contains('_')
    ? Locale.fromSubtags(
        languageCode: language.split('_').first,
        scriptCode: language.split('_').last,
      )
    : Locale(language);

bool _isSupportedLocale(Locale locale) {
  final language = locale.toString();
  return FFLocalizations.languages().contains(
    language.endsWith('_')
        ? language.substring(0, language.length - 1)
        : language,
  );
}

final kTranslationsMap = <Map<String, Map<String, String>>>[
  // exerciseHistory
  {
    'ku6z9m7t': {
      'en': 'Overview',
      'de': 'Überblick',
      'es': 'Descripción general',
      'fr': 'Aperçu',
      'he': 'סקירה כללית',
    },
    'zvb4qoh3': {
      'en': 'How To Perform',
      'de': 'So geht\'s',
      'es': 'Cómo realizar',
      'fr': 'Comment réaliser',
      'he': 'איך לבצע',
    },
    '27u3wsjl': {
      'en': 'Muscles Worked',
      'de': 'Beanspruchte Muskeln',
      'es': 'Músculos trabajados',
      'fr': 'Muscles sollicités',
      'he': 'שרירים שעבדו',
    },
    '6ofb0o43': {
      'en': 'Primary',
      'de': 'Primär',
      'es': 'Primario',
      'fr': 'Primaire',
      'he': 'יְסוֹדִי',
    },
    'nvw2uk4d': {
      'en': 'Secondary',
      'de': 'Sekundär',
      'es': 'Secundario',
      'fr': 'Secondaire',
      'he': 'מִשׁנִי',
    },
    'o7q6na44': {
      'en': 'Form Tips',
      'de': 'Formtipps',
      'es': 'Consejos sobre el formulario',
      'fr': 'Conseils de forme',
      'he': 'טיפים לטופס',
    },
    'u4s7bsvq': {
      'en': '🏋️',
      'de': '🏋️',
      'es': '🏋️',
      'fr': '🏋️',
      'he': '🏋️',
    },
    'h650k2gi': {
      'en': 'History',
      'de': 'Verlauf',
      'es': 'Historia',
      'fr': 'Historique',
      'he': 'היסטוריה',
    },
    'qga1ngcg': {
      'en': 'COMPARED TO PREVIOUS',
      'de': 'VS. LETZTES MAL',
      'es': 'VS. ANTERIOR',
      'fr': 'VS. PRÉCÉDENT',
      'he': 'לעומת הקודם',
    },
    '4cxxfjxo': {
      'en': 'Analytics',
      'de': 'Statistik',
      'es': 'Analítica',
      'fr': '\tStatistiques',
      'he': 'סטטיסטיקה',
    },
    'avmae72l': {
      'en': 'Personal Records',
      'de': 'Persönliche Rekorde ',
      'es': 'Récords personales',
      'fr': 'Records personnels',
      'he': 'שיאים אישיים',
    },
    'bthuwexp': {
      'en': 'Max Reps',
      'de': '\tMax. Wdh.',
      'es': '\tReps máx.',
      'fr': 'Reps max',
      'he': 'מקסימום חזרות',
    },
    'h51udxz4': {
      'en': 'Max Weight',
      'de': 'Maximalgewicht',
      'es': 'Peso máximo',
      'fr': '\tPoids max',
      'he': 'משקל מקסימלי',
    },
    'phz2sduw': {
      'en': 'Max Volume',
      'de': 'Max. Volumen',
      'es': 'Volumen máximo',
      'fr': 'Volume max',
      'he': 'נפח מקסימלי',
    },
    'bjqf2605': {
      'en': 'Personal Records',
      'de': 'Persönliche Rekorde',
      'es': 'Récords personales',
      'fr': 'Records personnels',
      'he': 'שיאים אישיים',
    },
    'kq3nc7bv': {
      'en': 'Max Reps',
      'de': '\tMax. Wdh.',
      'es': 'Reps máx.',
      'fr': 'Reps max',
      'he': 'מקסימום חזרות',
    },
    'cftge1vd': {
      'en': 'Max Session',
      'de': 'Beste Einheit',
      'es': 'Mejor sesión',
      'fr': 'Meilleure séance',
      'he': 'שיא לאימון',
    },
    '0coub435': {
      'en': 'Avrage Reps',
      'de': 'Ø Wdh.',
      'es': 'Reps promedio',
      'fr': '\tReps moy.',
      'he': 'ממוצע חזרות',
    },
    'f2s9p3qk': {
      'en': 'Personal Records',
      'de': 'Persönliche Rekorde',
      'es': 'Récords personales',
      'fr': 'Records personnels',
      'he': 'שיאים אישיים',
    },
    'k29kz8uw': {
      'en': 'Max Session Time',
      'de': 'Maximale Sitzungszeit',
      'es': 'Tiempo máximo de sesión',
      'fr': 'Durée maximale de la session',
      'he': 'זמן מקסימלי של סשן',
    },
    'lh5csxpm': {
      'en': 'Avrage Duration',
      'de': 'Durchschnittliche Dauer',
      'es': 'Duración promedio',
      'fr': 'Durée moyenne',
      'he': 'משך זמן ממוצע',
    },
    'yeuygv4r': {
      'en': 'Max Duration',
      'de': 'Maximale Dauer',
      'es': 'Duración máxima',
      'fr': 'Durée maximale',
      'he': 'משך זמן מקסימלי',
    },
    'jgxbou9q': {
      'en': 'Personal Records',
      'de': 'Persönliche Daten',
      'es': 'Registros personales',
      'fr': 'Dossiers personnels',
      'he': 'שיאים אישיים',
    },
    'vrhmm731': {
      'en': 'Max Reps',
      'de': 'Maximale Wiederholungen',
      'es': 'Repeticiones máximas',
      'fr': 'Nombre maximal de répétitions',
      'he': 'מקסימום חזרות',
    },
    't0sky0qb': {
      'en': 'Max Session Reps',
      'de': 'Maximale Wiederholungen pro Sitzung',
      'es': 'Repeticiones máximas por sesión',
      'fr': 'Nombre maximal de répétitions par session',
      'he': 'מספר חזרות מקסימלי של סשנים',
    },
    '9qhx4sbo': {
      'en': 'Min Assistance',
      'de': 'Mindestunterstützung',
      'es': 'Asistencia mínima',
      'fr': 'Assistance minimale',
      'he': 'סיוע מינימלי',
    },
    'evcm8m56': {
      'en': 'Exercise Analytics',
      'de': 'Trainingsanalyse',
      'es': 'Análisis de ejercicios',
      'fr': 'Analyse des exercices',
      'he': 'אנליטיקה של פעילות גופנית',
    },
    'xern0erp': {
      'en': 'Track your progress over time',
      'de': 'Verfolge deinen Fortschritt im Laufe der Zeit',
      'es': 'Haz un seguimiento de tu progreso a lo largo del tiempo.',
      'fr': 'Suivez vos progrès au fil du temps',
      'he': 'עקוב אחר ההתקדמות שלך לאורך זמן',
    },
    'cwwga2vf': {
      'en': 'Reps',
      'de': 'Reps',
      'es': 'Representantes',
      'fr': 'Réputation',
      'he': 'נציגים',
    },
    'slnrgrwv': {
      'en': 'Max Weight',
      'de': 'Maximalgewicht',
      'es': 'Peso máximo',
      'fr': 'Poids maximal',
      'he': 'משקל מקסימלי',
    },
    'jeq41t8a': {
      'en': 'Volume',
      'de': 'Volumen',
      'es': 'Volumen',
      'fr': 'Volume',
      'he': 'כֶּרֶך',
    },
    'eks7x5yt': {
      'en': 'Reps',
      'de': 'Reps',
      'es': 'Representantes',
      'fr': 'Réputation',
      'he': 'נציגים',
    },
    'gk5s7s0f': {
      'en': 'No analytics yet',
      'de': 'Noch keine Analysen',
      'es': 'Aún no hay análisis',
      'fr': 'Aucune analyse pour le moment',
      'he': 'עדיין אין אנליטיקה',
    },
    'fo4hu4ko': {
      'en': 'Log a few sessions to see how this exercise progresses over time.',
      'de':
          'Protokollieren Sie einige Trainingseinheiten, um zu sehen, wie sich diese Übung im Laufe der Zeit entwickelt.',
      'es':
          'Registra algunas sesiones para ver cómo progresa este ejercicio con el tiempo.',
      'fr':
          'Enregistrez quelques séances pour observer l\'évolution de cet exercice au fil du temps.',
      'he': 'רשמו כמה אימונים כדי לראות כיצד התרגיל הזה מתקדם לאורך זמן.',
    },
    'sgxwgzhz': {
      'en': 'Current Week',
      'de': 'Aktuelle Woche',
      'es': 'Semana actual',
      'fr': 'Semaine actuelle',
      'he': 'השבוע הנוכחי',
    },
    'oeshhned': {
      'en': 'Best Session',
      'de': 'Beste Session',
      'es': 'Mejor sesión',
      'fr': 'Meilleure session',
      'he': 'הסשן הטוב ביותר',
    },
    'tyw7dth7': {
      'en': 'Improvement',
      'de': 'Verbesserung',
      'es': 'Mejora',
      'fr': 'Amélioration',
      'he': 'הַשׁבָּחָה',
    },
    '2ok2d6bb': {
      'en': 'Exercise Analytics',
      'de': 'Trainingsanalyse',
      'es': 'Análisis de ejercicios',
      'fr': 'Analyse des exercices',
      'he': 'אנליטיקה של פעילות גופנית',
    },
    'hgboufyn': {
      'en': 'Track your progress over time',
      'de': 'Verfolge deinen Fortschritt im Laufe der Zeit',
      'es': 'Haz un seguimiento de tu progreso a lo largo del tiempo.',
      'fr': 'Suivez vos progrès au fil du temps',
      'he': 'עקוב אחר ההתקדמות שלך לאורך זמן',
    },
    'h8gou1y0': {
      'en': 'No analytics yet',
      'de': 'Noch keine Analysen',
      'es': 'Aún no hay análisis',
      'fr': 'Aucune analyse pour le moment',
      'he': 'עדיין אין אנליטיקה',
    },
    'lwq4ljxq': {
      'en': 'Log a few sessions to see how this exercise progresses over time.',
      'de':
          'Protokollieren Sie einige Trainingseinheiten, um zu sehen, wie sich diese Übung im Laufe der Zeit entwickelt.',
      'es':
          'Registra algunas sesiones para ver cómo progresa este ejercicio con el tiempo.',
      'fr':
          'Enregistrez quelques séances pour observer l\'évolution de cet exercice au fil du temps.',
      'he': 'רשמו כמה אימונים כדי לראות כיצד התרגיל הזה מתקדם לאורך זמן.',
    },
    'iuau6kxi': {
      'en': 'Current Week',
      'de': 'Aktuelle Woche',
      'es': 'Semana actual',
      'fr': 'Semaine actuelle',
      'he': 'השבוע הנוכחי',
    },
    'rw1dsevg': {
      'en': 'Best Session',
      'de': 'Beste Session',
      'es': 'Mejor sesión',
      'fr': 'Meilleure session',
      'he': 'הסשן הטוב ביותר',
    },
    'hbweo0lu': {
      'en': 'Improvement',
      'de': 'Verbesserung',
      'es': 'Mejora',
      'fr': 'Amélioration',
      'he': 'הַשׁבָּחָה',
    },
    'bplde2dk': {
      'en': 'Exercise Analytics',
      'de': 'Trainingsanalyse',
      'es': 'Análisis de ejercicios',
      'fr': 'Analyse des exercices',
      'he': 'אנליטיקה של פעילות גופנית',
    },
    'b2vq42si': {
      'en': 'Track your progress over time',
      'de': 'Verfolge deinen Fortschritt im Laufe der Zeit',
      'es': 'Haz un seguimiento de tu progreso a lo largo del tiempo.',
      'fr': 'Suivez vos progrès au fil du temps',
      'he': 'עקוב אחר ההתקדמות שלך לאורך זמן',
    },
    'ruz65xup': {
      'en': 'No analytics yet',
      'de': 'Noch keine Analysen',
      'es': 'Aún no hay análisis',
      'fr': 'Aucune analyse pour le moment',
      'he': 'עדיין אין אנליטיקה',
    },
    '6c6rkd9k': {
      'en': 'Log a few sessions to see how this exercise progresses over time.',
      'de':
          'Protokollieren Sie einige Trainingseinheiten, um zu sehen, wie sich diese Übung im Laufe der Zeit entwickelt.',
      'es':
          'Registra algunas sesiones para ver cómo progresa este ejercicio con el tiempo.',
      'fr':
          'Enregistrez quelques séances pour observer l\'évolution de cet exercice au fil du temps.',
      'he': 'רשמו כמה אימונים כדי לראות כיצד התרגיל הזה מתקדם לאורך זמן.',
    },
    '60fi9hh9': {
      'en': 'Current Week',
      'de': 'Aktuelle Woche',
      'es': 'Semana actual',
      'fr': 'Semaine actuelle',
      'he': 'השבוע הנוכחי',
    },
    'sfaomq97': {
      'en': 'Total Sessions',
      'de': 'Gesamtsitzungen',
      'es': 'Sesiones totales',
      'fr': 'Nombre total de séances',
      'he': 'סך כל הפעילויות',
    },
    'rwjhwmnq': {
      'en': 'Improvement',
      'de': 'Verbesserung',
      'es': 'Mejora',
      'fr': 'Amélioration',
      'he': 'הַשׁבָּחָה',
    },
    'cy8fn0ug': {
      'en': 'Exercise Analytics',
      'de': 'Trainingsanalyse',
      'es': 'Análisis de ejercicios',
      'fr': 'Analyse des exercices',
      'he': 'אנליטיקה של פעילות גופנית',
    },
    'zahprrwn': {
      'en': 'Track your progress over time',
      'de': 'Verfolge deinen Fortschritt im Laufe der Zeit',
      'es': 'Haz un seguimiento de tu progreso a lo largo del tiempo.',
      'fr': 'Suivez vos progrès au fil du temps',
      'he': 'עקוב אחר ההתקדמות שלך לאורך זמן',
    },
    'q718hvzg': {
      'en': 'Reps',
      'de': 'Reps',
      'es': 'Representantes',
      'fr': 'Réputation',
      'he': 'נציגים',
    },
    '4gyjxuio': {
      'en': 'Assistance',
      'de': 'Hilfe',
      'es': 'Asistencia',
      'fr': 'Assistance',
      'he': 'סִיוּעַ',
    },
    'p2hu3yvy': {
      'en': 'Volume',
      'de': 'Volumen',
      'es': 'Volumen',
      'fr': 'Volume',
      'he': 'כֶּרֶך',
    },
    'prmjwwik': {
      'en': 'Reps',
      'de': 'Reps',
      'es': 'Representantes',
      'fr': 'Réputation',
      'he': 'נציגים',
    },
    'u5si91ad': {
      'en': 'Current Week',
      'de': 'Aktuelle Woche',
      'es': 'Semana actual',
      'fr': 'Semaine actuelle',
      'he': 'השבוע הנוכחי',
    },
    '9qlq32ae': {
      'en': 'Best Session',
      'de': 'Beste Session',
      'es': 'Mejor sesión',
      'fr': 'Meilleure session',
      'he': 'הסשן הטוב ביותר',
    },
    'zhfjzh8q': {
      'en': 'Improvement',
      'de': 'Verbesserung',
      'es': 'Mejora',
      'fr': 'Amélioration',
      'he': 'הַשׁבָּחָה',
    },
    'na9xnckt': {
      'en': 'Estimated 1RM',
      'de': 'Geschätztes 1RM',
      'es': 'Estimado 1RM',
      'fr': '1RM estimé',
      'he': '1RM משוער',
    },
    'eqe4fjjo': {
      'en': 'Based on your heaviest set using the Epley formula',
      'de':
          'Basierend auf Ihrem schwersten Satz unter Verwendung der Epley-Formel',
      'es': 'Basado en tu serie más pesada usando la fórmula de Epley',
      'fr': 'En fonction de votre poids le plus élevé, selon la formule Epley',
      'he': 'בהתבסס על הסט הכבד ביותר שלך באמצעות נוסחת אפלי',
    },
    't36624zb': {
      'en': '1RM = weight × (1 + reps ÷ 30)',
      'de': '1RM = Gewicht × (1 + Wiederholungen ÷ 30)',
      'es': '1RM = peso × (1 + repeticiones ÷ 30)',
      'fr': '1RM = poids × (1 + répétitions ÷ 30)',
      'he': '1RM = משקל × (1 + חזרות ÷ 30)',
    },
    'ghmsigoc': {
      'en': 'Home',
      'de': 'Heim',
      'es': 'Hogar',
      'fr': 'Maison',
      'he': 'בַּיִת',
    },
  },
  // settingss
  {
    '5jtsd6pb': {
      'en': 'PROFILE',
      'de': 'PROFIL',
      'es': 'PERFIL',
      'fr': 'PROFIL',
      'he': 'פּרוֹפִיל',
    },
    'h3fvjxfg': {
      'en': 'PREFERENCES',
      'de': 'PRÄFERENZEN',
      'es': 'PREFERENCIAS',
      'fr': 'PRÉFÉRENCES',
      'he': 'העדפות',
    },
    'lw5la6gy': {
      'en': 'Units Preferences',
      'de': 'Einheitenpräferenzen',
      'es': 'Preferencias de unidades',
      'fr': 'Préférences d\'unités',
      'he': 'העדפות יחידות',
    },
    'du4vwpii': {
      'en': 'Appearance',
      'de': 'Aussehen',
      'es': 'Apariencia',
      'fr': 'Apparence',
      'he': 'הוֹפָעָה',
    },
    '8nr4khy4': {
      'en': 'PAYMENTS',
      'de': 'ZAHLUNGEN',
      'es': 'PAGOS',
      'fr': 'PAIEMENTS',
      'he': 'תשלומים',
    },
    '3lvournw': {
      'en': 'Upgrade to Premium',
      'de': 'Upgrade auf Premium',
      'es': 'Actualiza a Premium',
      'fr': 'Passez à la version Premium',
      'he': 'שדרג לפרימיום',
    },
    'lzem2ez3': {
      'en': 'NOTIFICATIONS',
      'de': 'BENACHRICHTIGUNGEN',
      'es': 'NOTIFICACIONES',
      'fr': 'NOTIFICATIONS',
      'he': 'התראות',
    },
    'j7ei20yf': {
      'en': 'Notifications',
      'de': 'Benachrichtigungen',
      'es': 'Notificaciones',
      'fr': 'Notifications',
      'he': 'התראות',
    },
    '6hnt4tpo': {
      'en': 'FEEDBACK',
      'de': 'RÜCKMELDUNG',
      'es': 'COMENTARIO',
      'fr': 'RETOUR',
      'he': 'מָשׁוֹב',
    },
    '4fkdiotd': {
      'en': 'Feedback / Report a Bug',
      'de': 'Feedback / Fehler melden',
      'es': 'Comentarios / Informar de un error',
      'fr': 'Commentaires / Signaler un bug',
      'he': 'משוב / דיווח על באג',
    },
    'v0mxk3o4': {
      'en': 'ACCOUNT',
      'de': 'KONTO',
      'es': 'CUENTA',
      'fr': 'COMPTE',
      'he': 'חֶשְׁבּוֹן',
    },
    'uvii8akr': {
      'en': 'Account',
      'de': 'Konto',
      'es': 'Cuenta',
      'fr': 'Compte',
      'he': 'חֶשְׁבּוֹן',
    },
    'rhs7fkvg': {
      'en': 'Log Out',
      'de': 'Abmelden',
      'es': 'Finalizar la sesión',
      'fr': 'Déconnexion',
      'he': 'התנתק',
    },
    'hq7ge7vi': {
      'en': 'Privacy Policy',
      'de': 'Datenschutzrichtlinie',
      'es': 'política de privacidad',
      'fr': 'politique de confidentialité',
      'he': 'מדיניות פרטיות',
    },
    'cgmkc0xi': {
      'en': '·',
      'de': '·',
      'es': '·',
      'fr': '·',
      'he': '·',
    },
    '8pq8yabs': {
      'en': 'Terms & Conditions',
      'de': 'Allgemeine Geschäftsbedingungen',
      'es': 'Términos y condiciones',
      'fr': 'Conditions générales',
      'he': 'תנאים והגבלות',
    },
    'lqu3vuzb': {
      'en': 'Home',
      'de': 'Heim',
      'es': 'Hogar',
      'fr': 'Maison',
      'he': 'בַּיִת',
    },
  },
  // templateWorkout
  {
    'c6xjjejd': {
      'en': 'Target Muscles',
      'de': 'Zielmuskeln',
      'es': 'Músculos objetivo',
      'fr': 'Muscles cibles',
      'he': 'שרירי מטרה',
    },
    '6pyvugqk': {
      'en': 'Min',
      'de': 'Min',
      'es': 'Min',
      'fr': 'Min',
      'he': 'דקות',
    },
    'ckvm2bx1': {
      'en': 'Exercises',
      'de': 'Übungen',
      'es': 'Ceremonias',
      'fr': 'Exercices',
      'he': 'תרגילים',
    },
    'degi078n': {
      'en': ' Save to My Workouts\n',
      'de': 'Zu „Meine Trainings“ hinzufügen',
      'es': 'Guardar en Mis entrenamientos',
      'fr': 'Enregistrer dans Mes entraînements',
      'he': 'שמור באימונים שלי',
    },
    'jacd6nom': {
      'en': 'Template Workout',
      'de': 'Vorlage-Workout',
      'es': 'Plantilla de entrenamiento',
      'fr': 'Modèle d\'entraînement',
      'he': 'אימון תבנית',
    },
    '3k6udnd5': {
      'en': 'Home',
      'de': 'Heim',
      'es': 'Hogar',
      'fr': 'Maison',
      'he': 'בַּיִת',
    },
  },
  // Signup_in
  {
    'nkm4pvg5': {
      'en': 'Sign In',
      'de': 'Anmelden',
      'es': 'Iniciar sesión',
      'fr': 'Se connecter',
      'he': 'כניסה',
    },
    '5fhndy9r': {
      'en': 'Let\'s get started by filling out the form below.',
      'de': 'Beginnen wir, indem Sie das untenstehende Formular ausfüllen.',
      'es': 'Comencemos rellenando el formulario que aparece a continuación.',
      'fr': 'Commençons par remplir le formulaire ci-dessous.',
      'he': 'בואו נתחיל על ידי מילוי הטופס למטה.',
    },
    'ytc02vw4': {
      'en': 'Email',
      'de': 'E-Mail',
      'es': 'Correo electrónico',
      'fr': 'E-mail',
      'he': 'אֶלֶקטרוֹנִי',
    },
    'uzscjsyn': {
      'en': 'Password',
      'de': 'Passwort',
      'es': 'Contraseña',
      'fr': 'Mot de passe',
      'he': 'סִיסמָה',
    },
    '9e7mtvf9': {
      'en': 'Sign In',
      'de': 'Anmelden',
      'es': 'Iniciar sesión',
      'fr': 'Se connecter',
      'he': 'כניסה',
    },
    '4nif9y6v': {
      'en': 'Forgot Password',
      'de': 'Passwort vergessen?',
      'es': 'Has olvidado tu contraseña',
      'fr': 'Mot de passe oublié',
      'he': 'שכחת סיסמה',
    },
    'suol384f': {
      'en': 'Sign Up',
      'de': 'Melden Sie sich an',
      'es': 'Inscribirse',
      'fr': 'S\'inscrire',
      'he': 'הרשמה',
    },
    'mjnq8dp5': {
      'en': 'Let\'s get started by filling out the form below.',
      'de': 'Beginnen wir, indem Sie das untenstehende Formular ausfüllen.',
      'es': 'Comencemos rellenando el formulario que aparece a continuación.',
      'fr': 'Commençons par remplir le formulaire ci-dessous.',
      'he': 'בואו נתחיל על ידי מילוי הטופס למטה.',
    },
    'vcaajwrs': {
      'en': 'Email',
      'de': 'E-Mail',
      'es': 'Correo electrónico',
      'fr': 'E-mail',
      'he': 'אֶלֶקטרוֹנִי',
    },
    'yp8lx9yy': {
      'en': 'Password',
      'de': 'Passwort',
      'es': 'Contraseña',
      'fr': 'Mot de passe',
      'he': 'סִיסמָה',
    },
    'x7y6poyb': {
      'en': 'Confirm Password',
      'de': 'Passwort bestätigen',
      'es': 'confirmar Contraseña',
      'fr': 'Confirmez le mot de passe',
      'he': 'אשר סיסמה',
    },
    'b0e5enwt': {
      'en': 'Create Account',
      'de': 'Benutzerkonto erstellen',
      'es': 'Crear una cuenta',
      'fr': 'Créer un compte',
      'he': 'צור חשבון',
    },
    'bqmguf7o': {
      'en': 'Home',
      'de': 'Heim',
      'es': 'Hogar',
      'fr': 'Maison',
      'he': 'בַּיִת',
    },
  },
  // ForgotPassword02
  {
    'd0eutc80': {
      'en': 'Back',
      'de': 'Zurück',
      'es': 'Atrás',
      'fr': 'Dos',
      'he': 'בְּחֲזָרָה',
    },
    'idahvcji': {
      'en': 'Forgot Password',
      'de': 'Passwort vergessen?',
      'es': 'Has olvidado tu contraseña',
      'fr': 'Mot de passe oublié',
      'he': 'שכחת סיסמה',
    },
    '204o5gtr': {
      'en':
          'We will send you an email with a link to reset your password, please enter the email associated with your account below.',
      'de':
          'Wir senden Ihnen eine E-Mail mit einem Link zum Zurücksetzen Ihres Passworts. Bitte geben Sie unten die mit Ihrem Konto verknüpfte E-Mail-Adresse ein.',
      'es':
          'Le enviaremos un correo electrónico con un enlace para restablecer su contraseña. Por favor, introduzca a continuación la dirección de correo electrónico asociada a su cuenta.',
      'fr':
          'Nous vous enverrons un courriel contenant un lien pour réinitialiser votre mot de passe. Veuillez saisir ci-dessous l\'adresse courriel associée à votre compte.',
      'he':
          'נשלח לך אימייל עם קישור לאיפוס הסיסמה שלך, אנא הזן את כתובת האימייל המקושרת לחשבונך למטה.',
    },
    'nijmhvw7': {
      'en': 'Your email address...',
      'de': 'Ihre E-Mail-Adresse...',
      'es': 'Su dirección de correo electrónico...',
      'fr': 'Votre adresse e-mail...',
      'he': 'כתובת הדוא\"ל שלך...',
    },
    'zjfm9zks': {
      'en': 'Enter your email...',
      'de': 'Geben Sie Ihre E-Mail-Adresse ein...',
      'es': 'Introduce tu correo electrónico...',
      'fr': 'Saisissez votre adresse e-mail...',
      'he': 'הזן את כתובת האימייל שלך...',
    },
    'gyrymd4w': {
      'en': 'Send Link',
      'de': 'Link senden',
      'es': 'Enviar enlace',
      'fr': 'Envoyer le lien',
      'he': 'שלח קישור',
    },
    'htlfdill': {
      'en': 'Home',
      'de': 'Heim',
      'es': 'Hogar',
      'fr': 'Maison',
      'he': 'בַּיִת',
    },
  },
  // workoutV2
  {
    'wuwiu344': {
      'en': '',
      'de': '',
      'es': '',
      'fr': '',
      'he': '',
    },
    'u58x2bqu': {
      'en': 'Finish',
      'de': 'Beenden',
      'es': 'Finalizar',
      'fr': 'Finition',
      'he': 'סִיוּם',
    },
    'toj7tcqv': {
      'en': 'Add Exercise',
      'de': 'Übung hinzufügen',
      'es': 'Agregar ejercicio',
      'fr': 'Ajouter de l\'exercice',
      'he': 'הוסף פעילות גופנית',
    },
    'svlo992g': {
      'en': 'Home',
      'de': 'Heim',
      'es': 'Hogar',
      'fr': 'Maison',
      'he': 'בַּיִת',
    },
  },
  // workoutComparison
  {
    'fddbo90a': {
      'en': 'Total Sets',
      'de': 'Gesamtsätze',
      'es': 'Conjuntos totales',
      'fr': 'Ensembles totaux',
      'he': 'סך כל הסטים',
    },
    'y3jhza38': {
      'en': 'Exercises',
      'de': 'Übungen',
      'es': 'Ceremonias',
      'fr': 'Exercices',
      'he': 'תרגילים',
    },
    'dy71ocxp': {
      'en': 'Duration',
      'de': 'Dauer',
      'es': 'Duración',
      'fr': 'Durée',
      'he': 'מֶשֶׁך',
    },
    'xofe8nlb': {
      'en': 'Volume',
      'de': 'Volumen',
      'es': 'Volumen',
      'fr': 'Volume',
      'he': 'כֶּרֶך',
    },
    'it61datq': {
      'en': 'Muscle Distribution Comparison',
      'de': 'Vergleich der Muskelverteilung',
      'es': 'Comparación de la distribución muscular',
      'fr': 'Comparaison de la répartition musculaire',
      'he': 'השוואת התפלגות שרירים',
    },
    'pvhw1j3g': {
      'en': 'Workout A',
      'de': 'Training A',
      'es': 'Entrenamiento A',
      'fr': 'Entraînement A',
      'he': 'אימון א\'',
    },
    '7s8i3ibj': {
      'en': '',
      'de': '',
      'es': '',
      'fr': '',
      'he': '',
    },
    's0dos1g3': {
      'en': 'Workout B',
      'de': 'Training B',
      'es': 'Entrenamiento B',
      'fr': 'Entraînement B',
      'he': 'אימון ב\'',
    },
    'yn9l20ol': {
      'en': '',
      'de': '',
      'es': '',
      'fr': '',
      'he': '',
    },
    '7gk2gkbu': {
      'en': 'Workout A',
      'de': 'Training A',
      'es': 'Entrenamiento A',
      'fr': 'Entraînement A',
      'he': 'אימון א\'',
    },
    'o12foay3': {
      'en': 'Workout B',
      'de': 'Training B',
      'es': 'Entrenamiento B',
      'fr': 'Entraînement B',
      'he': 'אימון ב\'',
    },
    'uveoeap2': {
      'en': 'Workout Comparison',
      'de': 'Trainingsvergleich',
      'es': 'Comparación de entrenamientos',
      'fr': 'Comparaison des programmes d\'entraînement',
      'he': 'השוואת אימונים',
    },
    'unxdo7tu': {
      'en': 'Home',
      'de': 'Heim',
      'es': 'Hogar',
      'fr': 'Maison',
      'he': 'בַּיִת',
    },
  },
  // workoutLogEditV2
  {
    'fr9z4xqp': {
      'en': 'Save',
      'de': 'Speichern',
      'es': 'Ahorrar',
      'fr': 'Sauvegarder',
      'he': 'לְהַצִיל',
    },
    'ii4brc6e': {
      'en': 'Edit Workout',
      'de': 'Edit Workout',
      'es': 'Editar entrenamiento',
      'fr': 'Modifier l\'entraînement',
      'he': 'עריכת אימון',
    },
    'rjqwdl5n': {
      'en': 'Workout Details',
      'de': 'Trainingsdetails',
      'es': 'Detalles del entrenamiento',
      'fr': 'Détails de l\'entraînement',
      'he': 'פרטי האימון',
    },
    'cvvb2v22': {
      'en': 'Workout Date',
      'de': 'Trainingstermin',
      'es': 'Fecha de entrenamiento',
      'fr': 'Date d\'entraînement',
      'he': 'תאריך אימון',
    },
    'd7trjszc': {
      'en': 'Duration',
      'de': 'Dauer',
      'es': 'Duración',
      'fr': 'Durée',
      'he': 'מֶשֶׁך',
    },
    'ap6suf99': {
      'en': 'Add Exercise',
      'de': 'Übung hinzufügen',
      'es': 'Agregar ejercicio',
      'fr': 'Ajouter de l\'exercice',
      'he': 'הוסף פעילות גופנית',
    },
    'cfli7m5j': {
      'en': 'Home',
      'de': 'Heim',
      'es': 'Hogar',
      'fr': 'Maison',
      'he': 'בַּיִת',
    },
  },
  // compareSelect
  {
    'sfeboz2k': {
      'en': 'History',
      'de': 'Geschichte',
      'es': 'Historia',
      'fr': 'Histoire',
      'he': 'הִיסטוֹרִיָה',
    },
  },
  // addExercisesV3
  {
    'lolzzrwh': {
      'en': 'Search exercise',
      'de': 'Suchübung',
      'es': 'Ejercicio de búsqueda',
      'fr': 'exercice de recherche',
      'he': 'תרגיל חיפוש',
    },
    'i6qnbexn': {
      'en': 'Recent Exercises',
      'de': 'Aktuelle Übungen',
      'es': 'Ejercicios recientes',
      'fr': 'Exercices récents',
      'he': 'תרגילים אחרונים',
    },
    'uug6n950': {
      'en': 'Custom Exercises',
      'de': 'Benutzerdefinierte Übungen',
      'es': 'Ejercicios personalizados',
      'fr': 'Exercices personnalisés',
      'he': 'תרגילים מותאמים אישית',
    },
    's3g1z6y8': {
      'en': 'All Exercises',
      'de': 'Alle Übungen',
      'es': 'Todos los ejercicios',
      'fr': 'Tous les exercices',
      'he': 'כל התרגילים',
    },
    'k1pexfvo': {
      'en': 'Add Exercises',
      'de': 'Übungen hinzufügen',
      'es': 'Agregar ejercicios',
      'fr': 'Ajouter des exercices',
      'he': 'הוסף תרגילים',
    },
    'my9xqnu7': {
      'en': 'Create',
      'de': 'Erstellen',
      'es': 'Crear',
      'fr': 'Créer',
      'he': 'לִיצוֹר',
    },
  },
  // createUserExercise
  {
    'nqz65u4k': {
      'en': 'Create Exercise',
      'de': 'Übung erstellen',
      'es': 'Crear ejercicio',
      'fr': 'Créer un exercice',
      'he': 'צור תרגיל',
    },
    '72373tu5': {
      'en': 'Create',
      'de': 'Erstellen',
      'es': 'Crear',
      'fr': 'Créer',
      'he': 'לִיצוֹר',
    },
    'bsm5jymd': {
      'en': 'Primary Muscels',
      'de': 'Primäre Muskeln',
      'es': 'Músculos primarios',
      'fr': 'Muscles primaires',
      'he': 'שרירים ראשוניים',
    },
    'i1gvpvw9': {
      'en': 'Equipment',
      'de': 'Ausrüstung',
      'es': 'Equipo',
      'fr': 'Équipement',
      'he': 'צִיוּד',
    },
    '75kamj2s': {
      'en': 'Secondary Muscels',
      'de': 'Sekundäre Muskeln',
      'es': 'Músculos secundarios',
      'fr': 'Muscles secondaires',
      'he': 'שרירים משניים',
    },
    'is82pj6x': {
      'en': '(optinal)',
      'de': '(optional)',
      'es': '(opcional)',
      'fr': '(optionnel)',
      'he': '(אופציונלי)',
    },
    '2i4tvohf': {
      'en': 'Exercise Type',
      'de': 'Übungsart',
      'es': 'Tipo de ejercicio',
      'fr': 'Type d\'exercice',
      'he': 'סוג התרגיל',
    },
    'j75z2nzd': {
      'en': 'Allows Bodyweight',
      'de': 'Erlaubt Körpergewicht',
      'es': 'Permite el peso corporal',
      'fr': 'Permet le poids du corps',
      'he': 'מאפשר משקל גוף',
    },
    'ulryx0lr': {
      'en': 'Can be done without weight',
      'de': 'Kann ohne Gewicht durchgeführt werden',
      'es': 'Se puede hacer sin peso',
      'fr': 'Peut être fait sans poids',
      'he': 'ניתן לעשות זאת ללא משקל',
    },
  },
  // addExercisesMidSeission
  {
    'nhg86t0p': {
      'en': 'Search exercise',
      'de': 'Suchübung',
      'es': 'Ejercicio de búsqueda',
      'fr': 'exercice de recherche',
      'he': 'תרגיל חיפוש',
    },
    'gqsmh6b7': {
      'en': 'Recent Exercises',
      'de': 'Aktuelle Übungen',
      'es': 'Ejercicios recientes',
      'fr': 'Exercices récents',
      'he': 'תרגילים אחרונים',
    },
    'kt9efzhx': {
      'en': 'Custom Exercises',
      'de': 'Benutzerdefinierte Übungen',
      'es': 'Ejercicios personalizados',
      'fr': 'Exercices personnalisés',
      'he': 'תרגילים מותאמים אישית',
    },
    't0s77qqf': {
      'en': 'All Exercises',
      'de': 'Alle Übungen',
      'es': 'Todos los ejercicios',
      'fr': 'Tous les exercices',
      'he': 'כל התרגילים',
    },
    'e6mmratz': {
      'en': 'Add Exercises',
      'de': 'Übungen hinzufügen',
      'es': 'Agregar ejercicios',
      'fr': 'Ajouter des exercices',
      'he': 'הוסף תרגילים',
    },
    'y57lsxr5': {
      'en': 'Create',
      'de': 'Erstellen',
      'es': 'Crear',
      'fr': 'Créer',
      'he': 'לִיצוֹר',
    },
  },
  // HelpUs
  {
    'xu7eo1ik': {
      'en': 'Contact & Feedback',
      'de': 'Kontakt & Feedback',
      'es': 'Contacto y comentarios',
      'fr': 'Contact et commentaires',
      'he': 'צור קשר ומשוב',
    },
    '8uu69emz': {
      'en': 'Help us improve Xlift',
      'de': 'Helfen Sie uns, Xlift zu verbessern.',
      'es': 'Ayúdanos a mejorar Xlift',
      'fr': 'Aidez-nous à améliorer Xlift',
      'he': 'עזרו לנו לשפר את Xlift',
    },
    'd5jm2ssp': {
      'en': 'Your feedback helps us create a better experience for everyone.',
      'de':
          'Ihr Feedback hilft uns, ein besseres Erlebnis für alle zu schaffen.',
      'es':
          'Sus comentarios nos ayudan a crear una mejor experiencia para todos.',
      'fr':
          'Vos commentaires nous aident à créer une meilleure expérience pour tous.',
      'he': 'המשוב שלך עוזר לנו ליצור חוויה טובה יותר עבור כולם.',
    },
    'i12h2e1a': {
      'en': 'Report a Bug',
      'de': 'Fehler melden',
      'es': 'Informar de un error',
      'fr': 'Signaler un bug',
      'he': 'דווח על באג',
    },
    'hrsfp9kh': {
      'en':
          'Something didn\'t work as expected? Let us know so we can fix it quickly.',
      'de':
          'Hat etwas nicht wie erwartet funktioniert? Lassen Sie es uns wissen, damit wir es schnell beheben können.',
      'es':
          '¿Algo no funcionó como esperabas? Avísanos para que podamos solucionarlo rápidamente.',
      'fr':
          'Un problème est survenu ? N\'hésitez pas à nous le signaler afin que nous puissions le résoudre rapidement.',
      'he': 'משהו לא עבד כמצופה? אנא הודע לנו כדי שנוכל לתקן זאת במהירות.',
    },
    'n262866u': {
      'en': 'Suggest a Feature',
      'de': 'Schlagen Sie eine Funktion vor',
      'es': 'Sugerir una función',
      'fr': 'Suggérer une fonctionnalité',
      'he': 'הצע תכונה',
    },
    'nnapg1da': {
      'en':
          'Share ideas to improve the app. We love hearing from our community.',
      'de':
          'Teilt eure Ideen zur Verbesserung der App mit. Wir freuen uns über Feedback aus unserer Community.',
      'es':
          'Comparte ideas para mejorar la aplicación. Nos encanta recibir comentarios de nuestra comunidad.',
      'fr':
          'Partagez vos idées pour améliorer l\'application. Nous apprécions les retours de notre communauté.',
      'he': 'שתפו רעיונות לשיפור האפליקציה. נשמח לשמוע מהקהילה שלנו.',
    },
  },
  // reportBug
  {
    'm6mdxiou': {
      'en': 'Help us understand what went wrong',
      'de': 'Helfen Sie uns zu verstehen, was schiefgelaufen ist.',
      'es': 'Ayúdanos a entender qué salió mal.',
      'fr': 'Aidez-nous à comprendre ce qui s\'est mal passé.',
      'he': 'עזרו לנו להבין מה השתבש',
    },
    'b8f0s301': {
      'en':
          'Describe the issue you encountered and what you expected to happen',
      'de':
          'Beschreiben Sie das aufgetretene Problem und was Sie als Reaktion darauf erwartet haben.',
      'es':
          'Describe el problema que encontraste y qué esperabas que sucediera.',
      'fr': 'Décrivez le problème rencontré et ce à quoi vous vous attendiez.',
      'he': 'תאר את הבעיה שנתקלת בה ומה ציפית שיקרה',
    },
    '3bniorw8': {
      'en': 'Add screenshot or video (optional)',
      'de': 'Screenshot oder Video hinzufügen (optional)',
      'es': 'Añadir captura de pantalla o vídeo (opcional)',
      'fr': 'Ajouter une capture d\'écran ou une vidéo (facultatif)',
      'he': 'הוסף צילום מסך או סרטון (אופציונלי)',
    },
    '082slt73': {
      'en': 'Help us see what you\'re experiencing',
      'de': 'Helfen Sie uns zu verstehen, was Sie erleben.',
      'es': 'Ayúdanos a ver qué estás experimentando.',
      'fr': 'Aidez-nous à comprendre ce que vous vivez.',
      'he': 'עזרו לנו לראות מה אתם חווים',
    },
    'jls700g6': {
      'en': 'Send Report',
      'de': 'Bericht senden',
      'es': 'Enviar informe',
      'fr': 'Envoyer un rapport',
      'he': 'שלח דוח',
    },
    'e1r4v4zt': {
      'en': 'Report A Bug',
      'de': 'Fehler melden',
      'es': 'Informar de un error',
      'fr': 'Signaler un bug',
      'he': 'דווח על באג',
    },
  },
  // feedback
  {
    'tfn6f86s': {
      'en': 'Help shape the future of Xlift',
      'de': 'Gestalte die Zukunft von Xlift mit!',
      'es': 'Ayuda a dar forma al futuro de Xlift.',
      'fr': 'Contribuez à façonner l\'avenir de Xlift',
      'he': 'עזרו לעצב את עתידה של Xlift',
    },
    'b8blrrke': {
      'en':
          'Describe the feature or improvement you’d like to see and why it would be useful.',
      'de':
          'Beschreiben Sie die Funktion oder Verbesserung, die Sie sich wünschen, und warum diese nützlich wäre.',
      'es':
          'Describe la función o mejora que te gustaría ver y por qué sería útil.',
      'fr':
          'Décrivez la fonctionnalité ou l\'amélioration que vous souhaiteriez voir et expliquez pourquoi elle serait utile.',
      'he': 'תאר את התכונה או השיפור שהיית רוצה לראות ומדוע הם יהיו שימושיים.',
    },
    'qeioi8sv': {
      'en': 'Add screenshot or video (optional)',
      'de': 'Screenshot oder Video hinzufügen (optional)',
      'es': 'Añadir captura de pantalla o vídeo (opcional)',
      'fr': 'Ajouter une capture d\'écran ou une vidéo (facultatif)',
      'he': 'הוסף צילום מסך או סרטון (אופציונלי)',
    },
    'h68stihv': {
      'en': 'Help us see what you\'re experiencing',
      'de': 'Helfen Sie uns zu verstehen, was Sie erleben.',
      'es': 'Ayúdanos a ver qué estás experimentando.',
      'fr': 'Aidez-nous à comprendre ce que vous vivez.',
      'he': 'עזרו לנו לראות מה אתם חווים',
    },
    'idie29ix': {
      'en': 'Send Report',
      'de': 'Bericht senden',
      'es': 'Enviar informe',
      'fr': 'Envoyer un rapport',
      'he': 'שלח דוח',
    },
    '5dbbkeh8': {
      'en': 'Suggest a Feature',
      'de': 'Schlagen Sie eine Funktion vor',
      'es': 'Sugerir una función',
      'fr': 'Suggérer une fonctionnalité',
      'he': 'הצע תכונה',
    },
  },
  // editWorkoutV2
  {
    '7fgre2jr': {
      'en': '',
      'de': '',
      'es': '',
      'fr': '',
      'he': '',
    },
    '40roqkvg': {
      'en': 'Add exercises',
      'de': 'Übungen hinzufügen',
      'es': 'Agregar ejercicios',
      'fr': 'Ajouter des exercices',
      'he': 'הוסף תרגילים',
    },
    '62rcsx1a': {
      'en': 'Save',
      'de': 'Speichern',
      'es': 'Ahorrar',
      'fr': 'Sauvegarder',
      'he': 'לְהַצִיל',
    },
    '1eaq2q45': {
      'en': 'Edit Workout',
      'de': 'Edit Workout',
      'es': 'Editar entrenamiento',
      'fr': 'Modifier l\'entraînement',
      'he': 'עריכת אימון',
    },
  },
  // profEditV2
  {
    '6vw3sskc': {
      'en': 'Change Picture',
      'de': 'Bild ändern',
      'es': 'Cambiar imagen',
      'fr': 'Changer d\'image',
      'he': 'שנה תמונה',
    },
    '3rx3xbqb': {
      'en': 'Account',
      'de': 'Konto',
      'es': 'Cuenta',
      'fr': 'Compte',
      'he': 'חֶשְׁבּוֹן',
    },
    'glzxjaep': {
      'en': 'Username',
      'de': 'Benutzername',
      'es': 'Nombre de usuario',
      'fr': 'Nom d\'utilisateur',
      'he': 'שם משתמש',
    },
    'oztb29pq': {
      'en': 'Personal',
      'de': 'Persönlich',
      'es': 'Personal',
      'fr': 'Personnel',
      'he': 'אִישִׁי',
    },
    't9zqdwy1': {
      'en': 'Sex',
      'de': 'Sex',
      'es': 'Sexo',
      'fr': 'Sexe',
      'he': 'מִין',
    },
    'sbn87l07': {
      'en': 'Birthday',
      'de': 'Geburtstag',
      'es': 'Cumpleaños',
      'fr': 'Anniversaire',
      'he': 'יוֹם הוּלֶדֶת',
    },
    'jldys2ch': {
      'en': 'Measurements',
      'de': 'Messungen',
      'es': 'Medidas',
      'fr': 'Mesures',
      'he': 'מידות',
    },
    'z50wgfbl': {
      'en': 'Height',
      'de': 'Höhe',
      'es': 'Altura',
      'fr': 'Hauteur',
      'he': 'גוֹבַה',
    },
    '4iritktz': {
      'en': 'Weight',
      'de': 'Gewicht',
      'es': 'Peso',
      'fr': 'Poids',
      'he': 'מִשׁקָל',
    },
    '4i1gf33a': {
      'en': 'Change',
      'de': 'Ändern',
      'es': 'Cambiar',
      'fr': 'Changement',
      'he': 'לְשַׁנוֹת',
    },
    '1wwala0i': {
      'en': 'Save',
      'de': 'Speichern',
      'es': 'Ahorrar',
      'fr': 'Sauvegarder',
      'he': 'לְהַצִיל',
    },
    'jhkyxozz': {
      'en': 'Edit Profile',
      'de': 'Profil bearbeiten',
      'es': 'Editar perfil',
      'fr': 'Modifier le profil',
      'he': 'עריכת פרופיל',
    },
  },
  // accountSettings
  {
    'b7pqx57r': {
      'en': 'Manage Subscription',
      'de': 'Abonnement verwalten',
      'es': 'Gestionar suscripción',
      'fr': 'Gérer mon abonnement',
      'he': 'ניהול מנוי',
    },
    '5q7okyv7': {
      'en': 'Update Password',
      'de': 'Passwort aktualisieren',
      'es': 'Actualizar contraseña',
      'fr': 'Mettre à jour le mot de passe',
      'he': 'עדכון סיסמה',
    },
    'hisbv3s7': {
      'en': 'Delete Account',
      'de': 'Konto löschen',
      'es': 'Eliminar cuenta',
      'fr': 'Supprimer le compte',
      'he': 'מחיקת חשבון',
    },
    'kvsqpbzs': {
      'en': 'Account Settings',
      'de': 'Kontoeinstellungen',
      'es': 'Configuraciones de la cuenta',
      'fr': 'Paramètres du compte',
      'he': 'הגדרות חשבון',
    },
  },
  // replaceExercisePage
  {
    'xk5mapm5': {
      'en': 'Replace Exercise',
      'de': 'Übung ersetzen',
      'es': 'Reemplazar ejercicio',
      'fr': 'Remplacer l\'exercice',
      'he': 'החלפת פעילות גופנית',
    },
    'q4v3yyvy': {
      'en': 'Create',
      'de': 'Erstellen',
      'es': 'Crear',
      'fr': 'Créer',
      'he': 'לִיצוֹר',
    },
    'lbilz5aw': {
      'en': 'Smart Replace',
      'de': 'Intelligenter Austausch',
      'es': 'Reemplazo inteligente',
      'fr': 'Remplacement intelligent',
      'he': 'החלפה חכמה',
    },
    'lmul7xzc': {
      'en': 'Best',
      'de': 'Am besten',
      'es': 'Mejor',
      'fr': 'Meilleur',
      'he': 'טוֹב בִּיוֹתֵר',
    },
    '7vtuneq6': {
      'en': 'Regular replace',
      'de': 'Regelmäßiger Austausch',
      'es': 'Reemplazo regular',
      'fr': 'Remplacement régulier',
      'he': 'החלפה רגילה',
    },
    'g53a9rui': {
      'en': 'Search exercise',
      'de': 'Suchübung',
      'es': 'Ejercicio de búsqueda',
      'fr': 'exercice de recherche',
      'he': 'תרגיל חיפוש',
    },
    'xcrzwa6q': {
      'en': 'Recent Exercises',
      'de': 'Aktuelle Übungen',
      'es': 'Ejercicios recientes',
      'fr': 'Exercices récents',
      'he': 'תרגילים אחרונים',
    },
    'dv2nlf9a': {
      'en': 'Custom Exercises',
      'de': 'Benutzerdefinierte Übungen',
      'es': 'Ejercicios personalizados',
      'fr': 'Exercices personnalisés',
      'he': 'תרגילים מותאמים אישית',
    },
    'nu52kuws': {
      'en': 'All Exercises',
      'de': 'Alle Übungen',
      'es': 'Todos los ejercicios',
      'fr': 'Tous les exercices',
      'he': 'כל התרגילים',
    },
    '8vuvs30z': {
      'en': 'Replace',
      'de': 'Ersetzen',
      'es': 'Reemplazar',
      'fr': 'Remplacer',
      'he': 'לְהַחלִיף',
    },
  },
  // replaceExercisePageCreation
  {
    'es5fim7y': {
      'en': 'Replace Exercise',
      'de': 'Übung ersetzen',
      'es': 'Reemplazar ejercicio',
      'fr': 'Remplacer l\'exercice',
      'he': 'החלפת פעילות גופנית',
    },
    'dpayteic': {
      'en': 'Create',
      'de': 'Erstellen',
      'es': 'Crear',
      'fr': 'Créer',
      'he': 'לִיצוֹר',
    },
    'xig04m03': {
      'en': 'Smart Replace',
      'de': 'Intelligenter Austausch',
      'es': 'Reemplazo inteligente',
      'fr': 'Remplacement intelligent',
      'he': 'החלפה חכמה',
    },
    'h66gqkvx': {
      'en': 'Best',
      'de': 'Am besten',
      'es': 'Mejor',
      'fr': 'Meilleur',
      'he': 'טוֹב בִּיוֹתֵר',
    },
    't3z2yb02': {
      'en': 'Regular replace',
      'de': 'Regelmäßiger Austausch',
      'es': 'Reemplazo regular',
      'fr': 'Remplacement régulier',
      'he': 'החלפה רגילה',
    },
    '6l1di9pf': {
      'en': 'Search exercise',
      'de': 'Suchübung',
      'es': 'Ejercicio de búsqueda',
      'fr': 'exercice de recherche',
      'he': 'תרגיל חיפוש',
    },
    'dvoejeql': {
      'en': 'Recent Exercises',
      'de': 'Aktuelle Übungen',
      'es': 'Ejercicios recientes',
      'fr': 'Exercices récents',
      'he': 'תרגילים אחרונים',
    },
    '1qwoz1r5': {
      'en': 'Custom Exercises',
      'de': 'Benutzerdefinierte Übungen',
      'es': 'Ejercicios personalizados',
      'fr': 'Exercices personnalisés',
      'he': 'תרגילים מותאמים אישית',
    },
    '9oi1r75l': {
      'en': 'All Exercises',
      'de': 'Alle Übungen',
      'es': 'Todos los ejercicios',
      'fr': 'Tous les exercices',
      'he': 'כל התרגילים',
    },
    '6zb90gq6': {
      'en': 'Replace',
      'de': 'Ersetzen',
      'es': 'Reemplazar',
      'fr': 'Remplacer',
      'he': 'לְהַחלִיף',
    },
  },
  // createUserExerciseMidSession
  {
    'qihg11af': {
      'en': 'Create Exercise',
      'de': 'Übung erstellen',
      'es': 'Crear ejercicio',
      'fr': 'Créer un exercice',
      'he': 'צור תרגיל',
    },
    '83sgh0br': {
      'en': 'Create',
      'de': 'Erstellen',
      'es': 'Crear',
      'fr': 'Créer',
      'he': 'לִיצוֹר',
    },
    '83coa8bl': {
      'en': 'Primary Muscels',
      'de': 'Primäre Muskeln',
      'es': 'Músculos primarios',
      'fr': 'Muscles primaires',
      'he': 'שרירים ראשוניים',
    },
    'i32iz7yw': {
      'en': 'Equipment',
      'de': 'Ausrüstung',
      'es': 'Equipo',
      'fr': 'Équipement',
      'he': 'צִיוּד',
    },
    'o391ubev': {
      'en': 'Secondary Muscels',
      'de': 'Sekundäre Muskeln',
      'es': 'Músculos secundarios',
      'fr': 'Muscles secondaires',
      'he': 'שרירים משניים',
    },
    'r89kst9t': {
      'en': '(optinal)',
      'de': '(optional)',
      'es': '(opcional)',
      'fr': '(facultatif)',
      'he': '(אופציונלי)',
    },
    '3mtko6ik': {
      'en': 'Exercise Type',
      'de': 'Übungsart',
      'es': 'Tipo de ejercicio',
      'fr': 'Type d\'exercice',
      'he': 'סוג התרגיל',
    },
    'picxypd6': {
      'en': 'Allows Bodyweight',
      'de': 'Erlaubt Körpergewicht',
      'es': 'Permite el peso corporal',
      'fr': 'Permet le poids du corps',
      'he': 'מאפשר משקל גוף',
    },
    '39nldbz7': {
      'en': 'Can be done without weight',
      'de': 'Kann ohne Gewicht durchgeführt werden',
      'es': 'Se puede hacer sin peso',
      'fr': 'Peut être fait sans poids',
      'he': 'ניתן לעשות זאת ללא משקל',
    },
  },
  // routineBuilder
  {
    'dwn3v2dq': {
      'en': 'Choose Your Training Split',
      'de': 'Wähle deinen Trainingsplan',
      'es': 'Elige tu plan de entrenamiento',
      'fr': 'Choisissez votre programme d\'entraînement',
      'he': 'בחר את חלוקת האימונים שלך',
    },
    'qpz9gutq': {
      'en': 'Select the structure that fits your training style',
      'de': 'Wählen Sie die Struktur, die zu Ihrem Trainingsstil passt.',
      'es':
          'Selecciona la estructura que mejor se adapte a tu estilo de entrenamiento.',
      'fr':
          'Choisissez la structure qui correspond à votre style d\'entraînement',
      'he': 'בחרו את המבנה שמתאים לסגנון האימון שלכם',
    },
    'aeeq9k15': {
      'en': 'Full Body',
      'de': 'Ganzkörper',
      'es': 'Cuerpo completo',
      'fr': 'Corps entier',
      'he': 'גוף מלא',
    },
    'ad58mnov': {
      'en': 'Train all muscles each session',
      'de': 'Trainiere in jeder Trainingseinheit alle Muskeln.',
      'es': 'Entrena todos los músculos en cada sesión.',
      'fr': 'Entraînez tous les muscles à chaque séance',
      'he': 'לאמן את כל השרירים בכל אימון',
    },
    'eotw7isi': {
      'en': 'Upper / Lower',
      'de': 'Ober-/Unterteil',
      'es': 'Superior / Inferior',
      'fr': 'Haut / Bas',
      'he': 'עליון / תחתון',
    },
    'ap8aqip5': {
      'en': 'Split between upper and lower body',
      'de': 'Aufteilung in Ober- und Unterkörper',
      'es': 'Dividido entre la parte superior e inferior del cuerpo.',
      'fr': 'Répartition entre le haut et le bas du corps',
      'he': 'חלוקה בין פלג גוף עליון לתחתון',
    },
    '4bsiiyne': {
      'en': 'Push / Pull / Legs',
      'de': 'Schieben / Ziehen / Beine',
      'es': 'Empujar / Tirar / Piernas',
      'fr': 'Pousser / Tirer / Jambes',
      'he': 'דחיפה / משיכה / רגליים',
    },
    'oja4lb7z': {
      'en': 'Focus on movement patterns',
      'de': 'Fokus auf Bewegungsmuster',
      'es': 'Concéntrese en los patrones de movimiento',
      'fr': 'Concentrez-vous sur les schémas de mouvement.',
      'he': 'דגש על דפוסי תנועה',
    },
    '3zh4pbdt': {
      'en': 'Custom',
      'de': 'Brauch',
      'es': 'Costumbre',
      'fr': 'Coutume',
      'he': 'מִנְהָג',
    },
    'h9h5f91i': {
      'en': 'Create your own split',
      'de': 'Erstelle deine eigene Aufteilung',
      'es': 'Crea tu propia división',
      'fr': 'Créez votre propre split',
      'he': 'צור את הפיצול שלך',
    },
    'wv1rmmrv': {
      'en': 'Step 1 of 3',
      'de': 'Schritt 1 von 3',
      'es': 'Paso 1 de 3',
      'fr': 'Étape 1 sur 3',
      'he': 'שלב 1 מתוך 3',
    },
    'hcuafajg': {
      'en': 'Build Your Weekly Schedule',
      'de': 'Erstelle deinen Wochenplan',
      'es': 'Crea tu horario semanal',
      'fr': 'Élaborez votre programme hebdomadaire',
      'he': 'בנה את לוח הזמנים השבועי שלך',
    },
    '0k157ofd': {
      'en': 'Choose how often you train and what each workout includes',
      'de':
          'Wähle selbst, wie oft du trainierst und was jedes Training beinhaltet.',
      'es':
          'Elige con qué frecuencia entrenas y qué incluye cada entrenamiento.',
      'fr':
          'Choisissez la fréquence de vos entraînements et le contenu de chaque séance.',
      'he': 'בחרו באיזו תדירות אתם מתאמנים ומה כל אימון כולל',
    },
    '07kq73y1': {
      'en': 'Workouts per Week',
      'de': 'Trainingseinheiten pro Woche',
      'es': 'Entrenamientos por semana',
      'fr': 'Entraînements par semaine',
      'he': 'אימונים בשבוע',
    },
    'eya9wr01': {
      'en': '2',
      'de': '2',
      'es': '2',
      'fr': '2',
      'he': '2',
    },
    'qi4v79xk': {
      'en': '3',
      'de': '3',
      'es': '3',
      'fr': '3',
      'he': '3',
    },
    '5wr49zrp': {
      'en': '4',
      'de': '4',
      'es': '4',
      'fr': '4',
      'he': '4',
    },
    'x114xo5o': {
      'en': '5',
      'de': '5',
      'es': '5',
      'fr': '5',
      'he': '5',
    },
    's7stmxj0': {
      'en': '6',
      'de': '6',
      'es': '6',
      'fr': '6',
      'he': '6',
    },
    'fh10hxx6': {
      'en': '7',
      'de': '7',
      'es': '7',
      'fr': '7',
      'he': '7',
    },
    'ja8qyzi0': {
      'en': 'Step 2 of 3',
      'de': 'Schritt 2 von 3',
      'es': 'Paso 2 de 3',
      'fr': 'Étape 2 sur 3',
      'he': 'שלב 2 מתוך 3',
    },
    'gw37yoiv': {
      'en': 'Your Workouts',
      'de': 'Deine Workouts',
      'es': 'Tus entrenamientos',
      'fr': 'Vos séances d\'entraînement',
      'he': 'האימונים שלך',
    },
    '1iel2l8a': {
      'en': 'Select the workouts you want to include this week',
      'de': 'Wähle die Workouts aus, die du diese Woche absolvieren möchtest.',
      'es': 'Selecciona los entrenamientos que quieras incluir esta semana.',
      'fr':
          'Sélectionnez les séances d\'entraînement que vous souhaitez inclure cette semaine',
      'he': 'בחר את האימונים שברצונך לכלול השבוע',
    },
    'k7sht9ux': {
      'en': '+ Add Workouts',
      'de': '+ Trainingseinheiten hinzufügen',
      'es': '+ Agregar entrenamientos',
      'fr': '+ Ajouter des séances d\'entraînement',
      'he': '+ הוסף אימונים',
    },
    'xe284rm2': {
      'en': 'Build Weekly Schedule',
      'de': 'Wöchentlichen Zeitplan erstellen',
      'es': 'Elaborar un horario semanal',
      'fr': 'Élaborer un planning hebdomadaire',
      'he': 'בניית לוח זמנים שבועי',
    },
    'fkuk9k53': {
      'en': 'Routine Builder',
      'de': 'Routinen-Builder',
      'es': 'Creador de rutinas',
      'fr': 'Créateur de routine',
      'he': 'בונה שגרות',
    },
    'ictudwj6': {
      'en': 'Home',
      'de': 'Heim',
      'es': 'Hogar',
      'fr': 'Maison',
      'he': 'בַּיִת',
    },
  },
  // selectWorkouts
  {
    'nmnk3r3l': {
      'en': 'TextField',
      'de': 'Textfeld',
      'es': 'Campo de texto',
      'fr': 'Champ de texte',
      'he': 'שדה טקסט',
    },
    'qgc5034k': {
      'en': 'All',
      'de': 'Alle',
      'es': 'Todo',
      'fr': 'Tous',
      'he': 'כֹּל',
    },
    'vr9q7hpc': {
      'en': 'Select...',
      'de': 'Wählen...',
      'es': 'Seleccionar...',
      'fr': 'Sélectionner...',
      'he': 'לִבחוֹר...',
    },
    'xkrf9oad': {
      'en': 'Search...',
      'de': 'Suchen...',
      'es': 'Buscar...',
      'fr': 'Recherche...',
      'he': 'לְחַפֵּשׂ...',
    },
    'yqjdnq2g': {
      'en': 'All',
      'de': 'Alle',
      'es': 'Todo',
      'fr': 'Tous',
      'he': 'כֹּל',
    },
    'po5q2d7p': {
      'en': 'Chest',
      'de': 'Brust',
      'es': 'Pecho',
      'fr': 'Poitrine',
      'he': 'חָזֶה',
    },
    'mg9d5xx7': {
      'en': 'Back',
      'de': 'Zurück',
      'es': 'Atrás',
      'fr': 'Dos',
      'he': 'בְּחֲזָרָה',
    },
    '7n5iel6y': {
      'en': 'Shoulders',
      'de': 'Schultern',
      'es': 'Espalda',
      'fr': 'Épaules',
      'he': 'כתפיים',
    },
    'megl63gg': {
      'en': 'Biceps',
      'de': 'Bizeps',
      'es': 'Bíceps',
      'fr': 'Biceps',
      'he': 'שְׁרִיר הַזְרוֹעַ',
    },
    '9yn036if': {
      'en': 'Triceps',
      'de': 'Trizeps',
      'es': 'Tríceps',
      'fr': 'Triceps',
      'he': 'שרירי התלת ראשי',
    },
    'od5dg01r': {
      'en': 'Legs',
      'de': 'Beine',
      'es': 'Piernas',
      'fr': 'Jambes',
      'he': 'רגליים',
    },
    'bg92z1e4': {
      'en': 'Core',
      'de': 'Kern',
      'es': 'Centro',
      'fr': 'Cœur',
      'he': 'ליבה',
    },
    '183bjqbe': {
      'en': 'Forearms',
      'de': 'Unterarme',
      'es': 'Antebrazos',
      'fr': 'Avant-bras',
      'he': 'אמות הידיים',
    },
    'qphwnpz9': {
      'en': 'Neck',
      'de': 'Nacken',
      'es': 'Cuello',
      'fr': 'Cou',
      'he': 'עוֹרֶף',
    },
    'ixfwrs7z': {
      'en': 'Continue',
      'de': 'Weitermachen',
      'es': 'Continuar',
      'fr': 'Continuer',
      'he': 'לְהַמשִׁיך',
    },
    'afs7dcxd': {
      'en': 'Select Workouts',
      'de': 'Trainingsprogramme auswählen',
      'es': 'Seleccionar entrenamientos',
      'fr': 'Sélection d\'entraînements',
      'he': 'בחר אימונים',
    },
  },
  // exerciseHistoryCustom
  {
    'sumish25': {
      'en': 'History',
      'de': 'Geschichte',
      'es': 'Historia',
      'fr': 'Histoire',
      'he': 'הִיסטוֹרִיָה',
    },
    '3480ehkz': {
      'en': 'COMPARED TO PREVIOUS',
      'de': 'IM VERGLEICH ZUVOR',
      'es': 'COMPARADO CON LA VERSIÓN ANTERIOR',
      'fr': 'COMPARÉ À LA VERSION PRÉCÉDENTE',
      'he': 'בהשוואה לקודם',
    },
    'g0k45442': {
      'en': 'Analytics',
      'de': 'Analysen',
      'es': 'Analítica',
      'fr': 'Analytique',
      'he': 'אנליטיקס',
    },
    'jc23lt1k': {
      'en': 'Personal Records',
      'de': 'Persönliche Daten',
      'es': 'Registros personales',
      'fr': 'Dossiers personnels',
      'he': 'שיאים אישיים',
    },
    '5a9r9zgl': {
      'en': 'Max Reps',
      'de': 'Maximale Wiederholungen',
      'es': 'Repeticiones máximas',
      'fr': 'Nombre maximal de répétitions',
      'he': 'מקסימום חזרות',
    },
    '19lyyidt': {
      'en': 'Max Weight',
      'de': 'Maximalgewicht',
      'es': 'Peso máximo',
      'fr': 'Poids maximal',
      'he': 'משקל מקסימלי',
    },
    'b21dnmi5': {
      'en': 'Max Volume',
      'de': 'Maximales Volumen',
      'es': 'Volumen máximo',
      'fr': 'Volume maximal',
      'he': 'נפח מקסימלי',
    },
    'er7qkq3g': {
      'en': 'Personal Records',
      'de': 'Persönliche Daten',
      'es': 'Registros personales',
      'fr': 'Dossiers personnels',
      'he': 'שיאים אישיים',
    },
    'pgjvgs1r': {
      'en': 'Max Reps',
      'de': 'Maximale Wiederholungen',
      'es': 'Repeticiones máximas',
      'fr': 'Nombre maximal de répétitions',
      'he': 'מקסימום חזרות',
    },
    'zg9am9wq': {
      'en': 'Max Session',
      'de': 'Max Session',
      'es': 'Sesión máxima',
      'fr': 'Session maximale',
      'he': 'מקסימום סשן',
    },
    'wkkzogbw': {
      'en': 'Avrage Reps',
      'de': 'Durchschnittliche Wiederholungen',
      'es': 'Representantes promedio',
      'fr': 'Rép. moyenne',
      'he': 'ממוצע חזרות',
    },
    'gk4m4zu9': {
      'en': 'Personal Records',
      'de': 'Persönliche Daten',
      'es': 'Registros personales',
      'fr': 'Dossiers personnels',
      'he': 'שיאים אישיים',
    },
    'xci4st5u': {
      'en': 'Max Session Time',
      'de': 'Maximale Sitzungszeit',
      'es': 'Tiempo máximo de sesión',
      'fr': 'Durée maximale de la session',
      'he': 'זמן מקסימלי של סשן',
    },
    '78i8b80k': {
      'en': 'Avrage Duration',
      'de': 'Durchschnittliche Dauer',
      'es': 'Duración promedio',
      'fr': 'Durée moyenne',
      'he': 'משך זמן ממוצע',
    },
    'jrqxv26i': {
      'en': 'Max Duration',
      'de': 'Maximale Dauer',
      'es': 'Duración máxima',
      'fr': 'Durée maximale',
      'he': 'משך זמן מקסימלי',
    },
    'isoqhf59': {
      'en': 'Personal Records',
      'de': 'Persönliche Daten',
      'es': 'Registros personales',
      'fr': 'Dossiers personnels',
      'he': 'שיאים אישיים',
    },
    '2u3xi6i5': {
      'en': 'Max Reps',
      'de': 'Maximale Wiederholungen',
      'es': 'Repeticiones máximas',
      'fr': 'Nombre maximal de répétitions',
      'he': 'מקסימום חזרות',
    },
    'k350lgfo': {
      'en': 'Max Session Reps',
      'de': 'Maximale Wiederholungen pro Sitzung',
      'es': 'Repeticiones máximas por sesión',
      'fr': 'Nombre maximal de répétitions par session',
      'he': 'מספר חזרות מקסימלי של סשנים',
    },
    '2q6hv3m3': {
      'en': 'Min Assistance',
      'de': 'Mindestunterstützung',
      'es': 'Asistencia mínima',
      'fr': 'Assistance minimale',
      'he': 'סיוע מינימלי',
    },
    'g6vceimb': {
      'en': 'Exercise Analytics',
      'de': 'Trainingsanalyse',
      'es': 'Análisis de ejercicios',
      'fr': 'Analyse des exercices',
      'he': 'אנליטיקה של פעילות גופנית',
    },
    'x7aqk0uu': {
      'en': 'Track your progress over time',
      'de': 'Verfolge deinen Fortschritt im Laufe der Zeit',
      'es': 'Haz un seguimiento de tu progreso a lo largo del tiempo.',
      'fr': 'Suivez vos progrès au fil du temps',
      'he': 'עקוב אחר ההתקדמות שלך לאורך זמן',
    },
    '5k4vax1p': {
      'en': 'Reps',
      'de': 'Reps',
      'es': 'Representantes',
      'fr': 'Réputation',
      'he': 'נציגים',
    },
    'taxosvjn': {
      'en': 'Max Weight',
      'de': 'Maximalgewicht',
      'es': 'Peso máximo',
      'fr': 'Poids maximal',
      'he': 'משקל מקסימלי',
    },
    'jc8mdri5': {
      'en': 'Volume',
      'de': 'Volumen',
      'es': 'Volumen',
      'fr': 'Volume',
      'he': 'כֶּרֶך',
    },
    '1fszsvo2': {
      'en': 'Reps',
      'de': 'Reps',
      'es': 'Representantes',
      'fr': 'Réputation',
      'he': 'נציגים',
    },
    '08ujb6mu': {
      'en': 'No analytics yet',
      'de': 'Noch keine Analysen',
      'es': 'Aún no hay análisis',
      'fr': 'Aucune analyse pour le moment',
      'he': 'עדיין אין אנליטיקה',
    },
    'i9ccbyhg': {
      'en': 'Log a few sessions to see how this exercise progresses over time.',
      'de':
          'Protokollieren Sie einige Trainingseinheiten, um zu sehen, wie sich diese Übung im Laufe der Zeit entwickelt.',
      'es':
          'Registra algunas sesiones para ver cómo progresa este ejercicio con el tiempo.',
      'fr':
          'Enregistrez quelques séances pour observer l\'évolution de cet exercice au fil du temps.',
      'he': 'רשמו כמה אימונים כדי לראות כיצד התרגיל הזה מתקדם לאורך זמן.',
    },
    'avks3n8b': {
      'en': 'Current Week',
      'de': 'Aktuelle Woche',
      'es': 'Semana actual',
      'fr': 'Semaine actuelle',
      'he': 'השבוע הנוכחי',
    },
    'y1w3kmyi': {
      'en': 'Best Session',
      'de': 'Beste Session',
      'es': 'Mejor sesión',
      'fr': 'Meilleure session',
      'he': 'הסשן הטוב ביותר',
    },
    'p68dddlc': {
      'en': 'Improvement',
      'de': 'Verbesserung',
      'es': 'Mejora',
      'fr': 'Amélioration',
      'he': 'הַשׁבָּחָה',
    },
    'hi1qvpqx': {
      'en': 'Exercise Analytics',
      'de': 'Trainingsanalyse',
      'es': 'Análisis de ejercicios',
      'fr': 'Analyse des exercices',
      'he': 'אנליטיקה של פעילות גופנית',
    },
    'shwdmzpg': {
      'en': 'Track your progress over time',
      'de': 'Verfolge deinen Fortschritt im Laufe der Zeit',
      'es': 'Haz un seguimiento de tu progreso a lo largo del tiempo.',
      'fr': 'Suivez vos progrès au fil du temps',
      'he': 'עקוב אחר ההתקדמות שלך לאורך זמן',
    },
    'bi5rjem8': {
      'en': 'No analytics yet',
      'de': 'Noch keine Analysen',
      'es': 'Aún no hay análisis',
      'fr': 'Aucune analyse pour le moment',
      'he': 'עדיין אין אנליטיקה',
    },
    '6orz8tdu': {
      'en': 'Log a few sessions to see how this exercise progresses over time.',
      'de':
          'Protokollieren Sie einige Trainingseinheiten, um zu sehen, wie sich diese Übung im Laufe der Zeit entwickelt.',
      'es':
          'Registra algunas sesiones para ver cómo progresa este ejercicio con el tiempo.',
      'fr':
          'Enregistrez quelques séances pour observer l\'évolution de cet exercice au fil du temps.',
      'he': 'רשמו כמה אימונים כדי לראות כיצד התרגיל הזה מתקדם לאורך זמן.',
    },
    '9vg3cbuz': {
      'en': 'Current Week',
      'de': 'Aktuelle Woche',
      'es': 'Semana actual',
      'fr': 'Semaine actuelle',
      'he': 'השבוע הנוכחי',
    },
    'pa9m8s93': {
      'en': 'Best Session',
      'de': 'Beste Session',
      'es': 'Mejor sesión',
      'fr': 'Meilleure session',
      'he': 'הסשן הטוב ביותר',
    },
    '2opf55rh': {
      'en': 'Improvement',
      'de': 'Verbesserung',
      'es': 'Mejora',
      'fr': 'Amélioration',
      'he': 'הַשׁבָּחָה',
    },
    'lx6e6ua0': {
      'en': 'Exercise Analytics',
      'de': 'Trainingsanalyse',
      'es': 'Análisis de ejercicios',
      'fr': 'Analyse des exercices',
      'he': 'אנליטיקה של פעילות גופנית',
    },
    'j1ezyjqo': {
      'en': 'Track your progress over time',
      'de': 'Verfolge deinen Fortschritt im Laufe der Zeit',
      'es': 'Haz un seguimiento de tu progreso a lo largo del tiempo.',
      'fr': 'Suivez vos progrès au fil du temps',
      'he': 'עקוב אחר ההתקדמות שלך לאורך זמן',
    },
    'cmrlanpg': {
      'en': 'No analytics yet',
      'de': 'Noch keine Analysen',
      'es': 'Aún no hay análisis',
      'fr': 'Aucune analyse pour le moment',
      'he': 'עדיין אין אנליטיקה',
    },
    '6jsq3v8f': {
      'en': 'Log a few sessions to see how this exercise progresses over time.',
      'de':
          'Protokollieren Sie einige Trainingseinheiten, um zu sehen, wie sich diese Übung im Laufe der Zeit entwickelt.',
      'es':
          'Registra algunas sesiones para ver cómo progresa este ejercicio con el tiempo.',
      'fr':
          'Enregistrez quelques séances pour observer l\'évolution de cet exercice au fil du temps.',
      'he': 'רשמו כמה אימונים כדי לראות כיצד התרגיל הזה מתקדם לאורך זמן.',
    },
    'sp23cish': {
      'en': 'Current Week',
      'de': 'Aktuelle Woche',
      'es': 'Semana actual',
      'fr': 'Semaine actuelle',
      'he': 'השבוע הנוכחי',
    },
    '640e4yle': {
      'en': 'Total Sessions',
      'de': 'Gesamtsitzungen',
      'es': 'Sesiones totales',
      'fr': 'Nombre total de séances',
      'he': 'סך כל הפעילויות',
    },
    'jqnfb2x7': {
      'en': 'Improvement',
      'de': 'Verbesserung',
      'es': 'Mejora',
      'fr': 'Amélioration',
      'he': 'הַשׁבָּחָה',
    },
    '76qov726': {
      'en': 'Exercise Analytics',
      'de': 'Trainingsanalyse',
      'es': 'Análisis de ejercicios',
      'fr': 'Analyse des exercices',
      'he': 'אנליטיקה של פעילות גופנית',
    },
    'jx4p2c2g': {
      'en': 'Track your progress over time',
      'de': 'Verfolge deinen Fortschritt im Laufe der Zeit',
      'es': 'Haz un seguimiento de tu progreso a lo largo del tiempo.',
      'fr': 'Suivez vos progrès au fil du temps',
      'he': 'עקוב אחר ההתקדמות שלך לאורך זמן',
    },
    'gzx8ytk0': {
      'en': 'Reps',
      'de': 'Reps',
      'es': 'Representantes',
      'fr': 'Réputation',
      'he': 'נציגים',
    },
    '1brmwhfu': {
      'en': 'Assistance',
      'de': 'Hilfe',
      'es': 'Asistencia',
      'fr': 'Assistance',
      'he': 'סִיוּעַ',
    },
    'yn9hwikv': {
      'en': 'Volume',
      'de': 'Volumen',
      'es': 'Volumen',
      'fr': 'Volume',
      'he': 'כֶּרֶך',
    },
    'he8b102c': {
      'en': 'Reps',
      'de': 'Reps',
      'es': 'Representantes',
      'fr': 'Réputation',
      'he': 'נציגים',
    },
    'z1xpwmzt': {
      'en': 'Current Week',
      'de': 'Aktuelle Woche',
      'es': 'Semana actual',
      'fr': 'Semaine actuelle',
      'he': 'השבוע הנוכחי',
    },
    '55s9rfeo': {
      'en': 'Best Session',
      'de': 'Beste Session',
      'es': 'Mejor sesión',
      'fr': 'Meilleure session',
      'he': 'הסשן הטוב ביותר',
    },
    'v6knhf1n': {
      'en': 'Improvement',
      'de': 'Verbesserung',
      'es': 'Mejora',
      'fr': 'Amélioration',
      'he': 'הַשׁבָּחָה',
    },
    '41b3hlhm': {
      'en': 'Estimated 1RM',
      'de': 'Geschätztes 1RM',
      'es': 'Estimado 1RM',
      'fr': '1RM estimé',
      'he': '1RM משוער',
    },
    'vni1cu3l': {
      'en': 'Based on your heaviest set using the Epley formula',
      'de':
          'Basierend auf Ihrem schwersten Satz unter Verwendung der Epley-Formel',
      'es': 'Basado en tu serie más pesada usando la fórmula de Epley',
      'fr': 'En fonction de votre poids le plus élevé, selon la formule Epley',
      'he': 'בהתבסס על הסט הכבד ביותר שלך באמצעות נוסחת אפלי',
    },
    'bmne3ih7': {
      'en': '1RM = weight × (1 + reps ÷ 30)',
      'de': '1RM = Gewicht × (1 + Wiederholungen ÷ 30)',
      'es': '1RM = peso × (1 + repeticiones ÷ 30)',
      'fr': '1RM = poids × (1 + répétitions ÷ 30)',
      'he': '1RM = משקל × (1 + חזרות ÷ 30)',
    },
    '6vx32ca9': {
      'en': 'Home',
      'de': 'Heim',
      'es': 'Hogar',
      'fr': 'Maison',
      'he': 'בַּיִת',
    },
  },
  // test
  {
    'd3k05ijc': {
      'en': 'Button',
      'de': 'Taste',
      'es': 'Botón',
      'fr': 'Bouton',
      'he': 'לַחְצָן',
    },
    'm1orp68a': {
      'en': 'HEVY',
      'de': 'SCHWER',
      'es': 'PESADO',
      'fr': 'LOURD',
      'he': 'הווי',
    },
    '6uv5sjg8': {
      'en': 'Page Title',
      'de': 'Seitentitel',
      'es': 'Título de la página',
      'fr': 'Titre de la page',
      'he': 'כותרת העמוד',
    },
    'eee63fkc': {
      'en': 'Home',
      'de': 'Heim',
      'es': 'Hogar',
      'fr': 'Maison',
      'he': 'בַּיִת',
    },
  },
  // videopage
  {
    'c244xa8i': {
      'en': 'Page Title',
      'de': 'Seitentitel',
      'es': 'Título de la página',
      'fr': 'Titre de la page',
      'he': 'כותרת העמוד',
    },
    '49qt3kqy': {
      'en': 'Home',
      'de': 'Heim',
      'es': 'Hogar',
      'fr': 'Maison',
      'he': 'בַּיִת',
    },
  },
  // manageSubscription
  {
    '77jo69zl': {
      'en': 'CURRENT PLAN',
      'de': 'AKTUELLER PLAN',
      'es': 'PLAN ACTUAL',
      'fr': 'PLAN ACTUEL',
      'he': 'התוכנית הנוכחית',
    },
    '8wqogeau': {
      'en': 'Active',
      'de': 'Aktiv',
      'es': 'Activo',
      'fr': 'Actif',
      'he': 'פָּעִיל',
    },
    'r2iseoqi': {
      'en': 'PLANS',
      'de': 'PLÄNE',
      'es': 'PLANES',
      'fr': 'PLANS',
      'he': 'תוכניות',
    },
    'plap5bcf': {
      'en': 'Monthly',
      'de': 'Monatlich',
      'es': 'Mensual',
      'fr': 'Mensuel',
      'he': 'יַרחוֹן',
    },
    'pufj6bzw': {
      'en': 'Billed every month',
      'de': 'Abrechnung erfolgt monatlich',
      'es': 'Se factura mensualmente.',
      'fr': 'Facturé chaque mois',
      'he': 'מחויב מדי חודש',
    },
    'imljim8g': {
      'en': '\$3.99',
      'de': '3,99 €',
      'es': '\$3.99',
      'fr': '3,99 \$',
      'he': '3.99 דולר',
    },
    '4j8jb5eg': {
      'en': 'per month',
      'de': 'pro Monat',
      'es': 'por mes',
      'fr': 'par mois',
      'he': 'לְחוֹדֶשׁ',
    },
    'oc4cilpm': {
      'en': 'Yearly',
      'de': 'Jährlich',
      'es': 'Anual',
      'fr': 'Annuel',
      'he': 'שְׁנָתִי',
    },
    'zjfkvyh4': {
      'en': 'Billed once a year',
      'de': 'Abrechnung erfolgt einmal jährlich',
      'es': 'Se factura una vez al año.',
      'fr': 'Facturé une fois par an',
      'he': 'מחויב פעם בשנה',
    },
    '7xeqqe63': {
      'en': '\$5.99',
      'de': '5,99 €',
      'es': '\$5.99',
      'fr': '5,99 \$',
      'he': '5.99 דולר',
    },
    'zswmpueb': {
      'en': 'Save 37%',
      'de': 'Sparen Sie 37 %',
      'es': 'Ahorra un 37%',
      'fr': 'Économisez 37%',
      'he': 'חסכו 37%',
    },
    '1r183oit': {
      'en': 'More information',
      'de': 'Weitere Informationen',
      'es': 'Más información',
      'fr': 'Plus d\'informations',
      'he': 'מידע נוסף',
    },
    'mmashq12': {
      'en': 'Cancel your subscription at any time.',
      'de': 'Sie können Ihr Abonnement jederzeit kündigen.',
      'es': 'Cancela tu suscripción cuando quieras.',
      'fr': 'Annulez votre abonnement à tout moment.',
      'he': 'בטלו את המנוי שלכם בכל עת.',
    },
    '4nw0d4nv': {
      'en': 'Manage in App Store',
      'de': 'Im App Store verwalten',
      'es': 'Gestionar en la App Store',
      'fr': 'Gérer dans l\'App Store',
      'he': 'ניהול בחנות האפליקציות',
    },
    'zpm95ruz': {
      'en': 'Privacy Policy',
      'de': 'Datenschutzrichtlinie',
      'es': 'política de privacidad',
      'fr': 'politique de confidentialité',
      'he': 'מדיניות פרטיות',
    },
    '277u5gzv': {
      'en': 'Terms & Conditions',
      'de': 'Allgemeine Geschäftsbedingungen',
      'es': 'Términos y condiciones',
      'fr': 'Conditions générales',
      'he': 'תנאים והגבלות',
    },
    'xk7ttxv0': {
      'en': 'Something not right? Let us know',
      'de': 'Stimmt etwas nicht? Lassen Sie es uns wissen.',
      'es': '¿Algo no funciona correctamente? Háganoslo saber.',
      'fr': 'Quelque chose ne va pas ? Faites-le nous savoir.',
      'he': 'משהו לא בסדר? תעדכן אותנו',
    },
    'fh32c1ua': {
      'en': 'Contect us',
      'de': 'Kontaktieren Sie uns',
      'es': 'Contáctanos',
      'fr': 'Contactez-nous',
      'he': 'צרו קשר',
    },
    '9zxdm4jg': {
      'en': 'Restore Purchases',
      'de': 'Käufe wiederherstellen',
      'es': 'Restaurar compras',
      'fr': 'Restaurer les achats',
      'he': 'שחזור רכישות',
    },
    'j34thjz9': {
      'en': 'Manage Subscription',
      'de': 'Abonnement verwalten',
      'es': 'Gestionar suscripción',
      'fr': 'Gérer mon abonnement',
      'he': 'ניהול מנוי',
    },
    'qpc7xog4': {
      'en': 'Home',
      'de': 'Heim',
      'es': 'Hogar',
      'fr': 'Maison',
      'he': 'בַּיִת',
    },
  },
  // test3
  {
    'zyxx1g8q': {
      'en': 'Page Title',
      'de': 'Seitentitel',
      'es': 'Título de la página',
      'fr': 'Titre de la page',
      'he': 'כותרת העמוד',
    },
    '4y2bsccq': {
      'en': 'Home',
      'de': 'Heim',
      'es': 'Hogar',
      'fr': 'Maison',
      'he': 'בַּיִת',
    },
  },
  // videopageHEVY
  {
    '428xgxdf': {
      'en': 'Page Title',
      'de': 'Seitentitel',
      'es': 'Título de la página',
      'fr': 'Titre de la page',
      'he': 'כותרת העמוד',
    },
    'tty2d4ff': {
      'en': 'Home',
      'de': 'Heim',
      'es': 'Hogar',
      'fr': 'Maison',
      'he': 'בַּיִת',
    },
  },
  // liveSquat
  {
    '7kt3w1xy': {
      'en': 'Home',
      'de': 'Heim',
      'es': 'Hogar',
      'fr': 'Maison',
      'he': 'בַּיִת',
    },
  },
  // camera
  {
    'bld8hx0k': {
      'en': 'Home',
      'de': 'Heim',
      'es': 'Hogar',
      'fr': 'Maison',
      'he': 'בַּיִת',
    },
  },
  // aiCustomMuscels
  {
    'rvbtcx4m': {
      'en': 'Step 1 of 3',
      'de': 'Schritt 1 von 3',
      'es': 'Paso 1 de 3',
      'fr': 'Étape 1 sur 3',
      'he': 'שלב 1 מתוך 3',
    },
    '4lqjbmqg': {
      'en': 'Which muscles do you want to train?',
      'de': 'Welche Muskeln möchten Sie trainieren?',
      'es': '¿Qué músculos quieres entrenar?',
      'fr': 'Quels muscles souhaitez-vous entraîner ?',
      'he': 'אילו שרירים אתם רוצים לאמן?',
    },
    'b1t1hkph': {
      'en': 'Select all that apply for your custom session.',
      'de':
          'Wählen Sie alle zutreffenden Optionen für Ihre benutzerdefinierte Sitzung aus.',
      'es':
          'Seleccione todas las opciones que correspondan a su sesión personalizada.',
      'fr':
          'Sélectionnez toutes les options qui s\'appliquent à votre session personnalisée.',
      'he': 'בחר את כל מה שרלוונטי לסשן המותאם אישית שלך.',
    },
    'mkb8mfog': {
      'en': 'continue',
      'de': 'weitermachen',
      'es': 'continuar',
      'fr': 'continuer',
      'he': 'לְהַמשִׁיך',
    },
  },
  // aiWorkoutType
  {
    '0gkzt94v': {
      'en': 'Step 1 of 3',
      'de': 'Schritt 1 von 3',
      'es': 'Paso 1 de 3',
      'fr': 'Étape 1 sur 3',
      'he': 'שלב 1 מתוך 3',
    },
    'xn3wcs51': {
      'en': 'Build your workout template',
      'de': 'Erstelle deine Trainingsvorlage',
      'es': 'Crea tu plantilla de entrenamiento',
      'fr': 'Créez votre modèle d\'entraînement',
      'he': 'בנה את תבנית האימון שלך',
    },
    '5bv7zba3': {
      'en': 'Choose a split, or pick your own muscles.',
      'de': 'Wähle eine Aufteilung oder suche dir deine eigenen Muskeln aus.',
      'es': 'Elige una rutina dividida o selecciona tus propios músculos.',
      'fr': 'Choisissez une répartition ou sélectionnez vos propres muscles.',
      'he': 'בחרו פיצול, או בחרו את השרירים שלכם בעצמכם.',
    },
    'ldu9ugd5': {
      'en': 'Push',
      'de': 'Drücken',
      'es': 'Empujar',
      'fr': 'Pousser',
      'he': 'לִדחוֹף',
    },
    'zacohhsl': {
      'en': 'Chest, shoulders & triceps',
      'de': 'Brust, Schultern und Trizeps',
      'es': 'Pecho, hombros y tríceps',
      'fr': 'Pectoraux, épaules et triceps',
      'he': 'חזה, כתפיים ושרירי תלת ראשי',
    },
    'sy4mx701': {
      'en': 'Pull',
      'de': 'Ziehen',
      'es': 'Jalar',
      'fr': 'Tirer',
      'he': 'מְשׁוֹך',
    },
    'ewg3msza': {
      'en': 'Back, biceps & rear delts',
      'de': 'Rücken, Bizeps und hintere Schultermuskeln',
      'es': 'Espalda, bíceps y deltoides posteriores',
      'fr': 'Dos, biceps et deltoïdes postérieurs',
      'he': 'גב, שרירי דו-ראשי ודלתא אחורית',
    },
    '2t1hs8uv': {
      'en': 'Legs',
      'de': 'Beine',
      'es': 'Piernas',
      'fr': 'Jambes',
      'he': 'רגליים',
    },
    '2f7rki7h': {
      'en': 'Quads, hamstrings & calves',
      'de': 'Oberschenkelvorderseite, Oberschenkelrückseite und Waden',
      'es': 'Cuádriceps, isquiotibiales y pantorrillas',
      'fr': 'Quadriceps, ischio-jambiers et mollets',
      'he': 'שרירי ארבע-ראשי, שרירי הירך האחורית ושרירי השוקיים',
    },
    'gg2vv63b': {
      'en': 'Full Body',
      'de': 'Ganzkörper',
      'es': 'Cuerpo completo',
      'fr': 'Corps entier',
      'he': 'גוף מלא',
    },
    '5fidc8ab': {
      'en': 'Comprehensive compound movements',
      'de': 'Umfassende Verbundbewegungen',
      'es': 'Movimientos compuestos integrales',
      'fr': 'mouvements composés complets',
      'he': 'תנועות מורכבות מקיפות',
    },
    '7sw0qqsg': {
      'en': 'Custom Split',
      'de': 'Benutzerdefinierte Aufteilung',
      'es': 'División personalizada',
      'fr': 'Division personnalisée',
      'he': 'פיצול מותאם אישית',
    },
    'iipl4qwh': {
      'en': 'Design your own muscle grouping',
      'de': 'Gestalte deine eigene Muskelgruppe',
      'es': 'Diseña tu propio grupo muscular',
      'fr': 'Concevez votre propre groupe musculaire',
      'he': 'עיצוב קבוצת שרירים משלך',
    },
  },
  // aiExpirenceLevel
  {
    'wiwpumnv': {
      'en': 'Step 2 of 3',
      'de': 'Schritt 2 von 3',
      'es': 'Paso 2 de 3',
      'fr': 'Étape 2 sur 3',
      'he': 'שלב 2 מתוך 3',
    },
    'tu1swqw8': {
      'en': 'What\'s your experience level?',
      'de': 'Wie hoch ist Ihr Erfahrungsniveau?',
      'es': '¿Cuál es tu nivel de experiencia?',
      'fr': 'Quel est votre niveau d\'expérience ?',
      'he': 'מה רמת הניסיון שלך?',
    },
    '3x8pc0ed': {
      'en': 'We\'ll match the volume and exercises to you.',
      'de': 'Wir passen Umfang und Übungen an Ihre Bedürfnisse an.',
      'es': 'Adaptaremos el volumen y los ejercicios a tus necesidades.',
      'fr': 'Nous adapterons le volume et les exercices à votre niveau.',
      'he': 'נתאים לך את הנפח והתרגילים.',
    },
    'nmh3rml0': {
      'en': 'Beginner',
      'de': 'Anfänger',
      'es': 'Principiante',
      'fr': 'Débutant',
      'he': 'מַתחִיל',
    },
    '9hv04bwj': {
      'en': 'New to lifting',
      'de': 'Neu im Krafttraining',
      'es': 'Principiante en levantamiento de pesas',
      'fr': 'Débutant en haltérophilie',
      'he': 'חדש בהרמת מטוסים',
    },
    'seazc0tm': {
      'en': 'Intermediate ',
      'de': 'Dazwischenliegend',
      'es': 'Intermedio',
      'fr': 'Intermédiaire',
      'he': 'בינוני',
    },
    '70w7kpq4': {
      'en': 'Training consistently for 1+ years',
      'de': 'Kontinuierliches Training seit über einem Jahr',
      'es': 'Entrenamiento constante durante más de 1 año.',
      'fr': 'Entraînement régulier pendant plus d\'un an',
      'he': 'אימונים באופן עקבי במשך שנה ומעלה',
    },
    'lvndihye': {
      'en': 'Advanced ',
      'de': 'Fortschrittlich',
      'es': 'Avanzado',
      'fr': 'Avancé',
      'he': 'מִתקַדֵם',
    },
    '24tdd10e': {
      'en': 'Experienced, high training volume',
      'de': 'Erfahren, hohes Trainingsvolumen',
      'es': 'Experimentado, alto volumen de entrenamiento',
      'fr': 'Expérimenté, volume d\'entraînement élevé',
      'he': 'מנוסה, נפח אימונים גבוה',
    },
    'dz5m6mvm': {
      'en': 'Continue',
      'de': 'Weitermachen',
      'es': 'Continuar',
      'fr': 'Continuer',
      'he': 'לְהַמשִׁיך',
    },
  },
  // aiGoal
  {
    'nu5253tz': {
      'en': 'Step 3 of 3',
      'de': 'Schritt 3 von 3',
      'es': 'Paso 3 de 3',
      'fr': 'Étape 3 sur 3',
      'he': 'שלב 3 מתוך 3',
    },
    'n9ms7y49': {
      'en': 'What\'s your training goal?',
      'de': 'Was ist dein Trainingsziel?',
      'es': '¿Cuál es tu objetivo de entrenamiento?',
      'fr': 'Quel est votre objectif d\'entraînement ?',
      'he': 'מהי מטרת האימון שלך?',
    },
    'hri91f9i': {
      'en': 'This sets your reps, sets, and rest.',
      'de': 'Hiermit legst du Wiederholungen, Sätze und Pausen fest.',
      'es': 'Esto determina tus repeticiones, series y descansos.',
      'fr':
          'Cela détermine vos répétitions, vos séries et votre temps de repos.',
      'he': 'זה קובע את מספר החזרות, הסטים והמנוחה שלך.',
    },
    'lad52cs2': {
      'en': 'Build Muscle',
      'de': 'Muskelaufbau',
      'es': 'Desarrollar músculo',
      'fr': 'Développer ses muscles',
      'he': 'בניית שרירים',
    },
    '8sw91is0': {
      'en': 'Grow size with moderate reps',
      'de': 'Muskelwachstum durch moderate Wiederholungen',
      'es': 'Aumenta de tamaño con repeticiones moderadas.',
      'fr': 'Augmentez votre masse musculaire avec des répétitions modérées.',
      'he': 'הגדלת גודל עם חזרות מתונות',
    },
    'uo9zjvcu': {
      'en': 'Get Stronger',
      'de': 'Werde stärker',
      'es': 'Fortalécete',
      'fr': 'Devenez plus fort',
      'he': 'התחזק',
    },
    '442o15f0': {
      'en': 'Get Stronger',
      'de': 'Werde stärker',
      'es': 'Fortalécete',
      'fr': 'Devenez plus fort',
      'he': 'התחזק',
    },
    '8gqq575c': {
      'en': 'Endurance',
      'de': 'Ausdauer',
      'es': 'Resistencia',
      'fr': 'Endurance',
      'he': 'הַתמָדָה',
    },
    'ehrwxabw': {
      'en': 'Higher reps, shorter rest',
      'de': 'Mehr Wiederholungen, kürzere Pausen',
      'es': 'Mayor número de repeticiones, menor tiempo de descanso.',
      'fr': 'Plus de répétitions, moins de repos',
      'he': 'חזרות גבוהות יותר, מנוחה קצרה יותר',
    },
    '9gtfowsf': {
      'en': 'Generate Workout',
      'de': 'Trainingsplan generieren',
      'es': 'Generar entrenamiento',
      'fr': 'Générer un entraînement',
      'he': 'צור אימון',
    },
  },
  // testAI
  {
    '8l6o3gwt': {
      'en': 'Page Title',
      'de': 'Seitentitel',
      'es': 'Título de la página',
      'fr': 'Titre de la page',
      'he': 'כותרת העמוד',
    },
    '3wcvl5pj': {
      'en': 'Home',
      'de': 'Heim',
      'es': 'Hogar',
      'fr': 'Maison',
      'he': 'בַּיִת',
    },
  },
  // aiWorkoutLoading
  {
    'zo8zv9tf': {
      'en': 'Building Your Workout ...',
      'de': 'Erstellen Sie Ihr Trainingsprogramm ...',
      'es': 'Diseñando tu rutina de ejercicios...',
      'fr': 'Créer votre programme d\'entraînement...',
      'he': 'בניית האימון שלך...',
    },
    'v60odw6r': {
      'en': 'Home',
      'de': 'Heim',
      'es': 'Hogar',
      'fr': 'Maison',
      'he': 'בַּיִת',
    },
  },
  // aiWorkoutView
  {
    'k67sgjjy': {
      'en': 'Minutes',
      'de': 'Minuten',
      'es': 'Minutos',
      'fr': 'Minutes',
      'he': 'פּרוֹטוֹקוֹל',
    },
    'u70684v5': {
      'en': '•',
      'de': '•',
      'es': '•',
      'fr': '•',
      'he': '•',
    },
    'yknk7dq0': {
      'en': 'Save Workout',
      'de': 'Training speichern',
      'es': 'Guardar entrenamiento',
      'fr': 'Enregistrer l\'entraînement',
      'he': 'שמור אימון',
    },
  },
  // PremiumPaywallPage
  {
    't8rryeqh': {
      'en': 'XLIFT PREMIUM',
      'de': 'XLIFT PREMIUM',
      'es': 'XLIFT PREMIUM',
      'fr': 'XLIFT PREMIUM',
      'he': 'XLIFT פרימיום',
    },
    'lw64qsg0': {
      'en': 'Unlock your\nfull potential',
      'de': 'Entfalte dein volles Potenzial',
      'es': 'Desbloquea todo tu potencial.',
      'fr': 'Libérez votre plein potentiel\n',
      'he': 'שחררו את מלוא הפוטנציאל שלכם',
    },
    'yd1g8q07': {
      'en': 'Start 7-Day Free Trial',
      'de': '7 Tage kostenlos testen',
      'es': 'Comienza tu prueba gratuita de 7 días.',
      'fr': 'Démarrez votre essai gratuit de 7 jours',
      'he': 'התחל תקופת ניסיון בחינם למשך 7 ימים',
    },
    '214fymmx': {
      'en': 'Privacy Policy',
      'de': 'Datenschutzrichtlinie',
      'es': 'política de privacidad',
      'fr': 'politique de confidentialité',
      'he': 'מדיניות פרטיות',
    },
    's0krmnr4': {
      'en': '·',
      'de': '·',
      'es': '·',
      'fr': '·',
      'he': '·',
    },
    'ca4hmb6f': {
      'en': 'Terms',
      'de': 'Bedingungen',
      'es': 'Términos',
      'fr': 'Termes',
      'he': 'תנאים',
    },
    'bff1v9sz': {
      'en': '·',
      'de': '·',
      'es': '·',
      'fr': '·',
      'he': '·',
    },
    'vpkpqnes': {
      'en': 'Restore',
      'de': 'Wiederherstellen',
      'es': 'Restaurar',
      'fr': 'Restaurer',
      'he': 'לְשַׁחְזֵר',
    },
  },
  // changePassword
  {
    '0uyeopfr': {
      'en': 'Back',
      'de': 'Zurück',
      'es': 'Atrás',
      'fr': 'Dos',
      'he': 'בְּחֲזָרָה',
    },
    'hv49gfa8': {
      'en': 'Change Password',
      'de': 'Kennwort ändern',
      'es': 'Cambiar la contraseña',
      'fr': 'Changer le mot de passe',
      'he': 'שינוי סיסמה',
    },
    'ouqq9g1p': {
      'en':
          'We will send you an email with a link to reset your password, please enter the email associated with your account below.',
      'de':
          'Wir senden Ihnen eine E-Mail mit einem Link zum Zurücksetzen Ihres Passworts. Bitte geben Sie unten die mit Ihrem Konto verknüpfte E-Mail-Adresse ein.',
      'es':
          'Le enviaremos un correo electrónico con un enlace para restablecer su contraseña. Por favor, introduzca a continuación la dirección de correo electrónico asociada a su cuenta.',
      'fr':
          'Nous vous enverrons un courriel contenant un lien pour réinitialiser votre mot de passe. Veuillez saisir ci-dessous l\'adresse courriel associée à votre compte.',
      'he':
          'נשלח לך אימייל עם קישור לאיפוס הסיסמה שלך, אנא הזן את כתובת האימייל המקושרת לחשבונך למטה.',
    },
    '2o2ch6f4': {
      'en': 'Your email address...',
      'de': 'Ihre E-Mail-Adresse...',
      'es': 'Su dirección de correo electrónico...',
      'fr': 'Votre adresse e-mail...',
      'he': 'כתובת הדוא\"ל שלך...',
    },
    '4sctl9sx': {
      'en': 'Enter your email...',
      'de': 'Geben Sie Ihre E-Mail-Adresse ein...',
      'es': 'Introduce tu correo electrónico...',
      'fr': 'Saisissez votre adresse e-mail...',
      'he': 'הזן את כתובת האימייל שלך...',
    },
    'oy84qymb': {
      'en': 'Send Link',
      'de': 'Link senden',
      'es': 'Enviar enlace',
      'fr': 'Envoyer le lien',
      'he': 'שלח קישור',
    },
    '5xhghx2g': {
      'en': 'Home',
      'de': 'Heim',
      'es': 'Hogar',
      'fr': 'Maison',
      'he': 'בַּיִת',
    },
  },
  // SignInWelcomePage6
  {
    'e8nt6zeb': {
      'en': 'XLIFT',
      'de': 'XLIFT',
      'es': 'XLIFT',
      'fr': 'XLIFT',
      'he': 'XLIFT',
    },
    'dcgmtwg7': {
      'en': 'Train smarter. Lift stronger.',
      'de': 'Trainiere intelligenter. Hebe stärkere Gewichte.',
      'es': 'Entrena de forma más inteligente. Levanta más peso.',
      'fr': 'Entraînez-vous plus intelligemment. Soulevez plus fort.',
      'he': 'להתאמן חכם יותר. להרים חזק יותר.',
    },
    't5l67562': {
      'en': 'Continue with Apple',
      'de': 'Weiter mit Apple',
      'es': 'Continuar con Apple',
      'fr': 'Continuez avec Apple',
      'he': 'המשך עם אפל',
    },
    'i1rz68vz': {
      'en': 'Continue with Google',
      'de': 'Mit Google fortfahren',
      'es': 'Continuar con Google',
      'fr': 'Continuer avec Google',
      'he': 'המשך עם גוגל',
    },
    'nxmlj0r3': {
      'en': 'Continue with email',
      'de': 'Mit der E-Mail fortfahren',
      'es': 'Continuar con el correo electrónico',
      'fr': 'Poursuivre par courriel',
      'he': 'המשך עם הדוא\"ל',
    },
    'eai5gy4m': {
      'en': 'By continuing you agree to our',
      'de': 'Indem Sie fortfahren, stimmen Sie unseren Bedingungen zu',
      'es': 'Al continuar, aceptas nuestros términos y condiciones.',
      'fr': 'En continuant, vous acceptez nos conditions générales.',
      'he': 'על ידי המשך השימוש הנך מסכים/ה לתנאים שלנו',
    },
    'yqyu9bkf': {
      'en': 'Terms',
      'de': 'Bedingungen',
      'es': 'Términos',
      'fr': 'Termes',
      'he': 'תנאים',
    },
    'nak0vblh': {
      'en': 'and',
      'de': 'Und',
      'es': 'y',
      'fr': 'et',
      'he': 'ו',
    },
    'y252v12n': {
      'en': 'Privacy Policy',
      'de': 'Datenschutzrichtlinie',
      'es': 'política de privacidad',
      'fr': 'politique de confidentialité',
      'he': 'מדיניות פרטיות',
    },
  },
  // FullResultPage
  {
    'dmhlqoy9': {
      'en': 'Total Reps',
      'de': 'Gesamtwiederholungen',
      'es': 'Repeticiones totales',
      'fr': 'Nombre total de répétitions',
      'he': 'סך חזרות',
    },
    'jlj8teaj': {
      'en': 'Proper Reps',
      'de': 'Richtige Wiederholungen',
      'es': 'Representantes adecuados',
      'fr': 'Répliques correctes',
      'he': 'חזרות נכונות',
    },
    'nt3lhro3': {
      'en': 'Form Tip',
      'de': 'Formtipp',
      'es': 'Consejo de forma',
      'fr': 'Conseil de forme',
      'he': 'טיפ לטופס',
    },
    'pmmqjyi3': {
      'en': 'View Video',
      'de': 'Video ansehen',
      'es': 'Ver vídeo',
      'fr': 'Voir la vidéo',
      'he': 'צפה בסרטון',
    },
    'saor8l81': {
      'en': 'Feedback',
      'de': 'Rückmeldung',
      'es': 'Comentario',
      'fr': 'Retour',
      'he': 'מָשׁוֹב',
    },
    'lhx7ymxp': {
      'en': 'Try going deeper on your squats',
      'de': 'Versuche, bei den Kniebeugen tiefer zu gehen.',
      'es': 'Intenta bajar más en tus sentadillas.',
      'fr': 'Essayez de descendre plus bas lors de vos squats.',
      'he': 'נסו לעשות סקוואטים עמוק יותר',
    },
    '96wal5wp': {
      'en': 'Continue as Workout',
      'de': 'Als Workout fortfahren',
      'es': 'Continúa como entrenamiento',
      'fr': 'Continuer comme entraînement',
      'he': 'המשך כאימון',
    },
  },
  // FullAnalyzingStatePage
  {
    'at083w6n': {
      'en': 'Tracking joints and bar path',
      'de': 'Gelenke und Stabverlauf verfolgen',
      'es': 'Seguimiento de juntas y trayectoria de la barra',
      'fr': 'Suivi des articulations et de la trajectoire de la barre',
      'he': 'מעקב אחר מפרקים ונתיב מוט',
    },
    'qwgrvacy': {
      'en': 'This usually takes about 30 seconds',
      'de': 'Das dauert normalerweise etwa 30 Sekunden.',
      'es': 'Esto suele tardar unos 30 segundos.',
      'fr': 'Cela prend généralement environ 30 secondes.',
      'he': 'זה בדרך כלל לוקח בערך 30 שניות',
    },
  },
  // masterPage
  {
    'e95uok47': {
      'en': 'Statistics',
      'de': 'Statistiken',
      'es': 'Estadística',
      'fr': 'Statistiques',
      'he': 'סטָטִיסטִיקָה',
    },
    'sq5o4cbn': {
      'en': 'Overview',
      'de': 'Überblick',
      'es': 'Descripción general',
      'fr': 'Aperçu',
      'he': 'סקירה כללית',
    },
    '1r95bm6r': {
      'en': 'Volume Over Time',
      'de': 'Volumen im Laufe der Zeit',
      'es': 'Volumen a lo largo del tiempo',
      'fr': 'Volume au fil du temps',
      'he': 'נפח לאורך זמן',
    },
    '9liemkyb': {
      'en': 'Workouts',
      'de': 'Trainingseinheiten',
      'es': 'Entrenamientos',
      'fr': 'Entraînements',
      'he': 'אימונים',
    },
    'kypsbi0s': {
      'en': 'Total Volume',
      'de': 'Gesamtvolumen',
      'es': 'Volumen total',
      'fr': 'Volume total',
      'he': 'נפח כולל',
    },
    'u6di45yf': {
      'en': 'Top Muscle',
      'de': 'Top-Muskeln',
      'es': 'Músculos superiores',
      'fr': 'Muscles supérieurs',
      'he': 'שריר עליון',
    },
    'v7w62k4h': {
      'en': 'Sets by Muscle Group',
      'de': 'Sätze nach Muskelgruppe',
      'es': 'Series por grupo muscular',
      'fr': 'Séries par groupe musculaire',
      'he': 'סטים לפי קבוצת שרירים',
    },
    'aoymqw3k': {
      'en': 'Sets',
      'de': 'Sets',
      'es': 'Conjuntos',
      'fr': 'Ensembles',
      'he': 'סטים',
    },
    'e8dgbzuh': {
      'en': 'By Exercise',
      'de': 'Durch Übung',
      'es': 'Mediante el ejercicio',
      'fr': 'Par l\'exercice',
      'he': 'לפי פעילות גופנית',
    },
    '48qrhv5k': {
      'en': 'By Muscle',
      'de': 'Durch Muskeln',
      'es': 'Por músculo',
      'fr': 'Par Muscle',
      'he': 'מאת שריר',
    },
    'v519r977': {
      'en': 'live',
      'de': 'live',
      'es': 'vivir',
      'fr': 'en direct',
      'he': 'לִחיוֹת',
    },
    'guz1gr5a': {
      'en': 'AI',
      'de': 'KI',
      'es': 'AI',
      'fr': 'IA',
      'he': 'בינה מלאכותית',
    },
    'c5eotijq': {
      'en': 'deadBarbell',
      'de': 'tote Hantel',
      'es': 'barra muerta',
      'fr': 'barre morte',
      'he': 'משקולת מתה',
    },
    'j052n2mz': {
      'en': 'Barbell',
      'de': 'Hantel',
      'es': 'Barra con pesas',
      'fr': 'Haltère',
      'he': 'מוט',
    },
    'tdz0v8sl': {
      'en': 'HEVY',
      'de': 'SCHWER',
      'es': 'PESADO',
      'fr': 'LOURD',
      'he': 'הווי',
    },
    '20ovd11d': {
      'en': 'overhead',
      'de': 'Überkopf',
      'es': 'arriba',
      'fr': 'aérien',
      'he': 'מִמַעַל',
    },
    '5faz4avs': {
      'en': 'stiff',
      'de': 'steif',
      'es': 'rígido',
      'fr': 'rigide',
      'he': 'נוּקשֶׁה',
    },
    'mzkxe4lg': {
      'en': 'dead',
      'de': 'tot',
      'es': 'muerto',
      'fr': 'mort',
      'he': 'מֵת',
    },
    'oa9v66qh': {
      'en': 'romanian',
      'de': 'rumänisch',
      'es': 'rumano',
      'fr': 'roumain',
      'he': 'רומנית',
    },
    'mnefh77d': {
      'en': 'Bulgarian',
      'de': 'bulgarisch',
      'es': 'búlgaro',
      'fr': 'bulgare',
      'he': 'בולגרית',
    },
    '8gaxhykq': {
      'en': 'bent',
      'de': 'gebogen',
      'es': 'doblado',
      'fr': 'courbé',
      'he': 'כִּפּוּף',
    },
    'i11qsqnm': {
      'en': 'curl',
      'de': 'Locke',
      'es': 'rizo',
      'fr': 'boucle',
      'he': 'סִלְסוּל',
    },
    'd7krjqep': {
      'en': 'pushup',
      'de': 'Liegestütze',
      'es': 'flexión',
      'fr': 'pompes',
      'he': 'שכיבות סמיכה',
    },
    '36rqa6e7': {
      'en': 'Button',
      'de': 'Taste',
      'es': 'Botón',
      'fr': 'Bouton',
      'he': 'לַחְצָן',
    },
    'k7sua9wp': {
      'en': 'pullup',
      'de': 'Klimmzug',
      'es': 'dominada',
      'fr': 'tirer vers le haut',
      'he': 'משיכה',
    },
    'lcrzglaf': {
      'en': 'dips',
      'de': 'Einbrüche',
      'es': 'luces cortas',
      'fr': 'trempettes',
      'he': 'מטבלים',
    },
    'yud1n1w6': {
      'en': 'Workout in Progress',
      'de': 'Training läuft',
      'es': 'Entrenamiento en curso',
      'fr': 'Entraînement en cours',
      'he': 'אימון בתהליך',
    },
    'beheo8ln': {
      'en': 'Home',
      'de': 'Heim',
      'es': 'Hogar',
      'fr': 'Maison',
      'he': 'בַּיִת',
    },
  },
  // CreateWorkoutV2
  {
    'ewirjb69': {
      'en': 'Workout name',
      'de': 'Name des Workouts',
      'es': 'Nombre del entrenamiento',
      'fr': 'Nom de l\'entraînement',
      'he': 'שם האימון',
    },
    'x8lkt3tb': {
      'en': 'Enter workout name',
      'de': 'Trainingsnamen eingeben',
      'es': 'Ingrese el nombre del entrenamiento',
      'fr': 'Saisissez le nom de l\'entraînement',
      'he': 'הזן שם אימון',
    },
    's28y3dxn': {
      'en': 'Add exercises',
      'de': 'Übungen hinzufügen',
      'es': 'Agregar ejercicios',
      'fr': 'Ajouter des exercices',
      'he': 'הוסף תרגילים',
    },
    'hxqefook': {
      'en': 'Save',
      'de': 'Speichern',
      'es': 'Ahorrar',
      'fr': 'Sauvegarder',
      'he': 'לְהַצִיל',
    },
    'c6sgql8x': {
      'en': 'Create Workout',
      'de': 'Training erstellen',
      'es': 'Crear entrenamiento',
      'fr': 'Créer un entraînement',
      'he': 'צור אימון',
    },
  },
  // workoutComplete
  {
    'wpugqjh5': {
      'en': 'WORKOUT COMPLETE',
      'de': 'TRAINING ABGESCHLOSSEN',
      'es': 'ENTRENAMIENTO COMPLETADO',
      'fr': 'SÉANCE D\'ENTRAÎNEMENT TERMINÉE',
      'he': 'אימון הושלם',
    },
    'z5r6sr0i': {
      'en': 'Previous best 145 kg',
      'de': 'Bisherige Bestleistung: 145 kg',
      'es': 'Mejor marca anterior: 145 kg',
      'fr': 'Meilleur précédent : 145 kg',
      'he': 'המשקל הטוב ביותר הקודם הוא 145 ק\"ג',
    },
    'nxjer796': {
      'en': 'Done',
      'de': 'Erledigt',
      'es': 'Hecho',
      'fr': 'Fait',
      'he': 'נַעֲשָׂה',
    },
  },
  // workoutSummaryView
  {
    '50vb30be': {
      'en': 'Home',
      'de': 'Heim',
      'es': 'Hogar',
      'fr': 'Maison',
      'he': 'בַּיִת',
    },
  },
  // exerciseStatsPlaceHolder
  {
    'zekrnvm0': {
      'en': 'No Data for This Period',
      'de': 'Für diesen Zeitraum liegen keine Daten vor.',
      'es': 'No hay datos para este período.',
      'fr': 'Aucune donnée disponible pour cette période',
      'he': 'אין נתונים לתקופה זו',
    },
    'u1bdzrku': {
      'en': 'Log workouts or adjust the time range to see stats.',
      'de':
          'Trainingseinheiten protokollieren oder den Zeitbereich anpassen, um Statistiken anzuzeigen.',
      'es':
          'Registra tus entrenamientos o ajusta el intervalo de tiempo para ver las estadísticas.',
      'fr':
          'Enregistrez vos séances d\'entraînement ou ajustez la plage horaire pour consulter les statistiques.',
      'he': 'רשום אימונים או התאם את טווח הזמן כדי לראות נתונים סטטיסטיים.',
    },
  },
  // statsPlaceHolder
  {
    'wyyf5hr7': {
      'en': 'No Stats Yet',
      'de': 'Noch keine Statistiken',
      'es': 'Aún no hay estadísticas.',
      'fr': 'Aucune statistique disponible pour le moment',
      'he': 'אין עדיין סטטיסטיקות',
    },
    'oexacyl7': {
      'en': 'Your workout stats will appear\n after your first session.\n\n',
      'de':
          'Deine Trainingsstatistiken werden\nnach deiner ersten Trainingseinheit angezeigt.',
      'es':
          'Tus estadísticas de entrenamiento aparecerán\n\ndespués de tu primera sesión.',
      'fr':
          'Vos statistiques d\'entraînement s\'afficheront\n\naprès votre première séance.',
      'he': 'סטטיסטיקות האימון שלך יופיעו לאחר האימון הראשון שלך.',
    },
  },
  // lineGraphPlaceHolder
  {
    'z22ymokx': {
      'en': 'No Volume Data',
      'de': 'Keine Volumendaten',
      'es': 'Sin datos de volumen',
      'fr': 'Aucune donnée de volume',
      'he': 'אין נתוני נפח',
    },
    'i7flkyk9': {
      'en': 'Log more workouts to see\nyour progress over time.',
      'de':
          'Protokolliere mehr Trainingseinheiten, um deinen Fortschritt im Laufe der Zeit zu sehen.',
      'es':
          'Registra más entrenamientos para ver tu progreso a lo largo del tiempo.',
      'fr':
          'Enregistrez davantage de séances d\'entraînement pour constater\n\nvos progrès au fil du temps.',
      'he': 'רשום עוד אימונים כדי לראות את ההתקדמות שלך לאורך זמן.',
    },
  },
  // historyPlaceHolder
  {
    '0dzfyl1j': {
      'en': 'No Workouts Yet',
      'de': 'Noch keine Trainingseinheiten',
      'es': 'Aún no hay entrenamientos.',
      'fr': 'Pas encore d\'entraînement',
      'he': 'אין עדיין אימונים',
    },
    'j0gweolp': {
      'en': 'Your workout history will show\n up once you get started.\n\n\n',
      'de': 'Deine Trainingshistorie wird angezeigt\nsobald du anfängst.',
      'es': 'Tu historial de entrenamiento aparecerá\nuna vez que comiences.',
      'fr':
          'Votre historique d\'entraînement s\'affichera\n\nune fois que vous aurez commencé.',
      'he': 'היסטוריית האימונים שלך תופיע לאחר שתתחיל.',
    },
  },
  // plc
  {
    'z1mhfswh': {
      'en': 'No workouts recorded',
      'de': 'Es wurden keine Trainingseinheiten aufgezeichnet',
      'es': 'No se registraron entrenamientos',
      'fr': 'Aucun entraînement enregistré',
      'he': 'לא תועדו אימונים',
    },
  },
  // aw
  {
    'cig0h5zr': {
      'en': 'No Workouts Yet',
      'de': 'Noch keine Trainingseinheiten',
      'es': 'Aún no hay entrenamientos.',
      'fr': 'Pas encore d\'entraînement',
      'he': 'אין עדיין אימונים',
    },
    'atsln1c0': {
      'en':
          'Start your fitness journey by creating your first workout or browse our collection for inspiration.',
      'de':
          'Starte deine Fitnessreise, indem du dein erstes Workout erstellst oder lass dich von unserer Sammlung inspirieren.',
      'es':
          'Comienza tu camino hacia una vida más saludable creando tu primer entrenamiento o explora nuestra colección en busca de inspiración.',
      'fr':
          'Commencez votre parcours de remise en forme en créant votre premier entraînement ou parcourez notre collection pour trouver l\'inspiration.',
      'he':
          'התחילו את מסע הכושר שלכם על ידי יצירת האימון הראשון שלכם או עיינו בקולקציה שלנו לקבלת השראה.',
    },
  },
  // workoutListPlaceHolder
  {
    'irzsj2pd': {
      'en': 'No Workouts Yet',
      'de': 'Noch keine Trainingseinheiten',
      'es': 'Aún no hay entrenamientos.',
      'fr': 'Pas encore d\'entraînement',
      'he': 'אין עדיין אימונים',
    },
    'yxrfbgye': {
      'en':
          'Create your own workout or start with one of our ready-made templates.\n\n',
      'de':
          'Stelle dein eigenes Workout zusammen oder nutze eine unserer vorgefertigten Vorlagen.',
      'es':
          'Crea tu propia rutina de ejercicios o empieza con una de nuestras plantillas prediseñadas.',
      'fr':
          'Créez votre propre programme d\'entraînement ou commencez avec l\'un de nos modèles prêts à l\'emploi.',
      'he': 'צור אימון משלך או התחיל עם אחת מהתבניות המוכנות שלנו.',
    },
  },
  // lightModeChange
  {
    'cxaijukp': {
      'en': 'Light',
      'de': 'Licht',
      'es': 'Luz',
      'fr': 'Lumière',
      'he': 'אוֹר',
    },
    '8sdf0gbg': {
      'en': 'Dark',
      'de': 'Dunkel',
      'es': 'Oscuro',
      'fr': 'Sombre',
      'he': 'כֵּהֶה',
    },
  },
  // editOrDelete
  {
    '9kxd6esc': {
      'en': 'Edit',
      'de': 'Bearbeiten',
      'es': 'Editar',
      'fr': 'Modifier',
      'he': 'לַעֲרוֹך',
    },
    '5nhj04kn': {
      'en': 'Delete',
      'de': 'Löschen',
      'es': 'Borrar',
      'fr': 'Supprimer',
      'he': 'לִמְחוֹק',
    },
  },
  // deleteAlert
  {
    '6ecb7p7l': {
      'en': 'Delete Workout',
      'de': 'Training löschen',
      'es': 'Eliminar entrenamiento',
      'fr': 'Supprimer l\'entraînement',
      'he': 'מחק אימון',
    },
    'u07w2qwk': {
      'en':
          'Are you sure you want to delete this workout? This action cannot be undone.',
      'de':
          'Möchten Sie dieses Training wirklich löschen? Diese Aktion kann nicht rückgängig gemacht werden.',
      'es':
          '¿Seguro que quieres eliminar este entrenamiento? Esta acción no se puede deshacer.',
      'fr':
          'Êtes-vous sûr de vouloir supprimer cette séance d\'entraînement ? Cette action est irréversible.',
      'he': 'האם אתה בטוח שברצונך למחוק את האימון הזה? לא ניתן לבטל פעולה זו.',
    },
    'vgd7xtjp': {
      'en': 'Cancel',
      'de': 'Stornieren',
      'es': 'Cancelar',
      'fr': 'Annuler',
      'he': 'לְבַטֵל',
    },
    '17wj1f41': {
      'en': 'Delete',
      'de': 'Löschen',
      'es': 'Borrar',
      'fr': 'Supprimer',
      'he': 'לִמְחוֹק',
    },
  },
  // analplaceHolder
  {
    '63wnlagg': {
      'en': 'No Exercise Data Yet',
      'de': 'Noch keine Trainingsdaten.',
      'es': 'Aún no hay datos de ejercicio.',
      'fr': 'Aucune donnée d\'exercice disponible pour le moment',
      'he': 'אין עדיין נתוני פעילות גופנית',
    },
    'n5gxn5mh': {
      'en':
          'Start logging your sets to track your progress and view detailed analytics for this exercise.',
      'de':
          'Beginnen Sie damit, Ihre Sätze zu protokollieren, um Ihren Fortschritt zu verfolgen und detaillierte Analysen für diese Übung einzusehen.',
      'es':
          'Empieza a registrar tus series para hacer un seguimiento de tu progreso y ver análisis detallados de este ejercicio.',
      'fr':
          'Commencez à enregistrer vos séries pour suivre vos progrès et consulter des analyses détaillées pour cet exercice.',
      'he':
          'התחילו לתעד את הסטים שלכם כדי לעקוב אחר ההתקדמות שלכם ולצפות בניתוחים מפורטים עבור תרגיל זה.',
    },
  },
  // restBottomShit
  {
    'sejf5l86': {
      'en': 'Rest Timer',
      'de': 'Ruhezeit',
      'es': 'Temporizador de descanso',
      'fr': 'Minuteur de repos',
      'he': 'טיימר מנוחה',
    },
    '63zlom13': {
      'en': 'Pause',
      'de': 'Pause',
      'es': 'Pausa',
      'fr': 'Pause',
      'he': 'הַפסָקָה',
    },
    'r3nsru9k': {
      'en': 'Continue',
      'de': 'Weitermachen',
      'es': 'Continuar',
      'fr': 'Continuer',
      'he': 'לְהַמשִׁיך',
    },
  },
  // cancelRest
  {
    '0cxjgs5u': {
      'en': 'Cancel Rest Timer',
      'de': 'Ruhezeit abbrechen',
      'es': 'Cancelar temporizador de descanso',
      'fr': 'Annuler le minuteur de repos',
      'he': 'ביטול טיימר מנוחה',
    },
    'jqxmif5y': {
      'en': 'Are you sure you want to cancel your rest time?',
      'de': 'Möchten Sie Ihre Ruhezeit wirklich stornieren?',
      'es': '¿Estás seguro de que quieres cancelar tu tiempo de descanso?',
      'fr': 'Êtes-vous sûr de vouloir annuler votre temps de repos ?',
      'he': 'האם אתה בטוח שאתה רוצה לבטל את זמן המנוחה שלך?',
    },
    'n5j0lo5r': {
      'en': 'No',
      'de': 'NEIN',
      'es': 'No',
      'fr': 'Non',
      'he': 'לֹא',
    },
    'ddmo7jlw': {
      'en': 'Yes, Cancel',
      'de': 'Ja, Abbrechen',
      'es': 'Sí, cancelar',
      'fr': 'Oui, annuler',
      'he': 'כן, ביטול',
    },
  },
  // manual
  {
    'm15uh64x': {
      'en': 'Count Up',
      'de': 'Zählen Sie mit.',
      'es': 'Cuenta hacia arriba',
      'fr': 'Comptez jusqu\'à',
      'he': 'לספור למעלה',
    },
    'c6taywyj': {
      'en': 'Countdown',
      'de': 'Countdown',
      'es': 'Cuenta atrás',
      'fr': 'Compte à rebours',
      'he': 'סְפִירָה לְאָחוֹר',
    },
    '7iux6n7v': {
      'en': 'Manual Entry',
      'de': 'Manuelle Eingabe',
      'es': 'Entrada manual',
      'fr': 'Saisie manuelle',
      'he': 'הזנה ידנית',
    },
  },
  // time
  {
    '9dmtmyq4': {
      'en': '0',
      'de': '0',
      'es': '0',
      'fr': '0',
      'he': '0',
    },
    '3bsz70t5': {
      'en': '0',
      'de': '0',
      'es': '0',
      'fr': '0',
      'he': '0',
    },
    '4yq05tvl': {
      'en': ':',
      'de': ':',
      'es': ':',
      'fr': ':',
      'he': ':',
    },
    '2q07fxz3': {
      'en': '0',
      'de': '0',
      'es': '0',
      'fr': '0',
      'he': '0',
    },
    'p9c1dceb': {
      'en': '0',
      'de': '0',
      'es': '0',
      'fr': '0',
      'he': '0',
    },
  },
  // video2
  {
    '7neaekml': {
      'en': 'Analyzed Video',
      'de': 'Analysiertes Video',
      'es': 'Vídeo analizado',
      'fr': 'Vidéo analysée',
      'he': 'סרטון מנותח',
    },
    'sybuu4wg': {
      'en': 'Download Original Video',
      'de': 'Originalvideo herunterladen',
      'es': 'Descargar vídeo original',
      'fr': 'Télécharger la vidéo originale',
      'he': 'הורד את הסרטון המקורי',
    },
  },
  // deopSetRow
  {
    'uem16cbb': {
      'en': '',
      'de': '',
      'es': '',
      'fr': '',
      'he': '',
    },
    'gblffgkd': {
      'en': '',
      'de': '',
      'es': '',
      'fr': '',
      'he': '',
    },
  },
  // dropSet
  {
    '46454wwc': {
      'en': 'Drop',
      'de': 'Fallen',
      'es': 'Gota',
      'fr': 'Baisse',
      'he': 'יְרִידָה',
    },
  },
  // exerciseComponet
  {
    'v02hj46u': {
      'en': 'Superset',
      'de': 'Superset',
      'es': 'Superconjunto',
      'fr': 'Surensemble',
      'he': 'סופרסט',
    },
    '1zuasebz': {
      'en': 'Previous',
      'de': 'Vorherige',
      'es': 'Anterior',
      'fr': 'Précédent',
      'he': 'קוֹדֵם',
    },
    'j5paqm5m': {
      'en': 'Time',
      'de': 'Zeit',
      'es': 'Tiempo',
      'fr': 'Temps',
      'he': 'זְמַן',
    },
    'ju5hixlu': {
      'en': 'Reps',
      'de': 'Reps',
      'es': 'Representantes',
      'fr': 'Réputation',
      'he': 'נציגים',
    },
    'y4ilum0g': {
      'en': 'Add set',
      'de': 'Set hinzufügen',
      'es': 'Agregar conjunto',
      'fr': 'Ajouter un ensemble',
      'he': 'הוסף סט',
    },
  },
  // setRowWarmUp
  {
    'zzxbbise': {
      'en': '-',
      'de': '-',
      'es': '-',
      'fr': '-',
      'he': '-',
    },
    '5jjee5qi': {
      'en': '-',
      'de': '-',
      'es': '-',
      'fr': '-',
      'he': '-',
    },
    'cn787aiv': {
      'en': 'Finish Warmup',
      'de': 'Aufwärmen beenden',
      'es': 'Finalizar el calentamiento',
      'fr': 'Fin de l\'échauffement',
      'he': 'סיום החימום',
    },
  },
  // warmupBottomShit
  {
    'z195okww': {
      'en': 'Warm-up Generator',
      'de': 'Aufwärmgenerator',
      'es': 'Generador de calentamiento',
      'fr': 'Générateur de préchauffage',
      'he': 'מחולל חימום',
    },
    'f1s21xn3': {
      'en': 'Auto-create warm-up sets that won\'t count toward stats.',
      'de':
          'Automatische Erstellung von Aufwärmsätzen, die nicht in die Statistik einfließen.',
      'es':
          'Crea automáticamente series de calentamiento que no contarán para las estadísticas.',
      'fr':
          'Création automatique de séries d\'échauffement qui ne seront pas prises en compte dans les statistiques.',
      'he': 'צור אוטומטית ערכות חימום שלא ייספרו בסטטיסטיקות.',
    },
    '914pplja': {
      'en': 'Target Weight (kg)',
      'de': 'Zielgewicht (kg)',
      'es': 'Peso objetivo (kg)',
      'fr': 'Poids cible (kg)',
      'he': 'משקל יעד (ק\"ג)',
    },
    'rubwy8mq': {
      'en': 'Number of Warm-up Sets',
      'de': 'Anzahl der Aufwärmsätze',
      'es': 'Número de series de calentamiento',
      'fr': 'Nombre de séries d\'échauffement',
      'he': 'מספר סטים של חימום',
    },
    'ydjwxhqd': {
      'en': 'Generate Warm-ups',
      'de': 'Aufwärmübungen generieren',
      'es': 'Generar ejercicios de calentamiento',
      'fr': 'Générer des échauffements',
      'he': 'יצירת חימום',
    },
  },
  // setOptinBottom
  {
    'dympnzjt': {
      'en': 'Mark as Completed',
      'de': 'Als erledigt markieren',
      'es': 'Marcar como completado',
      'fr': 'Marquer comme terminé',
      'he': 'סמן כ\"הושלם\"',
    },
    '2xp09dpc': {
      'en': 'Enable Dropset',
      'de': 'Dropset aktivieren',
      'es': 'Habilitar Dropset',
      'fr': 'Activer Dropset',
      'he': 'הפעלת Dropset',
    },
    'k1oh44e3': {
      'en': 'Reset Set',
      'de': 'Zurücksetzen',
      'es': 'Restablecer conjunto',
      'fr': 'Réinitialiser le jeu',
      'he': 'איפוס הגדרות',
    },
    '2s5q60x9': {
      'en': 'Delete Set',
      'de': 'Löschen Sie den Satz',
      'es': 'Eliminar conjunto',
      'fr': 'Supprimer l\'ensemble',
      'he': 'מחיקת קבוצה',
    },
  },
  // setAlert2
  {
    'ks1gvb8h': {
      'en': 'Close',
      'de': 'Schließen',
      'es': 'Cerca',
      'fr': 'Fermer',
      'he': 'לִסְגוֹר',
    },
  },
  // rowOffline
  {
    '9ftmeg29': {
      'en': 'Sets',
      'de': 'Sets',
      'es': 'Conjuntos',
      'fr': 'Ensembles',
      'he': 'סטים',
    },
    'kp3q0g57': {
      'en': '-',
      'de': '-',
      'es': '-',
      'fr': '-',
      'he': '-',
    },
    'dwno1x40': {
      'en': '%',
      'de': '%',
      'es': '%',
      'fr': '%',
      'he': '%',
    },
    'ojfjmqk7': {
      'en': 'Volume',
      'de': 'Volumen',
      'es': 'Volumen',
      'fr': 'Volume',
      'he': 'כֶּרֶך',
    },
    'nn0xmhvt': {
      'en': '-',
      'de': '-',
      'es': '-',
      'fr': '-',
      'he': '-',
    },
    'p3wq9jo6': {
      'en': 'Reps',
      'de': 'Reps',
      'es': 'Representantes',
      'fr': 'Réputation',
      'he': 'נציגים',
    },
    'qca2xxbu': {
      'en': '-',
      'de': '-',
      'es': '-',
      'fr': '-',
      'he': '-',
    },
    'ps3ilv9l': {
      'en': '%',
      'de': '%',
      'es': '%',
      'fr': '%',
      'he': '%',
    },
    '2o0onau1': {
      'en': '-',
      'de': '-',
      'es': '-',
      'fr': '-',
      'he': '-',
    },
    'whzet04x': {
      'en': '%',
      'de': '%',
      'es': '%',
      'fr': '%',
      'he': '%',
    },
  },
  // discardWorkout
  {
    'xfu8z0q6': {
      'en': 'Discard Workout',
      'de': 'Trainingseinheit verwerfen',
      'es': 'Descartar entrenamiento',
      'fr': 'Rejeter l\'entraînement',
      'he': 'מחק את האימון',
    },
    'zjnkx20k': {
      'en':
          'If you stop now, all progress from this workout will be discarded and not saved.',
      'de':
          'Wenn Sie jetzt aufhören, gehen alle Fortschritte dieses Trainings verloren und werden nicht gespeichert.',
      'es':
          'Si te detienes ahora, todo el progreso de este entrenamiento se descartará y no se guardará.',
      'fr':
          'Si vous vous arrêtez maintenant, toute votre progression durant cette séance d\'entraînement sera perdue et ne sera pas enregistrée.',
      'he': 'אם תעצור עכשיו, כל ההתקדמות מאימון זה תימחק ולא תישמר.',
    },
    'wjqy3mhv': {
      'en': 'Cancel',
      'de': 'Stornieren',
      'es': 'Cancelar',
      'fr': 'Annuler',
      'he': 'לְבַטֵל',
    },
    'tv7v5c6q': {
      'en': 'Discard',
      'de': 'Verwerfen',
      'es': 'Desechar',
      'fr': 'Jeter',
      'he': 'לְהַשְׁלִיך',
    },
  },
  // editDelte2
  {
    '5v3p908u': {
      'en': 'Edit',
      'de': 'Bearbeiten',
      'es': 'Editar',
      'fr': 'Modifier',
      'he': 'לַעֲרוֹך',
    },
    'lt4dw8gk': {
      'en': 'Delete',
      'de': 'Löschen',
      'es': 'Borrar',
      'fr': 'Supprimer',
      'he': 'לִמְחוֹק',
    },
  },
  // deleteWorkoutLog
  {
    'ormpbssd': {
      'en': 'Delete Workout',
      'de': 'Training löschen',
      'es': 'Eliminar entrenamiento',
      'fr': 'Supprimer l\'entraînement',
      'he': 'מחק אימון',
    },
    'm7wx35rg': {
      'en':
          'This will permanently delete this workout and all of its sets from your history, stats, and charts. This action can’t be undone.',
      'de':
          'Dadurch werden dieses Training und alle zugehörigen Sätze dauerhaft aus deinem Verlauf, deinen Statistiken und Diagrammen gelöscht. Diese Aktion kann nicht rückgängig gemacht werden.',
      'es':
          'Esto eliminará permanentemente este entrenamiento y todas sus series de tu historial, estadísticas y gráficos. Esta acción no se puede deshacer.',
      'fr':
          'Cette action supprimera définitivement cet entraînement et toutes ses séries de votre historique, de vos statistiques et de vos graphiques. Cette action est irréversible.',
      'he':
          'פעולה זו תמחק לצמיתות את האימון הזה ואת כל הסטים שלו מההיסטוריה, הסטטיסטיקות והגרפים שלך. לא ניתן לבטל פעולה זו.',
    },
    'z7kuan1q': {
      'en': 'Cancel',
      'de': 'Stornieren',
      'es': 'Cancelar',
      'fr': 'Annuler',
      'he': 'לְבַטֵל',
    },
    'xx67eva2': {
      'en': 'Delete',
      'de': 'Löschen',
      'es': 'Borrar',
      'fr': 'Supprimer',
      'he': 'לִמְחוֹק',
    },
  },
  // restShit
  {
    'tdmj1qot': {
      'en': 'Set Rest Time',
      'de': 'Ruhezeit festlegen',
      'es': 'Establecer tiempo de descanso',
      'fr': 'Définir le temps de repos',
      'he': 'הגדר זמן מנוחה',
    },
    '23soye9h': {
      'en': 'Set',
      'de': 'Satz',
      'es': 'Colocar',
      'fr': 'Ensemble',
      'he': 'מַעֲרֶכֶת',
    },
  },
  // exerciseComponeForEdit
  {
    'll11uggv': {
      'en': 'Superset',
      'de': 'Superset',
      'es': 'Superconjunto',
      'fr': 'Surensemble',
      'he': 'סופרסט',
    },
    '6i971pli': {
      'en': 'Previous',
      'de': 'Vorherige',
      'es': 'Anterior',
      'fr': 'Précédent',
      'he': 'קוֹדֵם',
    },
    'et510nqa': {
      'en': 'Time',
      'de': 'Zeit',
      'es': 'Tiempo',
      'fr': 'Temps',
      'he': 'זְמַן',
    },
    'kelb741f': {
      'en': 'Reps',
      'de': 'Reps',
      'es': 'Representantes',
      'fr': 'Réputation',
      'he': 'נציגים',
    },
    'uu87sx0m': {
      'en': 'Add set',
      'de': 'Set hinzufügen',
      'es': 'Agregar conjunto',
      'fr': 'Ajouter un ensemble',
      'he': 'הוסף סט',
    },
  },
  // workoutChangeCupertino
  {
    'g4bug6y8': {
      'en': 'Set',
      'de': 'Satz',
      'es': 'Colocar',
      'fr': 'Ensemble',
      'he': 'מַעֲרֶכֶת',
    },
  },
  // exerciseOptionsBottomShit
  {
    '3ie1fqhe': {
      'en': 'Replace Exercise',
      'de': 'Übung ersetzen',
      'es': 'Reemplazar ejercicio',
      'fr': 'Remplacer l\'exercice',
      'he': 'החלפת פעילות גופנית',
    },
    'ey92c3q1': {
      'en': 'Superset',
      'de': 'Superset',
      'es': 'Superconjunto',
      'fr': 'Surensemble',
      'he': 'סופרסט',
    },
    'f77ruy09': {
      'en': 'Cancel Superset',
      'de': 'Superset abbrechen',
      'es': 'Cancelar Superset',
      'fr': 'Annuler le surensemble',
      'he': 'ביטול סופרסט',
    },
    '9gobu7gn': {
      'en': ' View History',
      'de': 'Verlauf anzeigen',
      'es': 'Ver historial',
      'fr': 'Consulter l\'historique',
      'he': 'הצג היסטוריה',
    },
    'vd5qahaf': {
      'en': 'Smart Warm-up',
      'de': 'Intelligentes Aufwärmen',
      'es': 'Calentamiento inteligente',
      'fr': 'Échauffement intelligent',
      'he': 'חימום חכם',
    },
    '1n7nppmg': {
      'en': ' Warm-up',
      'de': 'Sich warm laufen',
      'es': 'Calentamiento',
      'fr': 'Réchauffer',
      'he': 'חימום',
    },
    'a7m3slr9': {
      'en': 'Reorder',
      'de': 'Neu bestellen',
      'es': 'Reordenar',
      'fr': 'Réorganiser',
      'he': 'סדר מחדש',
    },
    '1124vy71': {
      'en': 'Remove Exercise',
      'de': 'Übung entfernen',
      'es': 'Eliminar ejercicio',
      'fr': 'Supprimer l\'exercice',
      'he': 'הסר תרגיל',
    },
  },
  // removeExerciseFromWorkoutAlert
  {
    '65dazilr': {
      'en': 'Remove Exercise?',
      'de': 'Sport entfernen?',
      'es': '¿Eliminar el ejercicio?',
      'fr': 'Supprimer l\'exercice ?',
      'he': 'להסיר פעילות גופנית?',
    },
    'ui9crfuv': {
      'en': 'This will delete the exercise and all its sets from this workout.',
      'de':
          'Dadurch werden die Übung und alle zugehörigen Sätze aus diesem Workout gelöscht.',
      'es':
          'Esto eliminará el ejercicio y todas sus series de este entrenamiento.',
      'fr':
          'Cette action supprimera l\'exercice et toutes ses séries de cette séance d\'entraînement.',
      'he': 'פעולה זו תמחק את התרגיל וכל הסטים שלו מאימון זה.',
    },
    't9ktsldg': {
      'en': 'Cancel',
      'de': 'Stornieren',
      'es': 'Cancelar',
      'fr': 'Annuler',
      'he': 'לְבַטֵל',
    },
    'p7i92tri': {
      'en': 'Remove',
      'de': 'Entfernen',
      'es': 'Eliminar',
      'fr': 'Retirer',
      'he': 'לְהַסִיר',
    },
  },
  // discardAndStartNew
  {
    'vommgtbi': {
      'en': 'Start New Workout?',
      'de': 'Neues Workout starten?',
      'es': '¿Comenzar un nuevo entrenamiento?',
      'fr': 'Commencer un nouvel entraînement ?',
      'he': 'להתחיל אימון חדש?',
    },
    '2htduqvc': {
      'en':
          'Active workout in progress. Starting a new one will discard the current session and it won’t be saved.',
      'de':
          'Das Training ist bereits aktiv. Wenn Sie ein neues Training starten, wird die aktuelle Sitzung verworfen und nicht gespeichert.',
      'es':
          'Entrenamiento activo en curso. Si inicias uno nuevo, se descartará la sesión actual y no se guardará.',
      'fr':
          'Séance d\'entraînement en cours. En démarrer une nouvelle, la session actuelle sera annulée et ne sera pas enregistrée.',
      'he':
          'אימון פעיל מתבצע. התחלת אימון חדש תגרום למחיקת האימון הנוכחי והוא לא יישמר.',
    },
    'v9pgpx3n': {
      'en': 'Cancel',
      'de': 'Stornieren',
      'es': 'Cancelar',
      'fr': 'Annuler',
      'he': 'לְבַטֵל',
    },
    'lmrbxvgx': {
      'en': 'Discard',
      'de': 'Verwerfen',
      'es': 'Desechar',
      'fr': 'Jeter',
      'he': 'לְהַשְׁלִיך',
    },
  },
  // exerciseComponetForCreation
  {
    '9ymmex12': {
      'en': 'Superset',
      'de': 'Superset',
      'es': 'Superconjunto',
      'fr': 'Surensemble',
      'he': 'סופרסט',
    },
    'wmvw3w87': {
      'en': 'Previous',
      'de': 'Vorherige',
      'es': 'Anterior',
      'fr': 'Précédent',
      'he': 'קוֹדֵם',
    },
    'hlnkd0uc': {
      'en': 'Time',
      'de': 'Zeit',
      'es': 'Tiempo',
      'fr': 'Temps',
      'he': 'זְמַן',
    },
    '5cwnstxr': {
      'en': 'Reps',
      'de': 'Reps',
      'es': 'Representantes',
      'fr': 'Réputation',
      'he': 'נציגים',
    },
    'z2ocx9em': {
      'en': 'Add set',
      'de': 'Set hinzufügen',
      'es': 'Agregar conjunto',
      'fr': 'Ajouter un ensemble',
      'he': 'הוסף סט',
    },
  },
  // setRow2ForCreation
  {
    'dzdq7d11': {
      'en': '-',
      'de': '-',
      'es': '-',
      'fr': '-',
      'he': '-',
    },
  },
  // placeHolder
  {
    'ycy5ldvf': {
      'en': 'Get started by adding exercises to your workout',
      'de': 'Beginnen Sie, indem Sie Übungen in Ihr Training einbauen.',
      'es': 'Empieza por añadir ejercicios a tu entrenamiento.',
      'fr': 'Commencez par ajouter des exercices à votre entraînement.',
      'he': 'התחל על ידי הוספת תרגילים לאימון שלך',
    },
  },
  // dropSetRowCreation
  {
    'owelj4tf': {
      'en': '',
      'de': '',
      'es': '',
      'fr': '',
      'he': '',
    },
    'wgcnqfa1': {
      'en': '0',
      'de': '0',
      'es': '0',
      'fr': '0',
      'he': '0',
    },
    'fbjldyne': {
      'en': '-',
      'de': '-',
      'es': '-',
      'fr': '-',
      'he': '-',
    },
  },
  // dropSetCreation
  {
    '7tx24w02': {
      'en': 'Drop',
      'de': 'Fallen',
      'es': 'Gota',
      'fr': 'Baisse',
      'he': 'יְרִידָה',
    },
  },
  // muscleGroupDropdown
  {
    'zd5ezlwq': {
      'en': 'Choose Muscle group',
      'de': 'Muskelgruppe auswählen',
      'es': 'Seleccione el grupo muscular',
      'fr': 'Choisissez le groupe musculaire',
      'he': 'בחירת קבוצת שרירים',
    },
    '14ags065': {
      'en': 'Search Muscle',
      'de': 'Suche Muskeln',
      'es': 'Buscar músculo',
      'fr': 'Rechercher Muscle',
      'he': 'חיפוש שרירים',
    },
    '8ohkudg0': {
      'en': 'Chest',
      'de': 'Brust',
      'es': 'Pecho',
      'fr': 'Poitrine',
      'he': 'חָזֶה',
    },
    'eep2ajjb': {
      'en': 'Back',
      'de': 'Zurück',
      'es': 'Atrás',
      'fr': 'Dos',
      'he': 'בְּחֲזָרָה',
    },
    'pil4ybsd': {
      'en': 'Shoulders',
      'de': 'Schultern',
      'es': 'Espalda',
      'fr': 'Épaules',
      'he': 'כתפיים',
    },
    'a7ytysem': {
      'en': 'Biceps',
      'de': 'Bizeps',
      'es': 'Bíceps',
      'fr': 'Biceps',
      'he': 'שְׁרִיר הַזְרוֹעַ',
    },
    'uvit2zxh': {
      'en': 'Triceps',
      'de': 'Trizeps',
      'es': 'Tríceps',
      'fr': 'Triceps',
      'he': 'שרירי התלת ראשי',
    },
    '1k0v70ww': {
      'en': 'Legs',
      'de': 'Beine',
      'es': 'Piernas',
      'fr': 'Jambes',
      'he': 'רגליים',
    },
    'r2nxw4nx': {
      'en': 'Core',
      'de': 'Kern',
      'es': 'Centro',
      'fr': 'Cœur',
      'he': 'ליבה',
    },
    'nh9nsrm4': {
      'en': 'Neck',
      'de': 'Nacken',
      'es': 'Cuello',
      'fr': 'Cou',
      'he': 'עוֹרֶף',
    },
    'gmnhasd6': {
      'en': 'Forearms',
      'de': 'Unterarme',
      'es': 'Antebrazos',
      'fr': 'Avant-bras',
      'he': 'אמות הידיים',
    },
  },
  // muscleGroupDropdownn
  {
    'adfa1kd3': {
      'en': 'Choose Muscle group',
      'de': 'Muskelgruppe auswählen',
      'es': 'Seleccione el grupo muscular',
      'fr': 'Choisissez le groupe musculaire',
      'he': 'בחירת קבוצת שרירים',
    },
    'iu3ushok': {
      'en': 'Search Muscle',
      'de': 'Suche Muskeln',
      'es': 'Buscar músculo',
      'fr': 'Rechercher Muscle',
      'he': 'חיפוש שרירים',
    },
    'bwz97t4x': {
      'en': 'All',
      'de': 'Alle',
      'es': 'Todo',
      'fr': 'Tous',
      'he': 'כֹּל',
    },
    'ryjw4m95': {
      'en': 'Chest',
      'de': 'Brust',
      'es': 'Pecho',
      'fr': 'Poitrine',
      'he': 'חָזֶה',
    },
    'tmvg1man': {
      'en': 'Back',
      'de': 'Zurück',
      'es': 'Atrás',
      'fr': 'Dos',
      'he': 'בְּחֲזָרָה',
    },
    '6rioitg0': {
      'en': 'Shoulders',
      'de': 'Schultern',
      'es': 'Espalda',
      'fr': 'Épaules',
      'he': 'כתפיים',
    },
    'vw86eez1': {
      'en': 'Biceps',
      'de': 'Bizeps',
      'es': 'Bíceps',
      'fr': 'Biceps',
      'he': 'שְׁרִיר הַזְרוֹעַ',
    },
    'ubyy20rb': {
      'en': 'Triceps',
      'de': 'Trizeps',
      'es': 'Tríceps',
      'fr': 'Triceps',
      'he': 'שרירי התלת ראשי',
    },
    'dywaendr': {
      'en': 'Legs',
      'de': 'Beine',
      'es': 'Piernas',
      'fr': 'Jambes',
      'he': 'רגליים',
    },
    'xpjmrh9d': {
      'en': 'Core',
      'de': 'Kern',
      'es': 'Centro',
      'fr': 'Cœur',
      'he': 'ליבה',
    },
    'iv1a8kse': {
      'en': 'Neck',
      'de': 'Nacken',
      'es': 'Cuello',
      'fr': 'Cou',
      'he': 'עוֹרֶף',
    },
    'y9186qxd': {
      'en': 'forearms',
      'de': 'Unterarme',
      'es': 'antebrazos',
      'fr': 'avant-bras',
      'he': 'אמות',
    },
  },
  // subMuscleBottomShit
  {
    'ah1oqfbm': {
      'en': 'Choose Muscle group',
      'de': 'Muskelgruppe auswählen',
      'es': 'Seleccione el grupo muscular',
      'fr': 'Choisissez le groupe musculaire',
      'he': 'בחירת קבוצת שרירים',
    },
    'wleqw6qg': {
      'en': 'Search Muscle',
      'de': 'Suche Muskeln',
      'es': 'Buscar músculo',
      'fr': 'Rechercher Muscle',
      'he': 'חיפוש שרירים',
    },
  },
  // exercyseTypeBottom
  {
    'c6nq8pf3': {
      'en': 'Choose Measure Type',
      'de': 'Messart auswählen',
      'es': 'Seleccione el tipo de medida',
      'fr': 'Choisir le type de mesure',
      'he': 'בחר סוג מידה',
    },
    '76fu63t8': {
      'en': 'Weight & Reps',
      'de': 'Gewicht & Wiederholungen',
      'es': 'Peso y repeticiones',
      'fr': 'Poids et répétitions',
      'he': 'משקל וחזרות',
    },
    'u9jey59p': {
      'en': 'Example: Barbell Row, Dumbbell Press',
      'de': 'Beispiel: Langhantelrudern, Kurzhanteldrücken',
      'es': 'Ejemplo: Remo con barra, Press con mancuernas',
      'fr': 'Exemple : Rowing à la barre, développé haltères',
      'he': 'דוגמה: חתירה עם מוט, לחיצת משקולות',
    },
    'jp2s7nnh': {
      'en': 'REPS',
      'de': 'REP',
      'es': 'REPRESENTANTES',
      'fr': 'REPS',
      'he': 'נציגי כנסים',
    },
    '6f8jbcft': {
      'en': 'KG',
      'de': 'KG',
      'es': 'KG',
      'fr': 'KG',
      'he': 'ק\"ג',
    },
    'tona80u7': {
      'en': 'Bodyweight Reps',
      'de': 'Körpergewichtswiederholungen',
      'es': 'Repeticiones con peso corporal',
      'fr': 'Répétitions au poids du corps',
      'he': 'חזרות משקל גוף',
    },
    'yic05ndx': {
      'en': 'Example: Push-ups, Inverted Rows',
      'de': 'Beispiel: Liegestütze, umgekehrte Ruderzüge',
      'es': 'Ejemplo: Flexiones, Remo invertido',
      'fr': 'Exemple : Pompes, Tractions inversées',
      'he': 'דוגמה: שכיבות סמיכה, חתירה הפוכות',
    },
    'ykd8l7fm': {
      'en': 'REPS',
      'de': 'REP',
      'es': 'REPRESENTANTES',
      'fr': 'REPS',
      'he': 'נציגי כנסים',
    },
    'gzwswmtr': {
      'en': 'Assisted Bodyweight',
      'de': 'Unterstütztes Körpergewicht',
      'es': 'Peso corporal asistido',
      'fr': 'Poids corporel assisté',
      'he': 'משקל גוף בסיוע',
    },
    '4ifjitvi': {
      'en': 'Example: Assisted Pull-ups',
      'de': 'Beispiel: Unterstützte Klimmzüge',
      'es': 'Ejemplo: Dominadas asistidas',
      'fr': 'Exemple : Tractions assistées',
      'he': 'דוגמה: משיכות מתח בסיוע',
    },
    'a60bquvo': {
      'en': 'REPS',
      'de': 'REP',
      'es': 'REPRESENTANTES',
      'fr': 'REPS',
      'he': 'נציגי כנסים',
    },
    '2ybn8w6t': {
      'en': '-KG',
      'de': '-KG',
      'es': '-KG',
      'fr': '-KG',
      'he': '-KG',
    },
    'dtoqe37n': {
      'en': 'Duration (Time-based)',
      'de': 'Dauer (zeitbasiert)',
      'es': 'Duración (basada en el tiempo)',
      'fr': 'Durée (basée sur le temps)',
      'he': 'משך (מבוסס זמן)',
    },
    'eol2xyvf': {
      'en': 'Example:  Plank, Wall Hold',
      'de': 'Beispiel: Brett, Wandgriff',
      'es': 'Ejemplo: Tabla, agarre de pared',
      'fr': 'Exemple : Planche, prise murale',
      'he': 'דוגמה: קרש, אחיזה על קיר',
    },
    'jdqgvvat': {
      'en': 'TIME',
      'de': 'ZEIT',
      'es': 'TIEMPO',
      'fr': 'TEMPS',
      'he': 'זְמַן',
    },
  },
  // bwScore
  {
    'yk5ya3cg': {
      'en': 'Bodyweight Performance',
      'de': 'Körpergewichtsleistung',
      'es': 'Rendimiento con peso corporal',
      'fr': 'Performance au poids du corps',
      'he': 'ביצועי משקל גוף',
    },
    'q9zb1iao': {
      'en': '8 / 10',
      'de': '8/10',
      'es': '8/10',
      'fr': '8/10',
      'he': '8 / 10',
    },
    'vjngk12a': {
      'en':
          'Estimated score based on bodyweight, age, sex, and best set performance',
      'de':
          'Geschätzte Punktzahl basierend auf Körpergewicht, Alter, Geschlecht und bester Satzleistung',
      'es':
          'Puntuación estimada basada en el peso corporal, la edad, el sexo y el mejor rendimiento en la serie.',
      'fr':
          'Score estimé en fonction du poids corporel, de l\'âge, du sexe et de la meilleure performance.',
      'he': 'ציון משוער המבוסס על משקל גוף, גיל, מין וביצועים מיטביים בסט',
    },
    'jmp1oid2': {
      'en': '',
      'de': '',
      'es': '',
      'fr': '',
      'he': '',
    },
  },
  // TimedExercisePicker
  {
    '2xc7yiix': {
      'en': 'Set Duration',
      'de': 'Dauer festlegen',
      'es': 'Duración establecida',
      'fr': 'Durée définie',
      'he': 'הגדר משך זמן',
    },
    'onfz9b2b': {
      'en': 'Set',
      'de': 'Satz',
      'es': 'Colocar',
      'fr': 'Ensemble',
      'he': 'מַעֲרֶכֶת',
    },
  },
  // manualForCreation
  {
    '5c4jdtk1': {
      'en': 'Countdown',
      'de': 'Countdown',
      'es': 'Cuenta atrás',
      'fr': 'Compte à rebours',
      'he': 'סְפִירָה לְאָחוֹר',
    },
    'hmvt1nie': {
      'en': 'Manual Entry',
      'de': 'Manuelle Eingabe',
      'es': 'Entrada manual',
      'fr': 'Saisie manuelle',
      'he': 'הזנה ידנית',
    },
  },
  // exerciseOptionsBottomCreation
  {
    'pfh7j0ot': {
      'en': 'Replace Exercise',
      'de': 'Übung ersetzen',
      'es': 'Reemplazar ejercicio',
      'fr': 'Remplacer l\'exercice',
      'he': 'החלפת פעילות גופנית',
    },
    'zs7xb7je': {
      'en': 'Superset',
      'de': 'Superset',
      'es': 'Superconjunto',
      'fr': 'Surensemble',
      'he': 'סופרסט',
    },
    '08uyqg3l': {
      'en': 'Cancel Superset',
      'de': 'Superset abbrechen',
      'es': 'Cancelar Superset',
      'fr': 'Annuler le surensemble',
      'he': 'ביטול סופרסט',
    },
    'pyeet36s': {
      'en': ' View History',
      'de': 'Verlauf anzeigen',
      'es': 'Ver historial',
      'fr': 'Consulter l\'historique',
      'he': 'הצג היסטוריה',
    },
    'cn3rhfc4': {
      'en': 'Smart Warm-up',
      'de': 'Intelligentes Aufwärmen',
      'es': 'Calentamiento inteligente',
      'fr': 'Échauffement intelligent',
      'he': 'חימום חכם',
    },
    '4m774k9n': {
      'en': 'Reorder',
      'de': 'Neu bestellen',
      'es': 'Reordenar',
      'fr': 'Réorganiser',
      'he': 'סדר מחדש',
    },
    'xap4qpe9': {
      'en': 'Remove Exercise',
      'de': 'Übung entfernen',
      'es': 'Eliminar ejercicio',
      'fr': 'Supprimer l\'exercice',
      'he': 'הסר תרגיל',
    },
  },
  // setOptinBottomCreation
  {
    'xe8b8nso': {
      'en': 'Enable Dropset',
      'de': 'Dropset aktivieren',
      'es': 'Habilitar Dropset',
      'fr': 'Activer Dropset',
      'he': 'הפעלת Dropset',
    },
    'ilh4iuye': {
      'en': 'Reset Set',
      'de': 'Zurücksetzen',
      'es': 'Restablecer conjunto',
      'fr': 'Réinitialiser le jeu',
      'he': 'איפוס הגדרות',
    },
    'sz1mii4e': {
      'en': 'Delete Set',
      'de': 'Löschen Sie den Satz',
      'es': 'Eliminar conjunto',
      'fr': 'Supprimer l\'ensemble',
      'he': 'מחיקת קבוצה',
    },
  },
  // restShitCreation
  {
    'oylwv1ht': {
      'en': 'Set Rest Time',
      'de': 'Ruhezeit festlegen',
      'es': 'Establecer tiempo de descanso',
      'fr': 'Définir le temps de repos',
      'he': 'הגדר זמן מנוחה',
    },
    '9ub6x1jq': {
      'en': 'Set',
      'de': 'Satz',
      'es': 'Colocar',
      'fr': 'Ensemble',
      'he': 'מַעֲרֶכֶת',
    },
  },
  // exerciseOptionsBottomEdit
  {
    '8geuog8j': {
      'en': 'Replace Exercise',
      'de': 'Übung ersetzen',
      'es': 'Reemplazar ejercicio',
      'fr': 'Remplacer l\'exercice',
      'he': 'החלפת פעילות גופנית',
    },
    'jwcmvr9b': {
      'en': 'Superset',
      'de': 'Superset',
      'es': 'Superconjunto',
      'fr': 'Surensemble',
      'he': 'סופרסט',
    },
    'q24v9kyr': {
      'en': ' View History',
      'de': 'Verlauf anzeigen',
      'es': 'Ver historial',
      'fr': 'Consulter l\'historique',
      'he': 'הצג היסטוריה',
    },
    'qqj0lsek': {
      'en': 'Reorder',
      'de': 'Neu bestellen',
      'es': 'Reordenar',
      'fr': 'Réorganiser',
      'he': 'סדר מחדש',
    },
    'iw69eigi': {
      'en': 'Remove Exercise',
      'de': 'Übung entfernen',
      'es': 'Eliminar ejercicio',
      'fr': 'Supprimer l\'exercice',
      'he': 'הסר תרגיל',
    },
  },
  // setOptinBottomEdit
  {
    'ynkepd29': {
      'en': 'Mark as Completed',
      'de': 'Als erledigt markieren',
      'es': 'Marcar como completado',
      'fr': 'Marquer comme terminé',
      'he': 'סמן כ\"הושלם\"',
    },
    'gxf13dst': {
      'en': 'Enable Dropset',
      'de': 'Dropset aktivieren',
      'es': 'Habilitar Dropset',
      'fr': 'Activer Dropset',
      'he': 'הפעלת Dropset',
    },
    'qbwttnya': {
      'en': 'Reset Set',
      'de': 'Zurücksetzen',
      'es': 'Restablecer conjunto',
      'fr': 'Réinitialiser le jeu',
      'he': 'איפוס הגדרות',
    },
    'e9kwja1i': {
      'en': 'Delete Set',
      'de': 'Löschen Sie den Satz',
      'es': 'Eliminar conjunto',
      'fr': 'Supprimer l\'ensemble',
      'he': 'מחיקת קבוצה',
    },
  },
  // subMusclesFullCheckbox
  {
    'xa8cacxz': {
      'en': 'Choose Secondary Muscles',
      'de': 'Sekundäre Muskeln auswählen',
      'es': 'Elige los músculos secundarios',
      'fr': 'Choisir les muscles secondaires',
      'he': 'בחירת שרירים משניים',
    },
    'ds0rlszg': {
      'en': 'Search Muscle',
      'de': 'Suche Muskeln',
      'es': 'Buscar músculo',
      'fr': 'Rechercher Muscle',
      'he': 'חיפוש שרירים',
    },
  },
  // exerciseComponetFornEdit2
  {
    'bgvd82s1': {
      'en': 'Previous',
      'de': 'Vorherige',
      'es': 'Anterior',
      'fr': 'Précédent',
      'he': 'קוֹדֵם',
    },
    '24awmj9f': {
      'en': 'Time',
      'de': 'Zeit',
      'es': 'Tiempo',
      'fr': 'Temps',
      'he': 'זְמַן',
    },
    '4rh2z48v': {
      'en': 'Reps',
      'de': 'Reps',
      'es': 'Representantes',
      'fr': 'Réputation',
      'he': 'נציגים',
    },
    'tcjofx1a': {
      'en': 'Add set',
      'de': 'Set hinzufügen',
      'es': 'Agregar conjunto',
      'fr': 'Ajouter un ensemble',
      'he': 'הוסף סט',
    },
  },
  // TimeBottomShit
  {
    'bq3pk3y7': {
      'en': 'Pause',
      'de': 'Pause',
      'es': 'Pausa',
      'fr': 'Pause',
      'he': 'הַפסָקָה',
    },
    'nszgs0ic': {
      'en': 'Continue',
      'de': 'Weitermachen',
      'es': 'Continuar',
      'fr': 'Continuer',
      'he': 'לְהַמשִׁיך',
    },
    '751ec3mi': {
      'en': '',
      'de': '',
      'es': '',
      'fr': '',
      'he': '',
    },
  },
  // timer3
  {
    'zols1ih5': {
      'en': '-5',
      'de': '-5',
      'es': '-5',
      'fr': '-5',
      'he': '-5',
    },
    '5qwcpps9': {
      'en': '+5',
      'de': '+5',
      'es': '+5',
      'fr': '+5',
      'he': '+5',
    },
    'lmgy1tcs': {
      'en': '',
      'de': '',
      'es': '',
      'fr': '',
      'he': '',
    },
    'e9m3cdeb': {
      'en': 'Pause',
      'de': 'Pause',
      'es': 'Pausa',
      'fr': 'Pause',
      'he': 'הַפסָקָה',
    },
    'h6h23c84': {
      'en': 'Continue',
      'de': 'Weitermachen',
      'es': 'Continuar',
      'fr': 'Continuer',
      'he': 'לְהַמשִׁיך',
    },
  },
  // pieGraphPlaceHolder
  {
    'q9gcnfl6': {
      'en': 'No muscle data yet',
      'de': 'Noch keine Muskeldaten.',
      'es': 'Aún no hay datos musculares.',
      'fr': 'Aucune donnée musculaire pour le moment',
      'he': 'אין עדיין נתוני שרירים',
    },
    'yspdh6mg': {
      'en': 'Train to unlock muscle distribution insights\n',
      'de': 'Trainieren Sie, um Einblicke in die Muskelverteilung zu gewinnen',
      'es':
          'Entrena para descubrir información valiosa sobre la distribución muscular.',
      'fr': 'Entraînez-vous pour décrypter la répartition musculaire',
      'he': 'התאמנו כדי לפתוח תובנות על פיזור שרירים',
    },
  },
  // exerciseHistoryPlaceHolder
  {
    '5m1els28': {
      'en': 'No Sets Logged',
      'de': 'Keine Sätze protokolliert',
      'es': 'No se registraron conjuntos',
      'fr': 'Aucun ensemble enregistré',
      'he': 'אין סטים רשומים',
    },
    '8xyf4f4m': {
      'en': 'Start training to build history for this exercise.',
      'de':
          'Beginnen Sie mit dem Training, um für diese Übung historische Daten zu sammeln.',
      'es': 'Comienza a entrenar para crear un historial para este ejercicio.',
      'fr':
          'Commencez à vous entraîner pour constituer un historique en vue de cet exercice.',
      'he': 'התחל להתאמן כדי לבנות היסטוריה עבור תרגיל זה.',
    },
  },
  // exerciseOptionsBottomWorklogEdit
  {
    '319wktrk': {
      'en': 'Replace Exercise',
      'de': 'Übung ersetzen',
      'es': 'Reemplazar ejercicio',
      'fr': 'Remplacer l\'exercice',
      'he': 'החלפת פעילות גופנית',
    },
    'da4yze35': {
      'en': ' View History',
      'de': 'Verlauf anzeigen',
      'es': 'Ver historial',
      'fr': 'Consulter l\'historique',
      'he': 'הצג היסטוריה',
    },
    'b3e8klu3': {
      'en': 'Reorder',
      'de': 'Neu bestellen',
      'es': 'Reordenar',
      'fr': 'Réorganiser',
      'he': 'סדר מחדש',
    },
    'sj0h47m0': {
      'en': 'Remove Exercise',
      'de': 'Übung entfernen',
      'es': 'Eliminar ejercicio',
      'fr': 'Supprimer l\'exercice',
      'he': 'הסר תרגיל',
    },
  },
  // sexBottomshit
  {
    'ywviqcp9': {
      'en': 'Sex',
      'de': 'Sex',
      'es': 'Sexo',
      'fr': 'Sexe',
      'he': 'מִין',
    },
    'bfgcdmct': {
      'en': 'Male',
      'de': 'Männlich',
      'es': 'Masculino',
      'fr': 'Mâle',
      'he': 'זָכָר',
    },
    'o7kr95wo': {
      'en': 'Female',
      'de': 'Weiblich',
      'es': 'Femenino',
      'fr': 'Femelle',
      'he': 'נְקֵבָה',
    },
    'ilj2iz7k': {
      'en': 'Prefer not to say',
      'de': 'Ich möchte es lieber nicht sagen',
      'es': 'Prefiero no decirlo',
      'fr': 'Je préfère ne pas le dire',
      'he': 'מעדיף לא לומר',
    },
  },
  // birthdayCupertino
  {
    '2ocbjinm': {
      'en': 'Set Birthday',
      'de': 'Geburtstag festlegen',
      'es': 'Establecer cumpleaños',
      'fr': 'Date de naissance',
      'he': 'הגדר יום הולדת',
    },
    'yza23b3j': {
      'en': 'Set',
      'de': 'Satz',
      'es': 'Colocar',
      'fr': 'Ensemble',
      'he': 'מַעֲרֶכֶת',
    },
  },
  // weightCupertino
  {
    'zfexz58p': {
      'en': 'Set Weight',
      'de': 'Einstellgewicht',
      'es': 'Peso del conjunto',
      'fr': 'Poids réglé',
      'he': 'הגדר משקל',
    },
    'smw7i5ce': {
      'en': 'Set',
      'de': 'Satz',
      'es': 'Colocar',
      'fr': 'Ensemble',
      'he': 'מַעֲרֶכֶת',
    },
  },
  // heightCupertino
  {
    'ycmnnsvy': {
      'en': 'Set Height',
      'de': 'Höhe einstellen',
      'es': 'Ajuste de altura',
      'fr': 'Hauteur définie',
      'he': 'הגדר גובה',
    },
    'ggprypj5': {
      'en': 'Set',
      'de': 'Satz',
      'es': 'Colocar',
      'fr': 'Ensemble',
      'he': 'מַעֲרֶכֶת',
    },
  },
  // muscleLineGraphPlc
  {
    '34wwdwhd': {
      'en': 'No muscle volume data',
      'de': 'Keine Daten zum Muskelvolumen',
      'es': 'No hay datos sobre el volumen muscular.',
      'fr': 'Aucune donnée sur le volume musculaire',
      'he': 'אין נתוני נפח שרירים',
    },
    '7jqishjh': {
      'en': 'Log workouts for this muscle to see volume over time.\n',
      'de':
          'Protokolliere die Trainingseinheiten für diesen Muskel, um das Muskelwachstum im Laufe der Zeit zu erfassen.',
      'es':
          'Registra los entrenamientos de este músculo para observar su volumen a lo largo del tiempo.',
      'fr':
          'Consignez vos séances d\'entraînement pour ce muscle afin de suivre l\'évolution du volume au fil du temps.',
      'he': 'רשום אימונים עבור שריר זה כדי לראות את הנפח לאורך זמן.',
    },
  },
  // updateUnits
  {
    '52zgqb2u': {
      'en': 'Update Units',
      'de': 'Einheiten aktualisieren',
      'es': 'Actualizar unidades',
      'fr': 'Mise à jour des unités',
      'he': 'עדכון יחידות',
    },
    'hbz5nb24': {
      'en': 'Workout Weight Unit',
      'de': 'Trainingsgewicht',
      'es': 'Unidad de peso de entrenamiento',
      'fr': 'Unité de poids d\'entraînement',
      'he': 'יחידת משקל לאימון',
    },
    '9q0gx6vt': {
      'en': 'Kg',
      'de': 'kg',
      'es': 'kg',
      'fr': 'kg',
      'he': 'ק\"ג',
    },
    'orrha1ha': {
      'en': 'Lbs',
      'de': 'Pfund',
      'es': 'Libras',
      'fr': 'livres',
      'he': 'ליברות',
    },
    'i7n6pbj9': {
      'en': 'Height Unit',
      'de': 'Höheneinheit',
      'es': 'Unidad de altura',
      'fr': 'Unité de hauteur',
      'he': 'יחידת גובה',
    },
    'sov8d9oy': {
      'en': 'Cm',
      'de': 'Cm',
      'es': 'Centímetro',
      'fr': 'Cm',
      'he': 'ס\"מ',
    },
    '4qudj0hz': {
      'en': 'In',
      'de': 'In',
      'es': 'En',
      'fr': 'Dans',
      'he': 'ב',
    },
    '1bzsfojj': {
      'en': 'Body Weight Unit',
      'de': 'Körpergewichtseinheit',
      'es': 'Unidad de peso corporal',
      'fr': 'Unité de poids corporel',
      'he': 'יחידת משקל גוף',
    },
    '1xus34xa': {
      'en': 'Kg',
      'de': 'kg',
      'es': 'kg',
      'fr': 'kg',
      'he': 'ק\"ג',
    },
    '6091v3z2': {
      'en': 'Lbs',
      'de': 'Pfund',
      'es': 'Libras',
      'fr': 'livres',
      'he': 'ליברות',
    },
  },
  // dropSetRowEdit
  {
    'dbpo0f5d': {
      'en': '',
      'de': '',
      'es': '',
      'fr': '',
      'he': '',
    },
    'zejd8gy3': {
      'en': '0',
      'de': '0',
      'es': '0',
      'fr': '0',
      'he': '0',
    },
    'rc44gepq': {
      'en': '',
      'de': '',
      'es': '',
      'fr': '',
      'he': '',
    },
  },
  // dropSetCreationEdit
  {
    'm6qyuccz': {
      'en': 'Drop',
      'de': 'Fallen',
      'es': 'Gota',
      'fr': 'Baisse',
      'he': 'יְרִידָה',
    },
  },
  // warmupBottomStupid
  {
    'wicgutx3': {
      'en': 'Warm-up Generator',
      'de': 'Aufwärmgenerator',
      'es': 'Generador de calentamiento',
      'fr': 'Générateur de préchauffage',
      'he': 'מחולל חימום',
    },
    '749xfqs1': {
      'en': 'create warm-up sets that won\'t count toward stats.',
      'de': 'Erstelle Aufwärmsätze, die nicht in die Statistik einfließen.',
      'es':
          'Crea series de calentamiento que no contarán para las estadísticas.',
      'fr':
          'Créez des séries d\'échauffement qui ne seront pas comptabilisées dans les statistiques.',
      'he': 'צרו סטים של חימום שלא ייחשבו לסטטיסטיקות.',
    },
    'hi1h3y8i': {
      'en': 'Number of Warm-up Sets',
      'de': 'Anzahl der Aufwärmsätze',
      'es': 'Número de series de calentamiento',
      'fr': 'Nombre de séries d\'échauffement',
      'he': 'מספר סטים של חימום',
    },
    'x84vsz6v': {
      'en': 'Generate Warm-ups',
      'de': 'Aufwärmübungen generieren',
      'es': 'Generar ejercicios de calentamiento',
      'fr': 'Générer des échauffements',
      'he': 'יצירת חימום',
    },
  },
  // timeWarmup
  {
    '1lo0yc93': {
      'en': '0',
      'de': '0',
      'es': '0',
      'fr': '0',
      'he': '0',
    },
    'rq0gl2ar': {
      'en': '0',
      'de': '0',
      'es': '0',
      'fr': '0',
      'he': '0',
    },
    '2a81eiw6': {
      'en': ':',
      'de': ':',
      'es': ':',
      'fr': ':',
      'he': ':',
    },
    'gnwfyj6b': {
      'en': '0',
      'de': '0',
      'es': '0',
      'fr': '0',
      'he': '0',
    },
    'x4m6f9nc': {
      'en': '0',
      'de': '0',
      'es': '0',
      'fr': '0',
      'he': '0',
    },
  },
  // deopSetRowEdit
  {
    'yw0b505z': {
      'en': '',
      'de': '',
      'es': '',
      'fr': '',
      'he': '',
    },
    '6u0mwilc': {
      'en': '',
      'de': '',
      'es': '',
      'fr': '',
      'he': '',
    },
  },
  // workoutForRoutine
  {
    'fz58f7lq': {
      'en': '1x / week',
      'de': '1x/Woche',
      'es': '1 vez por semana',
      'fr': '1 fois par semaine',
      'he': 'פעם אחת בשבוע',
    },
    'v0vij56s': {
      'en': 'Select...',
      'de': 'Wählen...',
      'es': 'Seleccionar...',
      'fr': 'Sélectionner...',
      'he': 'לִבחוֹר...',
    },
    'bj1hmvux': {
      'en': 'Search...',
      'de': 'Suchen...',
      'es': 'Buscar...',
      'fr': 'Recherche...',
      'he': 'לְחַפֵּשׂ...',
    },
    '91fd56md': {
      'en': '1x / week',
      'de': '1x/Woche',
      'es': '1 vez por semana',
      'fr': '1 fois par semaine',
      'he': 'פעם אחת בשבוע',
    },
    'a2c3qhbw': {
      'en': '2x / week',
      'de': '2x pro Woche',
      'es': '2 veces por semana',
      'fr': '2 fois par semaine',
      'he': '2 פעמים בשבוע',
    },
    'pm42urdz': {
      'en': '3x / week',
      'de': '3x pro Woche',
      'es': '3 veces por semana',
      'fr': '3 fois par semaine',
      'he': '3 פעמים בשבוע',
    },
    'gqib0tgv': {
      'en': '4x / week',
      'de': '4x pro Woche',
      'es': '4 veces por semana',
      'fr': '4 fois par semaine',
      'he': '4 פעמים בשבוע',
    },
    'c2qktuwm': {
      'en': '5x / week',
      'de': '5x/Woche',
      'es': '5 veces por semana',
      'fr': '5 fois par semaine',
      'he': '5 פעמים בשבוע',
    },
    'rmylbiog': {
      'en': 'Minimum rest between sessions',
      'de': 'Mindestruhezeit zwischen den Trainingseinheiten',
      'es': 'Descanso mínimo entre sesiones',
      'fr': 'Repos minimum entre les séances',
      'he': 'מנוחה מינימלית בין אימונים',
    },
    'r60t74fk': {
      'en': 'Select...',
      'de': 'Wählen...',
      'es': 'Seleccionar...',
      'fr': 'Sélectionner...',
      'he': 'לִבחוֹר...',
    },
    'mr2jzhfy': {
      'en': 'Search...',
      'de': 'Suchen...',
      'es': 'Buscar...',
      'fr': 'Recherche...',
      'he': 'לְחַפֵּשׂ...',
    },
    'm6yhw1id': {
      'en': '24 hours',
      'de': '24 Stunden',
      'es': '24 horas',
      'fr': '24 heures',
      'he': '24 שעות',
    },
    'upkl14d4': {
      'en': '48 hours',
      'de': '48 Stunden',
      'es': '48 horas',
      'fr': '48 heures',
      'he': '48 שעות',
    },
    'iw9gl7kx': {
      'en': '72 hours',
      'de': '72 Stunden',
      'es': '72 horas',
      'fr': '72 heures',
      'he': '72 שעות',
    },
  },
  // addWorkoutForDayBottom
  {
    'l9xmaqdt': {
      'en': 'Select a workout',
      'de': 'Wähle ein Training aus',
      'es': 'Selecciona un entrenamiento',
      'fr': 'Sélectionnez un entraînement',
      'he': 'בחר אימון',
    },
    '7464i85u': {
      'en': 'Choose one workout to assign to this day',
      'de': 'Wähle ein Training aus, das du diesem Tag zuweisen möchtest.',
      'es': 'Elige un entrenamiento para asignar a este día.',
      'fr': 'Choisissez un entraînement à programmer pour aujourd\'hui.',
      'he': 'בחרו אימון אחד להקצאה ליום זה',
    },
    'f4aaktaf': {
      'en': 'Assign',
      'de': 'Zuordnen',
      'es': 'Asignar',
      'fr': 'Attribuer',
      'he': 'לְהַקְצוֹת',
    },
  },
  // ReplaceWorkoutForDayBottom
  {
    '8a4as6fs': {
      'en': 'Select a workout',
      'de': 'Wähle ein Training aus',
      'es': 'Selecciona un entrenamiento',
      'fr': 'Sélectionnez un entraînement',
      'he': 'בחר אימון',
    },
    'hpsmzrzq': {
      'en': 'Choose one workout to replace this day',
      'de': 'Wähle ein Training als Ersatz für diesen Tag.',
      'es': 'Elige un entrenamiento para reemplazar este día.',
      'fr': 'Choisissez un entraînement pour remplacer cette journée.',
      'he': 'בחרו אימון אחד שיחליף את היום הזה',
    },
    'kp4u6rjw': {
      'en': 'Assign',
      'de': 'Zuordnen',
      'es': 'Asignar',
      'fr': 'Attribuer',
      'he': 'לְהַקְצוֹת',
    },
  },
  // timeRangeShit
  {
    'w6m4dcqj': {
      'en': 'Select Time Range',
      'de': 'Zeitraum auswählen',
      'es': 'Seleccione el intervalo de tiempo.',
      'fr': 'Sélectionnez la plage horaire',
      'he': 'בחר טווח זמן',
    },
    '3lxbgng4': {
      'en': 'Last 7 days',
      'de': 'Letzte 7 Tage',
      'es': 'Últimos 7 días',
      'fr': 'Les 7 derniers jours',
      'he': '7 הימים האחרונים',
    },
    '7gn42928': {
      'en': 'Last 30 days',
      'de': 'Letzte 30 Tage',
      'es': 'Últimos 30 días',
      'fr': '30 derniers jours',
      'he': '30 הימים האחרונים',
    },
    '9wh2mlcf': {
      'en': 'Last 90 days',
      'de': 'Letzte 90 Tage',
      'es': 'Últimos 90 días',
      'fr': '90 derniers jours',
      'he': '90 הימים האחרונים',
    },
    'hjnaibzv': {
      'en': 'Last 90 days',
      'de': 'Letzte 90 Tage',
      'es': 'Últimos 90 días',
      'fr': '90 derniers jours',
      'he': '90 הימים האחרונים',
    },
    'xj8wq696': {
      'en': 'All time',
      'de': 'Alle Zeiten',
      'es': 'Todos los tiempos',
      'fr': 'Tout le temps',
      'he': 'כל הזמנים',
    },
    'jih0n23h': {
      'en': 'All time',
      'de': 'Alle Zeiten',
      'es': 'Todos los tiempos',
      'fr': 'Tout le temps',
      'he': 'כל הזמנים',
    },
  },
  // upgradeAlert
  {
    'jxftyfaq': {
      'en': 'Custom exercises are limited',
      'de': 'Individuelle Übungen sind begrenzt',
      'es': 'Los ejercicios personalizados son limitados.',
      'fr': 'Les exercices personnalisés sont limités',
      'he': 'תרגילים מותאמים אישית מוגבלים',
    },
    '1q7dwdh6': {
      'en':
          'Free users can create up to 3 custom exercises.\nUpgrade to Premium to create unlimited exercises and personalize your workouts.',
      'de':
          'Kostenlose Nutzer können bis zu 3 individuelle Übungen erstellen. Mit einem Premium-Upgrade können Sie unbegrenzt viele Übungen erstellen und Ihre Workouts personalisieren.',
      'es':
          'Los usuarios gratuitos pueden crear hasta 3 ejercicios personalizados.\n\nActualízate a Premium para crear ejercicios ilimitados y personalizar tus entrenamientos.',
      'fr':
          'Les utilisateurs de la version gratuite peuvent créer jusqu\'à 3 exercices personnalisés.\n\nPassez à la version Premium pour créer un nombre illimité d\'exercices et personnaliser vos entraînements.',
      'he':
          'משתמשים חינמיים יכולים ליצור עד 3 תרגילים מותאמים אישית. שדרגו לגרסה פרימיום כדי ליצור תרגילים ללא הגבלה ולהתאים אישית את האימונים שלכם.',
    },
    'mrqct4yj': {
      'en': 'Upgrade to Premium',
      'de': 'Upgrade auf Premium',
      'es': 'Actualiza a Premium',
      'fr': 'Passez à la version Premium',
      'he': 'שדרג לפרימיום',
    },
    '2vf63o13': {
      'en': 'Not now',
      'de': 'Nicht jetzt.',
      'es': 'Ahora no',
      'fr': 'Pas maintenant',
      'he': 'לא עכשיו',
    },
  },
  // Delte2
  {
    '2ojjtj9j': {
      'en': 'Delete',
      'de': 'Löschen',
      'es': 'Borrar',
      'fr': 'Supprimer',
      'he': 'לִמְחוֹק',
    },
  },
  // deleteExercise
  {
    'fuhicpez': {
      'en': 'Delete Custom Exercise',
      'de': 'Benutzerdefinierte Übung löschen',
      'es': 'Eliminar ejercicio personalizado',
      'fr': 'Supprimer l\'exercice personnalisé',
      'he': 'מחק תרגיל מותאם אישית',
    },
    'jlfqlcq1': {
      'en':
          'This custom exercise will be removed from your list. Past workouts and stats that used it will stay saved.',
      'de':
          'Diese benutzerdefinierte Übung wird aus Ihrer Liste entfernt. Frühere Trainingseinheiten und Statistiken, die diese Übung verwendet haben, bleiben gespeichert.',
      'es':
          'Este ejercicio personalizado se eliminará de tu lista. Los entrenamientos y estadísticas anteriores que lo utilizaron se conservarán.',
      'fr':
          'Cet exercice personnalisé sera supprimé de votre liste. Les entraînements et statistiques précédents qui l\'utilisaient seront conservés.',
      'he':
          'תרגיל מותאם אישית זה יוסר מהרשימה שלך. אימונים קודמים וסטטיסטיקות שהשתמשו בו יישארו נשמרים.',
    },
    'hd7ahwts': {
      'en': 'Cancel',
      'de': 'Stornieren',
      'es': 'Cancelar',
      'fr': 'Annuler',
      'he': 'לְבַטֵל',
    },
    'vcvh94rz': {
      'en': 'Delete',
      'de': 'Löschen',
      'es': 'Borrar',
      'fr': 'Supprimer',
      'he': 'לִמְחוֹק',
    },
  },
  // analyze2App
  {
    'cuvhfwqw': {
      'en': 'Total Reps',
      'de': 'Gesamtwiederholungen',
      'es': 'Repeticiones totales',
      'fr': 'Nombre total de répétitions',
      'he': 'סך חזרות',
    },
    'aalh08x1': {
      'en': 'Proper Reps',
      'de': 'Richtige Wiederholungen',
      'es': 'Representantes adecuados',
      'fr': 'Répliques correctes',
      'he': 'חזרות נכונות',
    },
    'xhml6uxq': {
      'en': 'Form Tip',
      'de': 'Formtipp',
      'es': 'Consejo de forma',
      'fr': 'Conseil de forme',
      'he': 'טיפ לטופס',
    },
    'nn6qj8v8': {
      'en': 'View Video',
      'de': 'Video ansehen',
      'es': 'Ver vídeo',
      'fr': 'Voir la vidéo',
      'he': 'צפה בסרטון',
    },
    'bp2brhck': {
      'en': 'Feedback',
      'de': 'Rückmeldung',
      'es': 'Comentario',
      'fr': 'Retour',
      'he': 'מָשׁוֹב',
    },
    'lp65zhwj': {
      'en': 'Continue Workout',
      'de': 'Training fortsetzen',
      'es': 'Continuar con el entrenamiento',
      'fr': 'Continuez l\'entraînement',
      'he': 'המשך אימון',
    },
  },
  // analysiAlert
  {
    '2aibzhq7': {
      'en': 'Retry',
      'de': 'Wiederholen',
      'es': 'Rever',
      'fr': 'Réessayer',
      'he': 'נסה שוב',
    },
    'wqdff70u': {
      'en': 'Retake video',
      'de': 'Video neu aufnehmen',
      'es': 'Repetición del vídeo',
      'fr': 'Reprendre la vidéo',
      'he': 'צילום מחדש של הסרטון',
    },
  },
  // deleteAccount
  {
    '0aknee49': {
      'en': 'Delete Account?',
      'de': 'Konto löschen?',
      'es': '¿Eliminar cuenta?',
      'fr': 'Supprimer le compte ?',
      'he': 'למחוק חשבון?',
    },
    'ow3dgd6r': {
      'en':
          'This will permanently delete your account and all your data — workouts, logs, and progress. This action cannot be undone.',
      'de':
          'Dadurch werden Ihr Konto und alle Ihre Daten – Trainingseinheiten, Protokolle und Fortschritte – endgültig gelöscht. Diese Aktion kann nicht rückgängig gemacht werden.',
      'es':
          'Esto eliminará permanentemente tu cuenta y todos tus datos: entrenamientos, registros y progreso. Esta acción es irreversible.',
      'fr':
          'Cette action supprimera définitivement votre compte et toutes vos données (entraînements, journaux et progression). Cette action est irréversible.',
      'he':
          'פעולה זו תמחק לצמיתות את חשבונך ואת כל הנתונים שלך - אימונים, יומנים והתקדמות. פעולה זו אינה ניתנת לביטול.',
    },
    'kkd3q2cz': {
      'en': 'Cancel',
      'de': 'Stornieren',
      'es': 'Cancelar',
      'fr': 'Annuler',
      'he': 'לְבַטֵל',
    },
    '5uk86ssy': {
      'en': 'Delete',
      'de': 'Löschen',
      'es': 'Borrar',
      'fr': 'Supprimer',
      'he': 'לִמְחוֹק',
    },
  },
  // createWorkoutBottom
  {
    'xt416705': {
      'en': 'New Workout',
      'de': 'Neues Workout',
      'es': 'Nuevo entrenamiento',
      'fr': 'Nouvelle séance d\'entraînement',
      'he': 'אימון חדש',
    },
    'ajyzoqnd': {
      'en': 'How do you want to build it?',
      'de': 'Wie soll es gebaut werden?',
      'es': '¿Cómo quieres construirlo?',
      'fr': 'Comment voulez-vous le construire ?',
      'he': 'איך אתה רוצה לבנות את זה?',
    },
    '7naska68': {
      'en': 'Build manually',
      'de': 'Manuelles Erstellen',
      'es': 'Construir manualmente',
      'fr': 'Construire manuellement',
      'he': 'בנה באופן ידני',
    },
    '4cff1cpd': {
      'en': 'Pick your own exercises',
      'de': 'Wähle deine eigenen Übungen',
      'es': 'Elige tus propios ejercicios',
      'fr': 'Choisissez vos propres exercices',
      'he': 'בחרו את התרגילים שלכם',
    },
    'aa6piccz': {
      'en': 'Generate with AI',
      'de': 'Mit KI generieren',
      'es': 'Generar con IA',
      'fr': 'Générer avec l\'IA',
      'he': 'צור עם בינה מלאכותית',
    },
    '5gu3t3uk': {
      'en': 'SMART',
      'de': 'SCHLAU',
      'es': 'ELEGANTE',
      'fr': 'INTELLIGENT',
      'he': 'לִכאוֹב',
    },
    '8hb4tok4': {
      'en': 'A plan built for you',
      'de': 'Ein speziell für Sie erstellter Plan',
      'es': 'Un plan diseñado para ti',
      'fr': 'Un plan conçu pour vous',
      'he': 'תוכנית שנבנתה במיוחד בשבילך',
    },
  },
  // discardUiWorkout
  {
    '975zplta': {
      'en': 'Discard workout?',
      'de': 'Training verwerfen?',
      'es': '¿Descartar el entrenamiento?',
      'fr': 'Jeter l\'entraînement ?',
      'he': 'למחוק את האימון?',
    },
    'emg853rx': {
      'en': 'This workout won\'t be saved. You can always generate a new one.',
      'de':
          'Dieses Training wird nicht gespeichert. Sie können jederzeit ein neues generieren.',
      'es':
          'Este entrenamiento no se guardará. Siempre puedes generar uno nuevo.',
      'fr':
          'Cette séance d\'entraînement ne sera pas enregistrée. Vous pouvez toujours en générer une nouvelle.',
      'he': 'אימון זה לא יישמר. תמיד ניתן ליצור אימון חדש.',
    },
    'gie118kq': {
      'en': 'Cancel',
      'de': 'Stornieren',
      'es': 'Cancelar',
      'fr': 'Annuler',
      'he': 'לְבַטֵל',
    },
    'e57wwhu4': {
      'en': 'Discard',
      'de': 'Verwerfen',
      'es': 'Desechar',
      'fr': 'Jeter',
      'he': 'לְהַשְׁלִיך',
    },
  },
  // discardSetAnalysis
  {
    'rentfs2a': {
      'en': 'Delete analysis?',
      'de': 'Analyse löschen?',
      'es': '¿Eliminar análisis?',
      'fr': 'Supprimer l\'analyse ?',
      'he': 'למחוק את הניתוח?',
    },
    'd21734ve': {
      'en':
          'The analysis and its video will be removed. You\'ll need to record again to re-analyze.',
      'de':
          'Die Analyse und das zugehörige Video werden entfernt. Sie müssen die Aufnahme wiederholen, um die Analyse erneut durchzuführen.',
      'es':
          'El análisis y su vídeo serán eliminados. Tendrás que grabar de nuevo para volver a analizarlo.',
      'fr':
          'L\'analyse et sa vidéo seront supprimées. Vous devrez effectuer un nouvel enregistrement pour réanalyser le sujet.',
      'he': 'הניתוח והסרטון שלו יוסרו. תצטרך להקליט שוב ​​כדי לבצע ניתוח מחדש.',
    },
    'dflw2a2u': {
      'en': 'Cancel',
      'de': 'Stornieren',
      'es': 'Cancelar',
      'fr': 'Annuler',
      'he': 'לְבַטֵל',
    },
    'mgvxa798': {
      'en': 'Discard',
      'de': 'Verwerfen',
      'es': 'Desechar',
      'fr': 'Jeter',
      'he': 'לְהַשְׁלִיך',
    },
  },
  // analyze2AppAfter
  {
    's1sqhrs6': {
      'en': 'Total Reps',
      'de': 'Gesamtwiederholungen',
      'es': 'Repeticiones totales',
      'fr': 'Nombre total de répétitions',
      'he': 'סך חזרות',
    },
    'k5mks4ti': {
      'en': 'Proper Reps',
      'de': 'Richtige Wiederholungen',
      'es': 'Representantes adecuados',
      'fr': 'Répliques correctes',
      'he': 'חזרות נכונות',
    },
    '4h9vuh5a': {
      'en': 'Form Tip',
      'de': 'Formtipp',
      'es': 'Consejo de forma',
      'fr': 'Conseil de forme',
      'he': 'טיפ לטופס',
    },
    'iyh9kiby': {
      'en': 'Feedback',
      'de': 'Rückmeldung',
      'es': 'Comentario',
      'fr': 'Retour',
      'he': 'מָשׁוֹב',
    },
  },
  // FeatureRow
  {
    '574uod45': {
      'en': '—',
      'de': '—',
      'es': '—',
      'fr': '—',
      'he': '—',
    },
  },
  // PriceCard
  {
    '8gj007xu': {
      'en': 'BEST VALUE',
      'de': 'BESTES PREIS-LEISTUNGS-VERHÄLTNIS',
      'es': 'LA MEJOR RELACIÓN CALIDAD-PRECIO',
      'fr': 'MEILLEUR RAPPORT QUALITÉ-PRIX',
      'he': 'התמורה הטובה ביותר',
    },
  },
  // warmupBottomShitCreation
  {
    'nhvhelsu': {
      'en': 'Warm-up Generator',
      'de': 'Aufwärmgenerator',
      'es': 'Generador de calentamiento',
      'fr': 'Générateur de préchauffage',
      'he': 'מחולל חימום',
    },
    'oykv34vp': {
      'en': 'Auto-create warm-up sets that won\'t count toward stats.',
      'de':
          'Automatische Erstellung von Aufwärmsätzen, die nicht in die Statistik einfließen.',
      'es':
          'Crea automáticamente series de calentamiento que no contarán para las estadísticas.',
      'fr':
          'Création automatique de séries d\'échauffement qui ne seront pas prises en compte dans les statistiques.',
      'he': 'צור אוטומטית ערכות חימום שלא ייספרו בסטטיסטיקות.',
    },
    '8l2x1g6t': {
      'en': 'Target Weight (kg)',
      'de': 'Zielgewicht (kg)',
      'es': 'Peso objetivo (kg)',
      'fr': 'Poids cible (kg)',
      'he': 'משקל יעד (ק\"ג)',
    },
    '5kzxkpqt': {
      'en': 'Number of Warm-up Sets',
      'de': 'Anzahl der Aufwärmsätze',
      'es': 'Número de series de calentamiento',
      'fr': 'Nombre de séries d\'échauffement',
      'he': 'מספר סטים של חימום',
    },
    'uv8au2l4': {
      'en': 'Generate Warm-ups',
      'de': 'Aufwärmübungen generieren',
      'es': 'Generar ejercicios de calentamiento',
      'fr': 'Générer des échauffements',
      'he': 'יצירת חימום',
    },
  },
  // CleanMinimalAlert2
  {
    'zjehw6bv': {
      'en': 'Notifications are off',
      'de': 'Benachrichtigungen sind deaktiviert',
      'es': 'Las notificaciones están desactivadas.',
      'fr': 'Les notifications sont désactivées.',
      'he': 'ההתראות כבויות',
    },
    'p1oi08v6': {
      'en': 'Turn on notifications to get an alert when your rest timer ends.',
      'de':
          'Aktivieren Sie die Benachrichtigungen, um eine Warnung zu erhalten, wenn Ihr Ruhetimer abläuft.',
      'es':
          'Activa las notificaciones para recibir una alerta cuando finalice tu temporizador de descanso.',
      'fr':
          'Activez les notifications pour recevoir une alerte lorsque votre minuteur de repos arrive à son terme.',
      'he': 'הפעל התראות כדי לקבל התראה כאשר טיימר המנוחה שלך מסתיים.',
    },
    'dwwarzte': {
      'en': 'Open Settings',
      'de': 'Einstellungen öffnen',
      'es': 'Abrir configuración',
      'fr': 'Ouvrir les paramètres',
      'he': 'פתח את ההגדרות',
    },
    'ap6c6a5o': {
      'en': 'Not now',
      'de': 'Nicht jetzt.',
      'es': 'Ahora no',
      'fr': 'Pas maintenant',
      'he': 'לא עכשיו',
    },
  },
  // setRowWarmUpCreation
  {
    'g57k0wto': {
      'en': '-',
      'de': '-',
      'es': '-',
      'fr': '-',
      'he': '-',
    },
    '4vdz6ylw': {
      'en': '-',
      'de': '-',
      'es': '-',
      'fr': '-',
      'he': '-',
    },
  },
  // muscleGroupDropdown2
  {
    'kflnehx4': {
      'en': 'Choose Muscle group',
      'de': 'Muskelgruppe auswählen',
      'es': 'Seleccione el grupo muscular',
      'fr': 'Choisissez le groupe musculaire',
      'he': 'בחירת קבוצת שרירים',
    },
    'qbhrcraq': {
      'en': 'Search Muscle',
      'de': 'Suche Muskeln',
      'es': 'Buscar músculo',
      'fr': 'Rechercher Muscle',
      'he': 'חיפוש שרירים',
    },
    'gxy68zb3': {
      'en': 'All',
      'de': 'Alle',
      'es': 'Todo',
      'fr': 'Tous',
      'he': 'כֹּל',
    },
    'zs1me8wf': {
      'en': 'Chest',
      'de': 'Brust',
      'es': 'Pecho',
      'fr': 'Poitrine',
      'he': 'חָזֶה',
    },
    '5tihkbf4': {
      'en': 'Back',
      'de': 'Zurück',
      'es': 'Atrás',
      'fr': 'Dos',
      'he': 'בְּחֲזָרָה',
    },
    'u53estgp': {
      'en': 'Shoulders',
      'de': 'Schultern',
      'es': 'Espalda',
      'fr': 'Épaules',
      'he': 'כתפיים',
    },
    'i48hvz7b': {
      'en': 'Biceps',
      'de': 'Bizeps',
      'es': 'Bíceps',
      'fr': 'Biceps',
      'he': 'שְׁרִיר הַזְרוֹעַ',
    },
    'ojtp1m23': {
      'en': 'Triceps',
      'de': 'Trizeps',
      'es': 'Tríceps',
      'fr': 'Triceps',
      'he': 'שרירי התלת ראשי',
    },
    'yi73cv0s': {
      'en': 'Legs',
      'de': 'Beine',
      'es': 'Piernas',
      'fr': 'Jambes',
      'he': 'רגליים',
    },
    'jyuw0wyj': {
      'en': 'Core',
      'de': 'Kern',
      'es': 'Centro',
      'fr': 'Cœur',
      'he': 'ליבה',
    },
    'iaqq5xak': {
      'en': 'Neck',
      'de': 'Nacken',
      'es': 'Cuello',
      'fr': 'Cou',
      'he': 'עוֹרֶף',
    },
    '5ngt1ou1': {
      'en': 'Forearms',
      'de': 'Unterarme',
      'es': 'Antebrazos',
      'fr': 'Avant-bras',
      'he': 'אמות הידיים',
    },
  },
  // BottomSheetNoFreeLeft
  {
    '0m2dr2jq': {
      'en': 'You\'re out of free checks',
      'de': 'Sie haben keine kostenlosen Schecks mehr.',
      'es': 'Ya no te quedan cheques gratis.',
      'fr': 'Vous n\'avez plus de chèques gratuits.',
      'he': 'נגמרו לך הצ\'קים החינמיים',
    },
    '9t3xj4yw': {
      'en':
          'Pro includes unlimited AI form analysis, rep-by-rep breakdowns and progress tracking.',
      'de':
          'Die Pro-Version beinhaltet unbegrenzte KI-gestützte Formanalyse, detaillierte Auswertung jeder einzelnen Wiederholung und Fortschrittsverfolgung.',
      'es':
          'La versión Pro incluye análisis ilimitado de formularios mediante IA, desgloses repetición por repetición y seguimiento del progreso.',
      'fr':
          'La version Pro inclut une analyse illimitée des formulaires par IA, des analyses détaillées répétition par répétition et un suivi des progrès.',
      'he':
          'ה-Pro כולל ניתוח טפסים ללא הגבלה באמצעות בינה מלאכותית, פירוט חזרות אחר חזרות ומעקב אחר התקדמות.',
    },
    'thmovivw': {
      'en': 'Go pro - unlimited checks',
      'de': 'Go Pro – unbegrenzte Schecks',
      'es': 'Hazte Pro: comprobaciones ilimitadas',
      'fr': 'Passez à la version Pro - chèques illimités',
      'he': 'גו פרו - צ\'קים ללא הגבלה',
    },
    'cdm0newf': {
      'en': 'Maybe later',
      'de': 'Vielleicht später',
      'es': 'Quizás más tarde',
      'fr': 'Peut-être plus tard',
      'he': 'אולי מאוחר יותר',
    },
  },
  // discardAndStartNewAnalysis
  {
    '21tcizw9': {
      'en': 'Start New Workout?',
      'de': 'Neues Workout starten?',
      'es': '¿Comenzar un nuevo entrenamiento?',
      'fr': 'Commencer un nouvel entraînement ?',
      'he': 'להתחיל אימון חדש?',
    },
    'go2bivur': {
      'en':
          'Active workout in progress. Starting a new one will discard the current session and it won’t be saved.',
      'de':
          'Das Training ist bereits aktiv. Wenn Sie ein neues Training starten, wird die aktuelle Sitzung verworfen und nicht gespeichert.',
      'es':
          'Entrenamiento activo en curso. Si inicias uno nuevo, se descartará la sesión actual y no se guardará.',
      'fr':
          'Séance d\'entraînement en cours. En démarrer une nouvelle, la session actuelle sera annulée et ne sera pas enregistrée.',
      'he':
          'אימון פעיל מתבצע. התחלת אימון חדש תגרום למחיקת האימון הנוכחי והוא לא יישמר.',
    },
    't0k66yob': {
      'en': 'Cancel',
      'de': 'Stornieren',
      'es': 'Cancelar',
      'fr': 'Annuler',
      'he': 'לְבַטֵל',
    },
    'd3laaf6k': {
      'en': 'Discard',
      'de': 'Verwerfen',
      'es': 'Desechar',
      'fr': 'Jeter',
      'he': 'לְהַשְׁלִיך',
    },
  },
  // timerCountUp
  {
    'g9116w2n': {
      'en': 'Done',
      'de': 'Erledigt',
      'es': 'Hecho',
      'fr': 'Fait',
      'he': 'נַעֲשָׂה',
    },
  },
  // video2Full
  {
    'l1rtvqcg': {
      'en': 'Analyzed Video',
      'de': 'Analysiertes Video',
      'es': 'Vídeo analizado',
      'fr': 'Vidéo analysée',
      'he': 'סרטון מנותח',
    },
    'nvnj0uic': {
      'en': 'Download Original Video',
      'de': 'Originalvideo herunterladen',
      'es': 'Descargar vídeo original',
      'fr': 'Télécharger la vidéo originale',
      'he': 'הורד את הסרטון המקורי',
    },
  },
  // BottomSheetNoFreeTemplates
  {
    'dlf9vuoc': {
      'en': 'Workout slots are full',
      'de': 'Die Trainingsplätze sind ausgebucht',
      'es': 'Los cupos para entrenar están completos.',
      'fr': 'Les créneaux d\'entraînement sont complets.',
      'he': 'משבצות האימונים מלאות',
    },
    'oee4cgby': {
      'en':
          'Free includes 3 saved workouts. Go Pro for unlimited — or free up a slot by deleting one',
      'de':
          'Die kostenlose Version beinhaltet 3 gespeicherte Trainingseinheiten. Mit Pro erhältst du unbegrenzten Zugriff – oder schaffst einen Speicherplatz frei, indem du eine Trainingseinheit löschst.',
      'es':
          'La versión gratuita incluye 3 entrenamientos guardados. Hazte Pro para tener acceso ilimitado, o libera un espacio eliminando uno.',
      'fr':
          'La version gratuite inclut 3 séances d\'entraînement enregistrées. Passez à la version Pro pour un nombre illimité — ou libérez un emplacement en supprimant une séance.',
      'he':
          'חינם כולל 3 אימונים שמורים. התחבר למקצוענים ללא הגבלה - או פנה משבצת על ידי מחיקת אחד',
    },
    'wqrggdhn': {
      'en': 'Go Pro — unlimited workouts',
      'de': 'GoPro – unbegrenzte Workouts',
      'es': 'Go Pro: entrenamientos ilimitados',
      'fr': 'Passez à la version Pro — entraînements illimités',
      'he': 'גו פרו - אימונים ללא הגבלה',
    },
    '7u8hn702': {
      'en': 'Manage my workouts',
      'de': 'Meine Trainingseinheiten verwalten',
      'es': 'Gestionar mis entrenamientos',
      'fr': 'Gérer mes entraînements',
      'he': 'ניהול האימונים שלי',
    },
  },
  // analysisHome
  {
    'fu74461j': {
      'en': 'Quick Form Check',
      'de': 'Schnellformularprüfung',
      'es': 'Verificación rápida de formularios',
      'fr': 'Vérification rapide du formulaire',
      'he': 'בדיקת טופס מהירה',
    },
    'ojaod5ts': {
      'en': 'Record a set, get instant AI feedback',
      'de': 'Nimm ein Set auf und erhalte sofortiges KI-Feedback',
      'es': 'Graba una sesión y obtén retroalimentación instantánea de la IA.',
      'fr':
          'Enregistrez une série de sets et recevez un retour instantané de l\'IA.',
      'he': 'הקלט סט, קבל משוב מיידי מבינה מלאכותית',
    },
  },
  // EmptyState
  {
    'pyh9f1zv': {
      'en': 'No exercises yet',
      'de': 'Noch keine Übungen',
      'es': 'Aún no hay ejercicios.',
      'fr': 'Pas encore d\'exercices',
      'he': 'אין עדיין תרגילים',
    },
    'qbl2v59l': {
      'en': 'Add your first exercise to start building this workout',
      'de':
          'Füge deine erste Übung hinzu, um mit dem Aufbau dieses Workouts zu beginnen.',
      'es':
          'Añade tu primer ejercicio para empezar a construir este entrenamiento.',
      'fr':
          'Ajoutez votre premier exercice pour commencer à construire votre entraînement.',
      'he': 'הוסף את התרגיל הראשון שלך כדי להתחיל לבנות את האימון הזה',
    },
  },
  // thankForPremium
  {
    'abutzm2s': {
      'en': 'Welcome to Premium',
      'de': 'Willkommen bei Premium',
      'es': 'Bienvenido a Premium',
      'fr': 'Bienvenue dans Premium',
      'he': 'ברוכים הבאים לפרימיום',
    },
    'jcju5z7e': {
      'en': 'Thanks for supporting the app. All features are now unlocked.',
      'de':
          'Vielen Dank für Ihre Unterstützung der App. Alle Funktionen sind jetzt freigeschaltet.',
      'es':
          'Gracias por apoyar la aplicación. Todas las funciones ya están desbloqueadas.',
      'fr':
          'Merci pour votre soutien à l\'application. Toutes les fonctionnalités sont désormais débloquées.',
      'he': 'תודה על התמיכה באפליקציה. כל התכונות פתוחות כעת.',
    },
    '3nkgtb18': {
      'en': 'continue',
      'de': 'weitermachen',
      'es': 'continuar',
      'fr': 'continuer',
      'he': 'לְהַמשִׁיך',
    },
  },
  // deleteSetAnalysis
  {
    '6wzs2mf0': {
      'en': 'Delete this analysis?',
      'de': 'Diese Analyse löschen?',
      'es': '¿Eliminar este análisis?',
      'fr': 'Supprimer cette analyse ?',
      'he': 'למחוק את הניתוח הזה?',
    },
    'r8ci5ogt': {
      'en':
          'This permanently removes the form score and feedback for this set. Your set stays in history.',
      'de':
          'Dadurch werden die Formwertung und das Feedback für diesen Satz dauerhaft gelöscht. Ihr Satz bleibt in der Historie gespeichert.',
      'es':
          'Esto elimina permanentemente la puntuación y los comentarios del formulario para este conjunto. Tu conjunto permanece en el historial.',
      'fr':
          'Cette action supprime définitivement la note et les commentaires relatifs à cette série. Votre série reste archivée.',
      'he':
          'פעולה זו מסירה לצמיתות את ציון הטופס והמשוב עבור קבוצה זו. הקבוצה שלך תישאר בהיסטוריה.',
    },
    'qmxyin6k': {
      'en': 'Cancel',
      'de': 'Stornieren',
      'es': 'Cancelar',
      'fr': 'Annuler',
      'he': 'לְבַטֵל',
    },
    'ftweamer': {
      'en': 'Delete',
      'de': 'Löschen',
      'es': 'Borrar',
      'fr': 'Supprimer',
      'he': 'לִמְחוֹק',
    },
  },
  // Miscellaneous
  {
    'puqvmecu': {
      'en': '',
      'de': '',
      'es':
          'Para tomar una foto o grabar un video, esta aplicación requiere permiso para acceder a la cámara.',
      'fr': '',
      'he': '',
    },
    'k7zrocf6': {
      'en': 'g',
      'de': 'G',
      'es': 'gramo',
      'fr': 'g',
      'he': 'ז',
    },
    '7n7jdtmv': {
      'en': '',
      'de': '',
      'es':
          'Para subir datos, esta aplicación necesita permiso para acceder a la biblioteca de fotos.',
      'fr': '',
      'he': '',
    },
    'nevaih88': {
      'en':
          'We use your camera to track your form and count reps during your workout.\n',
      'de':
          'Wir nutzen Ihre Kamera, um Ihre Haltung zu erfassen und die Wiederholungen während Ihres Trainings zu zählen.',
      'es':
          'Utilizamos tu cámara para monitorizar tu postura y contar las repeticiones durante tu entrenamiento.',
      'fr':
          'Nous utilisons votre caméra pour suivre votre posture et compter les répétitions pendant votre entraînement.',
      'he':
          'אנחנו משתמשים במצלמה שלך כדי לעקוב אחר הכושר שלך ולספור חזרות במהלך האימון.',
    },
    'zk63ynvm': {
      'en':
          '\n We use your microphone to capture sound with your workout videos (no talking needed!).',
      'de':
          'Wir verwenden Ihr Mikrofon, um den Ton Ihrer Trainingsvideos aufzunehmen (Sie müssen nicht sprechen!).',
      'es':
          'Utilizamos tu micrófono para capturar el sonido de tus vídeos de entrenamiento (¡no es necesario hablar!).',
      'fr':
          'Nous utilisons votre microphone pour enregistrer le son de vos vidéos d\'entraînement (pas besoin de parler !).',
      'he':
          'אנחנו משתמשים במיקרופון שלך כדי ללכוד קול עם סרטוני האימון שלך (אין צורך לדבר!).',
    },
    '0hnogjqz': {
      'en':
          'we save your workout videos to your device so you can review your progress anytime.',
      'de':
          'Wir speichern Ihre Trainingsvideos auf Ihrem Gerät, damit Sie Ihre Fortschritte jederzeit überprüfen können.',
      'es':
          'Guardamos tus vídeos de entrenamiento en tu dispositivo para que puedas revisar tu progreso en cualquier momento.',
      'fr':
          'Nous enregistrons vos vidéos d\'entraînement sur votre appareil afin que vous puissiez consulter vos progrès à tout moment.',
      'he':
          'אנו שומרים את סרטוני האימון שלך במכשיר שלך כדי שתוכל לעקוב אחר ההתקדמות שלך בכל עת.',
    },
    's9lvuq67': {
      'en': 'We use notifications to remind you when rest ends.\n',
      'de':
          'Wir verwenden Benachrichtigungen, um Sie daran zu erinnern, wenn die Ruhezeit endet.',
      'es':
          'Utilizamos notificaciones para recordarte cuándo termina el descanso.',
      'fr':
          'Nous utilisons des notifications pour vous rappeler la fin de votre pause.',
      'he': 'אנו משתמשים בהתראות כדי להזכיר לך מתי המנוחה מסתיימת.',
    },
    '22fhjbdl': {
      'en': '',
      'de': '',
      'es': '',
      'fr': '',
      'he': '',
    },
    'cj3gzz43': {
      'en': '',
      'de': '',
      'es': '',
      'fr': '',
      'he': '',
    },
    'o8mq5s7w': {
      'en': '',
      'de': '',
      'es': '',
      'fr': '',
      'he': '',
    },
    '2s0bj32k': {
      'en': '',
      'de': '',
      'es': '',
      'fr': '',
      'he': '',
    },
    'irn9cqdg': {
      'en': '',
      'de': '',
      'es': '',
      'fr': '',
      'he': '',
    },
    'gp2d7s7r': {
      'en': '',
      'de': '',
      'es': '',
      'fr': '',
      'he': '',
    },
    '013p3v7t': {
      'en': '',
      'de': '',
      'es': '',
      'fr': '',
      'he': '',
    },
    'utqxzq7r': {
      'en': '',
      'de': '',
      'es': '',
      'fr': '',
      'he': '',
    },
    '5yhw60ve': {
      'en': '',
      'de': '',
      'es': '',
      'fr': '',
      'he': '',
    },
    '9u1m6h3e': {
      'en': '',
      'de': '',
      'es': '',
      'fr': '',
      'he': '',
    },
    '4rw4l8e2': {
      'en': '',
      'de': '',
      'es': '',
      'fr': '',
      'he': '',
    },
    'zmnwi1qp': {
      'en': '',
      'de': '',
      'es': '',
      'fr': '',
      'he': '',
    },
    'sefamf0q': {
      'en': '',
      'de': '',
      'es': '',
      'fr': '',
      'he': '',
    },
    '1zzl8k79': {
      'en': '',
      'de': '',
      'es': '',
      'fr': '',
      'he': '',
    },
    '63r30oav': {
      'en': '',
      'de': '',
      'es': '',
      'fr': '',
      'he': '',
    },
    'ig5egybp': {
      'en': '',
      'de': '',
      'es': '',
      'fr': '',
      'he': '',
    },
    'aqvcnihk': {
      'en': '',
      'de': '',
      'es': '',
      'fr': '',
      'he': '',
    },
    'l0gc5kml': {
      'en': '',
      'de': '',
      'es': '',
      'fr': '',
      'he': '',
    },
    '6xi1ymro': {
      'en': '',
      'de': '',
      'es': '',
      'fr': '',
      'he': '',
    },
    'mojgv1vm': {
      'en': '',
      'de': '',
      'es': '',
      'fr': '',
      'he': '',
    },
    'ms3ynjkj': {
      'en': '',
      'de': '',
      'es': '',
      'fr': '',
      'he': '',
    },
    'l53au2hz': {
      'en': '',
      'de': '',
      'es': '',
      'fr': '',
      'he': '',
    },
    'egl69wtn': {
      'en': '',
      'de': '',
      'es': '',
      'fr': '',
      'he': '',
    },
    'co85of5h': {
      'en': '',
      'de': '',
      'es': '',
      'fr': '',
      'he': '',
    },
    'gmdc9b7n': {
      'en': '',
      'de': '',
      'es': '',
      'fr': '',
      'he': '',
    },
    '1h3phtym': {
      'en': '',
      'de': '',
      'es': '',
      'fr': '',
      'he': '',
    },
  },
].reduce((a, b) => a..addAll(b));
