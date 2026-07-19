import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

const Color appBackgroundColor = Color(0xFF061913);
const Color appSurfaceColor = Color(0xFF102B23);
const Color appSurfaceHighColor = Color(0xFF183A30);
const Color appPrimaryColor = Color(0xFF6DD075);
const Color appOnPrimaryColor = Color(0xFF061913);
const Color appSecondaryColor = Color(0xFFB8D6C4);

const ColorScheme appColorScheme = ColorScheme.dark(
  primary: appPrimaryColor,
  onPrimary: appOnPrimaryColor,
  primaryContainer: Color(0xFF224F40),
  onPrimaryContainer: Color(0xFFC7F9CC),
  secondary: appSecondaryColor,
  onSecondary: Color(0xFF10231C),
  secondaryContainer: Color(0xFF29483D),
  onSecondaryContainer: Color(0xFFD4EBDD),
  tertiary: Color(0xFFFFC66D),
  onTertiary: Color(0xFF2B1900),
  surface: appBackgroundColor,
  onSurface: Color(0xFFF0F5F2),
  surfaceDim: Color(0xFF04120E),
  surfaceBright: Color(0xFF29483D),
  surfaceContainerLowest: Color(0xFF04120E),
  surfaceContainerLow: Color(0xFF0B211A),
  surfaceContainer: appSurfaceColor,
  surfaceContainerHigh: appSurfaceHighColor,
  surfaceContainerHighest: Color(0xFF21483C),
  onSurfaceVariant: Color(0xFFC4D4CB),
  outline: Color(0xFF91B4A1),
  outlineVariant: Color(0xFF355449),
  error: Color(0xFFFFB4AB),
  onError: Color(0xFF690005),
);

const PaintingEffect skeletonizerEffect = PulseEffect(
  from: Color(0xFF40574F),
  to: Color(0xFF6B8179),
);

Widget Function(BuildContext context, Widget? widget) datePickerTheme =
    (context, child) {
  final ThemeData base = Theme.of(context);
  return Theme(
    data: base.copyWith(
      colorScheme: base.colorScheme.copyWith(
        primary: appPrimaryColor,
        onPrimary: appOnPrimaryColor,
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: appPrimaryColor),
      ),
    ),
    child: child!,
  );
};

