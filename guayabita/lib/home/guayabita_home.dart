import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../auth/change_password_page.dart';
import '../auth/login_page.dart';

class GuayabitaHome extends StatefulWidget {
  const GuayabitaHome({super.key});

  @override
  State<GuayabitaHome> createState() => GuayabitaHomeState();
}

class GuayabitaHomeState extends State<GuayabitaHome> {
  String? _errorNombre;
  String? _errorCumpleanos;
  final ScrollController _controllerScrollBar = ScrollController();

  DateTime? _fechaAddCumpleanos;

  //Controlador para leer lo que el usuario digita en el teclado
  final TextEditingController _controller = TextEditingController();
  final TextEditingController _controllerAddCumpleanos =
      TextEditingController();

  //Referencia a la "carpeta" en la nube donde guardaremos los datos
  final CollectionReference _amigos = FirebaseFirestore.instance.collection(
    'amigos',
  );

  //usuario que entra a la App
  final usuario = FirebaseAuth.instance.currentUser;

  // @override
  // //'initState' es la preparación para la renderización de la pantalla tras bambalinas antes q todo
  // void initState() {
  //   super.initState();
  // }

  @override
  //'build()' es el "Arquitecto" de la pantalla, función encargada de dibujar (renderizar) la UI
  //'BuildContext' es el "Mapa de Ubicación" del widget, le dice a Flutter dónde está ubicado este widget dentro del árbol de widgets y las funciones q puede cumplir
  //Construcción de la UI de Bienvenida habiendose logueado en la App
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        //AppBar
        appBar: AppBar(
          title: Text.rich(
            TextSpan(
              text: 'Bienvenido \n',
              style: const TextStyle(
                fontWeight: FontWeight.normal,
                fontSize: 18,
              ),
              children: [
                TextSpan(
                  text:
                      usuario?.displayName ??
                      usuario?.email?.split('@')[0] ??
                      'Usuario',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
          backgroundColor: const Color.fromARGB(255, 234, 234, 234),
          surfaceTintColor: Colors.transparent,

          //Shadow
          shadowColor: Colors.black.withValues(alpha: 0.4),
          elevation: 4,
          scrolledUnderElevation: 4,

          //Menu
          actions: [
            PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == 'change_password') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ChangePasswordPage(),
                    ),
                  );
                } else if (value == 'logout') {
                  await FirebaseAuth.instance.signOut();

                  //Navega a la pantalla de 'Login' y elimina el historial de navegación para evitar que el usuario pueda regresar a la pantalla de 'Bienvenido' usando el botón de retroceso
                  if (mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (context) => const LoginPage(),
                      ),
                      (route) => false,
                    );
                  }
                }
              },
              itemBuilder: (BuildContext context) => [
                const PopupMenuItem<String>(
                  value: 'change_password',
                  child: Text('Cambiar contraseña'),
                ),
                const PopupMenuItem<String>(
                  value: 'logout',
                  child: Text('Cerrar sesión'),
                ),
              ],
            ),
          ],
        ),
        body: Column(
          children: [
            //PARTE #1: Formulario para escribir (Create)
            Padding(
              padding: const EdgeInsets.only(
                left: 20,
                right: 5,
                top: 16,
                bottom: 16,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  //Textbox para ingresar el nombre del amigo a registrar en la BD
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: 'Nombre de amigo',
                        errorText: _errorNombre,
                        contentPadding: EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 10,
                        ),
                      ),
                      onChanged: (value) {
                        if (_errorNombre != null) {
                          setState(() {
                            _errorNombre = null;
                          });
                        }
                      },
                    ),
                  ),

                  //Espacio entre el TextBox del nombre y el DatePicker de cumpleaños
                  const SizedBox(width: 10),

                  //DatePicker para seleccionar la fecha de cumpleaños del amigo a registrar en la BD
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _controllerAddCumpleanos,
                      readOnly: true,
                      decoration: InputDecoration(
                        hintText: "Cumpleaños",
                        errorText: _errorCumpleanos,
                        suffixIcon: Icon(Icons.calendar_month),
                        contentPadding: EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 10,
                        ),
                      ),
                      onTap: _seleccionarFechaCumpleanos,
                    ),
                  ),

                  //Botón para agregar el amigo a la BD
                  IconButton(
                    icon: const Icon(
                      Icons.add_circle,
                      color: Colors.green,
                      size: 40,
                    ),

                    //Función para validar el nombre del amigo a registrar y agregarlo a la BD
                    onPressed: () async {
                      String nombre = _controller.text.trim();

                      //Consulta la existencia del amigo a ser insertado en la BD
                      final consulta = await _amigos
                          .where('Nombre', isEqualTo: nombre)
                          .get();

                      if (consulta.docs.isNotEmpty) {
                        setState(() {
                          _errorNombre =
                              'Este amigo ya lo tienes registrado en la BD';
                        });
                      } else {
                        setState(() {
                          if (_controller.text.trim().isEmpty &&
                              _fechaAddCumpleanos == null) {
                            _errorNombre = '*Campo obligatorio';
                            _errorCumpleanos = '*Campo obligatorio';
                          } else if (_controller.text.trim().isEmpty) {
                            _errorNombre = '*Campo obligatorio';
                          } else if (_fechaAddCumpleanos == null) {
                            _errorCumpleanos = '*Campo obligatorio';
                          } else {
                            _errorNombre = null;
                            _errorCumpleanos = null;
                            FocusScope.of(context).unfocus();

                            //Inserta el registro en Firebase
                            _amigos.add({
                              'UserID': usuario!.uid,
                              'Nombre': nombre,
                              'FechaCumpleanos': _fechaAddCumpleanos,
                              'FechaCreacion': FieldValue.serverTimestamp(),
                            });

                            if (!mounted) return;

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
                                          color: Colors.white,
                                        ),
                                      ),
                                      const TextSpan(
                                        text:
                                            '" ha sido agregado correctamente.',
                                      ),
                                    ],
                                  ),
                                ),
                                backgroundColor: Colors.green,
                              ),
                            );

                            //Limpia el formulario después de agregar el amigo a la BD para evitar cualquier almacenamiento en memoria y previene posibles fugas de memoria
                            _controller.clear();
                            _controllerAddCumpleanos.clear();
                            _fechaAddCumpleanos = null;
                          }
                        });
                      }
                    },
                  ),
                ],
              ),
            ),

            //LISTA de Amigos
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                //Lista de amigos ÚNICA por usuario registrado
                stream: _amigos
                    .where('UserID', isEqualTo: usuario!.uid)
                    .orderBy('FechaCreacion', descending: true)
                    .snapshots(),

                //Esta instrucción abre un canal de comunicación constante con Firebase. Escucha los cambios automática e instantaneamente
                builder: (context, snapshot) {
                  //Mientras cargue los datos desde Firebase, muestre un Loader
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  //Validación para cuando la lista de amigos está vacía
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.person_off, size: 80, color: Colors.grey),
                          SizedBox(height: 10),
                          Text(
                            '¡No hay registros todavía!',
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                          Text('Registra un amigo para empezar.'),
                        ],
                      ),
                    );
                  }

                  //Lista de los registros almacenados actualizada en tiempo real (Read)
                  var docs = snapshot.data!.docs.toList();

                  //Se ordena la lista de amigos por cumpleaños más próximo
                  docs.sort((a, b) {
                    final fechaA = (a['FechaCumpleanos'] as Timestamp).toDate();
                    final fechaB = (b['FechaCumpleanos'] as Timestamp).toDate();

                    final diasA = diasParaCumpleanos(fechaA);
                    final diasB = diasParaCumpleanos(fechaB);

                    return diasA.compareTo(diasB);
                  });

                  //ScrollBar de la lista de amigos
                  return Scrollbar(
                    controller: _controllerScrollBar,
                    trackVisibility: true,
                    thickness: 8.0,
                    radius: const Radius.circular(10),
                    child: ListView.builder(
                      key: const PageStorageKey<String>('lista_amigos'),
                      controller: _controllerScrollBar,
                      itemCount: docs.length,
                      // ignore: non_constant_identifier_names
                      itemBuilder: (context, reset_password) {
                        var doc = docs[reset_password];

                        final fechaCumpleanos =
                            (doc['FechaCumpleanos'] as Timestamp).toDate();
                        final diasFaltantes = diasParaCumpleanos(
                          fechaCumpleanos,
                        );

                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          child: ListTile(
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    doc['Nombre'],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Cumpleaños: ${formatearFechaCumpleanos(fechaCumpleanos)}",
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
                                  doc['FechaCreacion'] != null
                                      ? DateFormat('dd-MM-yyyy hh:mm a')
                                            .format(
                                              (doc['FechaCreacion']
                                                      as Timestamp)
                                                  .toDate(),
                                            )
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
                                  //Botón de EDITAR (Update)
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit,
                                      color: Colors.blue,
                                    ),
                                    //Función para mostrar la ventana de edición del amigo seleccionado
                                    onPressed: () {
                                      _mostrarVentanaEdicion(
                                        doc.id,
                                        doc['Nombre'],
                                        (doc['FechaCumpleanos'] as Timestamp)
                                            .toDate(),
                                      );
                                    },
                                  ),
                                  //Botón de ELIMINAR (Delete)
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                    //Función para mostrar la ventana de confirmación de eliminación del amigo seleccionado
                                    onPressed: () {
                                      _mostrarVentanaConfirmarEliminacion(
                                        doc.id,
                                        doc['Nombre'],
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  //Ventana de "Actualizar Amigo"
  void _mostrarVentanaEdicion(
    String docId,
    String nombreActual,
    DateTime fechaActual,
  ) {
    bool esValido = nombreActual.trim().isNotEmpty;
    String? mensajeErrorDialogo;
    DateTime fechaEditCumpleanos = fechaActual;

    final TextEditingController editController = TextEditingController(
      text: nombreActual,
    );

    final TextEditingController cumpleanosController = TextEditingController(
      text: DateFormat('dd/MM/yyyy').format(fechaActual),
    );

    showDialog(
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
              //Acción "Cancelar"
              actions: [
                TextButton(
                  //Limpia el controlador para evitar que el texto quede almacenado en memoria y previene posibles fugas de memoria
                  onPressed: () {
                    editController.clear();
                    cumpleanosController.clear();
                    Navigator.pop(context); //Cierra la ventanita
                    FocusScope.of(
                      context,
                    ).unfocus(); //Oculta el teclado en pantalla
                    //FocusManager.instance.primaryFocus?.unfocus();
                  },
                  child: const Text('Cancelar'),
                ),
                //Acción "Guardar cambios"
                ElevatedButton(
                  onPressed: esValido
                      ? () async {
                          String nuevoNombre = editController.text.trim();

                          //Si el nombre es idéntico al actual, no se insertan duplicados, solo se cierra la ventana
                          if (nuevoNombre == nombreActual &&
                              fechaEditCumpleanos == fechaActual) {
                            Navigator.pop(context); //Cierra la ventanita
                            FocusScope.of(
                              context,
                            ).unfocus(); //Oculta el teclado en pantalla
                            //FocusManager.instance.primaryFocus?.unfocus();
                            return;
                          }

                          //Consultamos en Firebase amigos con ese nombre ingresado
                          final consulta = await _amigos
                              .where('Nombre', isEqualTo: nuevoNombre)
                              .get();

                          //Si el único resultado es el mismo registro (doc.id == docId) no lo considera duplicado
                          final existeOtro = consulta.docs.any(
                            (doc) => doc.id != docId,
                          );

                          //Muestra error si existe otro documento diferente con el mismo nombre
                          if (existeOtro) {
                            setDialogState(() {
                              esValido = false;
                              mensajeErrorDialogo =
                                  'Este amigo ya lo tienes registrado en la BD';
                            });
                            return;
                          } else {
                            //Actualiza el registro en Firebase
                            await _amigos.doc(docId).update({
                              'Nombre': nuevoNombre,
                              'FechaCumpleanos': fechaEditCumpleanos,
                            });

                            //Chequeo de seguridad q para validar si el widget sigue vivo
                            if (!context.mounted) return;

                            Navigator.pop(context); //Cierra la ventanita
                            FocusScope.of(
                              context,
                            ).unfocus(); //Oculta el teclado en pantalla
                            //FocusManager.instance.primaryFocus?.unfocus();

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
  }

  //Ventana de "Eliminar Amigo"
  void _mostrarVentanaConfirmarEliminacion(String docId, String nombre) {
    showDialog(
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
                Navigator.pop(context); //Cierra la ventanita
                FocusScope.of(
                  context,
                ).unfocus(); //Oculta el teclado en pantalla
                //FocusManager.instance.primaryFocus?.unfocus();
              },
              child: const Text('Cancelar'),
            ),
            //Acción "Eliminar amigo"
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                //Elimina al amigo de Firebase
                _amigos.doc(docId).delete();

                //Chequeo de seguridad q para validar si el widget sigue vivo
                if (!context.mounted) return;

                Navigator.pop(context); //Cierra la ventanita
                FocusScope.of(
                  context,
                ).unfocus(); //Oculta el teclado en pantalla
                //FocusManager.instance.primaryFocus?.unfocus();

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

  //función para abrir el calendario y seleccionar la fecha de cumpleaños
  Future<void> _seleccionarFechaCumpleanos() async {
    DateTime hoy = DateTime.now();

    final DateTime? fechaSeleccionada = await showDatePicker(
      context: context,
      initialDate: hoy,
      firstDate: DateTime(1900),
      lastDate: hoy,
      locale: const Locale("es", "ES"),
    );

    if (!mounted) return;

    if (fechaSeleccionada != null) {
      setState(() {
        _fechaAddCumpleanos = fechaSeleccionada;
        _controllerAddCumpleanos.text = DateFormat('dd/MM/yyyy').format(
          fechaSeleccionada,
        ); //Formatea la fecha seleccionada en el TextField del formulario

        _errorCumpleanos = null; // Limpia el mensaje de error si había uno
      });
    }
  }

  //Función q calcula los días restantes para el cumpleaños:
  int diasParaCumpleanos(DateTime fechaCumple) {
    final hoy = DateTime.now();

    final cumpleEsteAno = DateTime(
      hoy.year,
      fechaCumple.month,
      fechaCumple.day,
    );

    if (cumpleEsteAno.isBefore(DateTime(hoy.year, hoy.month, hoy.day))) {
      //Si ya pasó este año, se calcula para el próximo año
      final cumpleProximoAno = DateTime(
        hoy.year + 1,
        fechaCumple.month,
        fechaCumple.day,
      );
      return cumpleProximoAno
          .difference(DateTime(hoy.year, hoy.month, hoy.day))
          .inDays;
    } else {
      return cumpleEsteAno
          .difference(DateTime(hoy.year, hoy.month, hoy.day))
          .inDays;
    }
  }

  //función para formatear la fecha de cumpleaños en formato "dd/MMMM" y con el mes en mayúscula
  String formatearFechaCumpleanos(DateTime fecha) {
    String fechaFormateada = DateFormat('dd/MMMM', 'es_ES').format(fecha);
    return fechaFormateada.replaceFirstMapped(
      RegExp(r'\/\w'),
      (match) => match.group(0)!.toUpperCase(),
    );
  }

  //Libera los controladores para evitar fugas de memoria y mantener la estabilidad de la App
  @override
  void dispose() {
    _controller.dispose();
    _controllerAddCumpleanos.dispose();
    _controllerScrollBar.dispose();
    super.dispose();
  }
}
