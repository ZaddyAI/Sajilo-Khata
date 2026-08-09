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

class AppTheme {
  // Primary - Deep Blue (Institutional trust & security)
  static const primary = Color(0xFF000666);
  static const primaryContainer = Color(0xFF1A237E);
  static const onPrimary = Color(0xFFFFFFFF);
  static const onPrimaryContainer = Color(0xFF8690EE);

  // Secondary - Emerald Green (Growth & credit)
  static const secondary = Color(0xFF1B6D24);
  static const secondaryContainer = Color(0xFFA0F399);
  static const onSecondary = Color(0xFFFFFFFF);
  static const onSecondaryContainer = Color(0xFF217128);

  // Tertiary - Deep Red (Expenses & debit)
  static const tertiary = Color(0xFF400003);
  static const tertiaryContainer = Color(0xFF670007);
  static const onTertiary = Color(0xFFFFFFFF);
  static const onTertiaryContainer = Color(0xFFFF635A);

  // Background & Surface
  static const background = Color(0xFFF7F9FC);
  static const onBackground = Color(0xFF191C1E);

  static const surface = Color(0xFFF7F9FC);
  static const surfaceBright = Color(0xFFF7F9FC);
  static const surfaceContainerLowest = Color(0xFFFFFFFF);
  static const surfaceContainerLow = Color(0xFFF2F4F7);
  static const surfaceContainer = Color(0xFFECEEF1);
  static const surfaceContainerHigh = Color(0xFFE6E8EB);
  static const surfaceContainerHighest = Color(0xFFE0E3E6);
  static const surfaceDim = Color(0xFFD8DADD);
  static const surfaceVariant = Color(0xFFE0E3E6);

  static const onSurface = Color(0xFF191C1E);
  static const onSurfaceVariant = Color(0xFF454652);

  // Error
  static const error = Color(0xFFBA1A1A);
  static const errorContainer = Color(0xFFFFDAD6);
  static const onError = Color(0xFFFFFFFF);
  static const onErrorContainer = Color(0xFF93000A);

  // Outline
  static const outline = Color(0xFF767683);
  static const outlineVariant = Color(0xFFC6C5D4);

  // Fixed variants
  static const primaryFixed = Color(0xFFE0E0FF);
  static const primaryFixedDim = Color(0xFFBDC2FF);
  static const onPrimaryFixed = Color(0xFF000767);
  static const onPrimaryFixedVariant = Color(0xFF343D96);
  static const secondaryFixed = Color(0xFFA3F69C);
  static const secondaryFixedDim = Color(0xFF88D982);
  static const onSecondaryFixed = Color(0xFF002204);
  static const onSecondaryFixedVariant = Color(0xFF005312);
  static const tertiaryFixed = Color(0xFFFFDAD6);
  static const tertiaryFixedDim = Color(0xFFFFB4AC);
  static const onTertiaryFixed = Color(0xFF410003);
  static const onTertiaryFixedVariant = Color(0xFF93000E);

  // Inverse
  static const inverseSurface = Color(0xFF2D3133);
  static const inverseOnSurface = Color(0xFFEFF1F4);
  static const inversePrimary = Color(0xFFBDC2FF);

