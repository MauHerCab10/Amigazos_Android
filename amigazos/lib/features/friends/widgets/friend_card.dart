import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/friend.dart';
import '../../../core/utils/birthday_utils.dart';

class FriendCard extends StatelessWidget {
  final Friend friend;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const FriendCard({
    super.key,
    required this.friend,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final diasFaltantes = diasParaCumpleanos(friend.fechaCumpleanos);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: ListTile(
        title: Row(
          children: [
            Expanded(
              child: Text(
                friend.nombre,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Cumpleaños: ${formatearFechaCumpleanos(friend.fechaCumpleanos)}",
            ),
            Text(
              diasFaltantes == 0
                  ? "¡Hoy es su cumpleaños! 🎉"
                  : diasFaltantes == 1
                  ? "Mañana"
                  : "Faltan $diasFaltantes días",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: diasFaltantes == 0
                    ? Colors.purple
                    : const Color.fromARGB(255, 35, 0, 210),
              ),
            ),
            Text(
              friend.fechaCreacion != null
                  ? DateFormat('dd-MM-yyyy hh:mm a')
                        .format(friend.fechaCreacion!)
                        .replaceAll('AM', 'a.m.')
                        .replaceAll('PM', 'p.m.')
                  : 'Guardando...',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
        trailing: SizedBox(
          width: 100,
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.blue),
                onPressed: onEdit,
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
