import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:trampo/data/demo.dart';
import 'package:trampo/data/repository.dart';
import 'package:trampo/data/workspace_store.dart';
import 'package:trampo/domain/workspace.dart';

class MemoryRepository implements WorkspaceRepository {
  Workspace? value;
  bool fail = false;
  @override
  Future<Workspace?> load() async => value;
  @override
  Future<void> save(Workspace workspace) async {
    if (fail) throw StateError('disk-full');
    value = Workspace.fromJson(
      jsonDecode(jsonEncode(workspace.toJson())) as Map<String, dynamic>,
    );
  }
}

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });
  test(
    'local plugin survives repository recreation and stores language/history',
    () async {
      final original = demoWorkspace(DateTime(2026, 11, 18))
          .copy(language: 'en');
      await LocalRepository().save(original);
      final restored = await LocalRepository().load();
      expect(restored!.language, 'en');
      expect(restored.toJson(), original.toJson());
    },
  );
  test('corrupt local data surfaces an error without reseeding', () async {
    await SharedPreferencesAsync().setString(LocalRepository.key, '{invalid');
    final store = WorkspaceStore(LocalRepository());
    await store.load();
    expect(store.error, isNotNull);
    expect(store.workspace, isNull);
    expect(
      await SharedPreferencesAsync().getString(LocalRepository.key),
      '{invalid',
    );
  });
  test('failed save keeps prior workspace and permits retry', () async {
    final repo = MemoryRepository();
    final store = WorkspaceStore(repo);
    await store.load();
    repo.fail = true;
    await expectLater(
      store.update((w) => w.copy(language: 'en')),
      throwsStateError,
    );
    expect(store.workspace!.language, 'pt');
    expect(store.saving, false);
    repo.fail = false;
    await store.update((w) => w.copy(language: 'en'));
    final reloaded = WorkspaceStore(repo);
    await reloaded.load();
    expect(reloaded.workspace!.language, 'en');
  });
  test(
    'referenced clients cannot be removed; new clients and edited jobs persist',
    () async {
      final repo = MemoryRepository();
      final store = WorkspaceStore(repo);
      await store.load();
      await expectLater(store.deleteClient('c1'), throwsStateError);
      await store.saveClient(Client('new', 'Cliente de teste', '', ''));
      await store.deleteClient('new');
      final job = store.workspace!.jobs.firstWhere(
        (j) => j.status == JobStatus.quote,
      );
      await store.saveJob(
        job.edit(
          clientId: job.clientId,
          title: 'Updated',
          notes: 'Updated scope',
          budget: Budget(10010, 20020, 30),
          now: DateTime.now(),
        ),
      );
      final reloaded = WorkspaceStore(repo);
      await reloaded.load();
      final restored = reloaded.workspace!.jobs.firstWhere(
        (j) => j.id == job.id,
      );
      expect(restored.title, 'Updated');
      expect(restored.budget.total, 30000);
      expect(restored.history.last.action, 'edited');
    },
  );
  test(
    'client reassignment preserves the original historical reference',
    () async {
      final store = WorkspaceStore(MemoryRepository());
      await store.load();
      await store.saveClient(Client('historic', 'Historical client', '', ''));
      var job = Job.create(
        id: 'audit',
        clientId: 'historic',
        title: 'Audit service',
        budget: Budget(100, 0, 0),
        now: DateTime.now(),
      );
      job = job.edit(
        clientId: 'c1',
        title: 'Edited audit',
        notes: '',
        budget: Budget(200, 0, 0),
        now: DateTime.now(),
      );
      await store.saveJob(job);
      expect(job.history.first.clientId, 'historic');
      expect(job.history.last.clientId, 'c1');
      await expectLater(store.deleteClient('historic'), throwsStateError);
    },
  );
}
