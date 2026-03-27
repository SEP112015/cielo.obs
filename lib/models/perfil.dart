class Perfil {
  final int id;
  final String nombre;
  final String apellido;
  final String matricula;
  final String fotoPath;
  final String frase;

  Perfil({
    required this.id,
    required this.nombre,
    required this.apellido,
    required this.matricula,
    required this.fotoPath,
    required this.frase,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'apellido': apellido,
      'matricula': matricula,
      'foto_path': fotoPath,
      'frase': frase,
    };
  }

  factory Perfil.fromMap(Map<String, dynamic> map) {
    return Perfil(
      id: map['id'],
      nombre: map['nombre'],
      apellido: map['apellido'],
      matricula: map['matricula'],
      fotoPath: map['foto_path'],
      frase: map['frase'],
    );
  }
}