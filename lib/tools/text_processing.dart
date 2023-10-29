import 'package:flutter/material.dart';

void setStringToTextController (var textController, var str) {
  textController.value = textController.value.copyWith(
    text: str.isEmpty? '' : str,
    selection: TextSelection(
      baseOffset: str.length, 
      extentOffset: str.length),
    composing: TextRange.empty,);
}