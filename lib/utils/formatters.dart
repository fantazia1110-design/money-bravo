import 'package:intl/intl.dart';

/// Format a number with Arabic locale grouping
String formatNumber(double num) {
  // تقريب الرقم لأقرب عدد صحيح لإلغاء الكسور العشرية المزعجة من التطبيق بالكامل
  return NumberFormat('#,##0', 'ar').format(num.round());
}

/// Format currency with amount and symbol
String formatCurrency(double amount, String currency) {
  return '${formatNumber(amount.abs())} $currency';
}

/// Format date to Arabic short date
String formatDate(DateTime date) {
  return DateFormat('d MMM yyyy', 'ar').format(date);
}

/// Generate unique ID
String generateId() {
  return '${DateTime.now().millisecondsSinceEpoch}_${(1000 + DateTime.now().microsecond % 9000)}';
}

/// Convert hex color string to Flutter Color int
int hexToColorInt(String hex) {
  final clean = hex.replaceAll('#', '');
  return int.parse('FF$clean', radix: 16);
}

const List<String> globalCurrencies = [
  'جنية مصري (EGP)',
  'دولار أمريكي (USD)',
  'يورو (EUR)',
  'جنيه إسترليني (GBP)',
  'ريال سعودي (SAR)',
  'درهم إماراتي (AED)',
  'دينار كويتي (KWD)',
  'ريال قطري (QAR)',
  'دينار بحريني (BHD)',
  'ريال عماني (OMR)',
  'دينار أردني (JOD)',
  'دينار جزائري (DZD)',
  'درهم مغربي (MAD)',
  'دينار تونسي (TND)',
  'دينار ليبي (LYD)',
  'دينار عراقي (IQD)',
  'ليرة لبنانية (LBP)',
  'ليرة سورية (SYP)',
  'ريال يمني (YER)',
  'جنيه سوداني (SDG)',
  'شلن صومالي (SOS)',
  'أوقية موريتانية (MRO)',
  'فرنك سويسري (CHF)',
  'دولار كندي (CAD)',
  'دولار أسترالي (AUD)',
  'دولار نيوزيلندي (NZD)',
  'دولار سنغافوري (SGD)',
  'ين ياباني (JPY)',
  'يوان صيني (CNY)',
  'وون كوري جنوبي (KRW)',
  'روبية هندية (INR)',
  'روبية باكستانية (PKR)',
  'ليرة تركية (TRY)',
  'روبل روسي (RUB)',
  'كرونة سويدية (SEK)',
  'كرونة نرويجية (NOK)',
  'راند جنوب أفريقي (ZAR)',
  'بيزو مكسيكي (MXN)',
];

/// فئة مساعدة لتحليل نصوص الفئات واستخراج الصورة والرمز
class CategoryData {
  final String name;
  final String icon;
  final String? imagePath;

  CategoryData({required this.name, required this.icon, this.imagePath});

  static CategoryData parse(String data) {
    if (data.contains('|')) {
      final parts = data.split('|');
      return CategoryData(
        name: parts[0],
        icon: parts.length > 1 ? parts[1] : '🛒',
        imagePath: parts.length > 2 && parts[2].isNotEmpty ? parts[2] : null,
      );
    }
    final parts = data.split(' ');
    if (parts.isNotEmpty && parts.length > 1) {
      return CategoryData(
          name: parts.sublist(1).join(' '), icon: parts[0], imagePath: null);
    }
    return CategoryData(name: data, icon: '🛒', imagePath: null);
  }

  String encode() => '$name|$icon|${imagePath ?? ''}';
}
