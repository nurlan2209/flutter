import 'package:intl/intl.dart';

class CurrencyUtils {
  static final Map<String, String> currencySymbols = {
    'USD': '\$',  // Убрал лишний экранирующий слеш
    'EUR': '€',
    'GBP': '£',
    'RUB': '₽',
    'KZT': '₸',
    'JPY': '¥',
    'CNY': '¥',
    'INR': '₹',
  };

  static String formatAmount(double amount, String currency) {
    final symbol = currencySymbols[currency] ?? currency;
    final formatter = NumberFormat.currency(
      symbol: symbol,
      decimalDigits: 2,
    );
    return formatter.format(amount);
  }

  static String formatAmountCompact(double amount, String currency) {
    final symbol = currencySymbols[currency] ?? currency;
    if (amount.abs() >= 1000000) {
      return '$symbol${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount.abs() >= 1000) {
      return '$symbol${(amount / 1000).toStringAsFixed(1)}K';
    }
    return formatAmount(amount, currency);
  }

  static double convertCurrency(
    double amount,
    String fromCurrency,
    String toCurrency,
  ) {
    // Простая конвертация с фиксированными курсами
    // В реальном приложении нужно использовать API для получения актуальных курсов
    final rates = {
      'USD': 1.0,
      'EUR': 0.85,
      'GBP': 0.73,
      'RUB': 90.0,
      'KZT': 450.0,
      'JPY': 110.0,
      'CNY': 6.5,
      'INR': 75.0,
    };

    final fromRate = rates[fromCurrency] ?? 1.0;
    final toRate = rates[toCurrency] ?? 1.0;

    return amount * (toRate / fromRate);
  }
}