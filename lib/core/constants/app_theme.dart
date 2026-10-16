import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/exchange_rate_service.dart';

IconData getCurrencyIcon(String? currency) {
  return switch (currency) {
    'USD' => Icons.attach_money,
    _ => Icons.currency_rupee,
  };
}

String getCurrencySymbol(String? currency) {
  return switch (currency) {
    'USD' => r'$',
    _ => 'NPR ',
  };
}

String _formatNPR(String amountStr) {
  final length = amountStr.length;
  if (length <= 3) return amountStr;
  if (length <= 5) {
    return '${amountStr.substring(0, length - 3)},${amountStr.substring(length - 3)}';
  }
  if (length <= 7) {
    return '${amountStr.substring(0, length - 5)},${amountStr.substring(length - 5, length - 3)},${amountStr.substring(length - 3)}';
  }
  return '${amountStr.substring(0, length - 7)},${amountStr.substring(length - 7, length - 5)},${amountStr.substring(length - 5, length - 3)},${amountStr.substring(length - 3)}';
}

String formatCurrency(double amount, [String? currencyCode]) {
  final currency = currencyCode ?? 'NPR';
  final amountStr = amount.toStringAsFixed(currency == 'USD' ? 2 : 0);
  if (currency == 'USD') {
    return NumberFormat('#,##0.00').format(amount);
  }
  return _formatNPR(amountStr);
}

class CurrencyHelper {
  static String currency = 'NPR';
  static String get symbol => getCurrencySymbol(currency);
  static IconData get icon => getCurrencyIcon(currency);

  static String format(double amount) {
    if (currency == 'USD' && ExchangeRateService.instance.isAvailable) {
      final displayAmount = ExchangeRateService.instance.convertNprToUsd(
        amount,
      );
      return formatCurrency(displayAmount, 'USD');
    }
    return formatCurrency(amount, 'NPR');
  }

  static double convertFromStored(double storedAmount) {
    if (currency == 'USD' && ExchangeRateService.instance.isAvailable) {
      return ExchangeRateService.instance.convertNprToUsd(storedAmount);
    }
    return storedAmount;
  }

  static double convertToStored(double displayAmount) {
    if (currency == 'USD' && ExchangeRateService.instance.isAvailable) {
      return ExchangeRateService.instance.convertUsdToNpr(displayAmount);
    }
    return displayAmount;
  }

  static void setCurrency(String value) {
    currency = value;
    ExchangeRateService.instance.fetchUsdToNprRate();
  }
}

class CurrencyNotifier extends ChangeNotifier {
  String _currency = 'NPR';

  String get currency => _currency;
  String get symbol => getCurrencySymbol(_currency);
  IconData get icon => getCurrencyIcon(_currency);
  String format(double amount) => formatCurrency(amount);

  void setCurrency(String value) {
    if (_currency != value) {
      _currency = value;
      CurrencyHelper.setCurrency(value);
      notifyListeners();
    }
  }
}

/// Verdant Sol - Biophilic Fintech Design System + iOS Cupertino Aesthetics
class AppTheme {
  // Brand Colors from theme_template.md
  // Primary (Muted Moss signature hue)
  static const primary = Color(0xFF5A7853);
  static const primaryDark = Color(0xFF394835);
  static const primaryLight = Color(0xFF75966D);
  static const primaryDeep = Color(0xFF2E3A2B);

  // Secondary (Deep Obsidian Moss for dock, heavy text, matte surfaces)
  static const secondary = Color(0xFF1B221A);
  static const secondaryDark = Color(0xFF121612);

  // Mint / Botanical Containers
  static const mint = Color(0xFFDDE5D8);
  static const mintAccent = Color(0xFFAFD0A4);
  static const paleMint = Color(0xFFF2F4F0);
  static const mintPale = Color(0xFFECEEEA);
  static const mintLight = Color(0xFFDDE5D8);

  // Material 3 Primary Container mappings
  static const primaryContainer = Color(0xFFDDE5D8);
  static const onPrimary = Color(0xFFFFFFFF);
  static const onPrimaryContainer = Color(0xFF062105);

  // Secondary Container
  static const secondaryContainer = Color(0xFFDDE5D8);
  static const onSecondary = Color(0xFFFFFFFF);
  static const onSecondaryContainer = Color(0xFF5F665C);

  // Tertiary / Expense (Blossom Coral)
  static const tertiary = Color(0xFFE07A70);
  static const tertiaryContainer = Color(0xFFFFF3F1);
  static const onTertiary = Color(0xFFFFFFFF);
  static const onTertiaryContainer = Color(0xFF93000A);

