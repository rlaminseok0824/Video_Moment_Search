import 'package:chewie/chewie.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class ResultPage extends StatefulWidget {
  const ResultPage(
      {super.key,
      required this.width,
      required this.semiResultControllers,
      required this.onSelectedIndices});

  final double width;
  final List<VideoPlayerController> semiResultControllers;
  final Function(List<int>) onSelectedIndices;

  @override
  State<ResultPage> createState() => _ResultPageState();
}

class _ResultPageState extends State<ResultPage> {
  final List<int> _selectedIndices = [];

  @override
  Widget build(BuildContext context) {
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
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  if (_selectedIndices.contains(index)) {
                                    _selectedIndices.remove(index);
                                  } else {
                                    _selectedIndices.add(index);
                                  }
                                  widget.onSelectedIndices(_selectedIndices);
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(8.0),
                                decoration: BoxDecoration(
                                  color: _selectedIndices.contains(index)
                                      ? Colors.blue
                                      : Colors.grey,
                                  shape: BoxShape.circle,
                                ),
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: Center(
                                    child: _selectedIndices.contains(index)
                                        ? Text(
                                            '${_selectedIndices.indexOf(index) + 1}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                            ))
                                        : const Icon(
                                            Icons.check_box_outline_blank,
                                            color: Colors.white,
                                            size: 14,
                                          ),
                                  ),
                                ),
                              ),
                            ),
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
