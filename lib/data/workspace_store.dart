import 'package:flutter/foundation.dart';

import '../domain/workspace.dart';
import 'demo.dart';
import 'repository.dart';

class WorkspaceStore extends ChangeNotifier {
  final WorkspaceRepository repository;
  Workspace? workspace;
  bool loading = true, saving = false;
  Object? error;
  WorkspaceStore(this.repository);
  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final stored = await repository.load();
      final next = stored ?? demoWorkspace(DateTime.now());
      if (stored == null) await repository.save(next);
      workspace = next;
    } catch (e) {
      error = e;
    }
    loading = false;
    notifyListeners();
  }

  Future<void> update(Workspace Function(Workspace) transform) async {
    if (saving || workspace == null) throw StateError('busy');
    saving = true;
    notifyListeners();
    try {
      final next = transform(workspace!);
      await repository.save(next);
      workspace = next;
    } finally {
      saving = false;
      notifyListeners();
    }
  }

  Future<void> saveClient(Client client) => update(
    (w) =>
        w.copy(clients: [...w.clients.where((c) => c.id != client.id), client]),
  );
  Future<void> deleteClient(String id) => update((w) {
    if (w.jobs.any(
      (j) => j.clientId == id || j.history.any((e) => e.clientId == id),
    )) {
      throw StateError('referenced');
    }
    return w.copy(clients: w.clients.where((c) => c.id != id).toList());
  });
  Future<void> saveJob(Job job) => update(
    (w) => w.copy(jobs: [...w.jobs.where((j) => j.id != job.id), job]),
  );
}
