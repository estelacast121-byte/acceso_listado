import 'package:flutter/material.dart';

/// Identidad visual sencilla, dibujada con iconos de Flutter, sin imágenes externas.
class MarcaAcceso extends StatelessWidget {
  const MarcaAcceso({super.key, this.tamano = 84});
  final double tamano;
  @override
  Widget build(BuildContext context) => Container(
    width: tamano, height: tamano,
    decoration: BoxDecoration(color: const Color(0xFF102C44),
      borderRadius: BorderRadius.circular(tamano * .22)),
    child: Icon(Icons.subject_rounded, color: Colors.white, size: tamano * .6));
}
class EtiquetaAcceso extends StatelessWidget {
  const EtiquetaAcceso({super.key, required this.texto});
  final String texto;
  @override
  Widget build(BuildContext context) => Center(child: Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
    decoration: BoxDecoration(color: const Color(0xFFE5EEFF), borderRadius: BorderRadius.circular(24)),
    child: Text(texto, style: const TextStyle(color: Color(0xFF005EB8), letterSpacing: 1.2, fontSize: 12, fontWeight: FontWeight.w600))));
}
