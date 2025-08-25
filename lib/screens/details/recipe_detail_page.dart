import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import '../../models/recipe.dart';
import '../../widgets/custom_app_bar.dart';

class RecipeDetailPage extends StatefulWidget {
  final Recipe recipe;

  const RecipeDetailPage({super.key, required this.recipe});

  @override
  State<RecipeDetailPage> createState() => _RecipeDetailPageState();
}

class _RecipeDetailPageState extends State<RecipeDetailPage> {
  String _authorName = 'Cargando...';
  bool _isLoadingAuthor = true;

  @override
  void initState() {
    super.initState();
    if (widget.recipe.author.isNotEmpty) {
      _loadAuthorInfo();
    } else {
      setState(() {
        _authorName = 'Autor desconocido';
        _isLoadingAuthor = false;
      });
    }
  }

  Future<void> _loadAuthorInfo() async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.recipe.author)
          .get();

      if (mounted) {
        setState(() {
          _authorName = userDoc.exists ?
          (userDoc['name'] ?? 'Usuario desconocido') : 'Usuario no encontrado';
          _isLoadingAuthor = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _authorName = 'Error al cargar autor';
          _isLoadingAuthor = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: widget.recipe.name),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen de la receta
            Container(
              width: double.infinity,
              height: 350,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: widget.recipe.imageUrl.startsWith('http')
                    ? Image.network(
                  widget.recipe.imageUrl,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Image.asset(
                      'assets/images/default.png',
                      fit: BoxFit.cover,
                    );
                  },
                )
                    : Image.asset(
                  'assets/images/default.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Descripción de la receta
            Text(
              widget.recipe.description.isNotEmpty
                  ? widget.recipe.description
                  : 'Descripción no disponible',
              style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
            ),

            const SizedBox(height: 20),
            const Text(
              'Ingredientes:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            // Lista de ingredientes
            widget.recipe.ingredients.isNotEmpty
                ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: widget.recipe.ingredients
                  .map((ingredient) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Text('- $ingredient'),
              ))
                  .toList(),
            )
                : const Text('No hay ingredientes disponibles.'),

            const SizedBox(height: 20),
            const Text(
              'Pasos para Preparar:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            widget.recipe.steps.isNotEmpty
                ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: widget.recipe.steps
                  .map((step) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Text('- $step'),
              ))
                  .toList(),
            )
                : const Text('No hay pasos disponibles.'),

            const SizedBox(height: 40),

            // Sección del autor
            const Divider(),
            const SizedBox(height: 10),
            const Text(
              'Subido por:',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _isLoadingAuthor
                ? const CircularProgressIndicator()
                : Text(
              _authorName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 20),

            // Botón para descargar receta en PDF
            Center(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.download),
                label: const Text('Descargar receta'),
                onPressed: _downloadRecipeAsPDF,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _downloadRecipeAsPDF() async {
    // Solicitar permisos de almacenamiento según la versión de Android
    if (Platform.isAndroid) {
      if (await Permission.manageExternalStorage.isGranted == false && await Permission.storage.isGranted == false) {
        var status = await Permission.manageExternalStorage.request();
        if (!status.isGranted) {
          status = await Permission.storage.request();
          if (!status.isGranted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Permiso de almacenamiento denegado.')),
            );
            return;
          }
        }
      }
    }

    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(widget.recipe.name, style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Text('Descripción:', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.Text(widget.recipe.description.isNotEmpty ? widget.recipe.description : 'Descripción no disponible'),
              pw.SizedBox(height: 16),
              pw.Text('Ingredientes:', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              if (widget.recipe.ingredients.isNotEmpty)
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: widget.recipe.ingredients.map((i) => pw.Text('- $i')).toList(),
                )
              else
                pw.Text('No hay ingredientes disponibles.'),
              pw.SizedBox(height: 16),
              pw.Text('Pasos para Preparar:', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              if (widget.recipe.steps.isNotEmpty)
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: widget.recipe.steps.map((s) => pw.Text('- $s')).toList(),
                )
              else
                pw.Text('No hay pasos disponibles.'),
              pw.SizedBox(height: 16),
              pw.Divider(),
              pw.Text('Subido por: ${_authorName}', style: pw.TextStyle(fontSize: 14)),
            ],
          );
        },
      ),
    );

    try {
      String? downloadsDir;
      if (Platform.isAndroid) {
        // Para Android, guardar en la carpeta de descargas pública
        downloadsDir = '/storage/emulated/0/Download';
      } else {
        // Para iOS y otros, usar el directorio de documentos
        final directory = await getApplicationDocumentsDirectory();
        downloadsDir = directory.path;
      }
      final file = File('$downloadsDir/${widget.recipe.name.replaceAll(' ', '_')}.pdf');
      await file.writeAsBytes(await pdf.save());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Receta guardada en PDF: ${file.path}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar PDF: $e')),
      );
    }
  }
}