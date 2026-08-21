// Copyright (c) 2026 piper-phonemize contributors
//
// Pure Dart CLI example: sync initialization in multiple isolates.

import 'dart:isolate';

import 'package:piper_phonemize/piper_phonemize.dart' as piper;

void worker(SendPort sendPort) {
  // Each isolate must initialize independently
  piper.initBindings();
  final version = piper.PiperPhonemize.getVersion();
  sendPort.send('Worker isolate version: $version');
}

void main() {
  // Initialize in main isolate
  piper.initBindings();
  final mainVersion = piper.PiperPhonemize.getVersion();
  print('Main isolate version: $mainVersion');

  // Spawn a worker isolate
  final receivePort = ReceivePort();
  Isolate.spawn(worker, receivePort.sendPort);

  receivePort.listen((message) {
    print(message);
    receivePort.close();
  });
}
