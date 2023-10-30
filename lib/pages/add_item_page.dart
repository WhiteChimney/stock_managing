import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:stock_managing/tools/my_cameras.dart';
import 'package:file_picker/file_picker.dart';

class AddItemPage extends StatefulWidget {
  @override
  State<AddItemPage> createState() => _AddItemPageState();
}

class _AddItemPageState extends State<AddItemPage> {
  List<String> items = ['one', 'two', 'three', 'one', 'two', 'three', 'one'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: Text('添加物品'),
          actions: [
            IconButton(onPressed: () {}, icon: const Icon(Icons.check)),
          ],
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(context);
            },
          )),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ElevatedButton(
                      onPressed: getPictures, child: Text('添加照片')),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ElevatedButton(
                      onPressed: readPicInfo, child: Text('添加附件')),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return GestureDetector(
                    child: Padding(
                      padding: const EdgeInsets.all(18.0),
                      child: Text(item),
                    ),
                    onTap: () {
                      items.removeAt(index);
                      setState(() {});
                    },
                  );
                }),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: addEntry,
        tooltip: '添加条目',
        child: const Icon(Icons.playlist_add),
      ),
    );
  }

  void addEntry() {
    items.add('ooo');
    setState(() {});
  }

  void getPictures() async {
    if (Platform.isIOS || Platform.isAndroid) {
      CameraDescription camera = await getCamera();
      if (!context.mounted) return;
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => TakePictureScreen(camera: camera)));
    } else {
      FilePickerResult? result = await FilePicker.platform.pickFiles();

      if (result != null) {
        File file = File(result.files.single.path.toString());
        print(file.path);
      } else {
        // User canceled the picker
        print('cancelled.');
      }
    }
  }

  void readPicInfo() async {
    if (Platform.isIOS || Platform.isAndroid) {
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
    } else {
      print('Sorry, not supported. ');
    }
  }
}
