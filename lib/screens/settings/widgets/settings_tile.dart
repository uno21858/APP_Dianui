import 'package:flutter/material.dart';


// Widget reutilizable para automatizar los elementos de configuración
class SettingsTile extends StatelessWidget{
  final String text;
  final VoidCallback onTap;

  const SettingsTile({
    super.key,
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 55,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey,
            width: 1.0,
          ),
        ),
      ),
      child: TextButton(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
          alignment: Alignment.centerLeft,
          foregroundColor: Colors.white,
        ),
        onPressed: onTap,
        child: Text(
          text,
          style: const TextStyle(color: Colors.black),
        ),
      ),
    );
  }
}