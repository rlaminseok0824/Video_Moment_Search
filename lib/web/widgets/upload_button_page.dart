import 'package:cross_file/cross_file.dart';
import 'package:ffmpeg_wasm/ffmpeg_wasm.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class UploadButtonPage extends StatefulWidget {
  const UploadButtonPage(
      {super.key, required this.setStateCallback, required this.ffmpeg});

  final Function setStateCallback;
  final FFmpeg ffmpeg;

  @override
  State<UploadButtonPage> createState() => _UploadButtonPageState();
}

class _UploadButtonPageState extends State<UploadButtonPage> {
  XFile? xfileVideo;

  Future<bool> pickFile() async {
    final filePickerResult =
        await FilePicker.platform.pickFiles(type: FileType.video);
    if (filePickerResult != null &&
        filePickerResult.files.single.bytes != null) {
      widget.ffmpeg
          .writeFile('input.mp4', filePickerResult.files.single.bytes!);
      setState(() {
        xfileVideo = XFile.fromData(filePickerResult.files.single.bytes!);
      });
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        try {
          if (await pickFile()) {
            VideoPlayerController newController =
                VideoPlayerController.networkUrl(Uri.parse(xfileVideo!.path));
            await newController.initialize();
            widget.setStateCallback(newController);
          }
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
