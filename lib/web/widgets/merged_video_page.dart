import 'package:capstone/web/widgets/checked_box_component.dart';
import 'package:chewie/chewie.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class MergedVideoPage extends StatefulWidget {
  const MergedVideoPage({
    super.key,
    required this.width,
    required this.resultControllers,
    required this.getSelectedIndices,
  });

  final double width;
  final List<VideoPlayerController> resultControllers;
  final List<int> Function() getSelectedIndices;

  @override
  State<MergedVideoPage> createState() => _MergedVideoPageState();
}

class _MergedVideoPageState extends State<MergedVideoPage> {
  @override
  Widget build(BuildContext context) {
    List<int> selectedIndices = widget.getSelectedIndices();
    return Column(
      children: [
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
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Wrap(spacing: 16, runSpacing: 16, children: [
                ...widget.resultControllers.mapIndexed((i, controller) {
                  return Column(
                    children: [
                      ConstrainedBox(
                        constraints:
                            BoxConstraints(maxWidth: 300, maxHeight: 200),
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
                              index: selectedIndices.indexOf(i) + 1,
                              onPressed: () {
                                setState(() {
                                  if (selectedIndices.contains(i)) {
                                    selectedIndices.remove(i);
                                  } else {
                                    selectedIndices.add(i);
                                  }
                                });
                              },
                              isSelected: selectedIndices.contains(i),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ])
            ]),
          ),
        ),
      ],
    );
  }
}
