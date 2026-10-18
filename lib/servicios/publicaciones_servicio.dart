import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../modelos/publicacion.dart';

class ErrorPublicaciones implements Exception {
  const ErrorPublicaciones(this.mensaje);
  final String mensaje;
  @override
  String toString() => mensaje;
}

class PublicacionesServicio {
  PublicacionesServicio(this.cliente);
  final http.Client cliente;
  Future<List<Publicacion>> obtenerPagina(int pagina) async {
    final uri = Uri.https('jsonplaceholder.typicode.com', '/posts', {
      '_page': '$pagina',
      '_limit': '15',
    });
    try {
      final respuesta = await cliente
          .get(uri, headers: {'Cache-Control': 'no-cache'})
          .timeout(const Duration(seconds: 15));
      if (respuesta.statusCode != 200) {
        throw ErrorPublicaciones(
          'No se pudo cargar el listado (HTTP ${respuesta.statusCode}).',
        );
      }
      final datos = jsonDecode(respuesta.body) as List<dynamic>;
      return datos
          .map((dato) => Publicacion.desdeJson(dato as Map<String, dynamic>))
          .toList();
    } on TimeoutException {
      throw const ErrorPublicaciones(
        'La conexión tardó demasiado. Intenta de nuevo.',
      );
    } on http.ClientException {
      throw const ErrorPublicaciones(
        'No se pudo conectar. Revisa tu conexión a Internet y presiona Reintentar.',
      );
    } on FormatException {
      throw const ErrorPublicaciones('El servidor devolvió datos inválidos.');
    } on TypeError {
      throw const ErrorPublicaciones('El servidor devolvió datos inválidos.');
    }
  }
}
