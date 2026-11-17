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

import 'dart:io';
import 'dart:ui' as ui show TextDirection;
import 'package:flutter/cupertino.dart'
    show
        CupertinoDatePicker,
        CupertinoDatePickerMode,
        CupertinoPicker,
        CupertinoTheme,
        CupertinoThemeData,
        CupertinoTextThemeData;
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart' as intl show DateFormat;
import 'package:path_provider/path_provider.dart';

/// The whole "Edit Profile" page as one self-managed widget: header (back,
/// title, Save), profile photo, user name, sex, date of birth, height, weight
/// and the units line.
///
/// Every picker (photo source, sex, date, height, weight) is built in - no
/// other bottom sheets or format functions are needed.
///
/// It does NOT read or write the database. It shows the values it is given,
/// keeps the edits to itself, and hands everything back in ONE callback when
/// Save is tapped.
///
/// Values in (all optional - bind them to the user row): - username, sex,
/// dateOfBirth (any text DateTime can parse, or epoch ms) - height +
/// heightIsCm  (height is cm, or TOTAL inches when heightIsCm is false) -
/// weight + weightIsKg  (weight is kg, or lb when weightIsKg is false) -
/// photoFileName        (bare file name inside the app Documents folder)
/// Values that arrive after the first build (a query on page load) are picked
/// up as long as the user has not started editing.
///
/// Callbacks: - onBack() - onSave(username, sex, dateOfBirth, height,
/// heightIsCm, weight, weightIsKg, workoutIsKg, photo) - nine separate
/// values, in this order: username (String), sex (String: "Male" / "Female" /
/// "Prefer not to say" / ""), dateOfBirth (String "yyyy-MM-dd" or ""), height
/// (double, 0 when empty), heightIsCm (bool), weight (double, 0 when empty),
/// weightIsKg (bool), workoutIsKg (bool), photo (String file name or ""). A
/// picked photo (downscaled to 512px) only changes what the page shows; its
/// file name comes back in `photo` on save. Photo files that are not the
/// saved one are removed the next time the page opens. -
/// onUnitsChanged(units): a unit was switched in the units sheet. JSON with
/// workout_is_kg, height_is_cm, body_is_kg - for saving the preference right
/// away. The workout unit is also written to App State `isKg` here.
///
/// Switching a unit converts the number on screen (175 cm -> 69 in).
///
/// Localization: reads the app language from FFLocalizations (no parameter).
/// Hebrew renders RTL.
class ProfileEditView extends StatefulWidget {
  const ProfileEditView({
    super.key,
    this.width,
    this.height,
    this.username,
    this.sex,
    this.dateOfBirth,
    this.bodyHeight,
    this.heightIsCm,
    this.weight,
    this.weightIsKg,
    this.photoFileName,
    this.onBack,
    this.onSave,
    this.onUnitsChanged,
  });

  final double? width;
  final double? height;
  final String? username;
  final String? sex;
  final String? dateOfBirth;

  /// The user's height: cm, or total inches when [heightIsCm] is false.
  /// (Named bodyHeight because `height` is the widget's own size.)
  final double? bodyHeight;
  final bool? heightIsCm;
  final double? weight;
  final bool? weightIsKg;
  final String? photoFileName;

  final Future Function()? onBack;
  final Future Function(
    String username,
    String sex,
    String dateOfBirth,
    double height,
    bool heightIsCm,
    double weight,
    bool weightIsKg,
    bool workoutIsKg,
    String photo,
  )? onSave;
  final Future Function(dynamic units)? onUnitsChanged;

  @override
  State<ProfileEditView> createState() => _ProfileEditViewState();
}

const Set<String> _kRtl = {"he", "ar"};

