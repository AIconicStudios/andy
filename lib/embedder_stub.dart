import 'dart:typed_data';

/// Stand-in where native code cannot run (the web preview).
class Embedder {
  bool get loaded => false;
  Future<void> load() async {}
  List<Int8List> embed(List<Float32List> crops) => const [];
}