  // Gradients
  static const signatureGradient = LinearGradient(
    colors: [Color(0xFF000666), Color(0xFF1A237E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0.0, 1.0],
  );

  static const shimmerGradient = LinearGradient(
    colors: [Color(0xFF000666), Color(0xFF1A237E), Color(0xFF000666)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const surfaceGradient = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFF7F9FC)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Shadows - Tonal layers
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: const Color(0xFF000000).withValues(alpha: 0.04),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: const Color(0xFF000000).withValues(alpha: 0.02),
      blurRadius: 4,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> get elevatedShadow => [
    BoxShadow(
      color: const Color(0xFF000000).withValues(alpha: 0.08),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
    BoxShadow(
      color: const Color(0xFF000000).withValues(alpha: 0.04),
      blurRadius: 8,
      offset: const Offset(0, 4),
    ),
  ];

  // Border Radius - Soft (0.25rem)
  static const inputRadius = 4.0;
  static const buttonRadius = 4.0;
  static const cardRadius = 8.0;
  static const chipRadius = 9999.0;

  // Spacing scale
  static const spacingUnit = 4.0;
  static const spacingXs = 4.0;
  static const spacingSm = 8.0;
  static const spacingMd = 16.0;
  static const spacingLg = 24.0;
  static const spacingXl = 32.0;

  static TextTheme _buildTextTheme() {
    return TextTheme(
      // display-lg: Manrope 48px 700
      displayLarge: GoogleFonts.manrope(
        fontSize: 48,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.02,
        height: 1.25,
        color: onSurface,
      ),
      // display-md: Manrope 40px 700
      displayMedium: GoogleFonts.manrope(
        fontSize: 40,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.02,
        color: onSurface,
      ),
      // display-sm: Manrope 36px 700
      displaySmall: GoogleFonts.manrope(
        fontSize: 36,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.02,
        color: onSurface,
      ),
      // headline-lg: Manrope 32px 600
      headlineLarge: GoogleFonts.manrope(
        fontSize: 32,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.02,
        color: onSurface,
      ),
      // headline-md: Manrope 24px 600
      headlineMedium: GoogleFonts.manrope(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: onSurface,
      ),
      // headline-sm: Manrope 20px 600
      headlineSmall: GoogleFonts.manrope(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: onSurface,
      ),
      // title-lg: Manrope 20px 600
      titleLarge: GoogleFonts.manrope(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: onSurface,
      ),
      // title-md: Manrope 16px 600
      titleMedium: GoogleFonts.manrope(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: onSurface,
      ),
      // title-sm: Manrope 14px 600
      titleSmall: GoogleFonts.manrope(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: onSurface,
      ),
      // body-lg: Inter 18px 400
      bodyLarge: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w400,
        color: onSurface,
      ),
      // body-md: Inter 16px 400
      bodyMedium: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: onSurface,
      ),
      // body-sm: Inter 14px 400
      bodySmall: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: onSurface,
      ),
      // label-lg: Inter 14px 600
      labelLarge: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: onSurface,
      ),
      // label-md: Inter 12px 700
      labelMedium: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.05,
        color: onSurface,
      ),
      // label-sm: Inter 11px 500
      labelSmall: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: onSurfaceVariant,
        letterSpacing: 0.4,
      ),
    );
  }

  static TextStyle dataMono({Color? color}) {
    return GoogleFonts.jetBrainsMono(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: color ?? onSurface,
    );
  }

  static ThemeData get lightTheme {
    final textTheme = _buildTextTheme();

    final outlinedBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(inputRadius),
      borderSide: const BorderSide(color: outlineVariant, width: 1.5),
    );

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: background,
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
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        color: surfaceContainerLowest,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
        ),
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceContainerLow,
        border: outlinedBorder,
        enabledBorder: outlinedBorder.copyWith(
          borderSide: const BorderSide(color: outlineVariant, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputRadius),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputRadius),
          borderSide: const BorderSide(color: error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputRadius),
          borderSide: const BorderSide(color: error, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputRadius),
          borderSide: const BorderSide(color: outlineVariant, width: 1.5),
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(color: onSurfaceVariant),
        labelStyle: textTheme.bodyMedium?.copyWith(color: onSurfaceVariant),
        floatingLabelStyle: textTheme.bodySmall?.copyWith(
          color: primary,
          fontWeight: FontWeight.w500,
        ),
        prefixIconColor: onSurfaceVariant,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spacingMd,
          vertical: spacingMd,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: spacingLg,
            vertical: spacingMd,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(buttonRadius),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: onSurface,
          side: const BorderSide(color: outlineVariant, width: 1.5),
          padding: const EdgeInsets.symmetric(
            horizontal: spacingLg,
            vertical: spacingMd,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(buttonRadius),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: textTheme.labelLarge,
          padding: const EdgeInsets.symmetric(
            horizontal: spacingSm,
            vertical: spacingSm / 2,
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.transparent,
        indicatorColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return textTheme.labelSmall!.copyWith(
              color: primary,
              fontWeight: FontWeight.w700,
            );
          }
          return textTheme.labelSmall!.copyWith(color: onSurfaceVariant);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: primary, size: 22);
          }
          return const IconThemeData(color: onSurfaceVariant, size: 22);
        }),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: onPrimary,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(buttonRadius),
        ),
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spacingMd,
          vertical: spacingSm / 2,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(buttonRadius),
        ),
        titleTextStyle: textTheme.titleSmall,
        subtitleTextStyle: textTheme.bodySmall?.copyWith(
          color: onSurfaceVariant,
        ),
        iconColor: onSurfaceVariant,
      ),
      dividerTheme: const DividerThemeData(
        color: surfaceContainer,
        thickness: 1,
        space: 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceContainer,
        selectedColor: primary.withValues(alpha: 0.12),
        labelStyle: textTheme.labelMedium,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(chipRadius),
        ),
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(
          horizontal: spacingSm / 2,
          vertical: spacingXs / 2,
        ),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius * 2),
        ),
        backgroundColor: surfaceContainerLowest,
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: onSurfaceVariant,
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surfaceContainerLowest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        showDragHandle: true,
        dragHandleColor: outlineVariant,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: inverseSurface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: inverseOnSurface,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(buttonRadius),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      popupMenuTheme: PopupMenuThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
        ),
        elevation: 8,
        shadowColor: Colors.black.withValues(alpha: 0.1),
      ),
    );
  }

  static ThemeData get darkTheme => lightTheme;
}

class AppColors {
  // Credit = Emerald Green
  static const credit = AppTheme.secondary;
  static const income = AppTheme.secondary;

  // Debit = Deep Red
  static const debit = AppTheme.tertiary;
  static const expense = AppTheme.tertiary;

  // Goal statuses
  static const onTrack = AppTheme.secondary;
  static const behind = AppTheme.tertiary;
  static const achieved = AppTheme.secondary;

  // Semantic
  static const success = AppTheme.secondary;
  static const warning = Color(0xFFE65100);
  static const info = AppTheme.primary;
}
