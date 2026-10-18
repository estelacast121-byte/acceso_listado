import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../modelos/publicacion.dart';
import '../servicios/publicaciones_servicio.dart';

final publicacionesServicioProvider = Provider<PublicacionesServicio>((ref) {
  final cliente = http.Client();
  ref.onDispose(cliente.close);
  return PublicacionesServicio(cliente);
});

class EstadoListado {
  const EstadoListado({
    this.publicaciones = const [],
    this.cargando = false,
    this.hayMas = true,
    this.error,
  });
  final List<Publicacion> publicaciones;
  final bool cargando;
  final bool hayMas;
  final String? error;
}

final listadoProvider = NotifierProvider.autoDispose<Listado, EstadoListado>(
  Listado.new,
);

class Listado extends Notifier<EstadoListado> {
  int _pagina = 1;
  bool _falloRecarga = false;

  // Repite la recarga desde página 1 aunque ya se haya llegado al final.
  Future<void> reintentar() => cargar(reiniciar: _falloRecarga);
  @override
  EstadoListado build() => const EstadoListado();
  Future<void> cargar({bool reiniciar = false}) async {
    // El bloqueo también evita duplicados entre refresco y scroll.
    if (state.cargando || (!reiniciar && !state.hayMas)) return;
    final pagina = reiniciar ? 1 : _pagina;
    final anteriores = state.publicaciones;
    state = EstadoListado(
      publicaciones: anteriores,
      cargando: true,
      hayMas: state.hayMas,
    );
    try {
      final nuevos = await ref
          .read(publicacionesServicioProvider)
          .obtenerPagina(pagina);
      if (!ref.mounted) return;
      _pagina = pagina + 1;
      _falloRecarga = false;
      state = EstadoListado(
        publicaciones: List.unmodifiable(
          reiniciar ? nuevos : [...anteriores, ...nuevos],
        ),
        hayMas: nuevos.length == 15,
      );
    } catch (error) {
      if (!ref.mounted) return;
      _falloRecarga = reiniciar;
      // Un error conserva los datos y no avanza la página.
      state = EstadoListado(
        publicaciones: anteriores,
        hayMas: state.hayMas,
        error: error is ErrorPublicaciones
            ? error.mensaje
            : 'Ocurrió un error al cargar. Intenta de nuevo.',
      );
    }
  }
}
