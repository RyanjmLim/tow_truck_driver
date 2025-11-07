import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:http/http.dart' as http;

class FilePreviewPage extends StatefulWidget {
  final String? fileName;
  final String? directory;
  final File? localFile;

  const FilePreviewPage({
    Key? key,
    required this.fileName,
    required this.directory,
  })  : localFile = null,
        super(key: key);

  const FilePreviewPage.localFile({
    Key? key,
    required this.localFile,
  })  : fileName = null,
        directory = null,
        super(key: key);

  @override
  State<FilePreviewPage> createState() => _FilePreviewPageState();
}

class _FilePreviewPageState extends State<FilePreviewPage> {
  Uint8List? fileBytes;
  String? contentType;
  bool isLoading = true;
  String? errorMessage;

  bool get isPdf => contentType == 'application/pdf';
  bool get isImage => contentType?.startsWith('image/') ?? false;

  @override
  void initState() {
    super.initState();
    if (widget.localFile != null) {
      _loadLocalFile();
    } else {
      _loadRemoteFile();
    }
  }

  Future<void> _loadRemoteFile() async {
    final url =
        'https://focsonmyfinger.com/MyInsurApi/api/FileServices/getview/${widget.directory}/${widget.fileName}';
    print("Preview URL: $url");


    try {
      final response = await http.get(Uri.parse(url));
      print("Headers: ${response.headers}");
      if (response.statusCode == 200) {
        String? type = response.headers['content-type'];

        // Fallback if content-type is not provided
        if (type == null || type.isEmpty || type == 'application/octet-stream') {
          final ext = widget.fileName?.split('.').last.toLowerCase();
          if (ext == 'pdf') {
            type = 'application/pdf';
          } else if (ext == 'jpg' || ext == 'jpeg') {
            type = 'image/jpeg';
          } else if (ext == 'png') {
            type = 'image/png';
          } else {
            type = 'unknown';
          }
        }


        setState(() {
          fileBytes = response.bodyBytes;
          contentType = type;
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Failed to load file (${response.statusCode})';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error: $e';
        isLoading = false;
      });
    }
  }

  Future<void> _loadLocalFile() async {
    try {
      final file = widget.localFile!;
      final bytes = await file.readAsBytes();
      final ext = file.path.split('.').last.toLowerCase();

      setState(() {
        fileBytes = bytes;
        contentType = ext == 'pdf'
            ? 'application/pdf'
            : ext == 'jpg' || ext == 'jpeg' || ext == 'png'
            ? 'image/$ext'
            : null;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Error loading local file: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text('File Preview')),
        body: Center(
            child: isLoading
                ? const CircularProgressIndicator()
                : errorMessage != null
                ? Text(errorMessage!)
                : fileBytes == null
                ? const Text("No file to preview.")
                : isPdf
                ? SfPdfViewer.memory(fileBytes!)
                : isImage
                ? Image.memory(fileBytes!)
                : const Text("Unsupported file type."),
           ),
       );
    }
}