import 'package:capstone/apis/api.dart';
import 'package:capstone/web/video_setup.dart';
import 'package:chewie/chewie.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class WebHomePage extends StatefulWidget {
  const WebHomePage({super.key});

  @override
  State<WebHomePage> createState() => _HomePageState();
}

class _HomePageState extends State<WebHomePage> {
  final VideoSetup _videoSetup = VideoSetup();
  VideoPlayerController? controller;
  String? _videoSrc;
  final TextEditingController _textEditingController = TextEditingController();
  final List<String> _messages = [];
  final List<List<String>> _timeStamps = [];
  bool _isLoading = false;

  AppBar _buildAppBar() {
    return AppBar(
      title: const Text(
        'Capstone Service App',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      backgroundColor: const Color(0xff14213D),
    );
  }

  Widget _uploadButton() {
    return InkWell(
      onTap: () async {
        try {
          _videoSrc = await _videoSetup.getLocalVideoUrl();

          controller = VideoPlayerController.networkUrl(Uri.parse(_videoSrc!))
            ..initialize().then((_) {
              setState(() {
                _messages.clear();
              });
            });
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
            child: (_videoSrc == null || _videoSrc!.isEmpty)
                ? _uploadButton()
                : _buildVideoPlayer(),
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
                        enabled: (_videoSrc != null && _videoSrc!.isNotEmpty) &&
                            !_isLoading,
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
                                      _isLoading = true;
                                    }
                                  });
                                  _timeStamps.addAll(await getTimeStamps());
                                  setState(() {
                                    _messages.add(_timeStamps.toString());
                                    _isLoading = false;
                                  });
                                })),
                        maxLines: 1,
                      ),
                    ),
                  ),
                  (_isLoading)
                      ? const Center(child: CircularProgressIndicator())
                      : Container(),
                ],
              )),
        ],
      ),
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
                fontWeight: FontWeight.bold),
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
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xff14213D),
        onPressed: () async {
          try {
            _videoSrc = await _videoSetup.getLocalVideoUrl();

            controller = VideoPlayerController.networkUrl(Uri.parse(_videoSrc!))
              ..initialize().then((_) {
                setState(() {
                  _messages.clear();
                });
              });
          } catch (e) {
            const ContinuousRectangleBorder();
          }
        },
        child: const Icon(Icons.cloud_upload, color: Color(0xffE5E5E5)),
      ),
      body: SafeArea(
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
      ),
    );
  }
}
