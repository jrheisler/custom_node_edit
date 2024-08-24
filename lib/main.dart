import 'package:flutter/material.dart';
import 'node_editor.dart';

void main() {
  runApp(const CustomNodeEditorApp());
}

class CustomNodeEditorApp extends StatelessWidget {
  const CustomNodeEditorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Custom Node Editor',
      theme: ThemeData.dark(), // Default to dark mode
      home: NodeEditor(),
    );
  }
}
