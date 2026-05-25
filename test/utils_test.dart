import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:finance_tracker/constants/date_format_manager.dart';
import 'package:finance_tracker/constants/app_constants.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DateFormatManager Tests', () {
    setUp(() async {
      // Mock shared preferences
      SharedPreferences.setMockInitialValues({});
      await DateFormatManager.initialize();
    });

    test('Should initialize with default format (European)', () {
      expect(DateFormatManager.currentFormat, AppConstants.defaultDateFormat);
      expect(DateFormatManager.isEuropeanFormat, true);
    });

    test('Should change format to American correctly', () async {
      await DateFormatManager.setFormat(AppConstants.americanDateFormat);
      
      expect(DateFormatManager.currentFormat, AppConstants.americanDateFormat);
      expect(DateFormatManager.isAmericanFormat, true);
      expect(DateFormatManager.shortDateFormat, 'MMM d, yyyy');
    });

    test('Should set and return correct format strings based on current format', () async {
      // European
      await DateFormatManager.setFormat(AppConstants.europeanDateFormat);
      expect(DateFormatManager.shortDateFormat, 'dd/MM/yyyy');
      expect(DateFormatManager.monthYearFormat, 'MM/yyyy');

      // American
      await DateFormatManager.setFormat(AppConstants.americanDateFormat);
      expect(DateFormatManager.shortDateFormat, 'MMM d, yyyy');
      expect(DateFormatManager.monthYearFormat, 'MMMM yyyy');
    });
  });
}