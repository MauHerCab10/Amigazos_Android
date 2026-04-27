import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

Future<void> mostrarDialogoEdicion(
  BuildContext context, {
  required String docId,
  required String nombreActual,
  required DateTime fechaActual,
  required CollectionReference amigos,
  required String userId,
}) async {
  bool esValido = nombreActual.trim().isNotEmpty;
  String? mensajeErrorDialogo;
  DateTime fechaEditCumpleanos = fechaActual;

  final TextEditingController editController = TextEditingController(
    text: nombreActual,
  );
  final TextEditingController cumpleanosController = TextEditingController(
    text: DateFormat('dd/MM/yyyy').format(fechaActual),
  );

  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text(
              'Actualizar Nombre',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: editController,
                  decoration: InputDecoration(
                    hintText: "Nuevo nombre",
                    errorText: mensajeErrorDialogo,
                  ),
                  onChanged: (value) {
                    setDialogState(() {
                      if (value.trim().isEmpty) {
                        esValido = false;
                        mensajeErrorDialogo =
                            'El nombre de amigo no puede estar vacío';
                      } else {
                        esValido = true;
                        mensajeErrorDialogo = null;
                      }
                    });
                  },
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: cumpleanosController,
                  readOnly: true,
                  decoration: const InputDecoration(
                    hintText: "Cumpleaños",
                    suffixIcon: Icon(Icons.calendar_month),
                  ),
                  onTap: () async {
                    DateTime hoy = DateTime.now();
                    final DateTime? fechaSeleccionada = await showDatePicker(
                      context: context,
                      initialDate: fechaEditCumpleanos,
                      firstDate: DateTime(1900),
                      lastDate: hoy,
                      locale: const Locale("es", "ES"),
                    );
                    if (fechaSeleccionada != null) {
                      setDialogState(() {
                        fechaEditCumpleanos = fechaSeleccionada;
                        cumpleanosController.text = DateFormat(
                          'dd/MM/yyyy',
                        ).format(fechaSeleccionada);
                      });
                    }
                  },
                ),
              ],
            ),
            actions: [
              //Acción "Cancelar"
              TextButton(
                onPressed: () {
                  editController.clear();
                  cumpleanosController.clear();
                  Navigator.pop(context);
                  FocusScope.of(context).unfocus();
                },
                child: const Text('Cancelar'),
              ),
              //Acción "Guardar cambios"
              ElevatedButton(
                onPressed: esValido
                    ? () async {
                        String nuevoNombre = editController.text.trim();

                        //Si el nombre y la fecha son idénticos, solo se cierra la ventana
                        if (nuevoNombre == nombreActual &&
                            fechaEditCumpleanos == fechaActual) {
                          Navigator.pop(context);
                          FocusScope.of(context).unfocus();
                          return;
                        }

                        //Consultamos en Firebase amigos con ese nombre ingresado
                        final consulta = await amigos
                            .where('UserID', isEqualTo: userId)
                            .where('Nombre', isEqualTo: nuevoNombre)
                            .get();

                        //Si el único resultado es el mismo registro no lo considera duplicado
                        final existeOtro = consulta.docs.any(
                          (doc) => doc.id != docId,
                        );

                        if (existeOtro) {
                          setDialogState(() {
                            esValido = false;
                            mensajeErrorDialogo =
                                'Este amigo ya lo tienes registrado en la BD';
                          });
                          return;
                        } else {
                          //Actualiza el registro en Firebase
                          await amigos.doc(docId).update({
                            'Nombre': nuevoNombre,
                            'FechaCumpleanos': fechaEditCumpleanos,
                          });

                          if (!context.mounted) return;

                          Navigator.pop(context);
                          FocusScope.of(context).unfocus();

                          //Mensaje emergente del proceso
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text.rich(
                                TextSpan(
                                  text: '"',
                                  children: [
                                    TextSpan(
                                      text: nuevoNombre,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Color.fromARGB(
                                          255,
                                          255,
                                          255,
                                          255,
                                        ),
                                      ),
                                    ),
                                    const TextSpan(
                                      text:
                                          '" ha sido actualizado satisfactoriamente.',
                                    ),
                                  ],
                                ),
                              ),
                              backgroundColor: Colors.blue,
                            ),
                          );
                        }
                      }
                    : null,
                child: const Text('Guardar Cambios'),
              ),
            ],
          );
        },
      );
    },
  );

  editController.dispose();
  cumpleanosController.dispose();
}

Future<void> mostrarDialogoEliminacion(
  BuildContext context, {
  required String docId,
  required String nombre,
  required CollectionReference amigos,
}) async {
  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return AlertDialog(
        title: const Text(
          '¿Eliminar amigo?',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text.rich(
          TextSpan(
            text: 'Estás a punto de eliminar a "',
            children: [
              TextSpan(
                text: nombre,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const TextSpan(
                text: '". Esta acción no se puede deshacer ¿Estás seguro?',
              ),
            ],
          ),
        ),
        actions: [
          //Acción "Cancelar"
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              FocusScope.of(context).unfocus();
            },
            child: const Text('Cancelar'),
          ),
          //Acción "Eliminar amigo"
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              //Elimina al amigo de Firebase
              amigos.doc(docId).delete();

              if (!context.mounted) return;

              Navigator.pop(context);
              FocusScope.of(context).unfocus();

              //Mensaje emergente del proceso
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text.rich(
                    TextSpan(
                      text: '"',
                      children: [
                        TextSpan(
                          text: nombre,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color.fromARGB(255, 255, 255, 255),
                          ),
                        ),
                        const TextSpan(
                          text: '" ha sido eliminado satisfactoriamente.',
                        ),
                      ],
                    ),
                  ),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            child: const Text(
              'Eliminar',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      );
    },
  );
}
