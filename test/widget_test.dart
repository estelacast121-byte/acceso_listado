import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:acceso_listado/main.dart';
import 'package:acceso_listado/estado/listado.dart';
import 'package:acceso_listado/estado/sesion.dart';
import 'package:acceso_listado/servicios/publicaciones_servicio.dart';
import 'package:acceso_listado/utilidades/validaciones.dart';
import 'package:acceso_listado/pantallas/listado.dart';

String datos(int inicio, int cantidad) => jsonEncode(
  List.generate(
    cantidad,
    (i) => {
      'id': inicio + i,
      'title': 'Título ${inicio + i}',
      'body': 'Contenido',
    },
  ),
);

void main() {
  testWidgets(
    'Listado: reintentar, scroll infinito y refrescar desde la interfaz',
    (tester) async {
      final paginas = <String>[];
      final cliente = MockClient((solicitud) async {
        final pagina = solicitud.url.queryParameters['_page']!;
        paginas.add(pagina);
        if (paginas.length == 1) return http.Response('', 500);
        return http.Response(pagina == '1' ? datos(1, 15) : datos(16, 2), 200);
      });
      addTearDown(cliente.close);
      final contenedor = ProviderContainer(
        overrides: [
          publicacionesServicioProvider.overrideWithValue(
            PublicacionesServicio(cliente),
          ),
        ],
      );
      addTearDown(contenedor.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: contenedor,
          child: const MaterialApp(home: PantallaListado()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Reintentar'), findsOneWidget);
      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();
      expect(find.text('PUBLICACIÓN 1'), findsOneWidget);
      for (var i = 0; i < 12 && paginas.length < 3; i++) {
        await tester.drag(find.byType(ListView), const Offset(0, -600));
        await tester.pumpAndSettle();
      }
      expect(paginas, ['1', '1', '2']);
      expect(contenedor.read(listadoProvider).publicaciones.length, 17);
      final scroll = tester.widget<ListView>(find.byType(ListView)).controller!;
      scroll.jumpTo(0);
      await tester.pumpAndSettle();
      await tester.drag(find.byType(ListView), const Offset(0, 400));
      await tester.pumpAndSettle();
      expect(paginas, ['1', '1', '2', '1']);
      expect(contenedor.read(listadoProvider).publicaciones.length, 15);
    },
  );

  test('Validaciones: vacíos, correo, longitud y confirmación', () {
    expect(validarNombre('  '), isNotNull);
    expect(validarNombre('Ana'), isNull);
    for (final correo in ['', 'ana', 'ana@', 'a b@c.com']) {
      expect(validarCorreo(correo), isNotNull);
    }
    expect(validarCorreo('ana@ejemplo.com'), isNull);
    expect(validarContrasena('1234567'), isNotNull);
    expect(validarContrasena('12345678'), isNull);
    expect(validarConfirmacion('', '12345678'), isNotNull);
    expect(validarConfirmacion('distinta', '12345678'), isNotNull);
    expect(validarConfirmacion('12345678', '12345678'), isNull);
  });

  test('Servicio: URL paginada, HTTP y JSON inválido', () async {
    final cliente = MockClient((solicitud) async {
      expect(solicitud.url.host, 'jsonplaceholder.typicode.com');
      expect(solicitud.url.queryParameters, {'_page': '2', '_limit': '15'});
      return http.Response(datos(16, 15), 200);
    });
    addTearDown(cliente.close);
    expect(
      (await PublicacionesServicio(cliente).obtenerPagina(2)).first.id,
      16,
    );
    for (final respuesta in [
      http.Response('error', 500),
      http.Response('{}', 200),
      http.Response('mal', 200),
    ]) {
      final clienteError = MockClient((_) async => respuesta);
      addTearDown(clienteError.close);
      await expectLater(
        PublicacionesServicio(clienteError).obtenerPagina(1),
        throwsA(isA<ErrorPublicaciones>()),
      );
    }
  });

  test('Listado: bloqueo de duplicados, páginas, final y refresco', () async {
    final pendiente = Completer<http.Response>();
    final paginas = <String>[];
    final cliente = MockClient((solicitud) {
      paginas.add(solicitud.url.queryParameters['_page']!);
      if (paginas.length == 1) return pendiente.future;
      return Future.value(http.Response(datos(16, 2), 200));
    });
    addTearDown(cliente.close);
    final contenedor = ProviderContainer(
      overrides: [
        publicacionesServicioProvider.overrideWithValue(
          PublicacionesServicio(cliente),
        ),
      ],
    );
    addTearDown(contenedor.dispose);
    final escucha = contenedor.listen(listadoProvider, (_, _) {});
    addTearDown(escucha.close);
    final listado = contenedor.read(listadoProvider.notifier);
    final primera = listado.cargar();
    await listado.cargar();
    await Future<void>.delayed(Duration.zero);
    expect(paginas, ['1']);
    expect(contenedor.read(listadoProvider).cargando, isTrue);
    pendiente.complete(http.Response(datos(1, 15), 200));
    await primera;
    await listado.cargar();
    expect(contenedor.read(listadoProvider).publicaciones.length, 17);
    expect(contenedor.read(listadoProvider).hayMas, isFalse);
    await listado.cargar();
    expect(paginas, ['1', '2']);
    await listado.cargar(reiniciar: true);
    expect(paginas, ['1', '2', '1']);
    expect(contenedor.read(listadoProvider).publicaciones.length, 2);
  });

  test('Listado: error, reintento de la misma página y vacío', () async {
    var llamadas = 0;
    final cliente = MockClient((solicitud) async {
      expect(solicitud.url.queryParameters['_page'], '1');
      return ++llamadas == 1
          ? http.Response('', 503)
          : http.Response('[]', 200);
    });
    addTearDown(cliente.close);
    final contenedor = ProviderContainer(
      overrides: [
        publicacionesServicioProvider.overrideWithValue(
          PublicacionesServicio(cliente),
        ),
      ],
    );
    addTearDown(contenedor.dispose);
    final escucha = contenedor.listen(listadoProvider, (_, _) {});
    addTearDown(escucha.close);
    await contenedor.read(listadoProvider.notifier).cargar();
    expect(contenedor.read(listadoProvider).error, contains('503'));
    await contenedor.read(listadoProvider.notifier).cargar();
    expect(contenedor.read(listadoProvider).error, isNull);
    expect(contenedor.read(listadoProvider).publicaciones, isEmpty);
    expect(contenedor.read(listadoProvider).hayMas, isFalse);
  });

  testWidgets('Login: valida, carga, elimina ruta anterior y cierra sesión', (
    tester,
  ) async {
    final cliente = MockClient((_) async => http.Response('[]', 200));
    addTearDown(cliente.close);
    final contenedor = ProviderContainer(
      overrides: [
        publicacionesServicioProvider.overrideWithValue(
          PublicacionesServicio(cliente),
        ),
      ],
    );
    addTearDown(contenedor.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: contenedor,
        child: const Aplicacion(),
      ),
    );
    await tester.ensureVisible(find.text('Iniciar sesión'));
    await tester.tap(find.text('Iniciar sesión'));
    await tester.pump();
    expect(find.text('Ingresa un correo válido.'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).at(0), 'ana@ejemplo.com');
    await tester.enterText(find.byType(TextFormField).at(1), '12345678');
    await tester.ensureVisible(find.text('Iniciar sesión'));
    await tester.tap(find.text('Iniciar sesión'));
    await tester.pump();
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pumpAndSettle();
    expect(find.text('No hay publicaciones.'), findsOneWidget);
    expect(contenedor.read(sesionProvider), 'ana@ejemplo.com');
    final contexto = tester.element(find.text('Publicaciones'));
    expect(Navigator.of(contexto).canPop(), isFalse);
    await tester.tap(find.byTooltip('Cerrar sesión'));
    await tester.pumpAndSettle();
    expect(find.text('Bienvenido'), findsOneWidget);
    expect(contenedor.read(sesionProvider), isNull);
  });

  testWidgets(
    'Registro: revalida confirmación, exige términos y devuelve correo',
    (tester) async {
      tester.view.physicalSize = const Size(900, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(const ProviderScope(child: Aplicacion()));
      await tester.tap(find.text('Crear cuenta'));
      await tester.pumpAndSettle();
      final campos = find.byType(TextFormField);
      await tester.enterText(campos.at(0), 'Ana');
      await tester.enterText(campos.at(1), 'ana@ejemplo.com');
      await tester.enterText(campos.at(2), '12345678');
      await tester.enterText(campos.at(3), '12345678');
      await tester.enterText(campos.at(2), 'abcdefgh');
      await tester.pump();
      expect(find.text('Las contraseñas no coinciden.'), findsOneWidget);
      await tester.enterText(campos.at(3), 'abcdefgh');
      await tester.tap(find.text('Registrarme'));
      await tester.pump();
      expect(find.text('Debes aceptar los términos.'), findsOneWidget);
      await tester.tap(find.byType(Checkbox));
      await tester.pump();
      await tester.tap(find.text('Registrarme'));
      await tester.pumpAndSettle();
      expect(find.text('Bienvenido'), findsOneWidget);
      expect(
        tester
            .widget<TextFormField>(find.byType(TextFormField).first)
            .controller!
            .text,
        'ana@ejemplo.com',
      );
    },
  );
}
