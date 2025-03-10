import 'dart:ffi';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

class FilePickerService {
  static Future<String?> pickFile() async {
    if (Platform.isWindows) {
      return _pickFileWindows();
    } else {
      return _pickFileMobile();
    }
  }

  static Future<String?> _pickFileMobile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    return result?.files.single.path;
  }

  static String? _pickFileWindows() {
    final buffer = wsalloc(MAX_PATH);
    final result = GetOpenFileName(buffer as Pointer<OPENFILENAME>);

    if (result == 1) {
      final filePath = buffer.toDartString();
      free(buffer);
      return filePath;
    }

    free(buffer);
    return null;
  }
}
