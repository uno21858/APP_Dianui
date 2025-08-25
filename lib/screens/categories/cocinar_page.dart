import 'package:flutter/material.dart';
import '../../widgets/custom_app_bar.dart';

class CocinarPage extends StatelessWidget {
  const CocinarPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Cocinar'),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Página de cocinar")
          ],
        ),
      ),
    );
  }
}