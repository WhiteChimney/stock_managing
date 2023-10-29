import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../tools/my_cameras.dart';

class AddItemPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: Text('添加条目'),
          leading: Icon(Icons.arrow_back),
        ),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text('Home')),
            Text('something'),
            ElevatedButton(
                onPressed: () async {
                  CameraDescription camera = await getCamera();
                  if (!context.mounted) return;
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => TakePictureScreen(
                                camera: camera,
                              )));
                },
                child: Text('Get Cameras')),
            ElevatedButton(
                onPressed: () async {
                  late String fileName;
                  try {
                    var filePath = await getApplicationCacheDirectory();
                    fileName =
                        '${filePath.path}/CAP_D6C6C735-90E7-4E84-A62A-DEF1A1598EF8.jpg';
                    var file = File(fileName);
                    print(await file.exists());
                    var image = Image.file(
                      file,
                      width: 100,
                      height: 200,
                    );
                    print('The image fullname is ${fileName}');
                    print(image);
                    print('The image size is ${image.width} x ${image.height}');
                  } catch (err) {
                    print(err);
                    return;
                  }

                  if (!context.mounted) return;

                  // If the picture was taken, display it on a new screen.
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => DisplayPictureScreen(
                        // Pass the automatically generated path to
                        // the DisplayPictureScreen widget.
                        imagePath: fileName,
                      ),
                    ),
                  );
                },
                child: Text('try to read image info')),
          ],
        ));
  }
}
