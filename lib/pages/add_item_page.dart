import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
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
  TextEditingController idController = TextEditingController();
  List<TextEditingController> nameControllers = [];
  List<TextEditingController> contentControllers = [];

  List<String> picPaths = [];
  List<String> filePaths = [];

  @override
  void dispose() {
    idController.dispose();
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
            IconButton(
                onPressed: () {
                  saveItemInfo();
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.check)),
          ],
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(context);
            },
          )),
      body: CustomScrollView(
        slivers: <Widget>[
          SliverToBoxAdapter(
            child: TextField(
              maxLines: 1,
              decoration: InputDecoration(
                icon: Icon(Icons.perm_identity),
                border: UnderlineInputBorder(),
                hintText: '唯一标识符，例如：AFG_3252_20231001_001',
                labelText: '物品 ID',
                errorText: '名称中只能包含字母、数字与下划线',
              ),
              controller: idController,
            ),
          ),
          SliverToBoxAdapter(
              child: Padding(
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
          )),
          SliverToBoxAdapter(
            child: SizedBox(
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
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (BuildContext context, int index) {
                return generateFilesWidget(filePaths[index]);
              },
              childCount: filePaths.length,
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (BuildContext context, int index) {
                return generateEntryWidget(
                    nameControllers[index], contentControllers[index]);
              },
              childCount: nameControllers.length,
            ),
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

  Column generateEntryWidget(TextEditingController nameController,
      TextEditingController contentController) {
    return Column(
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

  void addPictures() async {
    if (Platform.isIOS || Platform.isAndroid) {
      CameraDescription camera = await getCamera();
      if (!context.mounted) return;
      final result = await Navigator.push(context,
          MaterialPageRoute(builder: (_) => TakePictureScreen(camera: camera)));
      String picPath = result.path;
      print(picPath);
      picPaths.add(picPath);
      setState(() {});
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
        Image.file(
          File(picPath),
          height: 144,
          errorBuilder:
              (BuildContext context, Object exception, StackTrace? stackTrace) {
            print('error occurred');
            return Image(
                image: AssetImage('assets/images/image_loading_failed.png'));
          },
        ),
        IconButton(
          onPressed: () {
            picPaths.remove(picPath);
            setState(() {});
          },
          icon: Icon(Icons.delete),
        ),
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
        Icon(Icons.file_present),
        SizedBox(
          child: Text(filePath),
          width: MediaQuery.of(context).size.width - 64,
        ),
        IconButton(
          onPressed: () {
            filePaths.remove(filePath);
            setState(() {});
          },
          icon: Icon(Icons.delete),
        ),
      ],
    );
  }

  void saveItemInfo() async {
    if (idController.text == '') return;
    var cacheDir = await getApplicationCacheDirectory();
    var userDir = path.join(cacheDir.path, 'noland');
    var stockingDir = path.join(userDir, 'stockings');
    var itemsDir = path.join(stockingDir, 'items');
    var jsonDir = path.join(itemsDir, idController.text);
    var imgDir = path.join(jsonDir, 'images');
    var fileDir = path.join(jsonDir, 'files');
    await Directory(imgDir).create(recursive: true);
    await Directory(fileDir).create(recursive: true);

    print(imgDir);

    String itemId = idController.text;

    for (int index = 0; index < picPaths.length; index++) {
      var picRead = File(picPaths[index]);
      var picExt = path.extension(picRead.path);
      await picRead.copy(path.join(imgDir, '${itemId}_${index}${picExt}'));
    }

    for (int index = 0; index < filePaths.length; index++) {
      var fileRead = File(filePaths[index]);
      var fileBase = path.basename(fileRead.path);
      await fileRead.copy(path.join(fileDir, fileBase));
    }

    Map<String, dynamic> json = {};
    for (int index = 0; index < nameControllers.length; index++) {
      json[nameControllers[index].text] = contentControllers[index].text;
    }
    var fWrite = File(path.join(jsonDir, '${itemId}.json'));
    await fWrite.writeAsString(jsonEncode(json));

    var fMainJson = File(path.join(stockingDir, 'items.json'));
    var mainJson = {};
    if (!(await fMainJson.exists())) {
      await fMainJson.create();
    } else {
      mainJson = jsonDecode(await fMainJson.readAsString());
    }
    mainJson[itemId] = 'aaa';
    await fMainJson.writeAsString(jsonEncode(mainJson));
  }
}