  // Background & Surfaces (Warm Limestone & Pure White Paper Cards)
  static const background = Color(0xFFF8FAF6);
  static const onBackground = Color(0xFF191C1A);
  static const scaffoldBg = Color(0xFFF8FAF6);
  static const warmIvory = Color(0xFFF8FAF6);

  static const surface = Color(0xFFF8FAF6);
  static const surfaceBright = Color(0xFFFFFFFF);
  static const surfaceCard = Color(0xFFFFFFFF);
  static const surfaceContainerLowest = Color(0xFFFFFFFF);
  static const surfaceContainerLow = Color(0xFFF2F4F0);
  static const surfaceContainer = Color(0xFFECEEEA);
  static const surfaceContainerHigh = Color(0xFFE7E9E5);
  static const surfaceContainerHighest = Color(0xFFE1E3DF);
  static const surfaceDim = Color(0xFFD8DBD7);
  static const surfaceVariant = Color(0xFFE1E3DF);
  static const surfaceMint = Color(0xFFDDE5D8);

  // Typography Colors
  static const onSurface = Color(0xFF191C1A);
  static const onSurfaceVariant = Color(0xFF434840);
  static const primaryText = Color(0xFF191C1A);
  static const secondaryText = Color(0xFF434840);

  // Finance Status Colors
  static const income = Color(0xFF425F3C);
  static const incomeEmerald = Color(0xFF425F3C);
  static const expense = Color(0xFFE07A70);
  static const expenseCoral = Color(0xFFE07A70);
  static const coral = Color(0xFFE07A70);
  static const warning = Color(0xFFD99B26);

  // Error Status
  static const error = Color(0xFFBA1A1A);
  static const errorContainer = Color(0xFFFFDAD6);
  static const onError = Color(0xFFFFFFFF);
  static const onErrorContainer = Color(0xFF93000A);

  // Outlines & Borders
  static const outline = Color(0xFF73796F);
  static const outlineVariant = Color(0xFFE2E6DF);
  static const border = Color(0xFFE2E6DF);
  static const cardBorder = Color(0xFFE2E6DF);
  static const borderDefault = Color(0xFFE2E6DF);

  // Fixed variants
  static const primaryFixed = Color(0xFFCAECBF);
  static const primaryFixedDim = Color(0xFFAFD0A4);
  static const onPrimaryFixed = Color(0xFF062105);
  static const onPrimaryFixedVariant = Color(0xFF314E2C);
  static const secondaryFixed = Color(0xFFDDE5D8);
  static const secondaryFixedDim = Color(0xFFC1C9BC);
  static const onSecondaryFixed = Color(0xFF161D16);
  static const onSecondaryFixedVariant = Color(0xFF41493F);
  static const tertiaryFixed = Color(0xFFFFDAD6);
  static const tertiaryFixedDim = Color(0xFFFFB4AB);
  static const onTertiaryFixed = Color(0xFF400203);
  static const onTertiaryFixedVariant = Color(0xFF7B2D27);

  // Inverse
  static const inverseSurface = Color(0xFF2E312F);
  static const inverseOnSurface = Color(0xFFEFF1ED);
  static const inversePrimary = Color(0xFFAFD0A4);

