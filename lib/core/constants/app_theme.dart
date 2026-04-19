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
    'USD' => '\$',
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
      final displayAmount = ExchangeRateService.instance.convertNprToUsd(amount);
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
  // Architectural Ledger Design Tokens
  static const primary = Color(0xFF004339);
  static const primaryContainer = Color(0xFF005D4F);
  static const onPrimary = Color(0xFFFFFFFF);

  static const secondary = Color(0xFF52625E);
  static const secondaryContainer = Color(0xFFD2E3DE);
  static const onSecondary = Color(0xFFFFFFFF);

  static const background = Color(0xFFF8FAF9);
  static const onBackground = Color(0xFF191C1C);

  static const surface = Color(0xFFF8FAF9);
  static const surfaceBright = Color(0xFFF8FAF9);
  static const surfaceContainerLow = Color(0xFFF2F4F3);
  static const surfaceContainerLowest = Color(0xFFFFFFFF);
  static const surfaceVariant = Color(0xFFE1E3E2);
  static const onSurface = Color(0xFF191C1C);
  static const onSurfaceVariant = Color(0xFF3F4946);

  static const error = Color(0xFFBA1A1A);
  static const errorContainer = Color(0xFFFFDAD6);
  static const onError = Color(0xFFFFFFFF);

  static const outline = Color(0xFF6F7976);
  static const outlineVariant = Color(0xFFBEC9C4);

  // Reusable Gradient for main actions & cards
  static const signatureGradient = LinearGradient(
    colors: [primary, primaryContainer],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0.0, 1.0],
  );

  static ThemeData get lightTheme {
    const inputRadius = 12.0;

    final textTheme = TextTheme(
      displayLarge: GoogleFonts.manrope(
        fontSize: 57,
        fontWeight: FontWeight.normal,
        letterSpacing: -0.25,
        color: onSurface,
      ),
      displayMedium: GoogleFonts.manrope(
        fontSize: 45,
        fontWeight: FontWeight.normal,
        color: onSurface,
      ),
      displaySmall: GoogleFonts.manrope(
        fontSize: 36,
        fontWeight: FontWeight.normal,
        color: onSurface,
      ),
      headlineLarge: GoogleFonts.manrope(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: onSurface,
      ),
      headlineMedium: GoogleFonts.manrope(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: onSurface,
      ),
      headlineSmall: GoogleFonts.manrope(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        color: onSurface,
      ),
      titleLarge: GoogleFonts.manrope(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        color: onSurface,
      ),
      titleMedium: GoogleFonts.manrope(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: onSurface,
      ),
      titleSmall: GoogleFonts.manrope(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: onSurface,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: onSurface,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: onSurface,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.normal,
        color: onSurfaceVariant,
      ),
      labelLarge: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: onSurface,
      ),
      labelMedium: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: onSurface,
      ),
      labelSmall: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: onSurfaceVariant,
        letterSpacing: 0.4,
      ),
    );

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
        onPrimaryContainer: Colors.white,
        secondary: secondary,
        onSecondary: onSecondary,
        secondaryContainer: secondaryContainer,
        onSecondaryContainer: onSurface,
        error: error,
        onError: onError,
        errorContainer: errorContainer,
        surface: surface,
        onSurface: onSurface,
        surfaceContainerHighest: surfaceVariant,
        onSurfaceVariant: onSurfaceVariant,
        outline: outline,
        outlineVariant: outlineVariant,
      ),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: surfaceContainerLowest,
        foregroundColor: onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
        shape: const Border(
          bottom: BorderSide(color: surfaceContainerLow, width: 1),
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceContainerLowest,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: false,
        border: outlinedBorder,
        enabledBorder: outlinedBorder,
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
          borderSide: const BorderSide(color: surfaceVariant, width: 1.5),
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(color: onSurfaceVariant),
        labelStyle: textTheme.bodyMedium?.copyWith(color: onSurfaceVariant),
        floatingLabelStyle: textTheme.bodySmall?.copyWith(
          color: primary,
          fontWeight: FontWeight.w500,
        ),
        prefixIconColor: onSurfaceVariant,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: onSurface,
          side: const BorderSide(color: outlineVariant, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: textTheme.labelLarge,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        titleTextStyle: textTheme.titleSmall,
        subtitleTextStyle: textTheme.bodySmall?.copyWith(
          color: onSurfaceVariant,
        ),
        iconColor: onSurfaceVariant,
      ),
      dividerTheme: const DividerThemeData(
        color: surfaceContainerLow,
        thickness: 1,
        space: 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceContainerLow,
        selectedColor: primary.withValues(alpha: 0.12),
        labelStyle: textTheme.labelMedium,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        side: BorderSide.none,
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: surfaceContainerLowest,
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: onSurfaceVariant,
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surfaceContainerLowest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        showDragHandle: true,
        dragHandleColor: outlineVariant,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: onSurface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static ThemeData get darkTheme => lightTheme;
}

class AppColors {
  // Aliases for the architectural ledger colors mapped to legacy names
  static const debit = AppTheme.error;
  static const credit = AppTheme.primary;
  static const income = AppTheme.primary;
  static const expense = AppTheme.error;
  static const onTrack = AppTheme.primaryContainer;
  static const behind = Color(0xFFBA1A1A);
  static const achieved = AppTheme.primary;
}
