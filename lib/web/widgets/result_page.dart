import 'package:capstone/web/widgets/checked_box_component.dart';
import 'package:chewie/chewie.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class ResultPage extends StatefulWidget {
  const ResultPage(
      {super.key,
      required this.width,
      required this.semiResultControllers,
      required this.getSelectedIndices});

  final double width;
  final List<VideoPlayerController> semiResultControllers;

  final List<int> Function() getSelectedIndices;

  @override
  State<ResultPage> createState() => _ResultPageState();
}

class _ResultPageState extends State<ResultPage> {
  @override
  Widget build(BuildContext context) {
    List<int> selectedIndices = widget.getSelectedIndices();
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
          width: widget.width,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: const Color(0xffFCA311), width: 1),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Wrap(
              direction: Axis.horizontal,
              spacing: 16.0,
              runSpacing: 16.0,
              children:
                  widget.semiResultControllers.mapIndexed((index, controller) {
                return SizedBox(
                  width: 300,
                  child: Column(
                    children: [
                      ConstrainedBox(
                        constraints:
                            const BoxConstraints(maxWidth: 300, maxHeight: 200),
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
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 32,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CheckedBox(
                                index: selectedIndices.indexOf(index) + 1,
                                onPressed: () {
                                  setState(() {
                                    if (selectedIndices.contains(index)) {
                                      selectedIndices.remove(index);
                                    } else {
                                      selectedIndices.add(index);
                                    }
                                  });
                                },
                                isSelected: selectedIndices.contains(index)),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}
