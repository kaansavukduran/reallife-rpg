import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';

import '../app/settings.dart';
import '../domain/codec.dart';
import '../domain/local_date.dart';
import '../domain/task_data.dart';
import 'memory_task_store.dart';
import 'task_store.dart';

@JS('localStorage')
external _Storage get _storage;

extension type _Storage(JSObject _) implements JSObject {
  external String? getItem(String key);
  external void setItem(String key, String value);
}

@JS('document.createElement')
external _Element _element(String tag);

extension type _Element(JSObject _) implements JSObject {
  external set href(String value);
  external set download(String value);
  external set type(String value);
  external set accept(String value);
  external set onchange(JSFunction value);
  external set oncancel(JSFunction value);
  external _Files? get files;
  external void click();
}

extension type _Files(JSObject _) implements JSObject {
  external int get length;
  external _File? item(int index);
}

extension type _File(JSObject _) implements JSObject {
  external String get name;
  external int get size;
  external JSPromise<JSString> text();
}

/// No network or runtime dependency: browser data stays in this origin's local
/// storage. Browsers may erase it; JSON export is still the portable backup.
class BrowserTaskStore extends MemoryTaskStore {
  static const _dataKey = 'reallife-rpg-data';
  static const _settingsKey = 'reallife-rpg-settings';
  static const _backupsKey = 'reallife-rpg-backups';
  String? _picked;
  @override
  bool get persistent => true;
  @override
  String get location => 'Bu tarayıcının yerel depolaması (site verileri)';
  @override
  String get backupLocation => 'Tarayıcı içi son 14 günlük yedek';
  @override
  Future<LoadResult> load() async {
    try {
      saved = _storage.getItem(_dataKey);
      return await super.load();
    } catch (_) {
      return const LoadUnreadable(
        'Tarayıcı depolamasına erişilemiyor. Gizlilik/depolama ayarlarını kontrol et.',
      );
    }
  }

  @override
  Future<void> save(TaskData data, {required DateTime now}) async {
    final old = _storage.getItem(_dataKey);
    if (old != null) {
      final backups = _readBackups();
      backups.putIfAbsent(
        'gorevler-${LocalDate.of(now).toIso()}.json',
        () => old,
      );
      final keys = backups.keys.toList()..sort();
      while (keys.length > 14) {
        backups.remove(keys.removeAt(0));
      }
      _storage.setItem(_backupsKey, jsonEncode(backups));
    }
    final text = encodeTaskData(data, savedAt: now);
    _storage.setItem(_dataKey, text);
    saved = text;
  }

  @override
  Future<AppSettings> loadSettings() async {
    try {
      return AppSettings.decode(_storage.getItem(_settingsKey) ?? '{}');
    } catch (_) {
      return const AppSettings();
    }
  }

  @override
  Future<void> saveSettings(AppSettings settings) async {
    _storage.setItem(_settingsKey, settings.encode());
  }

  @override
  Future<String?> exportBackup(TaskData data, {required DateTime now}) async {
    final name = 'reallife-rpg-yedek-${LocalDate.of(now).toIso()}.json';
    final link = _element('a')
      ..download = name
      ..href =
          'data:application/json;charset=utf-8,${Uri.encodeComponent(encodeTaskData(data, savedAt: now))}';
    link.click();
    return name;
  }

  Map<String, String> _readBackups() {
    final raw = jsonDecode(_storage.getItem(_backupsKey) ?? '{}');
    if (raw is! Map<String, Object?>) {
      throw const FormatException('Tarayıcı yedek listesi bozuk');
    }
    return raw.map((k, v) => MapEntry(k, v as String));
  }

  @override
  Future<List<BackupCandidate>> importCandidates() async {
    final completion = Completer<void>();
    final input = _element('input')
      ..type = 'file'
      ..accept = '.json,application/json';
    _picked = null;
    input.onchange = ((JSAny? event) {
      () async {
        try {
          final file = input.files?.item(0);
          if (file != null) {
            if (file.size > 50 * 1024 * 1024) {
              throw const FormatException('Yedek en fazla 50 MB olabilir');
            }
            _picked = (await file.text().toDart).toDart;
            decodeTaskData(_picked!);
          }
          completion.complete();
        } catch (e, st) {
          completion.completeError(e, st);
        }
      }();
    }).toJS;
    input.oncancel = ((JSAny? event) {
      if (!completion.isCompleted) completion.complete();
    }).toJS;
    input.click();
    await completion.future;
    final backups = _readBackups();
    return [
      if (_picked != null)
        BackupCandidate(
          path: 'browser:selected',
          name: 'Seçilen JSON yedeği',
          modified: DateTime.now(),
          taskCount: decodeTaskData(_picked!).tasks.length,
        ),
      for (final key in (backups.keys.toList()..sort((a, b) => b.compareTo(a))))
        BackupCandidate(
          path: key,
          name: key,
          modified: DateTime.now(),
          taskCount: decodeTaskData(backups[key]!).tasks.length,
        ),
    ];
  }

  @override
  Future<TaskData> readCandidate(BackupCandidate candidate) async =>
      decodeTaskData(
        candidate.path == 'browser:selected'
            ? _picked!
            : _readBackups()[candidate.path]!,
      );
  @override
  Future<String?> keepBeforeImport(
    TaskData data, {
    required DateTime now,
  }) async {
    final backups = _readBackups();
    final name = 'ice-aktarma-${now.millisecondsSinceEpoch}.json';
    backups[name] = encodeTaskData(data, savedAt: now);
    _storage.setItem(_backupsKey, jsonEncode(backups));
    return name;
  }

  @override
  Future<String> setAsideUnreadable({required DateTime now}) async {
    final text = _storage.getItem(_dataKey);
    final key = 'reallife-rpg-unreadable-${now.millisecondsSinceEpoch}';
    if (text != null) _storage.setItem(key, text);
    _storage.setItem(_dataKey, encodeTaskData(TaskData.empty, savedAt: now));
    return key;
  }
}
