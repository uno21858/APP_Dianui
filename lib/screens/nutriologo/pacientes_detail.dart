import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;


class DetallePacienteScreen extends StatefulWidget {
  final String nutriologoUid;
  final String pacienteUid;

  const DetallePacienteScreen({
    Key? key,
    required this.nutriologoUid,
    required this.pacienteUid,
  }) : super(key: key);

  @override
  _DetallePacienteScreenState createState() => _DetallePacienteScreenState();
}

class _DetallePacienteScreenState extends State<DetallePacienteScreen> {
  List<String> subcolecciones = [];
  String nombrePaciente = "Cargando...";

 @override
void initState() {
  super.initState();
  tzdata.initializeTimeZones(); // Ahora sí está correctamente definido
  _cargarDatosPaciente();
}



  /// Carga el nombre del paciente y sus parámetros desde Firestore
  void _cargarDatosPaciente() async {
    DocumentSnapshot pacienteDoc = await FirebaseFirestore.instance
        .collection("users")
        .doc(widget.nutriologoUid)
        .collection("pacientes")
        .doc(widget.pacienteUid)
        .get();

    if (pacienteDoc.exists) {
      List<dynamic>? lista = pacienteDoc.get("parametros");
      String nombre = pacienteDoc.get("nombre") ?? "Sin nombre";

      setState(() {
        subcolecciones = lista != null ? List<String>.from(lista) : [];
        nombrePaciente = nombre;
      });
    }
  }

  /// Agregar un nuevo parámetro (nueva subcolección)
  void _agregarNuevoParametro() async {
    TextEditingController controller = TextEditingController();
    
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Nuevo Parámetro"),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(hintText: "Ej: grasa_corporal"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancelar"),
            ),
            TextButton(
              onPressed: () async {
                String nuevoParametro = controller.text.trim();
                if (nuevoParametro.isNotEmpty && !subcolecciones.contains(nuevoParametro)) {
                  DocumentReference pacienteRef = FirebaseFirestore.instance
                      .collection("users")
                      .doc(widget.nutriologoUid)
                      .collection("pacientes")
                      .doc(widget.pacienteUid);

                  await pacienteRef.update({
                    "parametros": FieldValue.arrayUnion([nuevoParametro])
                  });

                  setState(() {
                    subcolecciones.add(nuevoParametro);
                  });
                }
                Navigator.pop(context);
              },
              child: Text("Guardar"),
            ),
          ],
        );
      },
    );
  }

  /// Construye la lista de tarjetas con las mediciones de cada parámetro
  List<Widget> buildSubcollectionCards() {
    return subcolecciones.map((subcol) {
      return StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection("users")
            .doc(widget.nutriologoUid)
            .collection("pacientes")
            .doc(widget.pacienteUid)
            .collection(subcol)
            .orderBy("timestamp", descending: true)
            .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }
          return Card(
            margin: EdgeInsets.symmetric(vertical: 10),
            child: ExpansionTile(
              title: Text(subcol, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              children: [
                ...snapshot.data!.docs.map((doc) {
                  Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                  String formattedDate = _formatTimestamp(data['timestamp']);
                  return ListTile(
                    title: Text("${data['valor']}"),
                    subtitle: Text(formattedDate),
                  );
                }).toList(),
                ListTile(
                  leading: Icon(Icons.add),
                  title: Text("Agregar nuevo dato"),
                  onTap: () => _agregarDato(subcol),
                ),
              ],
            ),
          );
        },
      );
    }).toList();
  }

  /// Agregar un nuevo dato a una subcolección
  void _agregarDato(String subcol) async {
    TextEditingController controller = TextEditingController();
    
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Agregar Dato a $subcol"),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(hintText: "Ej: 85"),
            keyboardType: TextInputType.number,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancelar"),
            ),
            TextButton(
              onPressed: () async {
                String nuevoValor = controller.text.trim();
                if (nuevoValor.isNotEmpty) {
                  await FirebaseFirestore.instance
                      .collection("users")
                      .doc(widget.nutriologoUid)
                      .collection("pacientes")
                      .doc(widget.pacienteUid)
                      .collection(subcol)
                      .add({
                        "valor": nuevoValor,
                        "timestamp": _getTimestampMexico(),
                      });
                }
                Navigator.pop(context);
              },
              child: Text("Guardar"),
            ),
          ],
        );
      },
    );
  }

  /// Convierte un Timestamp de Firestore a hora de México en formato amigable
  String _formatTimestamp(Timestamp timestamp) {
    final tzLocation = tz.getLocation('America/Mexico_City');
    final tzDateTime = tz.TZDateTime.from(timestamp.toDate(), tzLocation);
    return DateFormat("d 'de' MMMM 'de' y, h:mm a", "es_MX").format(tzDateTime);
  }

  /// Obtiene el timestamp en hora de México
  Timestamp _getTimestampMexico() {
    final tzLocation = tz.getLocation('America/Mexico_City');
    final tzDateTime = tz.TZDateTime.now(tzLocation);
    return Timestamp.fromMillisecondsSinceEpoch(tzDateTime.millisecondsSinceEpoch);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Detalles del Paciente")),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16.0),
            color: Colors.green.shade200, // Fondo verde claro
            child: Text(
              "Nombre: $nombrePaciente",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.all(16.0),
              children: [
                ...buildSubcollectionCards(),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _agregarNuevoParametro,
                  child: Text("Agregar Nuevo Parámetro"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
