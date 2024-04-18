import 'package:flutter/material.dart';

class CustomFloatingActionButton extends StatefulWidget {
  const CustomFloatingActionButton(
      {super.key,
      required this.onDownloadPressed,
      required this.onMergePressed,
      required this.onUploadPressed});

  final Function onDownloadPressed;
  final Function onMergePressed;
  final Function onUploadPressed;

  @override
  State<CustomFloatingActionButton> createState() =>
      _CustomFloatingActionButtonState();
}

class _CustomFloatingActionButtonState extends State<CustomFloatingActionButton>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
  }

  void _toggleExpansion() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (_isExpanded)
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.only(bottom: 10),
                child: SizedBox(
                  width: 56,
                  height: 56,
                  child: FloatingActionButton(
                    heroTag: null,
                    onPressed: () async {
                      await widget.onUploadPressed();
                    },
                    tooltip: "Upload Video",
                    child: const Icon(Icons.upload),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.only(bottom: 10),
                child: SizedBox(
                  width: 56,
                  height: 56,
                  child: FloatingActionButton(
                    heroTag: null,
                    onPressed: () async {
                      await widget.onMergePressed();
                    },
                    tooltip: "Merge Selected Video",
                    child: const Icon(Icons.merge),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.only(bottom: 10),
                child: SizedBox(
                  width: 56,
                  height: 56,
                  child: FloatingActionButton(
                    heroTag: null,
                    onPressed: () async {
                      await widget.onDownloadPressed();
                    },
                    tooltip: "export Video",
                    child: const Icon(Icons.download),
                  ),
                ),
              ),
            ],
          ),
        Container(
          alignment: Alignment.bottomRight,
          child: SizedBox(
            width: 56,
            height: 56,
            child: FittedBox(
              child: FloatingActionButton(
                onPressed: _toggleExpansion,
                child: Icon(_isExpanded ? Icons.close : Icons.add),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
