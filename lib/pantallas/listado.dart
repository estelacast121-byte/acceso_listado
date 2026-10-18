import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../estado/listado.dart';
import '../estado/sesion.dart';
import '../widgets/marca_acceso.dart';
import 'login.dart';

class PantallaListado extends ConsumerStatefulWidget {
  const PantallaListado({super.key});
  @override
  ConsumerState<PantallaListado> createState() => _PantallaListadoState();
}

class _PantallaListadoState extends ConsumerState<PantallaListado> {
  final _scroll = ScrollController();
  @override
  void initState() {
    super.initState();
    _scroll.addListener(_alDesplazar);
    Future.microtask(() {
      if (mounted) ref.read(listadoProvider.notifier).cargar();
    });
  }

  void _alDesplazar() {
    if (_scroll.hasClients &&
        _scroll.position.extentAfter < 250 &&
        ref.read(listadoProvider).error == null) {
      ref.read(listadoProvider.notifier).cargar();
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _cerrarSesion() {
    ref.read(sesionProvider.notifier).cerrar();
    ref.invalidate(listadoProvider);
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const PantallaLogin()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final estado = ref.watch(listadoProvider);
    // En una pantalla alta, completa el espacio sin requerir un botón Cargar más.
    if (!estado.cargando &&
        estado.error == null &&
        estado.hayMas &&
        estado.publicaciones.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _alDesplazar();
      });
    }
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 80,
        automaticallyImplyLeading: false,
        title: const Row(
          children: [
            MarcaAcceso(tamano: 42),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ACCESO Y LISTADO',
                    style: TextStyle(fontSize: 11, letterSpacing: 1),
                  ),
                  Text(
                    'Publicaciones',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _cerrarSesion,
            tooltip: 'Cerrar sesión',
            color: const Color(0xFFB42318),
            icon: const Icon(Icons.logout),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Sesión: ${ref.watch(sesionProvider) ?? ""}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: estado.cargando
                            ? null
                            : () => ref
                                  .read(listadoProvider.notifier)
                                  .cargar(reiniciar: true),
                        icon: const Icon(Icons.sync),
                        label: const Text('Recargar'),
                      ),
                    ],
                  ),
                ),
                if (estado.cargando && estado.publicaciones.isNotEmpty)
                  const LinearProgressIndicator(),
                if (estado.error != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3F2),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFF1BAB5)),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Color(0xFFB42318),
                          ),
                          const SizedBox(height: 8),
                          Text(estado.error!, textAlign: TextAlign.center),
                          const SizedBox(height: 12),
                          FilledButton.icon(
                            onPressed: () =>
                                ref.read(listadoProvider.notifier).reintentar(),
                            icon: const Icon(Icons.refresh),
                            label: const Text('Reintentar'),
                          ),
                        ],
                      ),
                    ),
                  ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () => ref
                        .read(listadoProvider.notifier)
                        .cargar(reiniciar: true),
                    child: ListView.builder(
                      controller: _scroll,
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(20),
                      itemCount: estado.publicaciones.length + 1,
                      itemBuilder: (context, indice) {
                        if (indice == estado.publicaciones.length) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Column(
                              children: [
                                if (estado.cargando) ...[
                                  const CircularProgressIndicator(),
                                  const SizedBox(height: 12),
                                  Text(
                                    estado.publicaciones.isEmpty
                                        ? 'Cargando publicaciones…'
                                        : 'Cargando más publicaciones…',
                                  ),
                                ] else if (estado.error != null)
                                  const SizedBox.shrink()
                                else if (estado.publicaciones.isEmpty)
                                  const Text('No hay publicaciones.')
                                else if (!estado.hayMas)
                                  const Text('Has llegado al final.')
                                else
                                  const Text(
                                    'Desliza para ver más publicaciones.',
                                  ),
                                if (estado.publicaciones.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  Text(
                                    '${estado.publicaciones.length} publicaciones cargadas',
                                  ),
                                ],
                              ],
                            ),
                          );
                        }
                        final publicacion = estado.publicaciones[indice];
                        return Card(
                          color: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                            side: const BorderSide(color: Color(0xFFE8EDF5)),
                          ),
                          margin: const EdgeInsets.only(bottom: 16),
                          child: Padding(
                            padding: const EdgeInsets.all(18),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFDCE9FF),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Icon(
                                    Icons.article_outlined,
                                    color: Color(0xFF102C44),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFEEF3FF),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        child: Text(
                                          'PUBLICACIÓN ${publicacion.id}',
                                          style: const TextStyle(
                                            color: Color(0xFF005EB8),
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        publicacion.titulo,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        publicacion.contenido,
                                        style: const TextStyle(height: 1.5),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
