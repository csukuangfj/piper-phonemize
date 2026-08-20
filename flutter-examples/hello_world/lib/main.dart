// Copyright (c) 2026 Xiaomi Corporation
//
// Flutter hello_world example for piper-phonemize.

import 'package:flutter/material.dart';
import 'package:piper_phonemize/piper_phonemize.dart' as piper;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize FFI bindings (auto-resolves native library on all platforms)
  await piper.initBindingsAsync();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'piper-phonemize hello world',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const VersionPage(),
    );
  }
}

class VersionPage extends StatelessWidget {
  const VersionPage({super.key});

  @override
  Widget build(BuildContext context) {
    final version = piper.PiperPhonemize.getVersion();

    return Scaffold(
      appBar: AppBar(
        title: const Text('piper-phonemize hello world'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('piper-phonemize version: $version',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            const Text(
              'Native library loaded successfully!',
              style: TextStyle(color: Colors.green, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
