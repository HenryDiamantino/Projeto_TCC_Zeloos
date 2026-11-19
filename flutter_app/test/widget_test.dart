// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_app/config/app_config.dart';
import 'package:flutter_app/main.dart';
import 'package:flutter_app/screens/account_screen.dart';
import 'package:flutter_app/screens/app_settings_screen.dart';
import 'package:flutter_app/screens/dashboard_screen.dart';
import 'package:flutter_app/services/app_settings.dart';
import 'package:flutter_app/widgets/user_avatar.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _onePixelPng =
    'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=';

void main() {
  testWidgets('ZELOOS login screen smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(
      find.byWidgetPredicate((w) => w is Image && w.semanticLabel == 'ZELOOS'),
      findsOneWidget,
    );
    expect(find.text('Acesse sua conta'), findsOneWidget);
    expect(find.text('Entrar'), findsOneWidget);
  });

  testWidgets('login screen toggles between light and dark theme', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await AppSettings.instance.setThemeMode(ThemeMode.light);
    await tester.pumpWidget(const MyApp());

    expect(
      find.image(const AssetImage('assets/images/zeloos_logo_navy.png')),
      findsOneWidget,
    );
    await tester.tap(find.byTooltip('Mudar para tema escuro'));
    await tester.pumpAndSettle();

    expect(AppSettings.instance.themeMode, ThemeMode.dark);
    expect(
      find.image(const AssetImage('assets/images/zeloos_logo_white.png')),
      findsOneWidget,
    );
    expect(find.byTooltip('Mudar para tema claro'), findsOneWidget);
    await AppSettings.instance.setThemeMode(ThemeMode.system);
  });

  testWidgets('register form shows optional phone with mask', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    final toggle = find.text('Criar conta');
    await tester.ensureVisible(toggle);
    await tester.tap(toggle);
    await tester.pumpAndSettle();

    expect(find.text('Telefone (opcional)'), findsOneWidget);
    final phoneField = find.widgetWithText(TextField, 'Telefone (opcional)');
    await tester.enterText(phoneField, '11987654321');
    expect(
      tester.widget<TextField>(phoneField).controller!.text,
      '(11) 98765-4321',
    );
  });

  testWidgets('app settings links to account screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: AppSettingsScreen()),
    );
    await tester.scrollUntilVisible(find.text('Minha conta'), 200);
    await tester.tap(find.text('Minha conta'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.widgetWithText(AppBar, 'Minha conta'), findsOneWidget);
  });

  testWidgets('home screen greets the user and shows shortcuts', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: DashboardScreen(userName: 'Henry Silva')),
    );

    expect(
      find.image(const AssetImage('assets/images/zeloos_wordmark_white.png')),
      findsOneWidget,
    );
    expect(find.text('Olá, Henry!'), findsOneWidget);
    expect(find.text('Atalhos'), findsOneWidget);
    expect(find.text('Pulseiras'), findsOneWidget);
    expect(find.text('Perfis'), findsOneWidget);
    expect(find.text('Config. pulseira'), findsOneWidget);
    expect(find.text('Mapa'), findsOneWidget);
    expect(find.byTooltip('Mudar para tema escuro'), findsOneWidget);
  });

  testWidgets('home screen shows the account avatar next to logout', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: DashboardScreen(userName: 'henry Silva')),
    );

    final avatar = find.byTooltip('Minha conta');
    expect(
      find.descendant(of: avatar, matching: find.text('H')),
      findsOneWidget,
    );
    expect(
      tester.getCenter(avatar).dx,
      greaterThan(tester.getCenter(find.byTooltip('Sair da conta')).dx),
    );
  });

  testWidgets('user avatar shows the first letter until a photo is set', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: UserAvatar(name: 'Henry')));
    expect(find.text('H'), findsOneWidget);
    expect(
      tester.widget<CircleAvatar>(find.byType(CircleAvatar)).foregroundImage,
      isNull,
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: UserAvatar(name: 'Henry', photo: _onePixelPng),
      ),
    );
    final image = tester
        .widget<CircleAvatar>(find.byType(CircleAvatar))
        .foregroundImage;
    expect(image, isA<MemoryImage>());
    expect((image! as MemoryImage).bytes.take(4), [0x89, 0x50, 0x4e, 0x47]);
  });

  testWidgets('account screen offers gallery and camera for the photo', (
    WidgetTester tester,
  ) async {
    FlutterSecureStorage.setMockInitialValues({
      AppConfig.authTokenKey: 'token',
    });
    await http.runWithClient(
      () => tester.pumpWidget(const MaterialApp(home: AccountScreen())),
      () => MockClient(
        (_) async => http.Response(
          jsonEncode({
            'success': true,
            'user': {'nome': 'Henry Silva', 'email': 'henry@demo.com'},
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('H'), findsOneWidget);
    await tester.tap(find.text('Adicionar foto'));
    await tester.pumpAndSettle();

    expect(find.text('Escolher da galeria'), findsOneWidget);
    expect(find.text('Tirar foto'), findsOneWidget);
    expect(find.text('Remover foto'), findsNothing);
  });

  testWidgets('account screen lets the user remove an existing photo', (
    WidgetTester tester,
  ) async {
    FlutterSecureStorage.setMockInitialValues({
      AppConfig.authTokenKey: 'token',
    });
    final requests = <String>[];
    ImageProvider? avatarImage() =>
        tester.widget<CircleAvatar>(find.byType(CircleAvatar)).foregroundImage;

    await http.runWithClient(
      () async {
        await tester.pumpWidget(const MaterialApp(home: AccountScreen()));
        await tester.pumpAndSettle();
        expect(avatarImage(), isA<MemoryImage>());

        await tester.tap(find.text('Alterar foto'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Remover foto'));
        await tester.pumpAndSettle();
      },
      () => MockClient((request) async {
        requests.add('${request.method} ${request.url.path}');
        return http.Response(
          jsonEncode({
            'success': true,
            'user': {
              'nome': 'Henry Silva',
              'email': 'henry@demo.com',
              'foto_perfil': request.method == 'DELETE' ? null : _onePixelPng,
            },
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }),
    );

    expect(requests, ['GET /api/auth/me', 'DELETE /api/auth/me/foto']);
    expect(avatarImage(), isNull);
    expect(find.text('Foto removida.'), findsOneWidget);
    expect(find.text('Adicionar foto'), findsOneWidget);
  });

  testWidgets('app settings switches to dark theme', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await AppSettings.instance.load();
    await tester.pumpWidget(const MyApp());
    final context = tester.element(find.text('Acesse sua conta'));
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AppSettingsScreen()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Configurações do app'), findsOneWidget);
    await tester.tap(find.text('Escuro'));
    await tester.pumpAndSettle();

    expect(AppSettings.instance.themeMode, ThemeMode.dark);
    expect(
      Theme.of(tester.element(find.text('Tema'))).brightness,
      Brightness.dark,
    );
    await AppSettings.instance.setThemeMode(ThemeMode.system);
  });
}
