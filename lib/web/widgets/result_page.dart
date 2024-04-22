import 'package:capstone/web/widgets/checked_box_component.dart';
import 'package:chewie/chewie.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class ResultPage extends StatefulWidget {
  const ResultPage({
    super.key,
    required this.width,
    required this.semiResultControllers,
    required this.getSelectedIndices,
    required this.getTexts,
    required this.getTimeStamps,
  });

  final double width;
  final List<VideoPlayerController> semiResultControllers;
  final List<int> Function() getSelectedIndices;
  final List<String> Function() getTexts;
  final List<List<List<String>>> Function() getTimeStamps;

  @override
  State<ResultPage> createState() => _ResultPageState();
}

class _ResultPageState extends State<ResultPage> {
  List<Widget> _buildCols(List<String> texts,
      List<List<List<String>>> timeStamps, List<int> selectedIndices) {
    final List<Widget> videoRows = [];
    int idx = 0;
    for (int i = 0; i < texts.length; i++) {
      int currCount = timeStamps[i].length;

      videoRows.add(_buildvideosRow(texts[i], idx, currCount, selectedIndices));
      idx += currCount;
    }

    return videoRows;
  }

  Widget _buildvideosRow(
      String text, int startIndex, int endIndex, List<int> selectedIndices) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '"$text"',
          style: const TextStyle(
            color: Color(0xff14213D),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 10),
        Wrap(
          spacing: 16.0,
          runSpacing: 16.0,
          children: widget.semiResultControllers
              .skip(startIndex)
              .take(endIndex)
              .mapIndexed((i, controller) {
            return SizedBox(
              width: 300,
              child: Column(
                children: [
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: 300, maxHeight: 200),
                    child: SizedBox(
                      width: controller.value.size.width,
                      height: controller.value.size.height,
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
                  SizedBox(height: 10),
                  SizedBox(
                    height: 32,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        CheckedBox(
                          index: selectedIndices.indexOf(i + startIndex) + 1,
                          onPressed: () {
                            setState(() {
                              if (selectedIndices.contains(i + startIndex)) {
                                selectedIndices.remove(i + startIndex);
                              } else {
                                selectedIndices.add(i + startIndex);
                              }
                            });
                          },
                          isSelected: selectedIndices.contains(i + startIndex),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
        Divider(), // Add divider between each set of videos
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    List<int> selectedIndices = widget.getSelectedIndices();
    List<String> texts = widget.getTexts();
    List<List<List<String>>> timeStamps = widget.getTimeStamps();

    return Column(
      children: [
        // const Center(
        //   child: Text(
        //     'Result Videos',
        //     style: TextStyle(
        //       color: Color(0xff14213D),
        //       fontSize: 24,
        //       fontWeight: FontWeight.bold,
        //     ),
        //   ),
        // ),
        const SizedBox(height: 16),
        Container(
          width: widget.width,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: const Color(0xffFCA311), width: 1),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _buildCols(texts, timeStamps, selectedIndices)),
          ),
        ),
      ],
    );
  }
}
