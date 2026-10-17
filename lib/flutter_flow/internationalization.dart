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

  static List<String> languages() => ['en', 'es'];

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
  }) =>
      [enText, esText][languageIndex] ?? '';

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
  // workoutAfterview
  {
    'qxc0u2pp': {
      'en': 'Compare',
      'es': '',
    },
    '9f7xk3r4': {
      'en': 'Total Sets',
      'es': '',
    },
    '0hwg9p02': {
      'en': 'Exercises',
      'es': '',
    },
    'viwb15rk': {
      'en': 'Duration',
      'es': '',
    },
    'f2h32nb9': {
      'en': 'Volume ',
      'es': '',
    },
    'l329u8ty': {
      'en': 'Muscle Distribution',
      'es': '',
    },
    'ozgko901': {
      'en': 'Close',
      'es': 'Cerca',
    },
    'bt1v06rx': {
      'en': 'Home',
      'es': 'Hogar',
    },
  },
  // exerciseHistory
  {
    'ku6z9m7t': {
      'en': 'Overview',
      'es': 'Descripción general',
    },
    'zvb4qoh3': {
      'en': 'How To Perform',
      'es': 'Cómo realizarlo',
    },
    '27u3wsjl': {
      'en': 'Muscles Worked',
      'es': 'Músculos trabajados',
    },
    '6ofb0o43': {
      'en': 'Primary',
      'es': 'Primario',
    },
    'nvw2uk4d': {
      'en': 'Secondary',
      'es': 'Secundario',
    },
    'o7q6na44': {
      'en': 'Form Tips',
      'es': 'Consejos de formulario',
    },
    'u4s7bsvq': {
      'en': '🏋️',
      'es': '🏋️',
    },
    'h650k2gi': {
      'en': 'History',
      'es': 'Historia',
    },
    'qga1ngcg': {
      'en': 'COMPARED TO PREVIOUS',
      'es': 'COMPARADO CON EL ANTERIOR',
    },
    '4cxxfjxo': {
      'en': 'Analytics',
      'es': 'Analítica',
    },
    'avmae72l': {
      'en': 'Personal Records',
      'es': 'Registros personales',
    },
    'bthuwexp': {
      'en': 'Max Reps',
      'es': 'Máximas repeticiones',
    },
    'h51udxz4': {
      'en': 'Max Weight',
      'es': 'Peso máximo',
    },
    'phz2sduw': {
      'en': 'Max Volume',
      'es': 'Volumen máximo',
    },
    'bjqf2605': {
      'en': 'Personal Records',
      'es': 'Registros personales',
    },
    'kq3nc7bv': {
      'en': 'Max Reps',
      'es': 'Máximas repeticiones',
    },
    'cftge1vd': {
      'en': 'Max Session',
      'es': 'Peso máximo',
    },
    '0coub435': {
      'en': 'Avrage Reps',
      'es': 'Volumen máximo',
    },
    'f2s9p3qk': {
      'en': 'Personal Records',
      'es': 'Registros personales',
    },
    'k29kz8uw': {
      'en': 'Max Session Time',
      'es': 'Máximas repeticiones',
    },
    'lh5csxpm': {
      'en': 'Avrage Duration',
      'es': 'Peso máximo',
    },
    'yeuygv4r': {
      'en': 'Max Duration',
      'es': 'Volumen máximo',
    },
    'jgxbou9q': {
      'en': 'Personal Records',
      'es': 'Registros personales',
    },
    'vrhmm731': {
      'en': 'Max Reps',
      'es': 'Máximas repeticiones',
    },
    't0sky0qb': {
      'en': 'Max Session Reps',
      'es': 'Peso máximo',
    },
    '9qhx4sbo': {
      'en': 'Min Assistance',
      'es': 'Volumen máximo',
    },
    'evcm8m56': {
      'en': 'Exercise Analytics',
      'es': 'Análisis del entrenamiento',
    },
    'xern0erp': {
      'en': 'Track your progress over time',
      'es': 'Realice un seguimiento de su progreso a lo largo del tiempo',
    },
    'cwwga2vf': {
      'en': 'Reps',
      'es': 'Representantes',
    },
    'slnrgrwv': {
      'en': 'Max Weight',
      'es': 'Peso máximo',
    },
    'jeq41t8a': {
      'en': 'Volume',
      'es': 'Volumen',
    },
    'eks7x5yt': {
      'en': 'Reps',
      'es': 'Representantes',
    },
    'gk5s7s0f': {
      'en': 'No analytics yet',
      'es': 'No hay entrenamientos todavía',
    },
    'fo4hu4ko': {
      'en': 'Log a few sessions to see how this exercise progresses over time.',
      'es': 'Tu historial de entrenamiento aparecerá una vez que comiences.',
    },
    'sgxwgzhz': {
      'en': 'Current Week',
      'es': 'Semana actual',
    },
    'oeshhned': {
      'en': 'Best Session',
      'es': 'Mejor sesión',
    },
    'tyw7dth7': {
      'en': 'Improvement',
      'es': 'Mejora',
    },
    '2ok2d6bb': {
      'en': 'Exercise Analytics',
      'es': 'Análisis del entrenamiento',
    },
    'hgboufyn': {
      'en': 'Track your progress over time',
      'es': 'Realice un seguimiento de su progreso a lo largo del tiempo',
    },
    'h8gou1y0': {
      'en': 'No analytics yet',
      'es': 'No hay entrenamientos todavía',
    },
    'lwq4ljxq': {
      'en': 'Log a few sessions to see how this exercise progresses over time.',
      'es': 'Tu historial de entrenamiento aparecerá una vez que comiences.',
    },
    'iuau6kxi': {
      'en': 'Current Week',
      'es': 'Semana actual',
    },
    'rw1dsevg': {
      'en': 'Best Session',
      'es': 'Mejor sesión',
    },
    'hbweo0lu': {
      'en': 'Improvement',
      'es': 'Mejora',
    },
    'bplde2dk': {
      'en': 'Exercise Analytics',
      'es': 'Análisis del entrenamiento',
    },
    'b2vq42si': {
      'en': 'Track your progress over time',
      'es': 'Realice un seguimiento de su progreso a lo largo del tiempo',
    },
    'ruz65xup': {
      'en': 'No analytics yet',
      'es': 'No hay entrenamientos todavía',
    },
    '6c6rkd9k': {
      'en': 'Log a few sessions to see how this exercise progresses over time.',
      'es': 'Tu historial de entrenamiento aparecerá una vez que comiences.',
    },
    '60fi9hh9': {
      'en': 'Current Week',
      'es': 'Semana actual',
    },
    'sfaomq97': {
      'en': 'Total Sessions',
      'es': 'Mejor sesión',
    },
    'rwjhwmnq': {
      'en': 'Improvement',
      'es': 'Mejora',
    },
    'cy8fn0ug': {
      'en': 'Exercise Analytics',
      'es': 'Análisis del entrenamiento',
    },
    'zahprrwn': {
      'en': 'Track your progress over time',
      'es': 'Realice un seguimiento de su progreso a lo largo del tiempo',
    },
    'q718hvzg': {
      'en': 'Reps',
      'es': 'Representantes',
    },
    '4gyjxuio': {
      'en': 'Assistance',
      'es': 'Peso máximo',
    },
    'p2hu3yvy': {
      'en': 'Volume',
      'es': 'Volumen',
    },
    'prmjwwik': {
      'en': 'Reps',
      'es': 'Representantes',
    },
    'u5si91ad': {
      'en': 'Current Week',
      'es': 'Semana actual',
    },
    '9qlq32ae': {
      'en': 'Best Session',
      'es': 'Mejor sesión',
    },
    'zhfjzh8q': {
      'en': 'Improvement',
      'es': 'Mejora',
    },
    'na9xnckt': {
      'en': 'Estimated 1RM',
      'es': 'Estimado 1RM',
    },
    'eqe4fjjo': {
      'en': 'Based on your heaviest set using the Epley formula',
      'es': 'Basado en tu conjunto más pesado usando la fórmula de Epley',
    },
    't36624zb': {
      'en': '1RM = weight × (1 + reps ÷ 30)',
      'es': '1RM = peso × (1 + repeticiones ÷ 30)',
    },
    'ghmsigoc': {
      'en': 'Home',
      'es': 'Hogar',
    },
  },
  // settingss
  {
    '5jtsd6pb': {
      'en': 'PROFILE',
      'es': 'PERFIL',
    },
    'h3fvjxfg': {
      'en': 'PREFERENCES',
      'es': 'PREFERENCIAS',
    },
    'lw5la6gy': {
      'en': 'Units Preferences',
      'es': 'Unidad de peso',
    },
    'du4vwpii': {
      'en': 'Appearance',
      'es': 'Apariencia',
    },
    '8nr4khy4': {
      'en': 'PAYMENTS',
      'es': 'PAGOS',
    },
    '3lvournw': {
      'en': 'Upgrade to Premium',
      'es': 'Actualizar a Premium',
    },
    'lzem2ez3': {
      'en': 'NOTIFICATIONS',
      'es': 'NOTIFICACIONES',
    },
    'j7ei20yf': {
      'en': 'Notifications',
      'es': 'Información de facturación',
    },
    '6hnt4tpo': {
      'en': 'FEEDBACK',
      'es': 'COMENTARIO',
    },
    '4fkdiotd': {
      'en': 'Feedback / Report a Bug',
      'es': 'Comentarios / Informar un error',
    },
    'v0mxk3o4': {
      'en': 'ACCOUNT',
      'es': 'CUENTA',
    },
    'uvii8akr': {
      'en': 'Account',
      'es': 'Finalizar la sesión',
    },
    'rhs7fkvg': {
      'en': 'Log Out',
      'es': 'Finalizar la sesión',
    },
    'hq7ge7vi': {
      'en': 'Privacy Policy',
      'es': '',
    },
    'cgmkc0xi': {
      'en': '·',
      'es': '',
    },
    '8pq8yabs': {
      'en': 'Terms & Conditions',
      'es': '',
    },
    'lqu3vuzb': {
      'en': 'Home',
      'es': 'Hogar',
    },
  },
  // templateWorkout
  {
    'c6xjjejd': {
      'en': 'Target Muscles',
      'es': '',
    },
    '6pyvugqk': {
      'en': 'Min',
      'es': 'Mínimo',
    },
    'ckvm2bx1': {
      'en': 'Exercises',
      'es': 'Ceremonias',
    },
    'degi078n': {
      'en': ' Save to My Workouts\n',
      'es': 'Guardar en Mis entrenamientos',
    },
    'jacd6nom': {
      'en': 'Template Workout',
      'es': 'Plantilla de entrenamiento',
    },
    '3k6udnd5': {
      'en': 'Home',
      'es': 'Hogar',
    },
  },
  // Signup_in
  {
    'nkm4pvg5': {
      'en': 'Sign In',
      'es': 'Iniciar sesión',
    },
    '5fhndy9r': {
      'en': 'Let\'s get started by filling out the form below.',
      'es': 'Comencemos rellenando el formulario que aparece a continuación.',
    },
    'ytc02vw4': {
      'en': 'Email',
      'es': 'Correo electrónico',
    },
    'uzscjsyn': {
      'en': 'Password',
      'es': 'Contraseña',
    },
    '9e7mtvf9': {
      'en': 'Sign In',
      'es': 'Iniciar sesión',
    },
    '4nif9y6v': {
      'en': 'Forgot Password',
      'es': 'Has olvidado tu contraseña',
    },
    'suol384f': {
      'en': 'Sign Up',
      'es': 'Inscribirse',
    },
    'mjnq8dp5': {
      'en': 'Let\'s get started by filling out the form below.',
      'es': 'Comencemos rellenando el formulario que aparece a continuación.',
    },
    'vcaajwrs': {
      'en': 'Email',
      'es': 'Correo electrónico',
    },
    'yp8lx9yy': {
      'en': 'Password',
      'es': 'Contraseña',
    },
    'x7y6poyb': {
      'en': 'Confirm Password',
      'es': 'confirmar Contraseña',
    },
    'b0e5enwt': {
      'en': 'Create Account',
      'es': 'Crear una cuenta',
    },
    'bqmguf7o': {
      'en': 'Home',
      'es': 'Hogar',
    },
  },
  // ForgotPassword02
  {
    'd0eutc80': {
      'en': 'Back',
      'es': 'Atrás',
    },
    'idahvcji': {
      'en': 'Forgot Password',
      'es': 'Has olvidado tu contraseña',
    },
    '204o5gtr': {
      'en':
          'We will send you an email with a link to reset your password, please enter the email associated with your account below.',
      'es':
          'Le enviaremos un correo electrónico con un enlace para restablecer su contraseña, ingrese el correo electrónico asociado con su cuenta a continuación.',
    },
    'nijmhvw7': {
      'en': 'Your email address...',
      'es': 'Su dirección de correo electrónico...',
    },
    'zjfm9zks': {
      'en': 'Enter your email...',
      'es': 'Introduce tu email...',
    },
    'gyrymd4w': {
      'en': 'Send Link',
      'es': 'Enviar enlace',
    },
    'htlfdill': {
      'en': 'Home',
      'es': 'Hogar',
    },
  },
  // workoutV2
  {
    'wuwiu344': {
      'en': '',
      'es': '',
    },
    'u58x2bqu': {
      'en': 'Finish',
      'es': 'Finalizar',
    },
    'toj7tcqv': {
      'en': 'Add Exercise',
      'es': '',
    },
    'svlo992g': {
      'en': 'Home',
      'es': 'Hogar',
    },
  },
  // workoutComparison
  {
    'fddbo90a': {
      'en': 'Total Sets',
      'es': '',
    },
    'y3jhza38': {
      'en': 'Exercises',
      'es': '',
    },
    'dy71ocxp': {
      'en': 'Duration',
      'es': '',
    },
    'xofe8nlb': {
      'en': 'Volume',
      'es': '',
    },
    'it61datq': {
      'en': 'Muscle Distribution Comparison',
      'es': '',
    },
    'pvhw1j3g': {
      'en': 'Workout A',
      'es': '',
    },
    '7s8i3ibj': {
      'en': '',
      'es': '',
    },
    's0dos1g3': {
      'en': 'Workout B',
      'es': '',
    },
    'yn9l20ol': {
      'en': '',
      'es': '',
    },
    '7gk2gkbu': {
      'en': 'Workout A',
      'es': '',
    },
    'o12foay3': {
      'en': 'Workout B',
      'es': '',
    },
    'uveoeap2': {
      'en': 'Workout Comparison',
      'es': '',
    },
    'unxdo7tu': {
      'en': 'Home',
      'es': '',
    },
  },
  // workoutLogEditV2
  {
    'fr9z4xqp': {
      'en': 'Save',
      'es': 'Finalizar',
    },
    'ii4brc6e': {
      'en': 'Edit Workout',
      'es': '',
    },
    'rjqwdl5n': {
      'en': 'Workout Details',
      'es': '',
    },
    'cvvb2v22': {
      'en': 'Workout Date',
      'es': '',
    },
    'd7trjszc': {
      'en': 'Duration',
      'es': '',
    },
    'ap6suf99': {
      'en': 'Add Exercise',
      'es': '',
    },
    'cfli7m5j': {
      'en': 'Home',
      'es': 'Hogar',
    },
  },
  // compareSelect
  {
    'bk9lnhj8': {
      'en': 'Search',
      'es': 'Buscar',
    },
    '5u2ld39n': {
      'en': 'All',
      'es': 'Todo',
    },
    'y9hfbkdb': {
      'en': 'Select...',
      'es': 'Seleccionar...',
    },
    'baif73ri': {
      'en': 'Search...',
      'es': 'Buscar...',
    },
    '4h2csogd': {
      'en': 'All',
      'es': 'Todo',
    },
    'm5luzbld': {
      'en': 'Chest',
      'es': 'Cuádriceps',
    },
    'x36xr9zu': {
      'en': 'Back',
      'es': 'Glúteos',
    },
    '1z5cj4cz': {
      'en': 'Shoulders',
      'es': 'Isquiotibiales',
    },
    '63zk8cp0': {
      'en': 'Biceps',
      'es': 'Pecho',
    },
    'm8lzodpl': {
      'en': 'Triceps',
      'es': 'Dorsales',
    },
    '7nw86fmp': {
      'en': 'Legs',
      'es': 'Deltoides laterales',
    },
    '0zzq4hu4': {
      'en': 'Core',
      'es': 'Deltoides posteriores',
    },
    'ivahodkk': {
      'en': 'Neck',
      'es': 'Deltoides frontales',
    },
    'rq0a800g': {
      'en': 'Forearms',
      'es': 'Parte superior de la espalda',
    },
    '7tun8797': {
      'en': 'Workout in Progress',
      'es': '',
    },
    'vfbm2xiv': {
      'en': 'Compare',
      'es': '',
    },
    't0o041ju': {
      'en': 'Select',
      'es': '',
    },
    'sfeboz2k': {
      'en': 'History',
      'es': 'Historia',
    },
  },
  // addExercisesV3
  {
    'lolzzrwh': {
      'en': 'Search exercise',
      'es': '',
    },
    'i6qnbexn': {
      'en': 'Recent Exercises',
      'es': '',
    },
    'uug6n950': {
      'en': 'Custom Exercises',
      'es': '',
    },
    's3g1z6y8': {
      'en': 'All Exercises',
      'es': '',
    },
    'k1pexfvo': {
      'en': 'Add Exercises',
      'es': '',
    },
    'my9xqnu7': {
      'en': 'Create',
      'es': '',
    },
  },
  // createUserExercise
  {
    'nqz65u4k': {
      'en': 'Create Exercise',
      'es': '',
    },
    '72373tu5': {
      'en': 'Create',
      'es': 'Finalizar',
    },
    'bsm5jymd': {
      'en': 'Primary Muscels',
      'es': '',
    },
    'i1gvpvw9': {
      'en': 'Equipment',
      'es': '',
    },
    '75kamj2s': {
      'en': 'Secondary Muscels',
      'es': '',
    },
    'is82pj6x': {
      'en': '(optinal)',
      'es': '',
    },
    '2i4tvohf': {
      'en': 'Exercise Type',
      'es': '',
    },
    'j75z2nzd': {
      'en': 'Allows Bodyweight',
      'es': '',
    },
    'ulryx0lr': {
      'en': 'Can be done without weight',
      'es': '',
    },
  },
  // addExercisesMidSeission
  {
    'nhg86t0p': {
      'en': 'Search exercise',
      'es': '',
    },
    'gqsmh6b7': {
      'en': 'Recent Exercises',
      'es': '',
    },
    'kt9efzhx': {
      'en': 'Custom Exercises',
      'es': '',
    },
    't0s77qqf': {
      'en': 'All Exercises',
      'es': '',
    },
    'e6mmratz': {
      'en': 'Add Exercises',
      'es': '',
    },
    'y57lsxr5': {
      'en': 'Create',
      'es': '',
    },
  },
  // HelpUs
  {
    'xu7eo1ik': {
      'en': 'Contact & Feedback',
      'es': '',
    },
    '8uu69emz': {
      'en': 'Help us improve Xlift',
      'es': '',
    },
    'd5jm2ssp': {
      'en': 'Your feedback helps us create a better experience for everyone.',
      'es': '',
    },
    'i12h2e1a': {
      'en': 'Report a Bug',
      'es': '',
    },
    'hrsfp9kh': {
      'en':
          'Something didn\'t work as expected? Let us know so we can fix it quickly.',
      'es': '',
    },
    'n262866u': {
      'en': 'Suggest a Feature',
      'es': '',
    },
    'nnapg1da': {
      'en':
          'Share ideas to improve the app. We love hearing from our community.',
      'es': '',
    },
  },
  // reportBug
  {
    'm6mdxiou': {
      'en': 'Help us understand what went wrong',
      'es': '',
    },
    'b8f0s301': {
      'en':
          'Describe the issue you encountered and what you expected to happen',
      'es': '',
    },
    '3bniorw8': {
      'en': 'Add screenshot or video (optional)',
      'es': '',
    },
    '082slt73': {
      'en': 'Help us see what you\'re experiencing',
      'es': '',
    },
    'jls700g6': {
      'en': 'Send Report',
      'es': '',
    },
    'e1r4v4zt': {
      'en': 'Report A Bug',
      'es': '',
    },
  },
  // feedback
  {
    'tfn6f86s': {
      'en': 'Help shape the future of Xlift',
      'es': '',
    },
    'b8blrrke': {
      'en':
          'Describe the feature or improvement you’d like to see and why it would be useful.',
      'es': '',
    },
    'qeioi8sv': {
      'en': 'Add screenshot or video (optional)',
      'es': '',
    },
    'h68stihv': {
      'en': 'Help us see what you\'re experiencing',
      'es': '',
    },
    'idie29ix': {
      'en': 'Send Report',
      'es': '',
    },
    '5dbbkeh8': {
      'en': 'Suggest a Feature',
      'es': '',
    },
  },
  // editWorkoutV2
  {
    '7fgre2jr': {
      'en': '',
      'es': '',
    },
    '40roqkvg': {
      'en': 'Add exercises',
      'es': '',
    },
    '62rcsx1a': {
      'en': 'Save',
      'es': 'Finalizar',
    },
    '1eaq2q45': {
      'en': 'Edit Workout',
      'es': '',
    },
  },
  // addExercisesForEdit
  {
    '92eullnx': {
      'en': 'Search exercise',
      'es': '',
    },
    'i3lcqx9t': {
      'en': 'Recent Exercises',
      'es': '',
    },
    '2xnri1os': {
      'en': 'Custom Exercises',
      'es': '',
    },
    '915djoas': {
      'en': 'All Exercises',
      'es': '',
    },
    'dnsj8jwq': {
      'en': 'Add Exercises',
      'es': '',
    },
    'pukhy0mh': {
      'en': 'Create',
      'es': '',
    },
  },
  // addExercisesForWorklogEdit
  {
    'h56vao67': {
      'en': 'Search exercise',
      'es': '',
    },
    'fyb57ztx': {
      'en': 'Recent Exercises',
      'es': '',
    },
    '7iuw8mqa': {
      'en': 'Custom Exercises',
      'es': '',
    },
    'i1w6fjf9': {
      'en': 'All Exercises',
      'es': '',
    },
    'my4n57qq': {
      'en': 'Add Exercises',
      'es': '',
    },
    'lo89ffm5': {
      'en': 'Create',
      'es': '',
    },
  },
  // profEditV2
  {
    '6vw3sskc': {
      'en': 'Change Picture',
      'es': '',
    },
    '3rx3xbqb': {
      'en': 'Account',
      'es': '',
    },
    'glzxjaep': {
      'en': 'Username',
      'es': '',
    },
    'oztb29pq': {
      'en': 'Personal',
      'es': '',
    },
    't9zqdwy1': {
      'en': 'Sex',
      'es': '',
    },
    'sbn87l07': {
      'en': 'Birthday',
      'es': '',
    },
    'jldys2ch': {
      'en': 'Measurements',
      'es': '',
    },
    'z50wgfbl': {
      'en': 'Height',
      'es': '',
    },
    '4iritktz': {
      'en': 'Weight',
      'es': '',
    },
    '4i1gf33a': {
      'en': 'Change',
      'es': '',
    },
    '1wwala0i': {
      'en': 'Save',
      'es': 'Finalizar',
    },
    'jhkyxozz': {
      'en': 'Edit Profile',
      'es': '',
    },
  },
  // accountSettings
  {
    'b7pqx57r': {
      'en': 'Manage Subscription',
      'es': '',
    },
    '5q7okyv7': {
      'en': 'Update Password',
      'es': '',
    },
    'hisbv3s7': {
      'en': 'Delete Account',
      'es': '',
    },
    'kvsqpbzs': {
      'en': 'Account Settings',
      'es': '',
    },
  },
  // replaceExercisePage
  {
    'xk5mapm5': {
      'en': 'Replace Exercise',
      'es': '',
    },
    'q4v3yyvy': {
      'en': 'Create',
      'es': '',
    },
    'lbilz5aw': {
      'en': 'Smart Replace',
      'es': '',
    },
    'lmul7xzc': {
      'en': 'Best',
      'es': '',
    },
    '7vtuneq6': {
      'en': 'Regular replace',
      'es': '',
    },
    'g53a9rui': {
      'en': 'Search exercise',
      'es': '',
    },
    'xcrzwa6q': {
      'en': 'Recent Exercises',
      'es': '',
    },
    'dv2nlf9a': {
      'en': 'Custom Exercises',
      'es': '',
    },
    'nu52kuws': {
      'en': 'All Exercises',
      'es': '',
    },
    '8vuvs30z': {
      'en': 'Replace',
      'es': '',
    },
  },
  // replaceExercisePageCreation
  {
    'es5fim7y': {
      'en': 'Replace Exercise',
      'es': '',
    },
    'dpayteic': {
      'en': 'Create',
      'es': '',
    },
    'xig04m03': {
      'en': 'Smart Replace',
      'es': '',
    },
    'h66gqkvx': {
      'en': 'Best',
      'es': '',
    },
    't3z2yb02': {
      'en': 'Regular replace',
      'es': '',
    },
    '6l1di9pf': {
      'en': 'Search exercise',
      'es': '',
    },
    'dvoejeql': {
      'en': 'Recent Exercises',
      'es': '',
    },
    '1qwoz1r5': {
      'en': 'Custom Exercises',
      'es': '',
    },
    '9oi1r75l': {
      'en': 'All Exercises',
      'es': '',
    },
    '6zb90gq6': {
      'en': 'Replace',
      'es': '',
    },
  },
  // createUserExerciseMidSession
  {
    'qihg11af': {
      'en': 'Create Exercise',
      'es': '',
    },
    '83sgh0br': {
      'en': 'Create',
      'es': 'Finalizar',
    },
    '83coa8bl': {
      'en': 'Primary Muscels',
      'es': '',
    },
    'i32iz7yw': {
      'en': 'Equipment',
      'es': '',
    },
    'o391ubev': {
      'en': 'Secondary Muscels',
      'es': '',
    },
    'r89kst9t': {
      'en': '(optinal)',
      'es': '',
    },
    '3mtko6ik': {
      'en': 'Exercise Type',
      'es': '',
    },
    'picxypd6': {
      'en': 'Allows Bodyweight',
      'es': '',
    },
    '39nldbz7': {
      'en': 'Can be done without weight',
      'es': '',
    },
  },
  // routineBuilder
  {
    'dwn3v2dq': {
      'en': 'Choose Your Training Split',
      'es': '',
    },
    'qpz9gutq': {
      'en': 'Select the structure that fits your training style',
      'es': '',
    },
    'aeeq9k15': {
      'en': 'Full Body',
      'es': '',
    },
    'ad58mnov': {
      'en': 'Train all muscles each session',
      'es': '',
    },
    'eotw7isi': {
      'en': 'Upper / Lower',
      'es': '',
    },
    'ap8aqip5': {
      'en': 'Split between upper and lower body',
      'es': '',
    },
    '4bsiiyne': {
      'en': 'Push / Pull / Legs',
      'es': '',
    },
    'oja4lb7z': {
      'en': 'Focus on movement patterns',
      'es': '',
    },
    '3zh4pbdt': {
      'en': 'Custom',
      'es': '',
    },
    'h9h5f91i': {
      'en': 'Create your own split',
      'es': '',
    },
    'wv1rmmrv': {
      'en': 'Step 1 of 3',
      'es': '',
    },
    'hcuafajg': {
      'en': 'Build Your Weekly Schedule',
      'es': '',
    },
    '0k157ofd': {
      'en': 'Choose how often you train and what each workout includes',
      'es': '',
    },
    '07kq73y1': {
      'en': 'Workouts per Week',
      'es': '',
    },
    'eya9wr01': {
      'en': '2',
      'es': '',
    },
    'qi4v79xk': {
      'en': '3',
      'es': '',
    },
    '5wr49zrp': {
      'en': '4',
      'es': '',
    },
    'x114xo5o': {
      'en': '5',
      'es': '',
    },
    's7stmxj0': {
      'en': '6',
      'es': '',
    },
    'fh10hxx6': {
      'en': '7',
      'es': '',
    },
    'ja8qyzi0': {
      'en': 'Step 2 of 3',
      'es': '',
    },
    'gw37yoiv': {
      'en': 'Your Workouts',
      'es': '',
    },
    '1iel2l8a': {
      'en': 'Select the workouts you want to include this week',
      'es': '',
    },
    'k7sht9ux': {
      'en': '+ Add Workouts',
      'es': '',
    },
    'xe284rm2': {
      'en': 'Build Weekly Schedule',
      'es': '',
    },
    'fkuk9k53': {
      'en': 'Routine Builder',
      'es': '',
    },
    'ictudwj6': {
      'en': 'Home',
      'es': '',
    },
  },
  // selectWorkouts
  {
    'nmnk3r3l': {
      'en': 'TextField',
      'es': 'Campo de texto',
    },
    'qgc5034k': {
      'en': 'All',
      'es': '',
    },
    'vr9q7hpc': {
      'en': 'Select...',
      'es': 'Seleccionar...',
    },
    'xkrf9oad': {
      'en': 'Search...',
      'es': 'Buscar...',
    },
    'yqjdnq2g': {
      'en': 'All',
      'es': 'Opción 1',
    },
    'po5q2d7p': {
      'en': 'Chest',
      'es': 'Opción 2',
    },
    'mg9d5xx7': {
      'en': 'Back',
      'es': 'Opción 3',
    },
    '7n5iel6y': {
      'en': 'Shoulders',
      'es': '',
    },
    'megl63gg': {
      'en': 'Biceps',
      'es': '',
    },
    '9yn036if': {
      'en': 'Triceps',
      'es': '',
    },
    'od5dg01r': {
      'en': 'Legs',
      'es': '',
    },
    'bg92z1e4': {
      'en': 'Core',
      'es': '',
    },
    '183bjqbe': {
      'en': 'Forearms',
      'es': '',
    },
    'qphwnpz9': {
      'en': 'Neck',
      'es': '',
    },
    'ixfwrs7z': {
      'en': 'Continue',
      'es': '',
    },
    'afs7dcxd': {
      'en': 'Select Workouts',
      'es': '',
    },
  },
  // calender
  {
    'fuawnmbi': {
      'en': 'No workout scheduled',
      'es': '',
    },
    '3avsa6ls': {
      'en': 'Add workout',
      'es': '',
    },
    'sei68nld': {
      'en': 'Page Title',
      'es': '',
    },
    '2k41jpit': {
      'en': 'Home',
      'es': '',
    },
  },
  // exerciseHistoryCustom
  {
    'sumish25': {
      'en': 'History',
      'es': 'Historia',
    },
    '3480ehkz': {
      'en': 'COMPARED TO PREVIOUS',
      'es': 'COMPARADO CON EL ANTERIOR',
    },
    'g0k45442': {
      'en': 'Analytics',
      'es': 'Analítica',
    },
    'jc23lt1k': {
      'en': 'Personal Records',
      'es': 'Registros personales',
    },
    '5a9r9zgl': {
      'en': 'Max Reps',
      'es': 'Máximas repeticiones',
    },
    '19lyyidt': {
      'en': 'Max Weight',
      'es': 'Peso máximo',
    },
    'b21dnmi5': {
      'en': 'Max Volume',
      'es': 'Volumen máximo',
    },
    'er7qkq3g': {
      'en': 'Personal Records',
      'es': 'Registros personales',
    },
    'pgjvgs1r': {
      'en': 'Max Reps',
      'es': 'Máximas repeticiones',
    },
    'zg9am9wq': {
      'en': 'Max Session',
      'es': 'Peso máximo',
    },
    'wkkzogbw': {
      'en': 'Avrage Reps',
      'es': 'Volumen máximo',
    },
    'gk4m4zu9': {
      'en': 'Personal Records',
      'es': 'Registros personales',
    },
    'xci4st5u': {
      'en': 'Max Session Time',
      'es': 'Máximas repeticiones',
    },
    '78i8b80k': {
      'en': 'Avrage Duration',
      'es': 'Peso máximo',
    },
    'jrqxv26i': {
      'en': 'Max Duration',
      'es': 'Volumen máximo',
    },
    'isoqhf59': {
      'en': 'Personal Records',
      'es': 'Registros personales',
    },
    '2u3xi6i5': {
      'en': 'Max Reps',
      'es': 'Máximas repeticiones',
    },
    'k350lgfo': {
      'en': 'Max Session Reps',
      'es': 'Peso máximo',
    },
    '2q6hv3m3': {
      'en': 'Min Assistance',
      'es': 'Volumen máximo',
    },
    'g6vceimb': {
      'en': 'Exercise Analytics',
      'es': 'Análisis del entrenamiento',
    },
    'x7aqk0uu': {
      'en': 'Track your progress over time',
      'es': 'Realice un seguimiento de su progreso a lo largo del tiempo',
    },
    '5k4vax1p': {
      'en': 'Reps',
      'es': 'Representantes',
    },
    'taxosvjn': {
      'en': 'Max Weight',
      'es': 'Peso máximo',
    },
    'jc8mdri5': {
      'en': 'Volume',
      'es': 'Volumen',
    },
    '1fszsvo2': {
      'en': 'Reps',
      'es': 'Representantes',
    },
    '08ujb6mu': {
      'en': 'No analytics yet',
      'es': 'No hay entrenamientos todavía',
    },
    'i9ccbyhg': {
      'en': 'Log a few sessions to see how this exercise progresses over time.',
      'es': 'Tu historial de entrenamiento aparecerá una vez que comiences.',
    },
    'avks3n8b': {
      'en': 'Current Week',
      'es': 'Semana actual',
    },
    'y1w3kmyi': {
      'en': 'Best Session',
      'es': 'Mejor sesión',
    },
    'p68dddlc': {
      'en': 'Improvement',
      'es': 'Mejora',
    },
    'hi1qvpqx': {
      'en': 'Exercise Analytics',
      'es': 'Análisis del entrenamiento',
    },
    'shwdmzpg': {
      'en': 'Track your progress over time',
      'es': 'Realice un seguimiento de su progreso a lo largo del tiempo',
    },
    'bi5rjem8': {
      'en': 'No analytics yet',
      'es': 'No hay entrenamientos todavía',
    },
    '6orz8tdu': {
      'en': 'Log a few sessions to see how this exercise progresses over time.',
      'es': 'Tu historial de entrenamiento aparecerá una vez que comiences.',
    },
    '9vg3cbuz': {
      'en': 'Current Week',
      'es': 'Semana actual',
    },
    'pa9m8s93': {
      'en': 'Best Session',
      'es': 'Mejor sesión',
    },
    '2opf55rh': {
      'en': 'Improvement',
      'es': 'Mejora',
    },
    'lx6e6ua0': {
      'en': 'Exercise Analytics',
      'es': 'Análisis del entrenamiento',
    },
    'j1ezyjqo': {
      'en': 'Track your progress over time',
      'es': 'Realice un seguimiento de su progreso a lo largo del tiempo',
    },
    'cmrlanpg': {
      'en': 'No analytics yet',
      'es': 'No hay entrenamientos todavía',
    },
    '6jsq3v8f': {
      'en': 'Log a few sessions to see how this exercise progresses over time.',
      'es': 'Tu historial de entrenamiento aparecerá una vez que comiences.',
    },
    'sp23cish': {
      'en': 'Current Week',
      'es': 'Semana actual',
    },
    '640e4yle': {
      'en': 'Total Sessions',
      'es': 'Mejor sesión',
    },
    'jqnfb2x7': {
      'en': 'Improvement',
      'es': 'Mejora',
    },
    '76qov726': {
      'en': 'Exercise Analytics',
      'es': 'Análisis del entrenamiento',
    },
    'jx4p2c2g': {
      'en': 'Track your progress over time',
      'es': 'Realice un seguimiento de su progreso a lo largo del tiempo',
    },
    'gzx8ytk0': {
      'en': 'Reps',
      'es': 'Representantes',
    },
    '1brmwhfu': {
      'en': 'Assistance',
      'es': 'Peso máximo',
    },
    'yn9hwikv': {
      'en': 'Volume',
      'es': 'Volumen',
    },
    'he8b102c': {
      'en': 'Reps',
      'es': 'Representantes',
    },
    'z1xpwmzt': {
      'en': 'Current Week',
      'es': 'Semana actual',
    },
    '55s9rfeo': {
      'en': 'Best Session',
      'es': 'Mejor sesión',
    },
    'v6knhf1n': {
      'en': 'Improvement',
      'es': 'Mejora',
    },
    '41b3hlhm': {
      'en': 'Estimated 1RM',
      'es': 'Estimado 1RM',
    },
    'vni1cu3l': {
      'en': 'Based on your heaviest set using the Epley formula',
      'es': 'Basado en tu conjunto más pesado usando la fórmula de Epley',
    },
    'bmne3ih7': {
      'en': '1RM = weight × (1 + reps ÷ 30)',
      'es': '1RM = peso × (1 + repeticiones ÷ 30)',
    },
    '6vx32ca9': {
      'en': 'Home',
      'es': 'Hogar',
    },
  },
  // test
  {
    'd3k05ijc': {
      'en': 'Button',
      'es': '',
    },
    'm1orp68a': {
      'en': 'HEVY',
      'es': '',
    },
    '6uv5sjg8': {
      'en': 'Page Title',
      'es': '',
    },
    'eee63fkc': {
      'en': 'Home',
      'es': '',
    },
  },
  // videopage
  {
    'c244xa8i': {
      'en': 'Page Title',
      'es': '',
    },
    '49qt3kqy': {
      'en': 'Home',
      'es': '',
    },
  },
  // manageSubscription
  {
    '77jo69zl': {
      'en': 'CURRENT PLAN',
      'es': '',
    },
    '8wqogeau': {
      'en': 'Active',
      'es': '',
    },
    'r2iseoqi': {
      'en': 'PLANS',
      'es': '',
    },
    'plap5bcf': {
      'en': 'Monthly',
      'es': '',
    },
    'pufj6bzw': {
      'en': 'Billed every month',
      'es': '',
    },
    'imljim8g': {
      'en': '\$3.99',
      'es': '',
    },
    '4j8jb5eg': {
      'en': 'per month',
      'es': '',
    },
    'oc4cilpm': {
      'en': 'Yearly',
      'es': '',
    },
    'zjfkvyh4': {
      'en': 'Billed once a year',
      'es': '',
    },
    '7xeqqe63': {
      'en': '\$5.99',
      'es': '',
    },
    'zswmpueb': {
      'en': 'Save 37%',
      'es': '',
    },
    '1r183oit': {
      'en': 'More information',
      'es': '',
    },
    'mmashq12': {
      'en': 'Cancel your subscription at any time.',
      'es': '',
    },
    '4nw0d4nv': {
      'en': 'Manage in App Store',
      'es': '',
    },
    'zpm95ruz': {
      'en': 'Privacy Policy',
      'es': '',
    },
    '277u5gzv': {
      'en': 'Terms & Conditions',
      'es': '',
    },
    'xk7ttxv0': {
      'en': 'Something not right? Let us know',
      'es': '',
    },
    'fh32c1ua': {
      'en': 'Contect us',
      'es': '',
    },
    '9zxdm4jg': {
      'en': 'Restore Purchases',
      'es': '',
    },
    'j34thjz9': {
      'en': 'Manage Subscription',
      'es': '',
    },
    'qpc7xog4': {
      'en': 'Home',
      'es': '',
    },
  },
  // test3
  {
    'zyxx1g8q': {
      'en': 'Page Title',
      'es': '',
    },
    '4y2bsccq': {
      'en': 'Home',
      'es': '',
    },
  },
  // videopageHEVY
  {
    '428xgxdf': {
      'en': 'Page Title',
      'es': '',
    },
    'tty2d4ff': {
      'en': 'Home',
      'es': '',
    },
  },
  // liveSquat
  {
    '7kt3w1xy': {
      'en': 'Home',
      'es': '',
    },
  },
  // barbelll
  {
    'ebtzbrmx': {
      'en': 'Page Title',
      'es': '',
    },
    '66lg051x': {
      'en': 'Home',
      'es': '',
    },
  },
  // camera
  {
    'bld8hx0k': {
      'en': 'Home',
      'es': '',
    },
  },
  // aiCustomMuscels
  {
    'rvbtcx4m': {
      'en': 'Step 1 of 3',
      'es': '',
    },
    '4lqjbmqg': {
      'en': 'Which muscles do you want to train?',
      'es': '',
    },
    'b1t1hkph': {
      'en': 'Select all that apply for your custom session.',
      'es': '',
    },
    'mkb8mfog': {
      'en': 'continue',
      'es': '',
    },
  },
  // aiWorkoutType
  {
    '0gkzt94v': {
      'en': 'Step 1 of 3',
      'es': '',
    },
    'xn3wcs51': {
      'en': 'Build your workout template',
      'es': '',
    },
    '5bv7zba3': {
      'en': 'Choose a split, or pick your own muscles.',
      'es': '',
    },
    'ldu9ugd5': {
      'en': 'Push',
      'es': '',
    },
    'zacohhsl': {
      'en': 'Chest, shoulders & triceps',
      'es': '',
    },
    'sy4mx701': {
      'en': 'Pull',
      'es': '',
    },
    'ewg3msza': {
      'en': 'Back, biceps & rear delts',
      'es': '',
    },
    '2t1hs8uv': {
      'en': 'Legs',
      'es': '',
    },
    '2f7rki7h': {
      'en': 'Quads, hamstrings & calves',
      'es': '',
    },
    'gg2vv63b': {
      'en': 'Full Body',
      'es': '',
    },
    '5fidc8ab': {
      'en': 'Comprehensive compound movements',
      'es': '',
    },
    '7sw0qqsg': {
      'en': 'Custom Split',
      'es': '',
    },
    'iipl4qwh': {
      'en': 'Design your own muscle grouping',
      'es': '',
    },
  },
  // aiExpirenceLevel
  {
    'wiwpumnv': {
      'en': 'Step 2 of 3',
      'es': '',
    },
    'tu1swqw8': {
      'en': 'What\'s your experience level?',
      'es': '',
    },
    '3x8pc0ed': {
      'en': 'We\'ll match the volume and exercises to you.',
      'es': '',
    },
    'nmh3rml0': {
      'en': 'Beginner',
      'es': '',
    },
    '9hv04bwj': {
      'en': 'New to lifting',
      'es': '',
    },
    'seazc0tm': {
      'en': 'Intermediate ',
      'es': '',
    },
    '70w7kpq4': {
      'en': 'Training consistently for 1+ years',
      'es': '',
    },
    'lvndihye': {
      'en': 'Advanced ',
      'es': '',
    },
    '24tdd10e': {
      'en': 'Experienced, high training volume',
      'es': '',
    },
    'dz5m6mvm': {
      'en': 'Continue',
      'es': '',
    },
  },
  // aiGoal
  {
    'nu5253tz': {
      'en': 'Step 3 of 3',
      'es': '',
    },
    'n9ms7y49': {
      'en': 'What\'s your training goal?',
      'es': '',
    },
    'hri91f9i': {
      'en': 'This sets your reps, sets, and rest.',
      'es': '',
    },
    'lad52cs2': {
      'en': 'Build Muscle',
      'es': '',
    },
    '8sw91is0': {
      'en': 'Grow size with moderate reps',
      'es': '',
    },
    'uo9zjvcu': {
      'en': 'Get Stronger',
      'es': '',
    },
    '442o15f0': {
      'en': 'Get Stronger',
      'es': '',
    },
    '8gqq575c': {
      'en': 'Endurance',
      'es': '',
    },
    'ehrwxabw': {
      'en': 'Higher reps, shorter rest',
      'es': '',
    },
    '9gtfowsf': {
      'en': 'Generate Workout',
      'es': '',
    },
  },
  // testAI
  {
    'aal9asnx': {
      'en': 'Page Title',
      'es': '',
    },
    '3wcvl5pj': {
      'en': 'Home',
      'es': '',
    },
  },
  // aiWorkoutLoading
  {
    'zo8zv9tf': {
      'en': 'Building Your Workout ...',
      'es': '',
    },
    'v60odw6r': {
      'en': 'Home',
      'es': '',
    },
  },
  // aiWorkoutView
  {
    'k67sgjjy': {
      'en': 'Minutes',
      'es': '',
    },
    'u70684v5': {
      'en': '•',
      'es': '',
    },
    'yknk7dq0': {
      'en': 'Save Workout',
      'es': '',
    },
  },
  // PremiumPaywallPage
  {
    't8rryeqh': {
      'en': 'XLIFT PREMIUM',
      'es': '',
    },
    'lw64qsg0': {
      'en': 'Unlock your\nfull potential',
      'es': '',
    },
    'yd1g8q07': {
      'en': 'Start 7-Day Free Trial',
      'es': '',
    },
    '214fymmx': {
      'en': 'Privacy Policy',
      'es': '',
    },
    's0krmnr4': {
      'en': '·',
      'es': '',
    },
    'ca4hmb6f': {
      'en': 'Terms',
      'es': '',
    },
    'bff1v9sz': {
      'en': '·',
      'es': '',
    },
    'vpkpqnes': {
      'en': 'Restore',
      'es': '',
    },
  },
  // changePassword
  {
    '0uyeopfr': {
      'en': 'Back',
      'es': 'Atrás',
    },
    'hv49gfa8': {
      'en': 'Change Password',
      'es': 'Has olvidado tu contraseña',
    },
    'ouqq9g1p': {
      'en':
          'We will send you an email with a link to reset your password, please enter the email associated with your account below.',
      'es':
          'Le enviaremos un correo electrónico con un enlace para restablecer su contraseña, ingrese el correo electrónico asociado con su cuenta a continuación.',
    },
    '2o2ch6f4': {
      'en': 'Your email address...',
      'es': 'Su dirección de correo electrónico...',
    },
    '4sctl9sx': {
      'en': 'Enter your email...',
      'es': 'Introduce tu email...',
    },
    'oy84qymb': {
      'en': 'Send Link',
      'es': 'Enviar enlace',
    },
    '5xhghx2g': {
      'en': 'Home',
      'es': 'Hogar',
    },
  },
  // SignInWelcomePage6
  {
    'e8nt6zeb': {
      'en': 'XLIFT',
      'es': '',
    },
    'dcgmtwg7': {
      'en': 'Train smarter. Lift stronger.',
      'es': '',
    },
    't5l67562': {
      'en': 'Continue with Apple',
      'es': 'Continuar con Apple',
    },
    'i1rz68vz': {
      'en': 'Continue with Google',
      'es': 'Continuar con Google',
    },
    'nxmlj0r3': {
      'en': 'Continue with email',
      'es': '',
    },
    'eai5gy4m': {
      'en': 'By continuing you agree to our',
      'es': '',
    },
    'yqyu9bkf': {
      'en': 'Terms',
      'es': '',
    },
    'nak0vblh': {
      'en': 'and',
      'es': '',
    },
    'y252v12n': {
      'en': 'Privacy Policy',
      'es': '',
    },
  },
  // FullResultPage
  {
    'dmhlqoy9': {
      'en': 'Total Reps',
      'es': '',
    },
    'jlj8teaj': {
      'en': 'Proper Reps',
      'es': '',
    },
    'nt3lhro3': {
      'en': 'Form Tip',
      'es': '',
    },
    'pmmqjyi3': {
      'en': 'View Video',
      'es': '',
    },
    'saor8l81': {
      'en': 'Feedback',
      'es': '',
    },
    'lhx7ymxp': {
      'en': 'Try going deeper on your squats',
      'es': '',
    },
    '96wal5wp': {
      'en': 'Continue as Workout',
      'es': '',
    },
  },
  // FullAnalyzingStatePage
  {
    'at083w6n': {
      'en': 'Tracking joints and bar path',
      'es': '',
    },
    'qwgrvacy': {
      'en': 'This usually takes about 30 seconds',
      'es': '',
    },
  },
  // masterPage
  {
    'e95uok47': {
      'en': 'Statistics',
      'es': 'Estadística',
    },
    'sq5o4cbn': {
      'en': 'Overview',
      'es': 'Descripción general',
    },
    '1r95bm6r': {
      'en': 'Volume Over Time',
      'es': 'Volumen a lo largo del tiempo',
    },
    '9liemkyb': {
      'en': 'Workouts',
      'es': 'Entrenamientos',
    },
    'kypsbi0s': {
      'en': 'Total Volume',
      'es': 'Volumen total',
    },
    'u6di45yf': {
      'en': 'Top Muscle',
      'es': 'Músculo superior',
    },
    'v7w62k4h': {
      'en': 'Sets by Muscle Group',
      'es': 'Series por grupo muscular',
    },
    'aoymqw3k': {
      'en': 'Sets',
      'es': 'Conjuntos',
    },
    'e8dgbzuh': {
      'en': 'By Exercise',
      'es': 'Por ejercicio',
    },
    '48qrhv5k': {
      'en': 'By Muscle',
      'es': '',
    },
    'v519r977': {
      'en': 'live',
      'es': '',
    },
    'guz1gr5a': {
      'en': 'AI',
      'es': '',
    },
    'c5eotijq': {
      'en': 'deadBarbell',
      'es': '',
    },
    'j052n2mz': {
      'en': 'Barbell',
      'es': '',
    },
    'tdz0v8sl': {
      'en': 'HEVY',
      'es': '',
    },
    '20ovd11d': {
      'en': 'overhead',
      'es': '',
    },
    '5faz4avs': {
      'en': 'stiff',
      'es': '',
    },
    'mzkxe4lg': {
      'en': 'dead',
      'es': '',
    },
    'oa9v66qh': {
      'en': 'romanian',
      'es': '',
    },
    'mnefh77d': {
      'en': 'Bulgarian',
      'es': '',
    },
    '8gaxhykq': {
      'en': 'bent',
      'es': '',
    },
    'i11qsqnm': {
      'en': 'curl',
      'es': '',
    },
    'd7krjqep': {
      'en': 'pushup',
      'es': '',
    },
    '36rqa6e7': {
      'en': 'Button',
      'es': '',
    },
    'k7sua9wp': {
      'en': 'pullup',
      'es': '',
    },
    'lcrzglaf': {
      'en': 'dips',
      'es': '',
    },
    'ahlq77rb': {
      'en': 'Your Workouts',
      'es': 'Tus entrenamientos',
    },
    '8ktvi2nq': {
      'en': 'TextField',
      'es': 'Campo de texto',
    },
    'oy2b8ybn': {
      'en': 'All',
      'es': '',
    },
    'tq9oct0d': {
      'en': 'Select...',
      'es': 'Seleccionar...',
    },
    'ox894sck': {
      'en': 'Search...',
      'es': 'Buscar...',
    },
    '7pid1v9f': {
      'en': 'All',
      'es': 'Opción 1',
    },
    '10s22mju': {
      'en': 'Chest',
      'es': 'Opción 2',
    },
    '3uuvp7nl': {
      'en': 'Back',
      'es': 'Opción 3',
    },
    'kb8zdhu7': {
      'en': 'Shoulders',
      'es': '',
    },
    'r32ngiot': {
      'en': 'Biceps',
      'es': '',
    },
    'm58s0ooy': {
      'en': 'Triceps',
      'es': '',
    },
    'fvz529sn': {
      'en': 'Legs',
      'es': '',
    },
    'qx1fafec': {
      'en': 'Core',
      'es': '',
    },
    'pi7flkbt': {
      'en': 'Forearms',
      'es': '',
    },
    '7l5aqd87': {
      'en': 'Neck',
      'es': '',
    },
    'k205h2l1': {
      'en': 'Start',
      'es': 'Comenzar',
    },
    '2bd1t25s': {
      'en': 'Create New  Workout',
      'es': 'Crear nuevo entrenamiento',
    },
    'cj0vxjk2': {
      'en': 'Template',
      'es': 'Plantilla',
    },
    'v7ebt3bk': {
      'en': 'All',
      'es': '',
    },
    '9dap7ro4': {
      'en': 'Select...',
      'es': 'Seleccionar...',
    },
    'e7j902sf': {
      'en': 'Search...',
      'es': 'Buscar...',
    },
    's13m0nlj': {
      'en': 'All',
      'es': 'Opción 1',
    },
    'pqiwmalo': {
      'en': 'Chest',
      'es': 'Opción 2',
    },
    't1r5sfg5': {
      'en': 'Back',
      'es': 'Opción 3',
    },
    'psfvfw3i': {
      'en': 'Shoulders',
      'es': '',
    },
    'pyn1hlm8': {
      'en': 'Biceps',
      'es': '',
    },
    'cd1ytbtc': {
      'en': 'Triceps',
      'es': '',
    },
    'lg6a7k4g': {
      'en': 'Legs',
      'es': '',
    },
    '3jc8aihc': {
      'en': 'Core',
      'es': '',
    },
    'kuxlfp9u': {
      'en': 'Neck',
      'es': '',
    },
    '90xwveia': {
      'en': 'Forearms',
      'es': '',
    },
    '0bvto18q': {
      'en': 'Use',
      'es': 'Usar',
    },
    'yud1n1w6': {
      'en': 'Workout in Progress',
      'es': '',
    },
    '1w9l0zfj': {
      'en': 'Home',
      'es': '',
    },
  },
  // CreateWorkoutV2
  {
    'ewirjb69': {
      'en': 'Workout name',
      'es': '',
    },
    'x8lkt3tb': {
      'en': 'Enter workout name',
      'es': '',
    },
    's28y3dxn': {
      'en': 'Add exercises',
      'es': '',
    },
    'hxqefook': {
      'en': 'Save',
      'es': 'Finalizar',
    },
    'c6sgql8x': {
      'en': 'Create Workout',
      'es': '',
    },
  },
  // workoutComplete
  {
    'wpugqjh5': {
      'en': 'WORKOUT COMPLETE',
      'es': '',
    },
    'z5r6sr0i': {
      'en': 'Previous best 145 kg',
      'es': '',
    },
    'nxjer796': {
      'en': 'Done',
      'es': '',
    },
  },
  // workoutSummaryView
  {
    '50vb30be': {
      'en': 'Home',
      'es': '',
    },
  },
  // exerciseStatsPlaceHolder
  {
    'zekrnvm0': {
      'en': 'No Data for This Period',
      'es': 'No hay conjuntos registrados',
    },
    'u1bdzrku': {
      'en': 'Log workouts or adjust the time range to see stats.',
      'es':
          'Empieza a entrenar para construir tu historial\npara este ejercicio.',
    },
  },
  // statsPlaceHolder
  {
    'wyyf5hr7': {
      'en': 'No Stats Yet',
      'es': 'No hay estadísticas todavía',
    },
    'oexacyl7': {
      'en': 'Your workout stats will appear\n after your first session.\n\n',
      'es':
          'Tus estadísticas de entrenamiento aparecerán después de tu primera sesión.',
    },
  },
  // lineGraphPlaceHolder
  {
    'z22ymokx': {
      'en': 'No Volume Data',
      'es': 'Sin datos de volumen',
    },
    'i7flkyk9': {
      'en': 'Log more workouts to see\nyour progress over time.',
      'es':
          'Registra más entrenamientos para ver tu progreso a lo largo del tiempo.',
    },
  },
  // historyPlaceHolder
  {
    '0dzfyl1j': {
      'en': 'No Workouts Yet',
      'es': 'No hay entrenamientos todavía',
    },
    'j0gweolp': {
      'en': 'Your workout history will show\n up once you get started.\n\n\n',
      'es': 'Tu historial de entrenamiento aparecerá una vez que comiences.',
    },
  },
  // plc
  {
    'z1mhfswh': {
      'en': 'No workouts recorded',
      'es': 'No hay entrenamientos registrados',
    },
  },
  // aw
  {
    'cig0h5zr': {
      'en': 'No Workouts Yet',
      'es': 'No hay entrenamientos todavía',
    },
    'atsln1c0': {
      'en':
          'Start your fitness journey by creating your first workout or browse our collection for inspiration.',
      'es':
          'Comienza tu viaje de fitness creando tu primer entrenamiento o explora nuestra colección en busca de inspiración.',
    },
  },
  // workoutListPlaceHolder
  {
    'irzsj2pd': {
      'en': 'No Workouts Yet',
      'es': 'No hay entrenamientos todavía',
    },
    'yxrfbgye': {
      'en':
          'Create your own workout or start with one of our ready-made templates.\n\n',
      'es':
          'Crea tu propio entrenamiento o comienza con una de nuestras plantillas ya preparadas.',
    },
  },
  // lightModeChange
  {
    'cxaijukp': {
      'en': 'Light',
      'es': 'Luz',
    },
    '8sdf0gbg': {
      'en': 'Dark',
      'es': 'Oscuro',
    },
  },
  // editOrDelete
  {
    '9kxd6esc': {
      'en': 'Edit',
      'es': '',
    },
    '5nhj04kn': {
      'en': 'Delete',
      'es': '',
    },
  },
  // deleteAlert
  {
    '6ecb7p7l': {
      'en': 'Delete Workout',
      'es': 'Eliminar entrenamiento',
    },
    'u07w2qwk': {
      'en':
          'Are you sure you want to delete this workout? This action cannot be undone.',
      'es':
          '¿Estás seguro de que quieres eliminar este entrenamiento? Esta acción no se puede deshacer.',
    },
    'vgd7xtjp': {
      'en': 'Cancel',
      'es': 'Cancelar',
    },
    '17wj1f41': {
      'en': 'Delete',
      'es': 'Borrar',
    },
  },
  // analplaceHolder
  {
    '63wnlagg': {
      'en': 'No Exercise Data Yet',
      'es': 'Aún no hay datos de ejercicio',
    },
    'n5gxn5mh': {
      'en':
          'Start logging your sets to track your progress and view detailed analytics for this exercise.',
      'es':
          'Comience a registrar sus series para seguir su progreso y ver análisis detallados de este ejercicio.',
    },
  },
  // restBottomShit
  {
    'sejf5l86': {
      'en': 'Rest Timer',
      'es': '',
    },
    '63zlom13': {
      'en': 'Pause',
      'es': '',
    },
    'r3nsru9k': {
      'en': 'Continue',
      'es': '',
    },
  },
  // cancelRest
  {
    '0cxjgs5u': {
      'en': 'Cancel Rest Timer',
      'es': '',
    },
    'jqxmif5y': {
      'en': 'Are you sure you want to cancel your rest time?',
      'es': '',
    },
    'n5j0lo5r': {
      'en': 'No',
      'es': '',
    },
    'ddmo7jlw': {
      'en': 'Yes, Cancel',
      'es': '',
    },
  },
  // manual
  {
    'm15uh64x': {
      'en': 'Count Up',
      'es': '',
    },
    'c6taywyj': {
      'en': 'Countdown',
      'es': '',
    },
    '7iux6n7v': {
      'en': 'Manual Entry',
      'es': '',
    },
  },
  // time
  {
    '9dmtmyq4': {
      'en': '0',
      'es': '',
    },
    '3bsz70t5': {
      'en': '0',
      'es': '',
    },
    '4yq05tvl': {
      'en': ':',
      'es': '',
    },
    '2q07fxz3': {
      'en': '0',
      'es': '',
    },
    'p9c1dceb': {
      'en': '0',
      'es': '',
    },
  },
  // video2
  {
    '7neaekml': {
      'en': 'Analyzed Video',
      'es': '',
    },
    'sybuu4wg': {
      'en': 'Download Original Video',
      'es': '',
    },
  },
  // deopSetRow
  {
    'uem16cbb': {
      'en': '',
      'es': '',
    },
    'gblffgkd': {
      'en': '',
      'es': '',
    },
  },
  // dropSet
  {
    '46454wwc': {
      'en': 'Drop',
      'es': '',
    },
  },
  // exerciseComponet
  {
    'v02hj46u': {
      'en': 'Superset',
      'es': '',
    },
    '1zuasebz': {
      'en': 'Previous',
      'es': '',
    },
    'j5paqm5m': {
      'en': 'Time',
      'es': '',
    },
    'ju5hixlu': {
      'en': 'Reps',
      'es': '',
    },
    'y4ilum0g': {
      'en': 'Add set',
      'es': '',
    },
  },
  // setRowWarmUp
  {
    'zzxbbise': {
      'en': '-',
      'es': '60 kilos *5',
    },
    '5jjee5qi': {
      'en': '-',
      'es': '',
    },
    'cn787aiv': {
      'en': 'Finish Warmup',
      'es': '',
    },
  },
  // warmupBottomShit
  {
    'z195okww': {
      'en': 'Warm-up Generator',
      'es': '',
    },
    'f1s21xn3': {
      'en': 'Auto-create warm-up sets that won\'t count toward stats.',
      'es': '',
    },
    '914pplja': {
      'en': 'Target Weight (kg)',
      'es': '',
    },
    'rubwy8mq': {
      'en': 'Number of Warm-up Sets',
      'es': '',
    },
    'ydjwxhqd': {
      'en': 'Generate Warm-ups',
      'es': '',
    },
  },
  // setOptinBottom
  {
    'dympnzjt': {
      'en': 'Mark as Completed',
      'es': '',
    },
    '2xp09dpc': {
      'en': 'Enable Dropset',
      'es': '',
    },
    'k1oh44e3': {
      'en': 'Reset Set',
      'es': '',
    },
    '2s5q60x9': {
      'en': 'Delete Set',
      'es': '',
    },
  },
  // setAlert2
  {
    'ks1gvb8h': {
      'en': 'Close',
      'es': '',
    },
  },
  // rowOffline
  {
    '9ftmeg29': {
      'en': 'Sets',
      'es': 'Conjuntos',
    },
    'kp3q0g57': {
      'en': '-',
      'es': '',
    },
    'dwno1x40': {
      'en': '%',
      'es': '%',
    },
    'ojfjmqk7': {
      'en': 'Volume',
      'es': 'Volumen',
    },
    'nn0xmhvt': {
      'en': '-',
      'es': '',
    },
    'p3wq9jo6': {
      'en': 'Reps',
      'es': 'Representantes',
    },
    'qca2xxbu': {
      'en': '-',
      'es': '',
    },
    'ps3ilv9l': {
      'en': '%',
      'es': '%',
    },
    '2o0onau1': {
      'en': '-',
      'es': '',
    },
    'whzet04x': {
      'en': '%',
      'es': '%',
    },
  },
  // discardWorkout
  {
    'xfu8z0q6': {
      'en': 'Discard Workout',
      'es': 'Eliminar entrenamiento',
    },
    'zjnkx20k': {
      'en':
          'If you stop now, all progress from this workout will be discarded and not saved.',
      'es':
          '¿Estás seguro de que quieres eliminar este entrenamiento? Esta acción no se puede deshacer.',
    },
    'wjqy3mhv': {
      'en': 'Cancel',
      'es': 'Cancelar',
    },
    'tv7v5c6q': {
      'en': 'Discard',
      'es': 'Borrar',
    },
  },
  // editDelte2
  {
    '5v3p908u': {
      'en': 'Edit',
      'es': '',
    },
    'lt4dw8gk': {
      'en': 'Delete',
      'es': '',
    },
  },
  // deleteWorkoutLog
  {
    'ormpbssd': {
      'en': 'Delete Workout',
      'es': 'Eliminar entrenamiento',
    },
    'm7wx35rg': {
      'en':
          'This will permanently delete this workout and all of its sets from your history, stats, and charts. This action can’t be undone.',
      'es':
          '¿Estás seguro de que quieres eliminar este entrenamiento? Esta acción no se puede deshacer.',
    },
    'z7kuan1q': {
      'en': 'Cancel',
      'es': 'Cancelar',
    },
    'xx67eva2': {
      'en': 'Delete',
      'es': 'Borrar',
    },
  },
  // restShit
  {
    'tdmj1qot': {
      'en': 'Set Rest Time',
      'es': '',
    },
    '23soye9h': {
      'en': 'Set',
      'es': '',
    },
  },
  // exerciseComponeForEdit
  {
    'll11uggv': {
      'en': 'Superset',
      'es': '',
    },
    '6i971pli': {
      'en': 'Previous',
      'es': '',
    },
    'et510nqa': {
      'en': 'Time',
      'es': '',
    },
    'kelb741f': {
      'en': 'Reps',
      'es': '',
    },
    'uu87sx0m': {
      'en': 'Add set',
      'es': '',
    },
  },
  // workoutChangeCupertino
  {
    'g4bug6y8': {
      'en': 'Set',
      'es': '',
    },
  },
  // exerciseOptionsBottomShit
  {
    '3ie1fqhe': {
      'en': 'Replace Exercise',
      'es': '',
    },
    'ey92c3q1': {
      'en': 'Superset',
      'es': '',
    },
    'f77ruy09': {
      'en': 'Cancel Superset',
      'es': '',
    },
    '9gobu7gn': {
      'en': ' View History',
      'es': '',
    },
    'vd5qahaf': {
      'en': 'Smart Warm-up',
      'es': '',
    },
    '1n7nppmg': {
      'en': ' Warm-up',
      'es': '',
    },
    'a7m3slr9': {
      'en': 'Reorder',
      'es': '',
    },
    '1124vy71': {
      'en': 'Remove Exercise',
      'es': '',
    },
  },
  // removeExerciseFromWorkoutAlert
  {
    '65dazilr': {
      'en': 'Remove Exercise?',
      'es': 'Eliminar entrenamiento',
    },
    'ui9crfuv': {
      'en': 'This will delete the exercise and all its sets from this workout.',
      'es':
          '¿Estás seguro de que quieres eliminar este entrenamiento? Esta acción no se puede deshacer.',
    },
    't9ktsldg': {
      'en': 'Cancel',
      'es': 'Cancelar',
    },
    'p7i92tri': {
      'en': 'Remove',
      'es': 'Borrar',
    },
  },
  // discardAndStartNew
  {
    'vommgtbi': {
      'en': 'Start New Workout?',
      'es': 'Eliminar entrenamiento',
    },
    '2htduqvc': {
      'en':
          'Active workout in progress. Starting a new one will discard the current session and it won’t be saved.',
      'es':
          '¿Estás seguro de que quieres eliminar este entrenamiento? Esta acción no se puede deshacer.',
    },
    'v9pgpx3n': {
      'en': 'Cancel',
      'es': 'Cancelar',
    },
    'lmrbxvgx': {
      'en': 'Discard',
      'es': 'Borrar',
    },
  },
  // exerciseComponetForCreation
  {
    '9ymmex12': {
      'en': 'Superset',
      'es': '',
    },
    'wmvw3w87': {
      'en': 'Previous',
      'es': '',
    },
    'hlnkd0uc': {
      'en': 'Time',
      'es': '',
    },
    '5cwnstxr': {
      'en': 'Reps',
      'es': '',
    },
    'z2ocx9em': {
      'en': 'Add set',
      'es': '',
    },
  },
  // setRow2ForCreation
  {
    'dzdq7d11': {
      'en': '-',
      'es': '',
    },
  },
  // placeHolder
  {
    'ycy5ldvf': {
      'en': 'Get started by adding exercises to your workout',
      'es': '',
    },
  },
  // dropSetRowCreation
  {
    'owelj4tf': {
      'en': '',
      'es': '',
    },
    'wgcnqfa1': {
      'en': '0',
      'es': '',
    },
    'fbjldyne': {
      'en': '-',
      'es': '',
    },
  },
  // dropSetCreation
  {
    '7tx24w02': {
      'en': 'Drop',
      'es': '',
    },
  },
  // muscleGroupDropdown
  {
    'zd5ezlwq': {
      'en': 'Choose Muscle group',
      'es': 'Elija el grupo muscular',
    },
    '14ags065': {
      'en': 'Search Muscle',
      'es': '',
    },
    '8ohkudg0': {
      'en': 'Chest',
      'es': 'Pecho',
    },
    'eep2ajjb': {
      'en': 'Back',
      'es': 'Atrás',
    },
    'pil4ybsd': {
      'en': 'Shoulders',
      'es': 'Espalda',
    },
    'a7ytysem': {
      'en': 'Biceps',
      'es': 'Bíceps',
    },
    'uvit2zxh': {
      'en': 'Triceps',
      'es': 'Tríceps',
    },
    '1k0v70ww': {
      'en': 'Legs',
      'es': 'Piernas',
    },
    'r2nxw4nx': {
      'en': 'Core',
      'es': 'Centro',
    },
    'nh9nsrm4': {
      'en': 'Neck',
      'es': 'Cuello',
    },
    'gmnhasd6': {
      'en': 'Forearms',
      'es': 'antebrazos',
    },
  },
  // muscleGroupDropdownn
  {
    'adfa1kd3': {
      'en': 'Choose Muscle group',
      'es': 'Elija el grupo muscular',
    },
    'iu3ushok': {
      'en': 'Search Muscle',
      'es': '',
    },
    'bwz97t4x': {
      'en': 'All',
      'es': 'Todo',
    },
    'ryjw4m95': {
      'en': 'Chest',
      'es': 'Pecho',
    },
    'tmvg1man': {
      'en': 'Back',
      'es': 'Atrás',
    },
    '6rioitg0': {
      'en': 'Shoulders',
      'es': 'Espalda',
    },
    'vw86eez1': {
      'en': 'Biceps',
      'es': 'Bíceps',
    },
    'ubyy20rb': {
      'en': 'Triceps',
      'es': 'Tríceps',
    },
    'dywaendr': {
      'en': 'Legs',
      'es': 'Piernas',
    },
    'xpjmrh9d': {
      'en': 'Core',
      'es': 'Centro',
    },
    'iv1a8kse': {
      'en': 'Neck',
      'es': 'Cuello',
    },
    'y9186qxd': {
      'en': 'forearms',
      'es': 'antebrazos',
    },
  },
  // subMuscleBottomShit
  {
    'ah1oqfbm': {
      'en': 'Choose Muscle group',
      'es': 'Elija el grupo muscular',
    },
    'wleqw6qg': {
      'en': 'Search Muscle',
      'es': '',
    },
  },
  // exercyseTypeBottom
  {
    'c6nq8pf3': {
      'en': 'Choose Measure Type',
      'es': 'Elija el grupo muscular',
    },
    '76fu63t8': {
      'en': 'Weight & Reps',
      'es': '',
    },
    'u9jey59p': {
      'en': 'Example: Barbell Row, Dumbbell Press',
      'es': '',
    },
    'jp2s7nnh': {
      'en': 'REPS',
      'es': '',
    },
    '6f8jbcft': {
      'en': 'KG',
      'es': '',
    },
    'tona80u7': {
      'en': 'Bodyweight Reps',
      'es': '',
    },
    'yic05ndx': {
      'en': 'Example: Push-ups, Inverted Rows',
      'es': '',
    },
    'ykd8l7fm': {
      'en': 'REPS',
      'es': '',
    },
    'gzwswmtr': {
      'en': 'Assisted Bodyweight',
      'es': '',
    },
    '4ifjitvi': {
      'en': 'Example: Assisted Pull-ups',
      'es': '',
    },
    'a60bquvo': {
      'en': 'REPS',
      'es': '',
    },
    '2ybn8w6t': {
      'en': '-KG',
      'es': '',
    },
    'dtoqe37n': {
      'en': 'Duration (Time-based)',
      'es': '',
    },
    'eol2xyvf': {
      'en': 'Example:  Plank, Wall Hold',
      'es': '',
    },
    'jdqgvvat': {
      'en': 'TIME',
      'es': '',
    },
  },
  // bwScore
  {
    'yk5ya3cg': {
      'en': 'Bodyweight Performance',
      'es': '',
    },
    'q9zb1iao': {
      'en': '8 / 10',
      'es': '',
    },
    'vjngk12a': {
      'en':
          'Estimated score based on bodyweight, age, sex, and best set performance',
      'es': '',
    },
    'jmp1oid2': {
      'en': '',
      'es': '',
    },
  },
  // TimedExercisePicker
  {
    '2xc7yiix': {
      'en': 'Set Duration',
      'es': '',
    },
    'onfz9b2b': {
      'en': 'Set',
      'es': '',
    },
  },
  // manualForCreation
  {
    '5c4jdtk1': {
      'en': 'Countdown',
      'es': '',
    },
    'hmvt1nie': {
      'en': 'Manual Entry',
      'es': '',
    },
  },
  // exerciseOptionsBottomCreation
  {
    'pfh7j0ot': {
      'en': 'Replace Exercise',
      'es': '',
    },
    'zs7xb7je': {
      'en': 'Superset',
      'es': '',
    },
    '08uyqg3l': {
      'en': 'Cancel Superset',
      'es': '',
    },
    'pyeet36s': {
      'en': ' View History',
      'es': '',
    },
    'cn3rhfc4': {
      'en': 'Smart Warm-up',
      'es': '',
    },
    '4m774k9n': {
      'en': 'Reorder',
      'es': '',
    },
    'xap4qpe9': {
      'en': 'Remove Exercise',
      'es': '',
    },
  },
  // setOptinBottomCreation
  {
    'xe8b8nso': {
      'en': 'Enable Dropset',
      'es': '',
    },
    'ilh4iuye': {
      'en': 'Reset Set',
      'es': '',
    },
    'sz1mii4e': {
      'en': 'Delete Set',
      'es': '',
    },
  },
  // restShitCreation
  {
    'oylwv1ht': {
      'en': 'Set Rest Time',
      'es': '',
    },
    '9ub6x1jq': {
      'en': 'Set',
      'es': '',
    },
  },
  // exerciseOptionsBottomEdit
  {
    '8geuog8j': {
      'en': 'Replace Exercise',
      'es': '',
    },
    'jwcmvr9b': {
      'en': 'Superset',
      'es': '',
    },
    'q24v9kyr': {
      'en': ' View History',
      'es': '',
    },
    'qqj0lsek': {
      'en': 'Reorder',
      'es': '',
    },
    'iw69eigi': {
      'en': 'Remove Exercise',
      'es': '',
    },
  },
  // setOptinBottomEdit
  {
    'ynkepd29': {
      'en': 'Mark as Completed',
      'es': '',
    },
    'gxf13dst': {
      'en': 'Enable Dropset',
      'es': '',
    },
    'qbwttnya': {
      'en': 'Reset Set',
      'es': '',
    },
    'e9kwja1i': {
      'en': 'Delete Set',
      'es': '',
    },
  },
  // subMusclesFullCheckbox
  {
    'xa8cacxz': {
      'en': 'Choose Secondary Muscles',
      'es': 'Elija el grupo muscular',
    },
    'ds0rlszg': {
      'en': 'Search Muscle',
      'es': '',
    },
  },
  // exerciseComponetFornEdit2
  {
    'bgvd82s1': {
      'en': 'Previous',
      'es': '',
    },
    '24awmj9f': {
      'en': 'Time',
      'es': '',
    },
    '4rh2z48v': {
      'en': 'Reps',
      'es': '',
    },
    'tcjofx1a': {
      'en': 'Add set',
      'es': '',
    },
  },
  // TimeBottomShit
  {
    'bq3pk3y7': {
      'en': 'Pause',
      'es': '',
    },
    'nszgs0ic': {
      'en': 'Continue',
      'es': '',
    },
    '751ec3mi': {
      'en': '',
      'es': '',
    },
  },
  // timer3
  {
    'zols1ih5': {
      'en': '-5',
      'es': '',
    },
    '5qwcpps9': {
      'en': '+5',
      'es': '',
    },
    'lmgy1tcs': {
      'en': '',
      'es': '',
    },
    'e9m3cdeb': {
      'en': 'Pause',
      'es': '',
    },
    'h6h23c84': {
      'en': 'Continue',
      'es': '',
    },
  },
  // pieGraphPlaceHolder
  {
    'q9gcnfl6': {
      'en': 'No muscle data yet',
      'es': 'Sin datos de volumen',
    },
    'yspdh6mg': {
      'en': 'Train to unlock muscle distribution insights\n',
      'es':
          'Registra más entrenamientos para ver tu progreso a lo largo del tiempo.',
    },
  },
  // exerciseHistoryPlaceHolder
  {
    '5m1els28': {
      'en': 'No Sets Logged',
      'es': 'No hay conjuntos registrados',
    },
    '8xyf4f4m': {
      'en': 'Start training to build history for this exercise.',
      'es':
          'Empieza a entrenar para construir tu historial\npara este ejercicio.',
    },
  },
  // exerciseOptionsBottomWorklogEdit
  {
    '319wktrk': {
      'en': 'Replace Exercise',
      'es': '',
    },
    'da4yze35': {
      'en': ' View History',
      'es': '',
    },
    'b3e8klu3': {
      'en': 'Reorder',
      'es': '',
    },
    'sj0h47m0': {
      'en': 'Remove Exercise',
      'es': '',
    },
  },
  // sexBottomshit
  {
    'ywviqcp9': {
      'en': 'Sex',
      'es': '',
    },
    'bfgcdmct': {
      'en': 'Male',
      'es': '',
    },
    'o7kr95wo': {
      'en': 'Female',
      'es': '',
    },
    'ilj2iz7k': {
      'en': 'Prefer not to say',
      'es': '',
    },
  },
  // birthdayCupertino
  {
    '2ocbjinm': {
      'en': 'Set Birthday',
      'es': '',
    },
    'yza23b3j': {
      'en': 'Set',
      'es': '',
    },
  },
  // weightCupertino
  {
    'zfexz58p': {
      'en': 'Set Weight',
      'es': '',
    },
    'smw7i5ce': {
      'en': 'Set',
      'es': '',
    },
  },
  // heightCupertino
  {
    'ycmnnsvy': {
      'en': 'Set Height',
      'es': '',
    },
    'ggprypj5': {
      'en': 'Set',
      'es': '',
    },
  },
  // muscleLineGraphPlc
  {
    '34wwdwhd': {
      'en': 'No muscle volume data',
      'es': 'No hay entrenamientos todavía',
    },
    '7jqishjh': {
      'en': 'Log workouts for this muscle to see volume over time.\n',
      'es': 'Tu historial de entrenamiento aparecerá una vez que comiences.',
    },
  },
  // updateUnits
  {
    '52zgqb2u': {
      'en': 'Update Units',
      'es': '',
    },
    'hbz5nb24': {
      'en': 'Workout Weight Unit',
      'es': '',
    },
    '9q0gx6vt': {
      'en': 'Kg',
      'es': '',
    },
    'orrha1ha': {
      'en': 'Lbs',
      'es': '',
    },
    'i7n6pbj9': {
      'en': 'Height Unit',
      'es': '',
    },
    'sov8d9oy': {
      'en': 'Cm',
      'es': '',
    },
    '4qudj0hz': {
      'en': 'In',
      'es': '',
    },
    '1bzsfojj': {
      'en': 'Body Weight Unit',
      'es': '',
    },
    '1xus34xa': {
      'en': 'Kg',
      'es': '',
    },
    '6091v3z2': {
      'en': 'Lbs',
      'es': '',
    },
  },
  // dropSetRowEdit
  {
    'dbpo0f5d': {
      'en': '',
      'es': '',
    },
    'zejd8gy3': {
      'en': '0',
      'es': '',
    },
    'rc44gepq': {
      'en': '',
      'es': '',
    },
  },
  // dropSetCreationEdit
  {
    'm6qyuccz': {
      'en': 'Drop',
      'es': '',
    },
  },
  // warmupBottomStupid
  {
    'wicgutx3': {
      'en': 'Warm-up Generator',
      'es': '',
    },
    '749xfqs1': {
      'en': 'create warm-up sets that won\'t count toward stats.',
      'es': '',
    },
    'hi1h3y8i': {
      'en': 'Number of Warm-up Sets',
      'es': '',
    },
    'x84vsz6v': {
      'en': 'Generate Warm-ups',
      'es': '',
    },
  },
  // timeWarmup
  {
    '1lo0yc93': {
      'en': '0',
      'es': '',
    },
    'rq0gl2ar': {
      'en': '0',
      'es': '',
    },
    '2a81eiw6': {
      'en': ':',
      'es': '',
    },
    'gnwfyj6b': {
      'en': '0',
      'es': '',
    },
    'x4m6f9nc': {
      'en': '0',
      'es': '',
    },
  },
  // deopSetRowEdit
  {
    'yw0b505z': {
      'en': '',
      'es': '',
    },
    '6u0mwilc': {
      'en': '',
      'es': '',
    },
  },
  // workoutForRoutine
  {
    'fz58f7lq': {
      'en': '1x / week',
      'es': '',
    },
    'v0vij56s': {
      'en': 'Select...',
      'es': '',
    },
    'bj1hmvux': {
      'en': 'Search...',
      'es': '',
    },
    '91fd56md': {
      'en': '1x / week',
      'es': '',
    },
    'a2c3qhbw': {
      'en': '2x / week',
      'es': '',
    },
    'pm42urdz': {
      'en': '3x / week',
      'es': '',
    },
    'gqib0tgv': {
      'en': '4x / week',
      'es': '',
    },
    'c2qktuwm': {
      'en': '5x / week',
      'es': '',
    },
    'rmylbiog': {
      'en': 'Minimum rest between sessions',
      'es': '',
    },
    'r60t74fk': {
      'en': 'Select...',
      'es': '',
    },
    'mr2jzhfy': {
      'en': 'Search...',
      'es': '',
    },
    'm6yhw1id': {
      'en': '24 hours',
      'es': '',
    },
    'upkl14d4': {
      'en': '48 hours',
      'es': '',
    },
    'iw9gl7kx': {
      'en': '72 hours',
      'es': '',
    },
  },
  // addWorkoutForDayBottom
  {
    'l9xmaqdt': {
      'en': 'Select a workout',
      'es': '',
    },
    '7464i85u': {
      'en': 'Choose one workout to assign to this day',
      'es': '',
    },
    'f4aaktaf': {
      'en': 'Assign',
      'es': '',
    },
  },
  // ReplaceWorkoutForDayBottom
  {
    '8a4as6fs': {
      'en': 'Select a workout',
      'es': '',
    },
    'hpsmzrzq': {
      'en': 'Choose one workout to replace this day',
      'es': '',
    },
    'kp4u6rjw': {
      'en': 'Assign',
      'es': '',
    },
  },
  // timeRangeShit
  {
    'w6m4dcqj': {
      'en': 'Select Time Range',
      'es': '',
    },
    '3lxbgng4': {
      'en': 'Last 7 days',
      'es': '',
    },
    '7gn42928': {
      'en': 'Last 30 days',
      'es': '',
    },
    '9wh2mlcf': {
      'en': 'Last 90 days',
      'es': '',
    },
    'hjnaibzv': {
      'en': 'Last 90 days',
      'es': '',
    },
    'xj8wq696': {
      'en': 'All time',
      'es': '',
    },
    'jih0n23h': {
      'en': 'All time',
      'es': '',
    },
  },
  // upgradeAlert
  {
    'jxftyfaq': {
      'en': 'Custom exercises are limited',
      'es': '',
    },
    '1q7dwdh6': {
      'en':
          'Free users can create up to 3 custom exercises.\nUpgrade to Premium to create unlimited exercises and personalize your workouts.',
      'es': '',
    },
    'mrqct4yj': {
      'en': 'Upgrade to Premium',
      'es': '',
    },
    '2vf63o13': {
      'en': 'Not now',
      'es': '',
    },
  },
  // Delte2
  {
    '2ojjtj9j': {
      'en': 'Delete',
      'es': '',
    },
  },
  // deleteExercise
  {
    'fuhicpez': {
      'en': 'Delete Custom Exercise',
      'es': 'Eliminar entrenamiento',
    },
    'jlfqlcq1': {
      'en':
          'This custom exercise will be removed from your list. Past workouts and stats that used it will stay saved.',
      'es':
          '¿Estás seguro de que quieres eliminar este entrenamiento? Esta acción no se puede deshacer.',
    },
    'hd7ahwts': {
      'en': 'Cancel',
      'es': 'Cancelar',
    },
    'vcvh94rz': {
      'en': 'Delete',
      'es': 'Borrar',
    },
  },
  // analyze2App
  {
    'cuvhfwqw': {
      'en': 'Total Reps',
      'es': '',
    },
    'aalh08x1': {
      'en': 'Proper Reps',
      'es': '',
    },
    'xhml6uxq': {
      'en': 'Form Tip',
      'es': '',
    },
    'nn6qj8v8': {
      'en': 'View Video',
      'es': '',
    },
    'bp2brhck': {
      'en': 'Feedback',
      'es': '',
    },
    'lp65zhwj': {
      'en': 'Continue Workout',
      'es': '',
    },
  },
  // analysiAlert
  {
    '2aibzhq7': {
      'en': 'Retry',
      'es': '',
    },
    'wqdff70u': {
      'en': 'Retake video',
      'es': '',
    },
  },
  // deleteAccount
  {
    '0aknee49': {
      'en': 'Delete Account?',
      'es': '',
    },
    'ow3dgd6r': {
      'en':
          'This will permanently delete your account and all your data — workouts, logs, and progress. This action cannot be undone.',
      'es': '',
    },
    'kkd3q2cz': {
      'en': 'Cancel',
      'es': 'Cancelar',
    },
    '5uk86ssy': {
      'en': 'Delete',
      'es': 'Borrar',
    },
  },
  // createWorkoutBottom
  {
    'xt416705': {
      'en': 'New Workout',
      'es': '',
    },
    'ajyzoqnd': {
      'en': 'How do you want to build it?',
      'es': '',
    },
    '7naska68': {
      'en': 'Build manually',
      'es': '',
    },
    '4cff1cpd': {
      'en': 'Pick your own exercises',
      'es': '',
    },
    'aa6piccz': {
      'en': 'Generate with AI',
      'es': '',
    },
    '5gu3t3uk': {
      'en': 'SMART',
      'es': '',
    },
    '8hb4tok4': {
      'en': 'A plan built for you',
      'es': '',
    },
  },
  // discardUiWorkout
  {
    '975zplta': {
      'en': 'Discard workout?',
      'es': 'Eliminar entrenamiento',
    },
    'emg853rx': {
      'en': 'This workout won\'t be saved. You can always generate a new one.',
      'es':
          '¿Estás seguro de que quieres eliminar este entrenamiento? Esta acción no se puede deshacer.',
    },
    'gie118kq': {
      'en': 'Cancel',
      'es': 'Cancelar',
    },
    'e57wwhu4': {
      'en': 'Discard',
      'es': 'Borrar',
    },
  },
  // discardSetAnalysis
  {
    'rentfs2a': {
      'en': 'Delete analysis?',
      'es': 'Eliminar entrenamiento',
    },
    'd21734ve': {
      'en':
          'The analysis and its video will be removed. You\'ll need to record again to re-analyze.',
      'es':
          '¿Estás seguro de que quieres eliminar este entrenamiento? Esta acción no se puede deshacer.',
    },
    'dflw2a2u': {
      'en': 'Cancel',
      'es': 'Cancelar',
    },
    'mgvxa798': {
      'en': 'Discard',
      'es': 'Borrar',
    },
  },
  // analyze2AppAfter
  {
    's1sqhrs6': {
      'en': 'Total Reps',
      'es': '',
    },
    'k5mks4ti': {
      'en': 'Proper Reps',
      'es': '',
    },
    '4h9vuh5a': {
      'en': 'Form Tip',
      'es': '',
    },
    'iyh9kiby': {
      'en': 'Feedback',
      'es': '',
    },
  },
  // FeatureRow
  {
    '574uod45': {
      'en': '—',
      'es': '',
    },
  },
  // PriceCard
  {
    '8gj007xu': {
      'en': 'BEST VALUE',
      'es': '',
    },
  },
  // warmupBottomShitCreation
  {
    'nhvhelsu': {
      'en': 'Warm-up Generator',
      'es': '',
    },
    'oykv34vp': {
      'en': 'Auto-create warm-up sets that won\'t count toward stats.',
      'es': '',
    },
    '8l2x1g6t': {
      'en': 'Target Weight (kg)',
      'es': '',
    },
    '5kzxkpqt': {
      'en': 'Number of Warm-up Sets',
      'es': '',
    },
    'uv8au2l4': {
      'en': 'Generate Warm-ups',
      'es': '',
    },
  },
  // CleanMinimalAlert2
  {
    'zjehw6bv': {
      'en': 'Notifications are off',
      'es': '',
    },
    'p1oi08v6': {
      'en': 'Turn on notifications to get an alert when your rest timer ends.',
      'es': '',
    },
    'dwwarzte': {
      'en': 'Open Settings',
      'es': '',
    },
    'ap6c6a5o': {
      'en': 'Not now',
      'es': '',
    },
  },
  // setRowWarmUpCreation
  {
    'g57k0wto': {
      'en': '-',
      'es': '60 kilos *5',
    },
    '4vdz6ylw': {
      'en': '-',
      'es': '',
    },
  },
  // muscleGroupDropdown2
  {
    'kflnehx4': {
      'en': 'Choose Muscle group',
      'es': 'Elija el grupo muscular',
    },
    'qbhrcraq': {
      'en': 'Search Muscle',
      'es': '',
    },
    'gxy68zb3': {
      'en': 'All',
      'es': 'Todo',
    },
    'zs1me8wf': {
      'en': 'Chest',
      'es': 'Pecho',
    },
    '5tihkbf4': {
      'en': 'Back',
      'es': 'Atrás',
    },
    'u53estgp': {
      'en': 'Shoulders',
      'es': 'Espalda',
    },
    'i48hvz7b': {
      'en': 'Biceps',
      'es': 'Bíceps',
    },
    'ojtp1m23': {
      'en': 'Triceps',
      'es': 'Tríceps',
    },
    'yi73cv0s': {
      'en': 'Legs',
      'es': 'Piernas',
    },
    'jyuw0wyj': {
      'en': 'Core',
      'es': 'Centro',
    },
    'iaqq5xak': {
      'en': 'Neck',
      'es': 'Cuello',
    },
    '5ngt1ou1': {
      'en': 'Forearms',
      'es': 'antebrazos',
    },
  },
  // BottomSheetNoFreeLeft
  {
    '0m2dr2jq': {
      'en': 'You\'re out of free checks',
      'es': '',
    },
    '9t3xj4yw': {
      'en':
          'Pro includes unlimited AI form analysis, rep-by-rep breakdowns and progress tracking.',
      'es': '',
    },
    'thmovivw': {
      'en': 'Go pro - unlimited checks',
      'es': '',
    },
    'cdm0newf': {
      'en': 'Maybe later',
      'es': '',
    },
  },
  // discardAndStartNewAnalysis
  {
    '21tcizw9': {
      'en': 'Start New Workout?',
      'es': 'Eliminar entrenamiento',
    },
    'go2bivur': {
      'en':
          'Active workout in progress. Starting a new one will discard the current session and it won’t be saved.',
      'es':
          '¿Estás seguro de que quieres eliminar este entrenamiento? Esta acción no se puede deshacer.',
    },
    't0k66yob': {
      'en': 'Cancel',
      'es': 'Cancelar',
    },
    'd3laaf6k': {
      'en': 'Discard',
      'es': 'Borrar',
    },
  },
  // timerCountUp
  {
    'g9116w2n': {
      'en': 'Done',
      'es': '',
    },
  },
  // video2Full
  {
    'l1rtvqcg': {
      'en': 'Analyzed Video',
      'es': '',
    },
    'nvnj0uic': {
      'en': 'Download Original Video',
      'es': '',
    },
  },
  // BottomSheetNoFreeTemplates
  {
    'dlf9vuoc': {
      'en': 'Workout slots are full',
      'es': '',
    },
    'oee4cgby': {
      'en':
          'Free includes 3 saved workouts. Go Pro for unlimited — or free up a slot by deleting one',
      'es': '',
    },
    'wqrggdhn': {
      'en': 'Go Pro — unlimited workouts',
      'es': '',
    },
    '7u8hn702': {
      'en': 'Manage my workouts',
      'es': '',
    },
  },
  // analysisHome
  {
    'fu74461j': {
      'en': 'Quick Form Check',
      'es': '',
    },
    'ojaod5ts': {
      'en': 'Record a set, get instant AI feedback',
      'es': '',
    },
  },
  // EmptyState
  {
    'pyh9f1zv': {
      'en': 'No exercises yet',
      'es': '',
    },
    'qbl2v59l': {
      'en': 'Add your first exercise to start building this workout',
      'es': '',
    },
  },
  // thankForPremium
  {
    'abutzm2s': {
      'en': 'Welcome to Premium',
      'es': '',
    },
    'jcju5z7e': {
      'en': 'Thanks for supporting the app. All features are now unlocked.',
      'es': '',
    },
    '3nkgtb18': {
      'en': 'continue',
      'es': '',
    },
  },
  // deleteSetAnalysis
  {
    '6wzs2mf0': {
      'en': 'Delete this analysis?',
      'es': 'Eliminar entrenamiento',
    },
    'r8ci5ogt': {
      'en':
          'This permanently removes the form score and feedback for this set. Your set stays in history.',
      'es':
          '¿Estás seguro de que quieres eliminar este entrenamiento? Esta acción no se puede deshacer.',
    },
    'qmxyin6k': {
      'en': 'Cancel',
      'es': 'Cancelar',
    },
    'ftweamer': {
      'en': 'Delete',
      'es': 'Borrar',
    },
  },
  // Miscellaneous
  {
    'puqvmecu': {
      'en': '',
      'es': '',
    },
    'k7zrocf6': {
      'en': 'g',
      'es': '',
    },
    '7n7jdtmv': {
      'en': '',
      'es': '',
    },
    'nevaih88': {
      'en':
          'We use your camera to track your form and count reps during your workout.\n',
      'es': '',
    },
    'zk63ynvm': {
      'en':
          '\n We use your microphone to capture sound with your workout videos (no talking needed!).',
      'es': '',
    },
    '0hnogjqz': {
      'en':
          'we save your workout videos to your device so you can review your progress anytime.',
      'es': '',
    },
    's9lvuq67': {
      'en': 'We use notifications to remind you when rest ends.\n',
      'es': '',
    },
    '22fhjbdl': {
      'en': '',
      'es': '',
    },
    'cj3gzz43': {
      'en': '',
      'es': '',
    },
    'o8mq5s7w': {
      'en': '',
      'es': '',
    },
    '2s0bj32k': {
      'en': '',
      'es': '',
    },
    'irn9cqdg': {
      'en': '',
      'es': '',
    },
    'gp2d7s7r': {
      'en': '',
      'es': '',
    },
    '013p3v7t': {
      'en': '',
      'es': '',
    },
    'utqxzq7r': {
      'en': '',
      'es': '',
    },
    '5yhw60ve': {
      'en': '',
      'es': '',
    },
    '9u1m6h3e': {
      'en': '',
      'es': '',
    },
    '4rw4l8e2': {
      'en': '',
      'es': '',
    },
    'sefamf0q': {
      'en': '',
      'es': '',
    },
    '1zzl8k79': {
      'en': '',
      'es': '',
    },
    '63r30oav': {
      'en': '',
      'es': '',
    },
    'ig5egybp': {
      'en': '',
      'es': '',
    },
    'aqvcnihk': {
      'en': '',
      'es': '',
    },
    'l0gc5kml': {
      'en': '',
      'es': '',
    },
    '6xi1ymro': {
      'en': '',
      'es': '',
    },
    'mojgv1vm': {
      'en': '',
      'es': '',
    },
    'ms3ynjkj': {
      'en': '',
      'es': '',
    },
    'l53au2hz': {
      'en': '',
      'es': '',
    },
    'egl69wtn': {
      'en': '',
      'es': '',
    },
    'co85of5h': {
      'en': '',
      'es': '',
    },
    'gmdc9b7n': {
      'en': '',
      'es': '',
    },
    '1h3phtym': {
      'en': '',
      'es': '',
    },
  },
].reduce((a, b) => a..addAll(b));
