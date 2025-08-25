import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'pacientes_detail.dart';

class PacientesScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    String? nutriologoUid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(title: Text("Mis Pacientes")),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection("users")
            .doc(nutriologoUid)
            .collection("pacientes")
            .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text("No tienes pacientes registrados."));
          }

          return ListView(
            children: snapshot.data!.docs.map((doc) {
              Map<String, dynamic> paciente = doc.data() as Map<String, dynamic>;
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: ElevatedButton(
                  onPressed: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => DetallePacienteScreen(
        nutriologoUid: nutriologoUid!,
        pacienteUid: doc.id, // El ID del documento del paciente en Firestore
      ),
    ),
  );
},

                  child: Text(paciente['nombre'] ?? 'Paciente sin nombre'),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}