const Map<String, Map<String, String>> _kStrings = {
  "title": {
    "en": "Edit Profile",
    "es": "Editar perfil",
    "he": "עריכת פרופיל",
    "de": "Profil bearbeiten",
    "fr": "Modifier le profil",
  },
  "save": {
    "en": "Save",
    "es": "Guardar",
    "he": "שמירה",
    "de": "Speichern",
    "fr": "Enregistrer",
  },
  "changePhoto": {
    "en": "Change photo",
    "es": "Cambiar foto",
    "he": "שינוי תמונה",
    "de": "Foto ändern",
    "fr": "Changer la photo",
  },
  "photoTitle": {
    "en": "Profile photo",
    "es": "Foto de perfil",
    "he": "תמונת פרופיל",
    "de": "Profilfoto",
    "fr": "Photo de profil",
  },
  "takePhoto": {
    "en": "Take a photo",
    "es": "Hacer una foto",
    "he": "צילום תמונה",
    "de": "Foto aufnehmen",
    "fr": "Prendre une photo",
  },
  "fromGallery": {
    "en": "Choose from gallery",
    "es": "Elegir de la galería",
    "he": "בחירה מהגלריה",
    "de": "Aus Galerie wählen",
    "fr": "Choisir dans la galerie",
  },
  "account": {
    "en": "Account",
    "es": "Cuenta",
    "he": "חשבון",
    "de": "Konto",
    "fr": "Compte",
  },
  "username": {
    "en": "User name",
    "es": "Nombre de usuario",
    "he": "שם משתמש",
    "de": "Benutzername",
    "fr": "Nom d’utilisateur",
  },
  "personal": {
    "en": "Personal",
    "es": "Personal",
    "he": "אישי",
    "de": "Persönlich",
    "fr": "Personnel",
  },
  "sex": {
    "en": "Sex",
    "es": "Sexo",
    "he": "מין",
    "de": "Geschlecht",
    "fr": "Sexe",
  },
  "male": {
    "en": "Male",
    "es": "Hombre",
    "he": "זכר",
    "de": "Männlich",
    "fr": "Homme",
  },
  "female": {
    "en": "Female",
    "es": "Mujer",
    "he": "נקבה",
    "de": "Weiblich",
    "fr": "Femme",
  },
  "noSay": {
    "en": "Prefer not to say",
    "es": "Prefiero no decirlo",
    "he": "לא רוצה לציין",
    "de": "Keine Angabe",
    "fr": "Je préfère ne pas le dire",
  },
  "birthday": {
    "en": "Date of birth",
    "es": "Fecha de nacimiento",
    "he": "תאריך לידה",
    "de": "Geburtsdatum",
    "fr": "Date de naissance",
  },
  "measures": {
    "en": "Measurements",
    "es": "Medidas",
    "he": "מידות",
    "de": "Maße",
    "fr": "Mesures",
  },
  "heightLabel": {
    "en": "Height",
    "es": "Altura",
    "he": "גובה",
    "de": "Größe",
    "fr": "Taille",
  },
  "weightLabel": {
    "en": "Weight",
    "es": "Peso",
    "he": "משקל",
    "de": "Gewicht",
    "fr": "Poids",
  },
  "select": {
    "en": "Select",
    "es": "Elegir",
    "he": "בחירה",
    "de": "Wählen",
    "fr": "Choisir",
  },
  "confirm": {
    "en": "Done",
    "es": "Listo",
    "he": "אישור",
    "de": "Fertig",
    "fr": "OK",
  },
  "kg": {"en": "kg", "es": "kg", "he": "ק״ג", "de": "kg", "fr": "kg"},
  "lbs": {"en": "lbs", "es": "lb", "he": "ליב׳", "de": "lbs", "fr": "lb"},
  "cm": {"en": "cm", "es": "cm", "he": "ס״מ", "de": "cm", "fr": "cm"},
};

String _tr(String lang, String key) {
  final Map<String, String>? m = _kStrings[key];
  if (m == null) return key;
  return m[lang] ?? m["en"] ?? key;
}

String _langOf(BuildContext ctx) {
  try {
    final String l = FFLocalizations.of(ctx).languageCode.trim().toLowerCase();
    return l.isEmpty ? "en" : l;
  } catch (_) {
    return "en";
  }
}

/// Left-to-right isolate: keeps a number intact inside a Hebrew line.
String _ltr(String s) => "⁦" + s + "⁩";

const double _kLbPerKg = 2.20462;
const double _kCmPerInch = 2.54;

// Stored values of the sex field (English, stable).
const String _kMale = "Male";
const String _kFemale = "Female";
const String _kNoSay = "Prefer not to say";

