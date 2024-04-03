import 'dart:io';

import 'package:capstone/app/video_editor.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class AppHomePage extends StatefulWidget {
  const AppHomePage({super.key});

  @override
  State<AppHomePage> createState() => _AppHomePageState();
}

class _AppHomePageState extends State<AppHomePage> {
  final ImagePicker _picker = ImagePicker();

  AppBar _buildAppBar() {
    return AppBar(
      title: const Text(
        'Capstone Service App',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      backgroundColor: const Color(0xff14213D),
    );
  }

  Widget _buildDescription() {
    return const Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            Text('Please upload a video to get started',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 20),
          ],
        ));
  }

  void _pickVideo() async {
    final XFile? file = await _picker.pickVideo(source: ImageSource.gallery);

    if (mounted && file != null) {
      Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VideoEditor(file: File(file.path)),
          ));
    }
  }

  Widget _buildUploadButton() {
    return Center(
      child: InkWell(
        onTap: _pickVideo,
        child: Container(
          width: 300,
          height: 300,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            color: const Color(0xffE5E5E5),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cloud_upload, color: Color(0xff14213D)),
              SizedBox(width: 8),
              Text('Upload Video', style: TextStyle(color: Color(0xff14213D)))
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: _buildAppBar(),
        body: SafeArea(
            child: Column(
          children: [
            _buildDescription(),
            _buildUploadButton(),
          ],
        )));
  }
}
