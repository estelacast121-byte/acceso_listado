import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:acceso_listado/estado/listado.dart';
import 'package:acceso_listado/pantallas/listado.dart';
import 'package:acceso_listado/servicios/publicaciones_servicio.dart';

String datosPagina(int pagina) {
  final inicio = (pagina - 1) * 15 + 1;
  return jsonEncode([
    for (var id = inicio; id < inicio + 15 && id <= 100; id++)
      {'id': id, 'title': 'Publicación $id', 'body': 'Contenido de prueba'},
  ]);
}

void main() {
  testWidgets(
    'Recargar sin conexión muestra aviso visible, conserva 100 y reintenta página 1',
    (tester) async {
      var sinConexion = false;
      final paginas = <int>[];
      final cliente = MockClient((solicitud) async {
        final pagina = int.parse(solicitud.url.queryParameters['_page']!);
        paginas.add(pagina);
        expect(solicitud.url.queryParameters['_limit'], '15');
        expect(solicitud.headers['Cache-Control'], 'no-cache');
        if (sinConexion) {
          throw http.ClientException('Failed to fetch', solicitud.url);
        }
        return http.Response(datosPagina(pagina), 200);
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
      for (var pagina = 1; pagina <= 7; pagina++) {
        await listado.cargar();
      }
      expect(contenedor.read(listadoProvider).publicaciones.length, 100);
      expect(contenedor.read(listadoProvider).hayMas, isFalse);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: contenedor,
          child: const MaterialApp(home: PantallaListado()),
        ),
      );
      await tester.pumpAndSettle();
      sinConexion = true;
      await tester.tap(find.text('Recargar'));
      await tester.pumpAndSettle();
      expect(paginas, [1, 2, 3, 4, 5, 6, 7, 1]);
      expect(contenedor.read(listadoProvider).publicaciones.length, 100);
      expect(
        find.textContaining('Revisa tu conexión a Internet'),
        findsOneWidget,
      );
      expect(find.text('Reintentar').hitTestable(), findsOneWidget);
      expect(find.text('PUBLICACIÓN 1'), findsOneWidget);
      // Reintentar desconectado vuelve a solicitar la página 1.
      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();
      expect(paginas.last, 1);
      expect(paginas.length, 9);
      expect(contenedor.read(listadoProvider).publicaciones.length, 100);
      sinConexion = false;
      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();
      expect(paginas.last, 1);
      expect(paginas.length, 10);
      expect(find.text('Reintentar'), findsNothing);
      expect(contenedor.read(listadoProvider).publicaciones.length, 15);
      expect(contenedor.read(listadoProvider).hayMas, isTrue);
    },
  );

  test(
    'Página posterior sin conexión conserva datos y reintenta la misma página',
    () async {
      var sinConexion = false;
      final paginas = <int>[];
      final cliente = MockClient((solicitud) async {
        final pagina = int.parse(solicitud.url.queryParameters['_page']!);
        paginas.add(pagina);
        if (sinConexion) throw http.ClientException('Network error');
        return http.Response(datosPagina(pagina), 200);
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
      await listado.cargar();
      sinConexion = true;
      await listado.cargar();
      expect(contenedor.read(listadoProvider).publicaciones.length, 15);
      expect(contenedor.read(listadoProvider).error, contains('Internet'));
      sinConexion = false;
      await listado.reintentar();
      expect(paginas, [1, 2, 2]);
      expect(contenedor.read(listadoProvider).publicaciones.length, 30);
      expect(contenedor.read(listadoProvider).error, isNull);
    },
  );
}
