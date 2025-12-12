import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

/// DB 파일 경로 확인용 헬퍼
class DbPathHelper {
  /// DB 파일 경로 출력
  static Future<void> printDbPath() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'maeumbom.db'));

    print('═══════════════════════════════════════');
    print('📂 DB File Location:');
    print('   ${file.path}');
    print('═══════════════════════════════════════');
    print('📊 DB File Info:');
    print('   Exists: ${file.existsSync()}');
    if (file.existsSync()) {
      print('   Size: ${file.lengthSync()} bytes');
      print('   Last Modified: ${file.lastModifiedSync()}');
    }
    print('═══════════════════════════════════════');
  }
}
