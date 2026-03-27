class Observacion {
  final int? id;
  final String titulo;
  final String fechaHora;
  final double? lat;
  final double? lng;
  final String? ubicacionTexto;
  final int? duracionSeg;
  final String categoria;
  final String condicionesCielo;
  final String descripcion;
  final String? fotoPath;
  final String? audioPath;
  final String creadoEn;

  Observacion({
    this.id,
    required this.titulo,
    required this.fechaHora,
    this.lat,
    this.lng,
    this.ubicacionTexto,
    this.duracionSeg,
    required this.categoria,
    required this.condicionesCielo,
    required this.descripcion,
    this.fotoPath,
    this.audioPath,
    required this.creadoEn,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'titulo': titulo,
      'fecha_hora': fechaHora,
      'lat': lat,
      'lng': lng,
      'ubicacion_texto': ubicacionTexto,
      'duracion_seg': duracionSeg,
      'categoria': categoria,
      'condiciones_cielo': condicionesCielo,
      'descripcion': descripcion,
      'foto_path': fotoPath,
      'audio_path': audioPath,
      'creado_en': creadoEn,
    };
  }

  factory Observacion.fromMap(Map<String, dynamic> map) {
    return Observacion(
      id: map['id'],
      titulo: map['titulo'],
      fechaHora: map['fecha_hora'],
      lat: map['lat'] != null ? (map['lat'] as num).toDouble() : null,
      lng: map['lng'] != null ? (map['lng'] as num).toDouble() : null,
      ubicacionTexto: map['ubicacion_texto'],
      duracionSeg: map['duracion_seg'],
      categoria: map['categoria'],
      condicionesCielo: map['condiciones_cielo'],
      descripcion: map['descripcion'],
      fotoPath: map['foto_path'],
      audioPath: map['audio_path'],
      creadoEn: map['creado_en'],
    );
  }
}