import 'package:flutter_test/flutter_test.dart';
import 'package:dry_eye_widget/services/update_service.dart';

void main() {
  group('UpdateService', () {
    test('verify version comparison logic', () {
      final service = UpdateService();

      expect(service.compareVersions('1.0.0', '1.0.0'), 0);
      expect(service.compareVersions('1.0.1', '1.0.0') > 0, isTrue);
      expect(service.compareVersions('1.1.0', '1.0.0') > 0, isTrue);
      expect(service.compareVersions('2.0.0', '1.0.0') > 0, isTrue);

      expect(service.compareVersions('1.0.0', '1.0.1') < 0, isTrue);
      expect(service.compareVersions('1.0.0', '1.1.0') < 0, isTrue);
      expect(service.compareVersions('1.0.0', '2.0.0') < 0, isTrue);

      expect(service.compareVersions('1.10.0', '1.2.0') > 0, isTrue);
      expect(service.compareVersions('2.0.10', '2.0.9') > 0, isTrue);
    });

    test('só aceita HTTPS em hosts GitHub oficiais', () {
      final service = UpdateService();

      expect(
        service.isAllowedHttpsUrl(
          'https://api.github.com/repos/Sudo-psc/dry-eye-widget/releases/latest',
          api: true,
        ),
        isTrue,
      );
      expect(
        service.isAllowedHttpsUrl(
          'https://github.com/Sudo-psc/dry-eye-widget/releases/latest',
          api: false,
        ),
        isTrue,
      );
      expect(
        service.isAllowedHttpsUrl('http://api.github.com/x', api: true),
        isFalse,
      );
      expect(
        service.isAllowedHttpsUrl('https://evil.example/x', api: true),
        isFalse,
      );
      expect(
        service.isAllowedHttpsUrl(
          'https://user:pass@api.github.com/x',
          api: true,
        ),
        isFalse,
      );
    });
  });
}
