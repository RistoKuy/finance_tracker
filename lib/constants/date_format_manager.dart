import 'package:shared_preferences/shared_preferences.dart';
import 'app_constants.dart';

class DateFormatManager {
  DateFormatManager._();
  
  static String _currentFormat = AppConstants.defaultDateFormat;
  static SharedPreferences? _prefs;
  
  // Initialize the date format manager
  static Future<void> initialize() async {
    _prefs ??= await SharedPreferences.getInstance();
    _currentFormat = _prefs!.getString('date_format') ?? AppConstants.defaultDateFormat;
  }
  
  // Get current date format
  static String get currentFormat => _currentFormat;
  
  // Set new date format
  static Future<void> setFormat(String format) async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setString('date_format', format);
    _currentFormat = format;
  }
  
  // Check if using European format
  static bool get isEuropeanFormat => _currentFormat == AppConstants.europeanDateFormat;
  
  // Check if using American format  
  static bool get isAmericanFormat => _currentFormat == AppConstants.americanDateFormat;
  
  // Get short date format (without time)
  static String get shortDateFormat {
    if (isEuropeanFormat) {
      return 'dd/MM/yyyy';
    } else {
      return 'MMM d, yyyy';
    }
  }
  
  // Get short time format
  static String get shortTimeFormat {
    if (isEuropeanFormat) {
      return 'HH:mm';
    } else {
      return 'h:mm a';
    }
  }
  
  // Get month/year format
  static String get monthYearFormat {
    if (isEuropeanFormat) {
      return 'MM/yyyy';
    } else {
      return 'MMMM yyyy';
    }
  }
  
  // Get day/month format (for time ago)
  static String get dayMonthFormat {
    if (isEuropeanFormat) {
      return 'dd/MM';
    } else {
      return 'MMM d';
    }
  }
  
  // Get weekday, date format
  static String get weekdayDateFormat {
    if (isEuropeanFormat) {
      return 'EEEE, dd/MM/yyyy';
    } else {
      return 'EEEE, MMM d, yyyy';
    }
  }
  
  // Get short date format for lists
  static String get listDateFormat {
    if (isEuropeanFormat) {
      return 'dd/MM/yy';
    } else {
      return 'MM/dd/yy';
    }
  }
}