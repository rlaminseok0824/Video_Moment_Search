import 'dart:js' as js;
import 'dart:html' as html;

import 'package:capstone/apis/api.dart';
import 'package:capstone/web/widgets/chat_page.dart';
import 'package:capstone/web/widgets/floating_action_button.dart';
import 'package:capstone/web/widgets/merged_video_page.dart';
import 'package:capstone/web/widgets/result_page.dart';
import 'package:capstone/web/widgets/upload_button_page.dart';
import 'package:capstone/web/widgets/video_player_page.dart';
import 'package:cross_file/cross_file.dart';
import 'package:ffmpeg_wasm/ffmpeg_wasm.dart';
import 'package:file_picker/file_picker.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class WebHomePage extends StatefulWidget {
  const WebHomePage({super.key});

  @override
  State<WebHomePage> createState() => _WebHomePageState();
}

class _WebHomePageState extends State<WebHomePage> {
  late FFmpeg ffmpeg;
  FilePickerResult? filePickerResult;
  bool isMainVideoUploaded = false;
  int selectedIdx = 0;

  VideoPlayerController? controller; // MainVideoController
  final List<VideoPlayerController> semiResultControllers = [];
  final List<VideoPlayerController> resultControllers = [];
  final List<int> _selectedIndices = [];

  final progress = ValueNotifier<double?>(null);
  final statistics = ValueNotifier<String?>(null);

