import 'package:cloud_firestore/cloud_firestore.dart';

class Friend {
  final String id;
  final String nombre;
  final DateTime fechaCumpleanos;
  final DateTime? fechaCreacion;

  const Friend({
    required this.id,
    required this.nombre,
    required this.fechaCumpleanos,
    this.fechaCreacion,
  });

  factory Friend.fromDoc(DocumentSnapshot doc) {
    return Friend(
      id: doc.id,
      nombre: doc['Nombre'] as String,
      fechaCumpleanos: (doc['FechaCumpleanos'] as Timestamp).toDate(),
      fechaCreacion: doc['FechaCreacion'] != null
          ? (doc['FechaCreacion'] as Timestamp).toDate()
          : null,
    );
  }
}
