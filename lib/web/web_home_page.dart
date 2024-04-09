import 'dart:js' as js;
import 'dart:html' as html;

import 'package:capstone/apis/api.dart';
import 'package:chewie/chewie.dart';
import 'package:collection/collection.dart';
import 'package:cross_file/cross_file.dart';
import 'package:ffmpeg_wasm/ffmpeg_wasm.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class WebHomePage extends StatefulWidget {
  const WebHomePage({super.key});

  @override
  State<WebHomePage> createState() => _WebHomePageState();
}

class _WebHomePageState extends State<WebHomePage> {
  late FFmpeg ffmpeg;
  late XFile xfileVideo;
  FilePickerResult? filePickerResult;
  String? videoTitle;
  VideoPlayerController? controller; // MainVideoController
  final TextEditingController _textEditingController = TextEditingController();
  final List<String> _messages = [];
  final List<VideoPlayerController> semiResultControllers = [];

  final progress = ValueNotifier<double?>(null);
  final statistics = ValueNotifier<String?>(null);

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    loadFFmpeg();
  }

  @override
  void dispose() {
    progress.dispose();
    statistics.dispose();

    super.dispose();
  }

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
    return const Center(
      child: Column(
        children: [
          Text(
            'Upload a video to get started',
            style: TextStyle(
                color: Color(0xff14213D),
                fontSize: 24,
                fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildContainer() {
    double width = MediaQuery.of(context).size.width * 0.4;
    double height = MediaQuery.of(context).size.height * 0.6;

    BoxBorder border = Border.all(color: const Color(0xffFCA311), width: 1);

    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            decoration: BoxDecoration(border: border),
            width: width,
            height: height,
            child: (videoTitle == null) ? _uploadButton() : _buildVideoPlayer(),
          ),
          Container(
              width: width,
              height: height,
              decoration: BoxDecoration(border: border),
              child: Stack(
                children: [
                  SingleChildScrollView(
                    child: Column(children: [
                      ..._messages.mapIndexed((index, message) {
                        return Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Align(
                            alignment: index.isEven
                                ? Alignment.topRight
                                : Alignment.topLeft,
                            child: Container(
                              padding: const EdgeInsets.all(8.0),
                              decoration: BoxDecoration(
                                color: const Color(0xffFCA311),
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              child: Text(
                                message,
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                      const SizedBox(height: 75)
                    ]),
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(height: 50, color: Colors.white),
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextField(
                        controller: _textEditingController,
                        style: const TextStyle(color: Colors.white),
                        enabled:
                            (videoTitle != null && videoTitle!.isNotEmpty) &&
                                !isLoading,
                        decoration: InputDecoration(
                            hintText: 'Enter your text here',
                            hintStyle: const TextStyle(color: Colors.white),
                            filled: true,
                            fillColor: const Color(0xffFCA311),
                            border: const OutlineInputBorder(
                              borderSide: BorderSide.none,
                            ),
                            suffixIcon: IconButton(
                                icon:
                                    const Icon(Icons.send, color: Colors.white),
                                onPressed: () async {
                                  setState(() {
                                    if (_textEditingController
                                        .text.isNotEmpty) {
                                      _messages
                                          .add(_textEditingController.text);
                                      _textEditingController.clear();
                                      isLoading = true;
                                    }
                                  });
                                  final timeStamps = await getTimeStamps();
                                  for (int i = 0; i < timeStamps.length; i++) {
                                    await trimGivenTimeStamps(timeStamps[i]);
                                  }

                                  setState(() {
                                    _messages.add(timeStamps.toString());
                                    isLoading = false;
                                  });
                                })),
                        maxLines: 1,
                      ),
                    ),
                  ),
                  (isLoading)
                      ? const Center(child: CircularProgressIndicator())
                      : Container(),
                ],
              )),
        ],
      ),
    );
  }

  Widget _buildVideoPlayer() {
    if (controller != null && controller!.value.isInitialized) {
      return Chewie(
        controller: ChewieController(
          videoPlayerController: controller!,
          aspectRatio: controller!.value.aspectRatio,
          autoPlay: true,
        ),
      );
    } else {
      return Container();
    }
  }

  Widget _uploadButton() {
    return InkWell(
      onTap: () async {
        try {
          await pickFile();
          if (videoTitle != null) {
            controller =
                VideoPlayerController.networkUrl(Uri.parse(xfileVideo.path))
                  ..initialize().then((_) {
                    setState(() {});
                  });
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

  Widget _buildResult() {
    double width = MediaQuery.of(context).size.width * 0.8;
    return Column(
      children: [
        const Center(
          child: Text(
            'Result Video',
            style: TextStyle(
              color: Color(0xff14213D),
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: width,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: const Color(0xffFCA311), width: 1),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: semiResultControllers.map((controller) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: 400),
                    child: SizedBox(
                      height: 200,
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.black),
                        ),
                        child: Chewie(
                          controller: ChewieController(
                            videoPlayerController: controller,
                            aspectRatio: controller.value.aspectRatio,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: _buildAppBar(),
        body: SafeArea(
            child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                _buildDescription(),
                _buildContainer(),
                const SizedBox(height: 16),
                _buildResult(),
              ],
            ),
          ),
        )));
  }

  void loadFFmpeg() async {
    ffmpeg = createFFmpeg(CreateFFmpegParam(
        log: true,
        corePath: 'https://unpkg.com/@ffmpeg/core@0.11.0/dist/ffmpeg-core.js'));

    ffmpeg.setProgress(_onProgressHandler);
    ffmpeg.setLogger(_onLogHandler);

    await ffmpeg.load();
  }

  void _onProgressHandler(ProgressParam progress) {
    final isDone = progress.ratio >= 1;

    this.progress.value = isDone ? null : progress.ratio;
    if (isDone) {
      statistics.value = null;
    }
  }

  static final regex = RegExp(
    r'frame\s*=\s*(\d+)\s+fps\s*=\s*(\d+(?:\.\d+)?)\s+q\s*=\s*([\d.-]+)\s+L?size\s*=\s*(\d+)\w*\s+time\s*=\s*([\d:\.]+)\s+bitrate\s*=\s*([\d.]+)\s*(\w+)/s\s+speed\s*=\s*([\d.]+)x',
  );

  void _onLogHandler(LoggerParam logger) {
    if (logger.type == 'fferr') {
      final match = regex.firstMatch(logger.message);

      if (match != null) {
        // indicates the number of frames that have been processed so far.
        final frame = match.group(1);
        // is the current frame rate
        final fps = match.group(2);
        // stands for quality 0.0 indicating lossless compression, other values indicating that there is some lossy compression happening
        final q = match.group(3);
        // indicates the size of the output file so far
        final size = match.group(4);
        // is the time that has elapsed since the beginning of the conversion
        final time = match.group(5);
        // is the current output bitrate
        final bitrate = match.group(6);
        // for instance: 'kbits/s'
        final bitrateUnit = match.group(7);
        // is the speed at which the conversion is happening, relative to real-time
        final speed = match.group(8);

        statistics.value =
            'frame: $frame, fps: $fps, q: $q, size: $size, time: $time, bitrate: $bitrate$bitrateUnit, speed: $speed';
      }
    }
  }

  Future<void> pickFile() async {
    final filePickerResult =
        await FilePicker.platform.pickFiles(type: FileType.video);
    if (filePickerResult != null &&
        filePickerResult.files.single.bytes != null) {
      ffmpeg.writeFile('input.mp4', filePickerResult.files.single.bytes!);
      setState(() {
        videoTitle = filePickerResult.files.single.name;
        xfileVideo = XFile.fromData(filePickerResult.files.single.bytes!);
      });
    }
  }

  Future<void> trimGivenTimeStamps(List<String> timeStamp) async {
    await ffmpeg.run([
      '-i',
      'input.mp4',
      '-ss',
      timeStamp[0],
      '-to',
      timeStamp[1],
      '-c',
      'copy',
      'output.mp4',
    ]);

    final video = ffmpeg.readFile('output.mp4');
    final XFile newVideo = XFile.fromData(video);

    final newController =
        VideoPlayerController.networkUrl(Uri.parse(newVideo.path))
          ..initialize().then((_) {
            setState(() {});
          });

    // Add the new controller to the list
    semiResultControllers.add(newController);

    setState(() {});
  }
}