final ThemeData theme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  colorScheme: appColorScheme,
  scaffoldBackgroundColor: appBackgroundColor,
  canvasColor: appSurfaceColor,
  focusColor: appPrimaryColor.withOpacity(.22),
  hoverColor: appPrimaryColor.withOpacity(.10),
  textTheme: const TextTheme(
    headlineMedium: TextStyle(
      color: Color(0xFFF4F8F5),
      fontSize: 28,
      height: 1.15,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.4,
    ),
    headlineSmall: TextStyle(
      color: Color(0xFFF4F8F5),
      fontSize: 23,
      height: 1.2,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.2,
    ),
    titleLarge: TextStyle(
      color: Color(0xFFF4F8F5),
      fontWeight: FontWeight.w700,
    ),
    titleMedium: TextStyle(
      color: Color(0xFFF4F8F5),
      fontWeight: FontWeight.w700,
    ),
    labelLarge: TextStyle(
      color: Color(0xFFF0F5F2),
      fontWeight: FontWeight.w700,
      letterSpacing: .1,
    ),
    bodyLarge: TextStyle(color: Color(0xFFE4ECE7), height: 1.4),
    bodyMedium: TextStyle(color: Color(0xFFDDE7E1), height: 1.35),
    bodySmall: TextStyle(color: Color(0xFFB8C8BF), height: 1.3),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: appSurfaceColor,
    labelStyle: const TextStyle(color: Color(0xFFC4D4CB)),
    hintStyle: const TextStyle(color: Color(0xFFAABCB2)),
    prefixIconColor: appSecondaryColor,
    suffixIconColor: appSecondaryColor,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFF6E8C7D)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFF6E8C7D)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: appPrimaryColor, width: 2),
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: appPrimaryColor,
      foregroundColor: appOnPrimaryColor,
      minimumSize: const Size(64, 48),
      textStyle: const TextStyle(fontWeight: FontWeight.w700),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: appPrimaryColor,
      foregroundColor: appOnPrimaryColor,
      minimumSize: const Size(64, 48),
      textStyle: const TextStyle(fontWeight: FontWeight.w700),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: const Color(0xFFE9F6ED),
      minimumSize: const Size(64, 48),
      side: const BorderSide(color: Color(0xFF91B4A1)),
      textStyle: const TextStyle(fontWeight: FontWeight.w700),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: const Color(0xFFC7F9CC),
      minimumSize: const Size(48, 48),
    ),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: appBackgroundColor,
    foregroundColor: Color(0xFFF4F8F5),
    elevation: 0,
    scrolledUnderElevation: 0,
    centerTitle: false,
    toolbarHeight: 64,
    titleTextStyle: TextStyle(
      color: Color(0xFFF4F8F5),
      fontSize: 20,
      fontWeight: FontWeight.w700,
    ),
  ),
  cardTheme: CardTheme(
    color: appSurfaceColor,
    elevation: 0,
    margin: EdgeInsets.zero,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: const BorderSide(color: Color(0xFF29483D)),
    ),
  ),
  floatingActionButtonTheme: FloatingActionButtonThemeData(
    backgroundColor: appPrimaryColor,
    foregroundColor: appOnPrimaryColor,
    elevation: 2,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  ),
  dialogTheme: DialogTheme(
    backgroundColor: appSurfaceColor,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    titleTextStyle: const TextStyle(
      color: Color(0xFFF4F8F5),
      fontWeight: FontWeight.bold,
      fontSize: 20,
    ),
  ),
  snackBarTheme: SnackBarThemeData(
    backgroundColor: const Color(0xFF29483D),
    contentTextStyle: const TextStyle(color: Color(0xFFF4F8F5)),
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  ),
  dividerTheme: const DividerThemeData(color: Color(0xFF355449)),
  iconTheme: const IconThemeData(color: Color(0xFFE4ECE7)),
  listTileTheme: const ListTileThemeData(
    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 3),
    minTileHeight: 56,
    iconColor: Color(0xFFB8D6C4),
    textColor: Color(0xFFF0F5F2),
  ),
  navigationBarTheme: NavigationBarThemeData(
    height: 72,
    backgroundColor: const Color(0xFF0B211A),
    indicatorColor: const Color(0xFF315D4E),
    elevation: 0,
    labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
    iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(
          color: states.contains(WidgetState.selected)
              ? const Color(0xFFC7F9CC)
              : const Color(0xFF9FB9AB),
          size: 24,
        )),
    labelTextStyle: WidgetStateProperty.resolveWith((states) => TextStyle(
          color: states.contains(WidgetState.selected)
              ? const Color(0xFFC7F9CC)
              : const Color(0xFF9FB9AB),
          fontSize: 11,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w700
              : FontWeight.w500,
        )),
  ),
  bottomSheetTheme: const BottomSheetThemeData(
    backgroundColor: appSurfaceColor,
    surfaceTintColor: Colors.transparent,
    showDragHandle: true,
    dragHandleColor: Color(0xFF91B4A1),
  ),
  progressIndicatorTheme: const ProgressIndicatorThemeData(
    color: appPrimaryColor,
    linearTrackColor: Color(0xFF29483D),
    circularTrackColor: Color(0xFF29483D),
  ),
  checkboxTheme: CheckboxThemeData(
    fillColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) return appPrimaryColor;
      return Colors.transparent;
    }),
    checkColor: WidgetStateProperty.all(appOnPrimaryColor),
    side: const BorderSide(color: Color(0xFF9AB8A8), width: 1.5),
  ),
  radioTheme: RadioThemeData(
    fillColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.disabled)) return Colors.grey;
      return appPrimaryColor;
    }),
  ),
  chipTheme: ChipThemeData(
    backgroundColor: const Color(0xFF183A30),
    selectedColor: const Color(0xFF315D4E),
    side: const BorderSide(color: Color(0xFF547466)),
    labelStyle: const TextStyle(color: Color(0xFFF0F5F2)),
    secondaryLabelStyle: const TextStyle(
      color: Color(0xFFC7F9CC),
      fontWeight: FontWeight.w700,
    ),
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
  ),
);
