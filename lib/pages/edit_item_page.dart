import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';

import 'package:stock_managing/tools/my_cameras.dart';
import 'package:stock_managing/tools/data_processing.dart';
import 'package:stock_managing/tools/my_ssh.dart';
import 'package:stock_managing/tools/server_communication.dart';

class EditItemPage extends StatefulWidget {
  const EditItemPage({super.key, required this.itemId});
  final String itemId;
  @override
  State<EditItemPage> createState() => _EditItemPageState();
}

class _EditItemPageState extends State<EditItemPage> {
  TextEditingController idController = TextEditingController();
  List<TextEditingController> labelControllers = [];
  List<TextEditingController> contentControllers = [];

  Map<String, dynamic> json = {};
  List<String> picPaths = [];
  List<String> filePaths = [];

  @override
  void dispose() {
    idController.dispose();
    for (final controller in labelControllers) {
      controller.dispose();
    }
    for (final controller in contentControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    if (widget.itemId != '') _loadData(widget.itemId);
  }

  void _loadData(String itemId) async {
    var itemInfo = await loadItemInfo(widget.itemId);
    json = itemInfo[0];
    picPaths = itemInfo[1];
    filePaths = itemInfo[2];
    setStringToTextController(idController, widget.itemId);
    for (var key in json.keys) {
      var labelController = TextEditingController(text: key);
      var contentController = TextEditingController(text: json[key]);
      labelControllers.add(labelController);
      contentControllers.add(contentController);
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: Text(widget.itemId == '' ? '添加物品' : '修改物品'),
          actions: [
            IconButton(
                onPressed: () async {
                  const snackBar = SnackBar(
                    content: Text('文件上传中，请稍候……'),
                    duration: Duration(seconds: 2),
                  );
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(snackBar);

                  List<String> labelList = [];
                  List<String> contentList = [];
                  for (int i = 0; i < labelControllers.length; i++) {
                    labelList.add(labelControllers[i].text);
                    contentList.add(contentControllers[i].text);
                  }
                  await Future.wait([
                    saveItemInfo(idController.text, labelList, contentList,
                        picPaths, filePaths)
                  ]);
                  if (!context.mounted) return;
                  Navigator.pushReplacementNamed(context, '/homePage');
                },
                icon: const Icon(Icons.check)),
          ],
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              var pref = await loadUserPreferences();
              SshServerInfo serverInfo = loadSshServerInfoFromPref(pref);
              var cacheDir = await getApplicationCacheDirectory();
              var userDir = path.join(cacheDir.path, serverInfo.username);
              var stockingDir = path.join(userDir, 'stockings');
              var itemsDir = path.join(stockingDir, 'items');
              var jsonDir = path.join(itemsDir, widget.itemId);
              Directory(jsonDir).deleteSync(recursive: true);
              if (!context.mounted) return;
              Navigator.pop(context);
            },
          )),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusScope.of(context).requestFocus(FocusNode()),
        child: CustomScrollView(
          slivers: <Widget>[
            SliverToBoxAdapter(
              child: TextField(
                enabled: widget.itemId == '' ? true : false,
                maxLines: 1,
                decoration: const InputDecoration(
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
                        onPressed: addPictures, child: const Text('添加照片')),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ElevatedButton(
                        onPressed: addOtherFiles, child: const Text('添加附件')),
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
                      labelControllers[index], contentControllers[index]);
                },
                childCount: labelControllers.length,
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: addEntry,
        tooltip: '添加条目',
        child: const Icon(Icons.playlist_add),
      ),
    );
  }

  Column generateEntryWidget(TextEditingController labelController,
      TextEditingController contentController) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            maxLines: 1,
            decoration: const InputDecoration(
              icon: Icon(Icons.bookmark),
              border: UnderlineInputBorder(),
              hintText: '条目名称',
            ),
            controller: labelController,
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            minLines: 2,
            maxLines: 5,
            decoration: const InputDecoration(
              icon: Icon(Icons.assignment_outlined),
              border: OutlineInputBorder(),
              hintText: '条目内容',
            ),
            controller: contentController,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.delete),
          onPressed: () {
            labelController.dispose();
            labelControllers.remove(labelController);
            contentController.dispose();
            contentControllers.remove(contentController);
            setState(() {});
          },
        )
      ],
    );
  }

  void addEntry() {
    final labelController = TextEditingController();
    final contentController = TextEditingController();
    labelControllers.add(labelController);
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
      picPaths.add(picPath);
      setState(() {});
    } else {
      FilePickerResult? result = await FilePicker.platform.pickFiles();

      if (result != null) {
        picPaths.add(result.files.single.path.toString());
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
            return const Image(
                image: AssetImage('assets/images/image_loading_failed.png'));
          },
        ),
        IconButton(
          onPressed: () {
            picPaths.remove(picPath);
            setState(() {});
          },
          icon: const Icon(Icons.delete),
        ),
      ],
    );
  }

  void addOtherFiles() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      filePaths.add(result.files.single.path.toString());
      setState(() {});
    }
  }

  Row generateFilesWidget(String filePath) {
    return Row(
      children: [
        const Icon(Icons.file_present),
        SizedBox(
          width: MediaQuery.of(context).size.width - 64,
          child: Text(path.basename(filePath)),
        ),
        IconButton(
          onPressed: () {
            filePaths.remove(filePath);
            setState(() {});
          },
          icon: const Icon(Icons.delete),
        ),
      ],
    );
  }
}
