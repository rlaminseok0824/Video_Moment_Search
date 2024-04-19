import 'package:flutter/material.dart';

class CheckedBox extends StatefulWidget {
  const CheckedBox(
      {super.key,
      required this.index,
      required this.onPressed,
      required this.isSelected});

  final int index;
  final Function onPressed;
  final bool isSelected;

  @override
  State<CheckedBox> createState() => _CheckedBoxState();
}

class _CheckedBoxState extends State<CheckedBox> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        widget.onPressed();
      },
      child: Container(
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: widget.isSelected ? Colors.blue : Colors.grey,
          shape: BoxShape.circle,
        ),
        child: SizedBox(
          width: 24,
          height: 24,
          child: FittedBox(
            child: widget.isSelected
                ? Text('${widget.index}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold))
                : const Icon(
                    Icons.check_box_outline_blank,
                    color: Colors.white,
                    size: 14,
                  ),
          ),
        ),
      ),
    );
  }
}