  final List<String> texts = [];
  final List<List<List<String>>> timeStamps = [];

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    loadFFmpeg();
  }

  @override
  void dispose() {
    ffmpeg.exit();
    if (controller != null) {
      controller!.dispose();
    }

    if (semiResultControllers.isNotEmpty) {
      for (var i = 0; i < semiResultControllers.length; i++) {
        semiResultControllers[i].dispose();
      }
    }

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

  void _setController(VideoPlayerController newController) {
    setState(() {
      controller = newController;
      isMainVideoUploaded = true;
    });
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
              child: (isMainVideoUploaded)
                  ? VideoPlayerComponent(
                      chewieController: controller!,
                      autoPlay: true,
                    )
                  : UploadButtonPage(
                      setStateCallback: _setController,
                      ffmpeg: ffmpeg,
                    )),
          Container(
              width: width,
              height: height,
              decoration: BoxDecoration(border: border),
              child: ChatPage(
                isMainVideoUploaded: isMainVideoUploaded,
                trimGivenTimeStamps: trimGivenTimeStamps,
                getTimeStamps: _getTimeStamps,
              )),
        ],
      ),
    );
  }

  Widget _buildResult() {
    TextStyle tabBarTextStyle = const TextStyle(
      color: Color(0xff14213D),
      fontSize: 24,
      fontWeight: FontWeight.bold,
    );

    TextStyle unselectedTabBarTextStyle = const TextStyle(
      color: Color(0xffE5E5E5),
      fontSize: 24,
      fontWeight: FontWeight.normal,
    );
    double width = MediaQuery.of(context).size.width * 0.8;
    return DefaultTabController(
      length: 2,
      child: SizedBox(
        width: width,
        height: 1000,
        child: Column(
          children: [
            TabBar(
              onTap: (value) => setState(() {
                selectedIdx = value;
              }),
              tabs: [
                Tab(
                    child: Text(
                  'Result Videos',
                  style: selectedIdx == 0
                      ? tabBarTextStyle
                      : unselectedTabBarTextStyle,
                )),
                Tab(
                  child: Text(
                    'Merged Videos',
                    style: selectedIdx != 0
                        ? tabBarTextStyle
                        : unselectedTabBarTextStyle,
                  ),
                ),
              ],
              indicatorColor: const Color(0xff14213D),
            ),
            Expanded(
              child: TabBarView(children: [
                ResultPage(
                  width: width,
                  semiResultControllers: semiResultControllers,
                  getSelectedIndices: () => _selectedIndices,
                  getTimeStamps: () => timeStamps,
                  getTexts: () => texts,
                ),
                MergedVideoPage(
                    width: width, resultControllers: resultControllers),
              ]),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: _buildAppBar(),
        floatingActionButton: CustomFloatingActionButton(
          onMergePressed: mergeVideo,
          onDownloadPressed: exportVideos,
          onUploadPressed: pickFile,
        ),
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

  Future<List<List<String>>> _getTimeStamps(String text) async {
    final results = await getTimeStamps(text);

    setState(() {
      texts.add(text);
      timeStamps.add(results);
    });

    return results;
  }

  Future<void> pickFile() async {
    final filePickerResult =
        await FilePicker.platform.pickFiles(type: FileType.video);
    if (filePickerResult != null &&
        filePickerResult.files.single.bytes != null) {
      ffmpeg.writeFile('input.mp4', filePickerResult.files.single.bytes!);
      final xfileVideo = XFile.fromData(filePickerResult.files.single.bytes!);
      final newController =
          VideoPlayerController.networkUrl(Uri.parse(xfileVideo.path));
      await newController.initialize();
      setState(() {
        isMainVideoUploaded = true;
        controller = newController;

        semiResultControllers.clear();
        _selectedIndices.clear();
      });
    }
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

  Future<void> trimGivenTimeStamps(List<String> timeStamp) async {
    final currControllerLength = semiResultControllers.length;

    await ffmpeg.run([
      '-y',
      '-i',
      'input.mp4',
      '-ss',
      timeStamp[0],
      '-to',
      timeStamp[1],
      '-c',
      'copy',
      'output$currControllerLength.mp4',
    ]);

    await ffmpeg.run([
      '-i',
      'input.mp4',
      '-ss',
      timeStamp[0],
      '-to',
      timeStamp[1],
      '-c',
      'copy',
      'output$currControllerLength.ts',
    ]);

    final video = ffmpeg.readFile('output$currControllerLength.mp4');
    final XFile newVideo = XFile.fromData(video);

    final newController =
        VideoPlayerController.networkUrl(Uri.parse(newVideo.path))
          ..initialize().then((_) {
            setState(() {});
          });
    semiResultControllers.add(newController);

    setState(() {});
  }

  Future<void> mergeVideo() async {
    if (_selectedIndices.isEmpty) {
      return;
    }

    final inputFiles = [];
    for (var i = 0; i < _selectedIndices.length; i++) {
      inputFiles.add('output${_selectedIndices.elementAt(i)}.ts');
    }

    await ffmpeg.run([
      '-i',
      'concat:${inputFiles.join('|')}',
      '-c',
      'copy',
      'output_merged.mp4',
    ]);
    // '-y -i "concat:$firstVideoPath|$secondVideoPath" -c copy $outputPath'

    // 이제 concat이 되는데 이렇게 되면 너무 오래 걸림
    // await ffmpeg.runCommand(
    //     '-y -i output0.mp4 -i output1.mp4 -r 24000/1001 -filter_complex [0:v]scale=1080:1920[v0];[1:v]scale=1080:1920[v1];[v0][v1]concat=n=2:v=1:[outv] -map [outv] -vsync 2 output.mp4');

    final video = ffmpeg.readFile('output_merged.mp4');
    final XFile newVideo = XFile.fromData(video);

    final newController =
        VideoPlayerController.networkUrl(Uri.parse(newVideo.path))
          ..initialize().then((_) {
            setState(() {});
          });

    resultControllers.add(newController);

    setState(() {
      _selectedIndices.clear();
    });
  }

  Future<void> exportVideos() async {
    if (_selectedIndices.isEmpty) {
      return;
    }

    for (int i = 0; i < _selectedIndices.length; i++) {
      await exportVideo(i, _selectedIndices.elementAt(i));
    }

    setState(() {
      _selectedIndices.clear();
    });
  }

  Future<void> exportVideo(int idx1, int idx2) async {
    await FileSaver.instance.saveFile(
        name: "output$idx1.mp4", bytes: ffmpeg.readFile("output$idx2.mp4"));
  }

  void deleteVideo(int selectedIndex) {
    ffmpeg.unlink('output$selectedIndex.mp4');
    ffmpeg.unlink('output$selectedIndex.ts');
  }
}
