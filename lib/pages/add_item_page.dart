import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:stock_managing/tools/my_cameras.dart';
import 'package:file_picker/file_picker.dart';
// import 'package:json_annotation/json_annotation.dart;

class AddItemPage extends StatefulWidget {
  @override
  State<AddItemPage> createState() => _AddItemPageState();
}

class _AddItemPageState extends State<AddItemPage> {
  List<TextEditingController> nameControllers = [];
  List<TextEditingController> contentControllers = [];

  List<String> picPaths = [];
  List<String> filePaths = [];

  @override
  void dispose() {
    for (final controller in nameControllers) {
      controller.dispose();
    }
    for (final controller in contentControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: Text('添加物品'),
          actions: [
            IconButton(onPressed: saveItemInfo, icon: const Icon(Icons.check)),
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
                      onPressed: addPictures, child: Text('添加照片')),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ElevatedButton(
                      onPressed: addOtherFiles, child: Text('添加附件')),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: picPaths.length,
              itemBuilder: (context, index) {
                return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: generatePictureWidget(picPaths[index]),
                  );
              }),
          ),
          SizedBox(
            height: 100,
            child: ListView.builder(
              // scrollDirection: Axis.horizontal,
              itemCount: filePaths.length,
              itemBuilder: (context, index) {
                return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: generateFilesWidget(filePaths[index]),
                  );
              }),
          ),
          Expanded(
            child: ListView.builder(
                itemCount: nameControllers.length,
                itemBuilder: (context, index) {
                  return Padding(
                      padding: const EdgeInsets.all(18.0),
                      child: 
                      generateEntryWidget(
                        nameControllers[index],
                        contentControllers[index]),
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

  Column generateEntryWidget(
    TextEditingController nameController, 
    TextEditingController contentController) {
    return 
      Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              maxLines: 1,
              decoration: InputDecoration(
                icon: Icon(Icons.bookmark),
                border: UnderlineInputBorder(),
                hintText: '条目名称',
              ),
              controller: nameController,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              minLines: 2,
              maxLines: 5,
              decoration: InputDecoration(
                icon: Icon(Icons.assignment_outlined),
                border: OutlineInputBorder(),
                hintText: '条目内容',
              ),
              controller: contentController,
            ),
          ),
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: () {
              nameController.dispose();
              nameControllers.remove(nameController);
              contentController.dispose();
              contentControllers.remove(contentController);
              setState(() {});
            },
          )
        ],
      );
  }

  void addEntry() {
    final nameController = TextEditingController();
    final contentController = TextEditingController();
    nameControllers.add(nameController);
    contentControllers.add(contentController);
    setState(() {});
  }

  void saveItemInfo() async {
    Map<String,dynamic> json = {};
    for (int index = 0; index < nameControllers.length; index++) {
      json[nameControllers[index].text] = contentControllers[index].text;
    }

    final directory = await getApplicationCacheDirectory();
    var fWrite = File('${directory.path}/json_test.json');
    var contents = jsonEncode(json);
    fWrite.writeAsString(contents);
  }

  void addPictures() async {
    if (Platform.isIOS || Platform.isAndroid) {
      CameraDescription camera = await getCamera();
      if (!context.mounted) return;
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => TakePictureScreen(camera: camera)));
    } else {
      FilePickerResult? result = await FilePicker.platform.pickFiles();

      if (result != null) {
        picPaths.add(result.files.single.path.toString());
        print(picPaths);
        setState(() {});
      } 
    }
  }

  Column generatePictureWidget(String picPath) {
    return Column(
      children: [
        Image.file(File(picPath),
          height: 144,
          errorBuilder:
            (BuildContext context, Object exception, StackTrace? stackTrace) {
              print('error occurred');
              return Image(image: AssetImage('assets/images/image_loading_failed.png'));
            },
          ),
        IconButton(onPressed: (){
          picPaths.remove(picPath);
          setState(() {});
        }, icon: Icon(Icons.delete),),
      ],
    );
  }

  void addOtherFiles() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      filePaths.add(result.files.single.path.toString());
      print(filePaths);
      setState(() {});
    }
  }

  Row generateFilesWidget(String filePath) {
    return Row(
      children: [
        IconButton(onPressed: (){
          filePaths.remove(filePath);
          setState(() {});
        }, icon: Icon(Icons.delete),),
        SizedBox(child: Text(filePath), width: MediaQuery.of(context).size.width-56,),
      ],
    );
  }

}
