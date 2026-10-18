class Publicacion {
  const Publicacion({
    required this.id,
    required this.titulo,
    required this.contenido,
  });
  final int id;
  final String titulo;
  final String contenido;
  factory Publicacion.desdeJson(Map<String, dynamic> json) => Publicacion(
    id: json['id'] as int,
    titulo: json['title'] as String,
    contenido: json['body'] as String,
  );
}
