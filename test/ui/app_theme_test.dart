import 'package:dry_eye_widget/ui/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('tema usa Inter, dark M3 e scaffold transparente', () {
    final theme = buildAppTheme();
    expect(theme.useMaterial3, isTrue);
    expect(theme.brightness, Brightness.dark);
    expect(theme.scaffoldBackgroundColor, Colors.transparent);
    expect(theme.textTheme.bodyMedium!.fontFamily, 'Inter');
  });

  test('expõe cores semânticas via ThemeExtension', () {
    final theme = buildAppTheme();
    final sem = theme.extension<AppSemanticColors>();
    expect(sem, isNotNull);
    expect(sem!.success, isNot(sem.danger));
  });

  test('botões padronizados: radius 12 e altura mínima 44', () {
    final theme = buildAppTheme();
    final shape =
        theme.filledButtonTheme.style!.shape!.resolve({})
            as RoundedRectangleBorder;
    expect(shape.borderRadius, BorderRadius.circular(AppRadii.sm));
    final minSize = theme.filledButtonTheme.style!.minimumSize!.resolve({})!;
    expect(minSize.height, 44);
  });

  test('alto contraste reforça superfícies e contorno de foco', () {
    final theme = buildAppTheme(highContrast: true);
    expect(theme.colorScheme.surface, AppColorTokens.canvas);
    expect(theme.colorScheme.outline, AppColorTokens.focus);
  });
}
