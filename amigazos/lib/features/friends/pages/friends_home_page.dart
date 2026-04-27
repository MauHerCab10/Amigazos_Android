import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../auth/pages/change_password_page.dart';
import '../../auth/pages/login_page.dart';
import '../models/friend.dart';
import '../widgets/friend_card.dart';
import '../widgets/friend_form_dialog.dart';
import '../../../core/utils/birthday_utils.dart';

class FriendsHomePage extends StatefulWidget {
  const FriendsHomePage({super.key});

  @override
  State<FriendsHomePage> createState() => FriendsHomePageState();
}

class FriendsHomePageState extends State<FriendsHomePage> {
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

  @override
  //'build()' es el "Arquitecto" de la pantalla, función encargada de dibujar (renderizar) la UI
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

                  //Navega a la pantalla de 'Login' y elimina el historial de navegación
                  if (!context.mounted) return;

                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                    (route) => false,
                  );
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
                  //Textbox para ingresar el nombre del amigo
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

                  const SizedBox(width: 10),

                  //DatePicker para seleccionar la fecha de cumpleaños
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

                  //Botón para agregar el amigo
                  IconButton(
                    icon: const Icon(
                      Icons.add_circle,
                      color: Colors.green,
                      size: 40,
                    ),
                    onPressed: () async {
                      String nombre = _controller.text.trim();

                      //Consulta la existencia del amigo a ser insertado
                      final consulta = await _amigos
                          .where('UserID', isEqualTo: usuario!.uid)
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

                            //Limpia el formulario después de agregar
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

                  //Lista de registros actualizada en tiempo real (Read)
                  var docs = snapshot.data!.docs.toList();

                  //Se ordena la lista por cumpleaños más próximo
                  docs.sort((a, b) {
                    final fechaA = (a['FechaCumpleanos'] as Timestamp).toDate();
                    final fechaB = (b['FechaCumpleanos'] as Timestamp).toDate();
                    return diasParaCumpleanos(
                      fechaA,
                    ).compareTo(diasParaCumpleanos(fechaB));
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
                      itemBuilder: (context, index) {
                        final doc = docs[index];
                        final friend = Friend.fromDoc(doc);

                        return FriendCard(
                          friend: friend,
                          onEdit: () {
                            mostrarDialogoEdicion(
                              context,
                              docId: friend.id,
                              nombreActual: friend.nombre,
                              fechaActual: friend.fechaCumpleanos,
                              amigos: _amigos,
                              userId: usuario!.uid,
                            );
                          },
                          onDelete: () {
                            mostrarDialogoEliminacion(
                              context,
                              docId: friend.id,
                              nombre: friend.nombre,
                              amigos: _amigos,
                            );
                          },
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
        _controllerAddCumpleanos.text = DateFormat(
          'dd/MM/yyyy',
        ).format(fechaSeleccionada);
        _errorCumpleanos = null;
      });
    }
  }

  //Libera los controladores para evitar fugas de memoria
  @override
  void dispose() {
    _controller.dispose();
    _controllerAddCumpleanos.dispose();
    _controllerScrollBar.dispose();
    super.dispose();
  }
}
