import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

void showSnackBar(BuildContext context, String content) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(content.toString()),
      ),
    );
}

Future<File?> pickAudio() async {
  try {
    final filePickeRes = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3', 'wav', 'aac', 'flac', 'ogg'],
    );

    if (filePickeRes != null) {
      return File(filePickeRes!.files.first.xFile.path);
    }

    return null;
  } catch (e) {
    return null;
  }
}

Future<File?> pickImage() async {
  try {
    final filePickeRes = await FilePicker.pickFiles(
      type: FileType.image,
    );

    if (filePickeRes != null) {
      return File(filePickeRes!.files.first.xFile.path);
    }

    return null;
  } catch (e) {
    return null;
  }
}
