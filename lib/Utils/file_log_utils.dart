import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_media_store/flutter_media_store.dart';

class FileLogUtils {
  static final _mediaStore = FlutterMediaStore();

  static final List<Map<String, dynamic>> _buffer = [];
  static bool enabled = true;

  static String _fileName =
      'valu_quest_log_${DateTime.now().toIso8601String().replaceAll(":", "-")}.txt';

  // Salva in Download/valu_quest_logs
  static const String _rootFolderName = 'Download';
  static const String _folderName = 'valu_quest_logs';

  static String? _uri; // URI MediaStore del file log

  static void log(String title, Object? msg, {String level = 'INFO'}) {
    if (!enabled) return;

    final line = {
      'ts': DateTime.now().toIso8601String(),
      'level': level,
      'title': title,
      'msg': msg?.toString() ?? '',
    };

    _buffer.add(line);

    if (kDebugMode) {
      // ignore: avoid_print
      print('[${line['level']}] ${line['title']}: ${line['msg']}');
    }

    if (_buffer.length >= 30) {
      unawaited(flush());
    }
  }

  static Future<void> flush() async {
    if (!enabled || _buffer.isEmpty) return;

    final text = _buffer
        .map((e) => '[${e['ts']}] ${e['level']} ${e['title']} | ${e['msg']}')
        .join('\n') +
        '\n';
    _buffer.clear();

    final Uint8List fileData = Uint8List.fromList(utf8.encode(text));

    // 1) Se il file non esiste ancora, crealo con saveFile e salva l'URI
    if (_uri == null) {
      final completer = Completer<void>();

      await _mediaStore.saveFile(
        fileData: fileData,
        mimeType: 'text/plain',
        rootFolderName: _rootFolderName,
        folderName: _folderName,
        fileName: _fileName,
        onSuccess: (String uri, String filePath) {
          _uri = uri;
          completer.complete();
        },
        onError: (String errorMessage) {
          completer.completeError(errorMessage);
        },
      );

      return completer.future;
    }

    // 2) Se esiste già, append
    final completer = Completer<void>();

    await _mediaStore.appendDataToFile(
      uri: _uri!,
      fileData: fileData,
      onSuccess: (result) {
        completer.complete();
      },
      onError: (errorMessage) {
        completer.completeError(errorMessage);
      },
    );

    return completer.future;
  }

  static String currentFileName() => _fileName;
}
