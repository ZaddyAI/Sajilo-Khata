import 'package:flutter_test/flutter_test.dart';
import 'package:sajilo_khata/core/services/sms_service.dart';
import 'package:sajilo_khata/domain/entities/transaction.dart';

void main() {
  final sms = SmsService();

  setUp(() {
    // Empty selection = accept every sender (parser gate).
    SmsService.selectedGroups = [];
  });

  group('Global bank parser', () {
    test('eSewa "Payment successful" SMS', () {
      final parsed = sms.parseSmsManual(
        'eSewa',
        'Payment successful to eSewa with amount 3,000.00 and remarks '
        'MOS/eSewa/9811891031/paisa',
      );
      expect(parsed, isNotNull);
      expect(parsed!['amount'], 3000.0);
      expect(parsed['type'], TransactionType.debit);
      expect(parsed['category'], 'Food & Dining');
      expect(parsed['description'], contains('MOS/eSewa/9811891031/paisa'));
    });

    test('Bank debit SMS (NPR ... debited, ISO date)', () {
      const body =
          'From a/c : ###6495Txn ID : BYZVMDUPOYH Dear user, Your account '
          '##6495 is debited by NPR 5010 on 2026-06-11 10:43:20 '
          'by:FonePay:IBFT:1603250803';
      final parsed = sms.parseSmsManual('NabilBank', body);
      expect(parsed, isNotNull);
      expect(parsed!['amount'], 5010.0);
      expect(parsed['type'], TransactionType.debit);
      expect(parsed['description'], contains('BYZVMDUPOYH'));

      final date = sms.extractDateForTest(body);
      expect(date, isNotNull);
      expect(date!.year, 2026);
      expect(date.month, 6);
      expect(date.day, 11);
    });

    test('Bank credit SMS (Deposited, US style MM/DD/YYYY)', () {
      const body =
          'Deposited 11,000.00 from A/C:###5492 on 10/15/2026, 4:51:43 PM.'
          'TX ID: 4Z6SQPS3KXU';
      final parsed = sms.parseSmsManual('GlobalIMEBank', body);
      expect(parsed, isNotNull);
      expect(parsed!['amount'], 11000.0);
      expect(parsed['type'], TransactionType.credit);
      expect(parsed['description'], contains('4Z6SQPS3KXU'));

      final date = sms.extractDateForTest(body);
      expect(date, isNotNull);
      expect(date!.year, 2026);
      expect(date.month, 10);
      expect(date.day, 15);
    });

    test('Rejects non-transaction SMS', () {
      expect(
        sms.parseSmsManual('SomeBrand', 'Congratulations, you won a prize!'),
        isNull,
      );
    });

    test('Keeps the sender allowlist gate', () {
      SmsService.selectedGroups = ['nabil'];
      expect(
        sms.parseSmsManual('otherSender', 'debited by NPR 500 from account'),
        isNull,
      );
      expect(
        sms.parseSmsManual('NabilBank', 'debited by NPR 500 from account'),
        isNotNull,
      );
    });
  });

  group('Date extraction', () {
    test('ISO date is not misread as DD/MM/YY', () {
      final date = sms.extractDateForTest(
        'Your account is debited by NPR 1000 on 2026-06-25 10:00:00',
      );
      expect(date, isNotNull);
      expect(date!.year, 2026);
      expect(date.month, 6);
      expect(date.day, 25);
    });

    test('DD/MM/YYYY', () {
      final date = sms.extractDateForTest('debited on 25/08/2025 at 10:00');
      expect(date, isNotNull);
      expect(date!.year, 2025);
      expect(date.month, 8);
      expect(date.day, 25);
    });

    test('DD/MM/YY (Laxmi Sunrise)', () {
      final date = sms.extractDateForTest('withdrawn on 17/04/26');
      expect(date, isNotNull);
      expect(date!.year, 2026);
      expect(date.month, 4);
      expect(date.day, 17);
    });

    test('DDMonYY (Nepali bank)', () {
      final date = sms.extractDateForTest('credited Rs.5,000 on 01Dec25');
      expect(date, isNotNull);
      expect(date!.year, 2025);
      expect(date.month, 12);
      expect(date.day, 1);
    });

    test('US style MM/DD/YYYY with "on" prefix', () {
      final date = sms.extractDateForTest('on 10/15/2026, 4:51:43 PM');
      expect(date, isNotNull);
      expect(date!.year, 2026);
      expect(date.month, 10);
      expect(date.day, 15);
    });
  });
}
