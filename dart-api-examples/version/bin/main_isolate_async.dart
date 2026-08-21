// Copyright (c) 2026 piper-phonemize contributors
//
// Pure Dart CLI example: async initialization in multiple isolates.

import 'dart:isolate';

import 'package:piper_phonemize/piper_phonemize.dart' as piper;

Future<void> worker(SendPort sendPort) async {
  // Each isolate must initialize independently
  await piper.initBindingsAsync();
  final version = piper.PiperPhonemize.getVersion();
  sendPort.send('Worker isolate version: $version');
}

Future<void> main() async {
  // Initialize in main isolate
  await piper.initBindingsAsync();
  final mainVersion = piper.PiperPhonemize.getVersion();
  print('Main isolate version: $mainVersion');

  // Spawn a worker isolate
  final receivePort = ReceivePort();
  await Isolate.spawn(worker, receivePort.sendPort);

  receivePort.listen((message) {
    print(message);
    receivePort.close();
  });
}