  // Gradients from theme_template.md
  // Botanical Moss Gradient: #75966D -> #5A7853 -> #394835
  static const primaryGradient = LinearGradient(
    colors: [Color(0xFF75966D), Color(0xFF5A7853), Color(0xFF394835)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Deep Obsidian Gradient: #1B221A -> #121612
  static const obsidianGradient = LinearGradient(
    colors: [Color(0xFF1B221A), Color(0xFF121612)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const signatureGradient = LinearGradient(
    colors: [Color(0xFF5A7853), Color(0xFF394835), Color(0xFF1B221A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const softBgGradient = LinearGradient(
    colors: [Color(0xFFF8FAF6), Color(0xFFF2F4F0), Color(0xFFECEEEA)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const surfaceGradient = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFF8FAF6)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const mintGradient = LinearGradient(
    colors: [Color(0xFFDDE5D8), Color(0xFFAFD0A4)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Elevation & Ambient Diffusion Shadows
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: const Color(0xFF283426).withValues(alpha: 0.05),
      blurRadius: 18,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.02),
      blurRadius: 4,
      offset: const Offset(0, 1),
    ),
  ];

  static List<BoxShadow> get dashboardShadow => [
    BoxShadow(
      color: const Color(0xFF283426).withValues(alpha: 0.16),
      blurRadius: 32,
      offset: const Offset(0, 12),
    ),
    BoxShadow(
      color: const Color(0xFF283426).withValues(alpha: 0.06),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get dockShadow => [
    BoxShadow(
      color: const Color(0xFF121612).withValues(alpha: 0.22),
      blurRadius: 28,
      offset: const Offset(0, 8),
    ),
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.08),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> get buttonShadow => [
    BoxShadow(
      color: const Color(0xFF5A7853).withValues(alpha: 0.24),
      blurRadius: 14,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get elevatedShadow => dashboardShadow;

  // iOS Geometry Radii
  static const radiusSm = 8.0;
  static const radiusMd = 12.0;
  static const radiusLg = 16.0;
  static const tileRadius = 16.0;
  static const squircleRadius = 14.0;
  static const cardRadius = 22.0;
  static const dashboardRadius = 26.0;
  static const sheetRadius = 28.0;
  static const pillRadius = 999.0;

  // Compatibility aliases
  static const inputRadius = 14.0;
  static const buttonRadius = 999.0;
  static const chipRadius = 999.0;

  // Spacing Scale
  static const spacingUnit = 4.0;
  static const spacingXs = 4.0;
  static const spacingSm = 8.0;
  static const spacingMd = 16.0;
  static const spacingLg = 24.0;
  static const spacingXl = 32.0;

  // Plus Jakarta Sans (theme font, bundled in assets/fonts)
  static TextStyle fontJakarta({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w500,
    Color? color,
    double? height,
    double? letterSpacing,
  }) {
    return GoogleFonts.plusJakartaSans(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color ?? onSurface,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  static TextTheme _buildTextTheme() {
    return TextTheme(
      displayLarge: fontJakarta(
        fontSize: 48,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.2,
        height: 1.12,
        color: onSurface,
      ),
      displayMedium: fontJakarta(
        fontSize: 38,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.0,
        height: 1.15,
        color: onSurface,
      ),
      displaySmall: fontJakarta(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.6,
        color: onSurface,
      ),
      headlineLarge: fontJakarta(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: onSurface,
      ),
      headlineMedium: fontJakarta(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
        color: onSurface,
      ),
      headlineSmall: fontJakarta(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        color: onSurface,
      ),
      titleLarge: fontJakarta(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
        color: onSurface,
      ),
      titleMedium: fontJakarta(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: onSurface,
      ),
      titleSmall: fontJakarta(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: onSurface,
      ),
      bodyLarge: fontJakarta(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.45,
        color: onSurface,
      ),
      bodyMedium: fontJakarta(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.4,
        color: onSurface,
      ),
      bodySmall: fontJakarta(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: onSurfaceVariant,
      ),
      labelLarge: fontJakarta(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: onSurface,
      ),
      labelMedium: fontJakarta(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        color: onSurface,
      ),
      labelSmall: fontJakarta(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
        color: onSurfaceVariant,
      ),
    );
  }

  static TextStyle dataMono({
    Color? color,
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w600,
  }) {
    return GoogleFonts.jetBrainsMono(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color ?? onSurface,
    );
  }

  // iOS Card & Inset Grouped Decorations
  static BoxDecoration get iosCardDecoration => BoxDecoration(
    color: surfaceCard,
    borderRadius: BorderRadius.circular(cardRadius),
    border: Border.all(color: outlineVariant, width: 0.8),
    boxShadow: cardShadow,
  );

  static BoxDecoration get iosGroupedCardDecoration => BoxDecoration(
    color: surfaceCard,
    borderRadius: BorderRadius.circular(cardRadius),
    border: Border.all(color: outlineVariant, width: 0.8),
    boxShadow: cardShadow,
  );

  static ThemeData get lightTheme {
    final textTheme = _buildTextTheme();

    final outlinedBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(inputRadius),
      borderSide: const BorderSide(color: outlineVariant, width: 1.0),
    );

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: background,
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: primary,
        onPrimary: onPrimary,
        primaryContainer: primaryContainer,
        onPrimaryContainer: onPrimaryContainer,
        secondary: secondary,
        onSecondary: onSecondary,
        secondaryContainer: secondaryContainer,
        onSecondaryContainer: onSecondaryContainer,
        tertiary: tertiary,
        onTertiary: onTertiary,
        tertiaryContainer: tertiaryContainer,
        onTertiaryContainer: onTertiaryContainer,
        error: error,
        onError: onError,
        errorContainer: errorContainer,
        onErrorContainer: onErrorContainer,
        surface: surface,
        onSurface: onSurface,
        surfaceContainerHighest: surfaceContainerHighest,
        onSurfaceVariant: onSurfaceVariant,
        outline: outline,
        outlineVariant: outlineVariant,
        inverseSurface: inverseSurface,
        onInverseSurface: inverseOnSurface,
        inversePrimary: inversePrimary,
      ),
      textTheme: textTheme,
      cupertinoOverrideTheme: const NoDefaultCupertinoThemeData(
        primaryColor: primary,
        scaffoldBackgroundColor: background,
        barBackgroundColor: surfaceCard,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: onSurface,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceContainerLowest,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
          side: const BorderSide(color: outlineVariant, width: 0.8),
        ),
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceContainerLowest,
        border: outlinedBorder,
        enabledBorder: outlinedBorder,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputRadius),
          borderSide: const BorderSide(color: primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputRadius),
          borderSide: const BorderSide(color: error, width: 1.0),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputRadius),
          borderSide: const BorderSide(color: error, width: 1.6),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputRadius),
          borderSide: const BorderSide(color: outlineVariant, width: 1.0),
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: onSurfaceVariant.withValues(alpha: 0.65),
        ),
        labelStyle: textTheme.bodyMedium?.copyWith(color: onSurfaceVariant),
        floatingLabelStyle: textTheme.bodySmall?.copyWith(
          color: primary,
          fontWeight: FontWeight.w600,
        ),
        prefixIconColor: onSurfaceVariant,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spacingMd,
          vertical: 14,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          elevation: 0,
          shadowColor: primary.withValues(alpha: 0.2),
          padding: const EdgeInsets.symmetric(
            horizontal: spacingLg,
            vertical: 14,
          ),
          shape: const StadiumBorder(),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: outlineVariant, width: 1.0),
          padding: const EdgeInsets.symmetric(
            horizontal: spacingLg,
            vertical: 14,
          ),
          shape: const StadiumBorder(),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: spacingSm,
            vertical: spacingSm / 2,
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: secondary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: const CircleBorder(),
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spacingMd,
          vertical: spacingSm / 2,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
        titleTextStyle: textTheme.titleSmall,
        subtitleTextStyle: textTheme.bodySmall?.copyWith(
          color: onSurfaceVariant,
        ),
        iconColor: onSurfaceVariant,
      ),
      dividerTheme: const DividerThemeData(
        color: outlineVariant,
        thickness: 0.8,
        space: 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceContainerLow,
        selectedColor: mint,
        labelStyle: textTheme.labelMedium,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(pillRadius),
        ),
        side: const BorderSide(color: outlineVariant, width: 0.8),
        padding: const EdgeInsets.symmetric(
          horizontal: spacingSm,
          vertical: spacingXs,
        ),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
        ),
        backgroundColor: surfaceContainerLowest,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: onSurface,
        ),
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: onSurfaceVariant,
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surfaceContainerLowest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(sheetRadius),
          ),
        ),
        showDragHandle: false,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: secondary,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      popupMenuTheme: PopupMenuThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          side: const BorderSide(color: outlineVariant, width: 0.8),
        ),
        elevation: 8,
        color: surfaceContainerLowest,
        shadowColor: const Color(0xFF191C1A).withValues(alpha: 0.1),
      ),
    );
  }

  static ThemeData get darkTheme => lightTheme;
}

