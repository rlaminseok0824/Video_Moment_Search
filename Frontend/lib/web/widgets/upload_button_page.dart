import 'package:ffmpeg_wasm/ffmpeg_wasm.dart';
import 'package:flutter/material.dart';

class UploadButtonPage extends StatefulWidget {
  const UploadButtonPage(
      {super.key,
      required this.setStateCallback,
      required this.ffmpeg,
      required this.pickFile});

  final Function setStateCallback;
  final FFmpeg ffmpeg;
  final Function pickFile;

  @override
  State<UploadButtonPage> createState() => _UploadButtonPageState();
}

class _UploadButtonPageState extends State<UploadButtonPage> {
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        try {
          if (await widget.pickFile()) {}
        } catch (e) {
          const ContinuousRectangleBorder();
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_upload, color: Color(0xffE5E5E5)),
            SizedBox(width: 8),
            Text('Upload Video', style: TextStyle(color: Color(0xffE5E5E5))),
          ],
        ),
      ),
    );
  }
}
