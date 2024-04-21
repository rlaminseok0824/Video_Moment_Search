import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

class ChatPage extends StatefulWidget {
  const ChatPage(
      {super.key,
      required this.isMainVideoUploaded,
      required this.trimGivenTimeStamps,
      required this.getTimeStamps});

  final bool isMainVideoUploaded;
  final Function trimGivenTimeStamps;
  final Function getTimeStamps;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final List<String> _messages = ['ex) 피자 만드는 장면을 추출해주세요.'];
  final TextEditingController _textEditingController = TextEditingController();

  bool isLoading = false;

  Future<void> _onSubmitted() async {
    setState(() {
      if (_textEditingController.text.isNotEmpty) {
        _messages.add(_textEditingController.text);
        isLoading = true;
      }
    });
    final timeStamps = await widget.getTimeStamps(_textEditingController.text);
    for (int i = 0; i < timeStamps.length; i++) {
      await widget.trimGivenTimeStamps(timeStamps[i]);
    }

    setState(() {
      _textEditingController.clear();
      _messages.add(timeStamps.toString());
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SingleChildScrollView(
          child: Column(children: [
            ..._messages.mapIndexed((index, message) {
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: Align(
                  alignment: index.isOdd || index == 0
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
              onSubmitted: (_) async {
                await _onSubmitted();
              },
              controller: _textEditingController,
              style: const TextStyle(color: Colors.white),
              enabled: !isLoading && widget.isMainVideoUploaded,
              decoration: InputDecoration(
                hintText: 'Enter your text here',
                hintStyle: const TextStyle(color: Colors.white),
                filled: true,
                fillColor: const Color(0xffFCA311),
                border: const OutlineInputBorder(
                  borderSide: BorderSide.none,
                ),
                suffixIcon: IconButton(
                    onPressed: () async {
                      await _onSubmitted();
                    },
                    icon: const Icon(Icons.send, color: Colors.white)),
              ),
              maxLines: 1,
            ),
          ),
        ),
        (isLoading)
            ? const Center(child: CircularProgressIndicator())
            : Container(),
      ],
    );
  }
}