class AppColors {
  // Income / Credit = Muted Moss / Success
  static const credit = AppTheme.income;
  static const income = AppTheme.income;

  // Expense / Debit = Blossom Coral
  static const debit = AppTheme.expense;
  static const expense = AppTheme.expense;

  // Goal statuses
  static const onTrack = AppTheme.income;
  static const behind = AppTheme.expense;
  static const achieved = AppTheme.income;

  // Semantic
  static const success = AppTheme.income;
  static const warning = AppTheme.warning;
  static const info = AppTheme.primary;
}

/// Standard smooth sheet animation style with iOS-like easing curves
AnimationStyle get appSheetAnimationStyle => AnimationStyle(
  curve: Curves.easeOutCubic,
  reverseCurve: Curves.easeInCubic,
  duration: const Duration(milliseconds: 320),
  reverseDuration: const Duration(milliseconds: 240),
);

/// Smooth iOS-style dialog with fluid scale and opacity animations on open and close
Future<T?> showSmoothDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
  String? barrierLabel,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: barrierLabel ?? 'Dismiss',
    barrierColor: Colors.black.withValues(alpha: 0.45),
    transitionDuration: const Duration(milliseconds: 260),
    pageBuilder: (ctx, anim1, anim2) => builder(ctx),
    transitionBuilder: (ctx, anim, secondaryAnim, child) {
      final curvedValue = Curves.easeOutCubic.transform(anim.value);
      return Transform.scale(
        scale: 0.92 + (0.08 * curvedValue),
        child: Opacity(opacity: anim.value.clamp(0.0, 1.0), child: child),
      );
    },
  );
}
