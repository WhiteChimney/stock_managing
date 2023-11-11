import 'package:flutter/material.dart';

void showModalMessage(BuildContext context, String msg, bool showCloseButton) {
  List<Widget> w = [
    Expanded(
        child: Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(msg),
    ))
  ];
  if (showCloseButton) {
    w.add(IconButton(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.close)));
  }
  showModalBottomSheet<void>(
    enableDrag: false,
    isDismissible: false,
    context: context,
    builder: (BuildContext context) {
      return Container(
        color: Theme.of(context).colorScheme.onInverseSurface,
        child: Center(
          heightFactor: 1.5,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: w,
          ),
        ),
      );
    },
  );
}
