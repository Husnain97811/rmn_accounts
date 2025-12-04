import 'dart:io';
import 'dart:typed_data';
import 'package:file_saver/file_saver.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';

class PdfService {
  static Future<void> savePdf({
    required String fileName,
    required Uint8List bytes,
  }) async {
    final path = await getDownloadsDirectory();
    final outputFile = File('${path!.path}/$fileName.pdf');
    await outputFile.writeAsBytes(bytes);
    await FileSaver.instance.saveFile(
      name: fileName,
      bytes: bytes,
      ext: 'pdf',
      mimeType: MimeType.pdf,
    );
  }

  static pw.Font loadFont(List<int> fontData) {
    return pw.Font.ttf(ByteData.sublistView(Uint8List.fromList(fontData)));
  }
}
