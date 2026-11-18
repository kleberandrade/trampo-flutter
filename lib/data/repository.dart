import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/workspace.dart';

abstract interface class WorkspaceRepository {
  Future<Workspace?> load();
  Future<void> save(Workspace workspace);
}

/// A single versioned snapshot; corrupt data is never silently overwritten.
class LocalRepository implements WorkspaceRepository {
  static const key = 'trampo.workspace.v1';
  final SharedPreferencesAsync preferences;
  LocalRepository({SharedPreferencesAsync? preferences})
    : preferences = preferences ?? SharedPreferencesAsync();
  @override
  Future<Workspace?> load() async {
    final raw = await preferences.getString(key);
    if (raw == null) return null;
    return Workspace.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  @override
  Future<void> save(Workspace workspace) =>
      preferences.setString(key, jsonEncode(workspace.toJson()));
}