class _ProfileEditViewState extends State<ProfileEditView> {
  final TextEditingController _nameCtrl = TextEditingController();
  final FocusNode _nameFocus = FocusNode();

  String _sex = "";
  DateTime? _birthday;
  double? _height; // cm, or total inches when !_heightCm
  bool _heightCm = true;
  double? _weight; // kg, or lb when !_weightKg
  bool _weightKg = true;
  String _photo = "";

  String? _docsPath;
  bool _touched = false; // the user changed something: stop following params
  bool _saving = false;
  bool _sheetOpen = false;

  @override
  void initState() {
    super.initState();
    _seed();
    _loadDocs();
  }

  @override
  void didUpdateWidget(covariant ProfileEditView old) {
    super.didUpdateWidget(old);
    final bool changed = old.username != widget.username ||
        old.sex != widget.sex ||
        old.dateOfBirth != widget.dateOfBirth ||
        old.bodyHeight != widget.bodyHeight ||
        old.heightIsCm != widget.heightIsCm ||
        old.weight != widget.weight ||
        old.weightIsKg != widget.weightIsKg;
    // values that arrive after the first build (page-load query)
    if (changed && !_touched) _seed();
    if (old.photoFileName != widget.photoFileName) {
      _photo = (widget.photoFileName ?? "").trim();
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  // ---------- values in ----------
  static String _sexKey(String? raw) {
    final String s = (raw ?? "").trim().toLowerCase();
    if (s.isEmpty) return "";
    if (s == "male" || s == "m") return _kMale;
    if (s == "female" || s == "f") return _kFemale;
    return _kNoSay;
  }

  static DateTime? _parseDate(String? raw) {
    String s = (raw ?? "").trim();
    if (s.isEmpty) return null;
    if (RegExp(r"^\d+$").hasMatch(s)) {
      final int? ms = int.tryParse(s);
      if (ms == null) return null;
      return DateTime.fromMillisecondsSinceEpoch(ms).toLocal();
    }
    if (s.length > 10 && s[10] == " ") s = s.replaceFirst(" ", "T");
    final DateTime? d = DateTime.tryParse(s);
    if (d == null) return null;
    final DateTime local = d.isUtc ? d.toLocal() : d;
    return DateTime(local.year, local.month, local.day);
  }

  void _seed() {
    final String name = (widget.username ?? "").trim();
    if (_nameCtrl.text != name) _nameCtrl.text = name;
    _sex = _sexKey(widget.sex);
    _birthday = _parseDate(widget.dateOfBirth);
    _heightCm = widget.heightIsCm ?? true;
    _weightKg = widget.weightIsKg ?? true;
    final double h = widget.bodyHeight ?? 0;
    _height = h > 0 ? h : null;
    final double w = widget.weight ?? 0;
    _weight = w > 0 ? w : null;
    _photo = (widget.photoFileName ?? "").trim();
  }

  Future<void> _loadDocs() async {
    try {
      final Directory d = await getApplicationDocumentsDirectory();
      if (mounted) setState(() => _docsPath = d.path);
      // Remove photos that were picked earlier and never saved. Only when the
      // saved file name is known, so the photo in use is never deleted.
      final String keep = (widget.photoFileName ?? "").trim();
      if (keep.isEmpty) return;
      for (final FileSystemEntity e in d.listSync()) {
        if (e is! File) continue;
        final String name = e.path.split(Platform.pathSeparator).last;
        if (!name.startsWith("profile_") || name == keep) continue;
        try {
          await e.delete();
        } catch (_) {}
      }
    } catch (_) {}
  }

  bool get _workoutKg {
    try {
      return FFAppState().isKg;
    } catch (_) {
      return true;
    }
  }

  // ---------- text ----------
  TextStyle _st(double size, FontWeight w, Color c) {
    final th = FlutterFlowTheme.of(context);
    return th.bodyMedium.override(
      fontFamily: th.bodyMediumFamily,
      color: c,
      fontSize: size,
      fontWeight: w,
      letterSpacing: 0,
      useGoogleFonts: GoogleFonts.asMap().containsKey(th.bodyMediumFamily),
    );
  }

  static String _num1(double v) {
    final double r = (v * 10).round() / 10;
    if (r == r.roundToDouble()) return r.toInt().toString();
    return r.toStringAsFixed(1);
  }

  String _sexText(String lang) {
    if (_sex == _kMale) return _tr(lang, "male");
    if (_sex == _kFemale) return _tr(lang, "female");
    if (_sex == _kNoSay) return _tr(lang, "noSay");
    return "";
  }

  String _birthdayText(String lang) {
    final DateTime? d = _birthday;
    if (d == null) return "";
    try {
      return intl.DateFormat.yMMMd(lang).format(d);
    } catch (_) {
      return d.day.toString() +
          "/" +
          d.month.toString() +
          "/" +
          d.year.toString();
    }
  }

  String _heightText(String lang) {
    final double? h = _height;
    if (h == null || h <= 0) return "";
    if (_heightCm) return _ltr(_num1(h)) + " " + _tr(lang, "cm");
    final int total = h.round();
    // feet and inches: 5′ 7″
    return _ltr(
        (total ~/ 12).toString() + "′ " + (total % 12).toString() + "″");
  }

  String _weightText(String lang) {
    final double? w = _weight;
    if (w == null || w <= 0) return "";
    return _ltr(_num1(w)) + " " + _tr(lang, _weightKg ? "kg" : "lbs");
  }

  // ---------- sheets ----------
  Future<T?> _sheet<T>(Widget Function(BuildContext ctx) builder) async {
    if (_sheetOpen) return null;
    _sheetOpen = true;
    FocusScope.of(context).unfocus();
    HapticFeedback.selectionClick();
    final String lang = _langOf(context);
    final bool rtl = _kRtl.contains(lang);
    try {
      return await showModalBottomSheet<T>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => Directionality(
          textDirection: rtl ? ui.TextDirection.rtl : ui.TextDirection.ltr,
          child: builder(ctx),
        ),
      );
    } finally {
      _sheetOpen = false;
    }
  }

  /// Sheet shell: rounded top, grab handle, title, then [children].
  Widget _shell(BuildContext ctx, String title, List<Widget> children) {
    final th = FlutterFlowTheme.of(ctx);
    final double bottom = MediaQuery.of(ctx).padding.bottom;
    return Container(
      decoration: BoxDecoration(
        color: th.secondaryBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
      ),
      padding: EdgeInsets.only(top: 10, bottom: 16 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: th.alternate,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(title,
              textAlign: TextAlign.center,
              style: _st(18, FontWeight.w600, th.primaryText)),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }

  Widget _confirmButton(BuildContext ctx, String lang, VoidCallback onTap) {
    final th = FlutterFlowTheme.of(ctx);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Container(
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: th.primary,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(_tr(lang, "confirm"),
              style: _st(17, FontWeight.w700, Colors.white)),
        ),
      ),
    );
  }

  Future<void> _pickSex() async {
    final String lang = _langOf(context);
    final String? picked = await _sheet<String>((ctx) {
      final th = FlutterFlowTheme.of(ctx);
      Widget row(String key, String value) {
        final bool sel = _sex == value;
        return InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            Navigator.of(ctx).pop(value);
          },
          child: SizedBox(
            height: 56,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Expanded(
                    child: Text(_tr(lang, key),
                        style: _st(16, sel ? FontWeight.w600 : FontWeight.w400,
                            th.primaryText)),
                  ),
                  if (sel)
                    Icon(Icons.check_rounded, size: 22, color: th.primary),
                ],
              ),
            ),
          ),
        );
      }

      Widget line() => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Divider(height: 1, thickness: 1, color: th.alternate),
          );

      return _shell(ctx, _tr(lang, "sex"), [
        row("male", _kMale),
        line(),
        row("female", _kFemale),
        line(),
        row("noSay", _kNoSay),
      ]);
    });
    if (picked == null || !mounted) return;
    setState(() {
      _sex = picked;
      _touched = true;
    });
  }

  Future<void> _pickBirthday() async {
    final String lang = _langOf(context);
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    DateTime current = _birthday ?? DateTime(2000, 1, 1);
    if (current.isAfter(today)) current = today;
    final DateTime? picked = await _sheet<DateTime>((ctx) {
      final th = FlutterFlowTheme.of(ctx);
      final bool dark = Theme.of(ctx).brightness == Brightness.dark;
      return _shell(ctx, _tr(lang, "birthday"), [
        SizedBox(
          height: 200,
          child: CupertinoTheme(
            data: CupertinoThemeData(
              brightness: dark ? Brightness.dark : Brightness.light,
              textTheme: CupertinoTextThemeData(
                dateTimePickerTextStyle:
                    _st(20, FontWeight.w500, th.primaryText),
              ),
            ),
            child: CupertinoDatePicker(
              mode: CupertinoDatePickerMode.date,
              initialDateTime: current,
              minimumDate: DateTime(1920, 1, 1),
              maximumDate: today,
              onDateTimeChanged: (d) => current = d,
            ),
          ),
        ),
        _confirmButton(ctx, lang, () => Navigator.of(ctx).pop(current)),
      ]);
    });
    if (picked == null || !mounted) return;
    setState(() {
      _birthday = DateTime(picked.year, picked.month, picked.day);
      _touched = true;
    });
  }

  /// One or two number wheels with a unit beside them. Returns the picked
  /// index of every wheel. The wheels stay left-to-right in every language.
  Future<List<int>?> _pickWheels({
    required String title,
    required List<List<String>> columns,
    required List<int> initial,
    required String unit,
  }) async {
    final String lang = _langOf(context);
    final List<int> picked = List<int>.from(initial);
    return _sheet<List<int>>((ctx) {
      final th = FlutterFlowTheme.of(ctx);
      return _shell(ctx, title, [
        SizedBox(
          height: 180,
          child: Directionality(
            textDirection: ui.TextDirection.ltr,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (int c = 0; c < columns.length; c++)
                  SizedBox(
                    width: 84,
                    child: CupertinoPicker(
                      scrollController:
                          FixedExtentScrollController(initialItem: initial[c]),
                      itemExtent: 40,
                      selectionOverlay: Container(
                        decoration: BoxDecoration(
                          color: th.primaryText.withOpacity(0.06),
                          borderRadius: BorderRadius.horizontal(
                            left: Radius.circular(c == 0 ? 10 : 0),
                            right: Radius.circular(
                                c == columns.length - 1 ? 10 : 0),
                          ),
                        ),
                      ),
                      onSelectedItemChanged: (i) {
                        HapticFeedback.selectionClick();
                        picked[c] = i;
                      },
                      children: [
                        for (final String label in columns[c])
                          Center(
                            child: Text(label,
                                style:
                                    _st(22, FontWeight.w600, th.primaryText)),
                          ),
                      ],
                    ),
                  ),
                if (unit.isNotEmpty) ...[
                  const SizedBox(width: 12),
                  Text(unit, style: _st(15, FontWeight.w500, th.secondaryText)),
                ],
              ],
            ),
          ),
        ),
        _confirmButton(ctx, lang, () => Navigator.of(ctx).pop(picked)),
      ]);
    });
  }

  Future<void> _pickHeight() async {
    final String lang = _langOf(context);
    if (_heightCm) {
      const int lo = 100, hi = 250;
      final int cur = ((_height ?? 170).round()).clamp(lo, hi).toInt();
      final List<int>? r = await _pickWheels(
        title: _tr(lang, "heightLabel"),
        columns: [
          [for (int v = lo; v <= hi; v++) v.toString()],
        ],
        initial: [cur - lo],
        unit: _tr(lang, "cm"),
      );
      if (r == null || !mounted) return;
      setState(() {
        _height = (lo + r[0]).toDouble();
        _touched = true;
      });
      return;
    }
    // feet + inches, kept as total inches
    const int ftLo = 3, ftHi = 8;
    final int total =
        ((_height ?? 67).round()).clamp(ftLo * 12, ftHi * 12 + 11).toInt();
    final List<int>? r = await _pickWheels(
      title: _tr(lang, "heightLabel"),
      columns: [
        [for (int f = ftLo; f <= ftHi; f++) f.toString() + "′"],
        [for (int i = 0; i <= 11; i++) i.toString() + "″"],
      ],
      initial: [total ~/ 12 - ftLo, total % 12],
      unit: "",
    );
    if (r == null || !mounted) return;
    setState(() {
      _height = ((ftLo + r[0]) * 12 + r[1]).toDouble();
      _touched = true;
    });
  }

  Future<void> _pickWeight() async {
    final String lang = _langOf(context);
    final int lo = _weightKg ? 20 : 45;
    final int hi = _weightKg ? 300 : 660;
    final double cur = _weight ?? (_weightKg ? 70 : 155);
    final int tenths = (cur * 10).round().clamp(lo * 10, hi * 10 + 9).toInt();
    final List<int>? r = await _pickWheels(
      title: _tr(lang, "weightLabel"),
      columns: [
        [for (int v = lo; v <= hi; v++) v.toString()],
        [for (int d = 0; d <= 9; d++) "." + d.toString()],
      ],
      initial: [tenths ~/ 10 - lo, tenths % 10],
      unit: _tr(lang, _weightKg ? "kg" : "lbs"),
    );
    if (r == null || !mounted) return;
    setState(() {
      _weight = (lo + r[0]) + r[1] / 10.0;
      _touched = true;
    });
  }

  // ---------- photo ----------
  Future<void> _pickPhoto() async {
    final String lang = _langOf(context);
    final ImageSource? source = await _sheet<ImageSource>((ctx) {
      final th = FlutterFlowTheme.of(ctx);
      Widget row(IconData icon, String key, ImageSource src) {
        return InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            Navigator.of(ctx).pop(src);
          },
          child: SizedBox(
            height: 56,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Icon(icon, size: 24, color: th.primary),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(_tr(lang, key),
                        style: _st(16, FontWeight.w500, th.primaryText)),
                  ),
                ],
              ),
            ),
          ),
        );
      }

      return _shell(ctx, _tr(lang, "photoTitle"), [
        row(Icons.photo_camera_outlined, "takePhoto", ImageSource.camera),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Divider(height: 1, thickness: 1, color: th.alternate),
        ),
        row(Icons.photo_library_outlined, "fromGallery", ImageSource.gallery),
      ]);
    });
    if (source == null) return;

    XFile? picked;
    try {
      picked = await ImagePicker().pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
        preferredCameraDevice: CameraDevice.front,
      );
    } catch (_) {
      return; // permission denied / camera unavailable
    }
    if (picked == null) return;

    String fileName = "";
    try {
      final Directory docs = await getApplicationDocumentsDirectory();
      // The saved photo stays on disk until this one is saved: leaving the
      // page without saving must not break the current photo.
      fileName = "profile_" +
          DateTime.now().millisecondsSinceEpoch.toString() +
          ".jpg";
      await File(picked.path)
          .copy(docs.path + Platform.pathSeparator + fileName);
      _docsPath = docs.path;
    } catch (_) {
      return;
    }
    if (!mounted) return;
    setState(() {
      _photo = fileName;
      _touched = true;
    });
  }

  // ---------- units ----------
  Map<String, dynamic> _unitsJson() => {
        "workout_is_kg": _workoutKg,
        "height_is_cm": _heightCm,
        "body_is_kg": _weightKg,
      };

  Future<void> _setWorkoutKg(bool v) async {
    try {
      FFAppState().update(() => FFAppState().isKg = v);
    } catch (_) {}
    if (mounted) setState(() {});
    await widget.onUnitsChanged?.call(_unitsJson());
  }

  Future<void> _setHeightCm(bool v) async {
    if (v == _heightCm) return;
    setState(() {
      final double? h = _height;
      if (h != null && h > 0) {
        _height = v
            ? (h * _kCmPerInch).roundToDouble() // inches -> cm
            : (h / _kCmPerInch).roundToDouble(); // cm -> inches
      }
      _heightCm = v;
      _touched = true;
    });
    await widget.onUnitsChanged?.call(_unitsJson());
  }

  Future<void> _setWeightKg(bool v) async {
    if (v == _weightKg) return;
    setState(() {
      final double? w = _weight;
      if (w != null && w > 0) {
        final double c = v ? w / _kLbPerKg : w * _kLbPerKg;
        _weight = (c * 10).round() / 10;
      }
      _weightKg = v;
      _touched = true;
    });
    await widget.onUnitsChanged?.call(_unitsJson());
  }

  // ---------- save ----------
  Future<void> _save() async {
    if (_saving) return;
    FocusScope.of(context).unfocus();
    HapticFeedback.mediumImpact();
    setState(() => _saving = true);
    final DateTime? d = _birthday;
    final String dob = d == null
        ? ""
        : d.year.toString().padLeft(4, "0") +
            "-" +
            d.month.toString().padLeft(2, "0") +
            "-" +
            d.day.toString().padLeft(2, "0");
    try {
      await widget.onSave?.call(
        _nameCtrl.text.trim(),
        _sex,
        dob,
        _height ?? 0,
        _heightCm,
        _weight ?? 0,
        _weightKg,
        _workoutKg,
        _photo,
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ---------- pieces ----------
  Widget _sectionTitle(String text) {
    final th = FlutterFlowTheme.of(context);
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(4, 0, 4, 8),
      child: Text(text, style: _st(13, FontWeight.w600, th.secondaryText)),
    );
  }

  Widget _card(List<Widget> children) {
    final th = FlutterFlowTheme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: th.secondaryBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: th.alternate),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }

  Widget _line() {
    final th = FlutterFlowTheme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Divider(height: 1, thickness: 1, color: th.alternate),
    );
  }

  Widget _row(String label, String value, String lang, VoidCallback onTap) {
    final th = FlutterFlowTheme.of(context);
    final bool rtl = _kRtl.contains(lang);
    final bool empty = value.isEmpty;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        height: 56,
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 10, 0),
          child: Row(
            children: [
              Text(label, style: _st(15, FontWeight.w400, th.primaryText)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  empty ? _tr(lang, "select") : value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: _st(15, empty ? FontWeight.w400 : FontWeight.w500,
                      empty ? th.secondaryText : th.primaryText),
                ),
              ),
              const SizedBox(width: 4),
              // chevron icons mirror themselves in a right-to-left context;
              // forcing LTR means the one chosen here is the one drawn
              Directionality(
                textDirection: ui.TextDirection.ltr,
                child: Icon(
                    rtl
                        ? Icons.chevron_left_rounded
                        : Icons.chevron_right_rounded,
                    size: 22,
                    color: th.secondaryText),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _avatar() {
    final th = FlutterFlowTheme.of(context);
    final String? docs = _docsPath;
    Widget inner =
        Icon(Icons.person_rounded, size: 48, color: th.secondaryText);
    if (_photo.isNotEmpty && docs != null) {
      inner = Image.file(
        File(docs + Platform.pathSeparator + _photo),
        fit: BoxFit.cover,
        width: 96,
        height: 96,
        errorBuilder: (_, __, ___) =>
            Icon(Icons.person_rounded, size: 48, color: th.secondaryText),
      );
    }
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _pickPhoto,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 104,
            height: 104,
            child: Stack(
              children: [
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Container(
                      decoration: BoxDecoration(
                        color: th.secondaryBackground,
                        shape: BoxShape.circle,
                        border: Border.all(color: th.alternate),
                      ),
                      clipBehavior: Clip.antiAlias,
                      alignment: Alignment.center,
                      child: inner,
                    ),
                  ),
                ),
                PositionedDirectional(
                  end: 0,
                  bottom: 0,
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: th.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: th.primaryBackground, width: 3),
                    ),
                    child: const Icon(Icons.photo_camera_rounded,
                        size: 16, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(_tr(_langOf(context), "changePhoto"),
              style: _st(14, FontWeight.w600, th.primary)),
        ],
      ),
    );
  }

  Widget _header(String lang, bool rtl) {
    final th = FlutterFlowTheme.of(context);
    final double top = MediaQuery.of(context).padding.top;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, top + 6, 16, 10),
      child: SizedBox(
        height: 44,
        child: NavigationToolbar(
          centerMiddle: true,
          middleSpacing: 10,
          leading: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              FocusScope.of(context).unfocus();
              HapticFeedback.selectionClick();
              widget.onBack?.call();
            },
            child: Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: th.secondaryBackground,
                shape: BoxShape.circle,
                border: Border.all(color: th.alternate),
              ),
              child: Directionality(
                textDirection: ui.TextDirection.ltr,
                child: Icon(
                    rtl
                        ? Icons.chevron_right_rounded
                        : Icons.chevron_left_rounded,
                    size: 26,
                    color: th.primaryText),
              ),
            ),
          ),
          middle: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(_tr(lang, "title"),
                maxLines: 1, style: _st(16, FontWeight.w600, th.primaryText)),
          ),
          trailing: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _saving ? null : _save,
            child: Container(
              height: 44,
              constraints: const BoxConstraints(minWidth: 84),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: th.primary,
                borderRadius: BorderRadius.circular(22),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.4, color: Colors.white),
                    )
                  : Text(_tr(lang, "save"),
                      maxLines: 1,
                      style: _st(15, FontWeight.w700, Colors.white)),
            ),
          ),
        ),
      ),
    );
  }

  // ---------- build ----------
  @override
  Widget build(BuildContext context) {
    final th = FlutterFlowTheme.of(context);
    final String lang = _langOf(context);
    final bool rtl = _kRtl.contains(lang);
    final MediaQueryData mq = MediaQuery.of(context);
    final double bottom =
        (mq.padding.bottom > 0 ? mq.padding.bottom : 12) + mq.viewInsets.bottom;

    return Directionality(
      textDirection: rtl ? ui.TextDirection.rtl : ui.TextDirection.ltr,
      child: Container(
        width: widget.width,
        height: widget.height,
        color: th.primaryBackground,
        child: Column(
          children: [
            _header(lang, rtl),
            Expanded(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.fromLTRB(16, 12, 16, 24 + bottom),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(child: _avatar()),
                    const SizedBox(height: 28),

                    // ---- account ----
                    _sectionTitle(_tr(lang, "account")),
                    _card([
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => _nameFocus.requestFocus(),
                        child: Padding(
                          padding: const EdgeInsetsDirectional.fromSTEB(
                              16, 12, 16, 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_tr(lang, "username"),
                                  style: _st(
                                      13, FontWeight.w500, th.secondaryText)),
                              const SizedBox(height: 2),
                              TextField(
                                controller: _nameCtrl,
                                focusNode: _nameFocus,
                                maxLines: 1,
                                maxLength: 30,
                                textInputAction: TextInputAction.done,
                                cursorColor: th.primary,
                                onChanged: (_) => _touched = true,
                                onTapOutside: (_) =>
                                    FocusScope.of(context).unfocus(),
                                style: _st(17, FontWeight.w600, th.primaryText),
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  isDense: true,
                                  filled: false,
                                  counterText: "",
                                  contentPadding:
                                      EdgeInsets.symmetric(vertical: 4),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 24),

                    // ---- personal ----
                    _sectionTitle(_tr(lang, "personal")),
                    _card([
                      _row(_tr(lang, "sex"), _sexText(lang), lang, _pickSex),
                      _line(),
                      _row(_tr(lang, "birthday"), _birthdayText(lang), lang,
                          _pickBirthday),
                    ]),
                    const SizedBox(height: 24),

                    // ---- measurements ----
                    _sectionTitle(_tr(lang, "measures")),
                    _card([
                      _row(_tr(lang, "heightLabel"), _heightText(lang), lang,
                          _pickHeight),
                      _line(),
                      _row(_tr(lang, "weightLabel"), _weightText(lang), lang,
                          _pickWeight),
                      _line(),
                      // the shared units row, in its Edit Profile look: same
                      // sheet as on the Profile page
                      Padding(
                        padding:
                            const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 0),
                        child: UnitsRow(
                          width: double.infinity,
                          height: 52,
                          editProfileMode: true,
                          workoutIsKg: _workoutKg,
                          heightIsCm: _heightCm,
                          bodyIsKg: _weightKg,
                          onWorkoutWeightChanged: (v) async => _setWorkoutKg(v),
                          onHeightChanged: (v) async => _setHeightCm(v),
                          onBodyWeightChanged: (v) async => _setWeightKg(v),
                        ),
                      ),
                    ]),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
// Set your widget name, define your parameter, and then add the
// boilerplate code using the `</>` button on the right!
