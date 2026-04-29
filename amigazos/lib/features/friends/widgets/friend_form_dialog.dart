import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

//Función para mostrar el diálogo de edición de un Amigo
Future<void> mostrarDialogoEdicion(
  BuildContext context, {
  required String docId,
  required String nombreActual,
  required DateTime fechaActual,
  required CollectionReference amigos,
  required String userId,
}) async {
  //Obtenemos el ScaffoldMessenger para mostrar SnackBar después de cerrar el diálogo
  final scaffoldMessenger = ScaffoldMessenger.of(context);

  //linea para quitar el foco del campo de "Nombre de amigo" al abrir el dialogo
  FocusManager.instance.primaryFocus?.unfocus();

  //mostramos el diálogo de edición y esperamos a que se cierre para obtener el nombre guardado (si se guardó alguno)
  final String? nombreGuardado = await showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => _EditFriendDialog(
      docId: docId,
      nombreActual: nombreActual,
      fechaActual: fechaActual,
      amigos: amigos,
      userId: userId,
    ),
  );

  //linea para quitar el foco del campo de "Nombre de amigo" al cerrar el dialogo
  FocusManager.instance.primaryFocus?.unfocus();

  //Si el nombreGuardado es null, significa que el usuario canceló la edición o no se guardó ningún cambio, por lo que no se muestra ningún SnackBar
  if (nombreGuardado == null || !scaffoldMessenger.mounted) return;

  //Si se guardó un nuevo nombre, se muestra un SnackBar confirmando la actualización
  scaffoldMessenger.showSnackBar(
    SnackBar(
      content: Text.rich(
        TextSpan(
          text: '"',
          children: [
            TextSpan(
              text: nombreGuardado,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 255, 255, 255),
              ),
            ),
            const TextSpan(text: '" ha sido actualizado satisfactoriamente.'),
          ],
        ),
      ),
      backgroundColor: Colors.blue,
    ),
  );
}

//Widget que representa el contenido del diálogo de edición de un Amigo
class _EditFriendDialog extends StatefulWidget {
  const _EditFriendDialog({
    required this.docId,
    required this.nombreActual,
    required this.fechaActual,
    required this.amigos,
    required this.userId,
  });

  final String docId;
  final String nombreActual;
  final DateTime fechaActual;
  final CollectionReference amigos;
  final String userId;

  @override
  State<_EditFriendDialog> createState() => _EditFriendDialogState();
}

//Estado del diálogo de edición de un Amigo que maneja la lógica de validación del formulario, selección de fecha y actualización en Firebase
class _EditFriendDialogState extends State<_EditFriendDialog> {
  late final TextEditingController editController;
  late final TextEditingController cumpleanosController;
  late bool esValido;
  String? mensajeErrorDialogo;
  late DateTime fechaEditCumpleanos;

  @override
  //inicialización del estado del diálogo, configurando los controladores de texto con los valores actuales y estableciendo la validez inicial del formulario
  void initState() {
    super.initState();
    esValido = widget.nombreActual.trim().isNotEmpty;
    fechaEditCumpleanos = widget.fechaActual;
    editController = TextEditingController(text: widget.nombreActual);
    cumpleanosController = TextEditingController(
      text: DateFormat('dd/MM/yyyy').format(widget.fechaActual),
    );
  }

  @override
  //se liberan los controladores de texto para evitar fugas de memoria cuando el diálogo se cierra
  void dispose() {
    editController.dispose();
    cumpleanosController.dispose();
    super.dispose();
  }

  @override
  //Construcción del diálogo de edición con campos para el nombre y cumpleaños, validación en tiempo real y acciones para cancelar o guardar cambios
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        'Actualizar Nombre',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),

      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          //Campo de texto para el Nombre
          TextField(
            controller: editController,
            decoration: InputDecoration(
              hintText: "Nuevo nombre",
              errorText: mensajeErrorDialogo,
            ),
            onChanged: (value) {
              setState(() {
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

          //Campo de texto para el Cumpleaños
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
                setState(() {
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
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        //Acción "Guardar cambios"
        ElevatedButton(
          onPressed: esValido
              ? () async {
                  String nuevoNombre = editController.text.trim();

                  //Si el nombre y la fecha son idénticos, solo se cierra la ventana
                  if (nuevoNombre == widget.nombreActual &&
                      fechaEditCumpleanos == widget.fechaActual) {
                    Navigator.pop(context);
                    return;
                  }

                  //Consultamos en Firebase amigos con ese nombre ingresado
                  final consulta = await widget.amigos
                      .where('UserID', isEqualTo: widget.userId)
                      .where('Nombre', isEqualTo: nuevoNombre)
                      .get();

                  //Si el único resultado es el mismo registro no lo considera duplicado
                  final existeOtro = consulta.docs.any(
                    (doc) => doc.id != widget.docId,
                  );

                  if (existeOtro) {
                    setState(() {
                      esValido = false;
                      mensajeErrorDialogo =
                          'Este amigo ya lo tienes registrado en la BD';
                    });
                    return;
                  }

                  //Actualiza el registro en Firebase
                  await widget.amigos.doc(widget.docId).update({
                    'Nombre': nuevoNombre,
                    'FechaCumpleanos': fechaEditCumpleanos,
                  });

                  if (!context.mounted) return;

                  // Cerramos el diálogo devolviendo el nombre guardado
                  Navigator.pop(context, nuevoNombre);
                }
              : null,
          child: const Text('Guardar Cambios'),
        ),
      ],
    );
  }
}

//Función para mostrar el diálogo de confirmación de eliminación de un Amigo, eliminarlo de Firebase si se confirma y mostrar un SnackBar con el resultado de eliminación
Future<void> mostrarDialogoEliminacion(
  BuildContext context, {
  required String docId,
  required String nombre,
  required CollectionReference amigos,
}) async {
  final scaffoldMessenger = ScaffoldMessenger.of(context);

  //linea para quitar el foco del campo de "Nombre de amigo" al abrir el dialogo
  FocusManager.instance.primaryFocus?.unfocus();

  //se muestra el diálogo de confirmación para eliminar a un amigo, esperando a que el usuario confirme o cancele la acción
  final bool? confirmado = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
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
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          //Acción "Eliminar amigo"
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await amigos.doc(docId).delete();
              if (!dialogContext.mounted) return;
              Navigator.pop(dialogContext, true);
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

  //linea para quitar el foco del campo de "Nombre de amigo" al cerrar el dialogo
  FocusManager.instance.primaryFocus?.unfocus();

  //Si el usuario no confirmó la eliminación o el ScaffoldMessenger ya no está montado, no se muestra ningún SnackBar
  if (confirmado != true || !scaffoldMessenger.mounted) return;

  //Si se eliminó el amigo, se muestra un SnackBar confirmando la eliminación
  scaffoldMessenger.showSnackBar(
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
            const TextSpan(text: '" ha sido eliminado satisfactoriamente.'),
          ],
        ),
      ),
      backgroundColor: Colors.orange,
    ),
  );
}
