import 'package:flutter/material.dart';
import 'package:difference_editor/anomaly_editor/anomaly_editor_page.dart';
import 'package:difference_editor/difference_editor/difference_editor_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('选择编辑器'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              child: const Text('找不同编辑器'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const DifferenceEditorPage()),
                );
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              child: const Text('找异常编辑器'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AnomalyEditorPage()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
