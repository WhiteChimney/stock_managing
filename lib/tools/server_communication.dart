import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dartssh2/dartssh2.dart';
import 'package:mime/mime.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:stock_managing/tools/data_processing.dart';
import 'package:stock_managing/tools/my_ssh.dart';

Future<List> downloadJsonFromServer() async {
  // 加载配置
  var pref = await loadUserPreferences();
  SshServerInfo serverInfo = loadSshServerInfoFromPref(pref);

  // 连接服务器
  SSHClient client;
  var result = await sshConnectServer(serverInfo);
  if (!result[0]) return [result[0], result[1]];
  client = result[2];
  var sftp = await client.sftp();

  // 将远程 items.json 文件下载下来
  var remoteMainJson = ('/home/${serverInfo.username}/stockings/items.json');
  var cacheDir = await getApplicationCacheDirectory();
  var localMainJson =
      path.join(cacheDir.path, serverInfo.username, 'stockings', 'items.json');
  Map<String, dynamic> mainJson =
      jsonDecode(await File(localMainJson).readAsString());
  final fRemoteMainJson = await sftp.open(remoteMainJson);
  final content = await fRemoteMainJson.readBytes();
  mainJson.addAll(jsonDecode(latin1.decode(content)));
  await File(localMainJson).writeAsString(jsonEncode(mainJson));

  result = await sshDisconnectServer(client);
  return [result, localMainJson];
}

Future<List> loadItemInfo(String itemId) async {
  // 加载物品信息时，items.json 文件中包含条目名称，但本地缓存中不存在具体信息
  // 需要先新建文件夹：items/itemId, items/itemId/images, items/itemId/files
  SharedPreferences pref = await loadUserPreferences();
  SshServerInfo serverInfo = loadSshServerInfoFromPref(pref);
  var cacheDir = await getApplicationCacheDirectory();
  var stockingDir = path.join(cacheDir.path, serverInfo.username, 'stockings');
  var itemDir = path.join(stockingDir, 'items', itemId);
  String itemJson = path.join(itemDir, '${itemId}.json');
  await Directory(itemDir).create(recursive: true);
  await Directory(path.join(itemDir, 'images')).create(recursive: true);
  await Directory(path.join(itemDir, 'files')).create(recursive: true);

  Map<String, dynamic> json = {};
  List<String> picList = []; // 照片返回的是本地完整路径名称列表
  List<String> fileList = []; // 文件返回的是 basename 列表

  // 该情况为新建物品，直接返回空白列表
  if (itemId == '') return [json, picList, fileList];

  // 其次为已存在的物品，需要下载 itemId.json
  var result = await sshConnectServer(serverInfo);
  if (!result[0]) {
    print('server connection failed');
    return [json, picList, fileList];
  }
  SSHClient client = result[2];
  result = await Future.wait([
    sftpReceiveFile(
        client,
        '/home/${serverInfo.username}/stockings/items/${itemId}/${itemId}.json',
        itemJson)
  ]);
  result = result[0];
  if (!result[0]) {
    print('json file download failed');
    print('error info: ${result[1]}');
    return [json, picList, fileList];
  } else {
    var fJson = File(itemJson);
    json = jsonDecode(fJson.readAsStringSync());
  }

  // 然后下载 images 文件夹下的所有图片文件
  var localPicDir = path.join(itemDir, 'images');
  result = await sftpListFiles(
      client, '/home/${serverInfo.username}/stockings/items/${itemId}/images');
  if (!result[0]) {
    print('list remote images folder failed');
    return [json, picList, fileList];
  }
  var remotePicList = result[2];
  print(remotePicList);

  for (var remotePic in remotePicList) {
    var mimetype = lookupMimeType(remotePic);
    if (mimetype != null && mimetype.startsWith('image/')) {
      result = await sftpReceiveFile(
          client,
          '/home/${serverInfo.username}/stockings/items/${itemId}/images/${remotePic}',
          path.join(localPicDir, remotePic));
      if (!result[0]) {
        print('Download pic file ${remotePic} failed');
        return [json, picList, fileList];
      }
      picList.add(path.join(localPicDir, remotePic));
    }
  }

  // 下载 itemId/itemId_files.json
  result = await Future.wait([
    sftpReceiveFile(
        client,
        '/home/${serverInfo.username}/stockings/items/${itemId}/${itemId}_files.json',
        path.join(itemDir, '${itemId}_files.json'))
  ]);
  var fJson = jsonDecode(
      await File(path.join(itemDir, '${itemId}_files.json')).readAsString());
  for (var key in fJson.keys) {
    fileList.add(fJson[key]);
  }

  return [json, picList, fileList];
}

Future<List> saveItemInfo(
    String itemId,
    List<String> labelList,
    List<String> contentList,
    List<String> picPaths, // 输入的路径为用户待上传的文件路径
    List<String> filePaths) async {
  if (itemId == '') return [false, 'Item ID not specified! '];

  // 总体目标：除了 itemId/files 文件夹，其余的部分直接对远程目录进行覆盖

  // 首先找到本地各目录，并连接服务器
  var pref = await loadUserPreferences();
  SshServerInfo serverInfo = loadSshServerInfoFromPref(pref);
  var cacheDir = await getApplicationCacheDirectory();
  var userDir = path.join(cacheDir.path, serverInfo.username);
  var stockingDir = path.join(userDir, 'stockings');
  var itemsDir = path.join(stockingDir, 'items');
  var jsonDir = path.join(itemsDir, itemId);
  var result = await sshConnectServer(serverInfo);
  if (!result[0]) return [result[0], result[1]];
  SSHClient client = result[2];
  var sftp = await client.sftp();

  // 设置所需要上传的文件列表，进行统一上传处理，以应对大文件
  // key 对应本地文件，value 对应远程文件
  Map<String, String> filesToBeUploaded = {};

  // 对主物品条目信息文件 stockings/items.json 文件进行修改
  var fMainJson = File(path.join(stockingDir, 'items.json'));
  print(fMainJson);
  var mainJson = jsonDecode(fMainJson.readAsStringSync());
  print(mainJson);
  mainJson[itemId] = 'To be developed';
  print(mainJson);
  fMainJson.writeAsStringSync(jsonEncode(mainJson));
  print(await fMainJson.readAsString());
  filesToBeUploaded[fMainJson.path] =
      '/home/${serverInfo.username}/stockings/items.json';

  // 建立远程文件夹目录结构
  var remoteItemDir = '/home/${serverInfo.username}/stockings/items/${itemId}';
  try {
    await sftp.stat(remoteItemDir);
  } catch (err) {
    if (err.toString() == SFTP_NO_SUCH_FILE_ERROR) {
      await sftp.mkdir(remoteItemDir);
    } else {
      return [false, err.toString()];
    }
  }
  try {
    await sftp.stat('${remoteItemDir}/images');
  } catch (err) {
    if (err.toString() == SFTP_NO_SUCH_FILE_ERROR) {
      await sftp.mkdir('${remoteItemDir}/images');
    } else {
      return [false, err.toString()];
    }
  }
  try {
    await sftp.stat('${remoteItemDir}/files');
  } catch (err) {
    if (err.toString() == SFTP_NO_SUCH_FILE_ERROR) {
      await sftp.mkdir('${remoteItemDir}/files');
    } else {
      return [false, err.toString()];
    }
  }
  try {
    await sftp.stat('${remoteItemDir}/${itemId}.json');
  } catch (err) {
    if (err.toString() == SFTP_NO_SUCH_FILE_ERROR) {
      final file = await sftp.open('${remoteItemDir}/${itemId}.json',
          mode: SftpFileOpenMode.create | SftpFileOpenMode.write);
      await file.writeBytes(utf8.encode('{}') as Uint8List);
    } else {
      return [false, err.toString()];
    }
  }
  try {
    await sftp.stat('${remoteItemDir}/${itemId}_files.json');
  } catch (err) {
    if (err.toString() == SFTP_NO_SUCH_FILE_ERROR) {
      final file = await sftp.open('${remoteItemDir}/${itemId}_files.json',
          mode: SftpFileOpenMode.create | SftpFileOpenMode.write);
      await file.writeBytes(utf8.encode('{}') as Uint8List);
    } else {
      return [false, err.toString()];
    }
  }

  // 建立本地文件夹目录结构
  Directory(jsonDir).createSync(recursive: true);
  Directory(path.join(jsonDir, 'images')).createSync(recursive: true);
  Directory(path.join(jsonDir, 'files')).createSync(recursive: true);
  File(path.join(jsonDir, '${itemId}.json')).writeAsStringSync('{}');
  File(path.join(jsonDir, '${itemId}_files.json')).writeAsStringSync('{}');

  // 然后修改 stockings/items/itemId/itemId.json
  Map<String, dynamic> json = {};
  for (int index = 0; index < labelList.length; index++) {
    json[labelList[index]] = contentList[index];
  }
  var fWrite = File(path.join(jsonDir, '${itemId}.json'));
  fWrite.writeAsStringSync(jsonEncode(json));
  filesToBeUploaded[fWrite.path] =
      '/home/${serverInfo.username}/stockings/items/${itemId}/${itemId}.json';

  // 接着修改图片
  result = await sftpListFiles(
      client, '/home/${serverInfo.username}/stockings/items/${itemId}/images');
  if (!result[0]) return [result[0], result[1]];
  var remotePicList = result[2];
  for (var file in remotePicList) {
    await sftp.remove(
        '/home/${serverInfo.username}/stockings/items/${itemId}/images/${file}');
  }
  for (int index = 0; index < picPaths.length; index++) {
    var picRead = File(picPaths[index]);
    var picExt = path.extension(picRead.path);
    // await picRead.copy(path.join(imgDir, '${itemId}_${index}${picExt}'));
    filesToBeUploaded[picRead.path] =
        '/home/${serverInfo.username}/stockings/items/${itemId}/images/${itemId}_${index}${picExt}';
  }

  // 最后对比附件信息，删除远程多余文件，上传本地新增文件
  result = await Future.wait([
    sftpReceiveFile(
        client,
        '/home/${serverInfo.username}/stockings/items/${itemId}/${itemId}_files.json',
        path.join(jsonDir, '${itemId}_files_remote.json'))
  ]);
  result = result[0];
  if (!result[0]) return result;

  String itemFileJson = path.join(jsonDir, '${itemId}_files.json');
  var fFileJson = File(itemFileJson);
  var fFileJsonRemote = File(path.join(jsonDir, '${itemId}_files_remote.json'));
  Map fileJson = {};
  Map fileJsonRemote = jsonDecode(fFileJsonRemote.readAsStringSync());
  int filesCount = 0;
  for (var key in fileJsonRemote.keys) {
    var file = fileJsonRemote[key];
    if (!filePaths.contains(file)) {
      // 该文件需要在远端删除
      await sftp.remove(
          '/home/${serverInfo.username}/stockings/items/${itemId}/files/${file}');
    } else {
      fileJson[filesCount.toString()] = file;
      filesCount++;
    }
  }
  print(fileJsonRemote);
  print(filePaths);
  for (var file in filePaths) {
    if (!fileJsonRemote.containsValue(file)) {
      // 该文件需要上传至远端
      filesToBeUploaded[file] =
          '/home/${serverInfo.username}/stockings/items/${itemId}/files/${path.basename(file)}';
      fileJson[filesCount.toString()] = path.basename(file);
      filesCount++;
    }
  }

  print('7');
  print('length: ${filesToBeUploaded.length}');
  print(filesToBeUploaded);
  // 等待文件信息 json 保存完毕后，上传所有文件
  filesToBeUploaded[fFileJson.path] =
      '/home/${serverInfo.username}/stockings/items/${itemId}/${itemId}_files.json';

  await Future.wait([fFileJson.writeAsString(jsonEncode(fileJson))]);

  List results = [];
  for (var key in filesToBeUploaded.keys) {
    result = await Future.wait(
        [sftpUploadFile(client, key, filesToBeUploaded[key]!)]);
    results.add(result);
    print('${result}:${key}');
  }

  print('8');
  if (results.isNotEmpty) await Directory(jsonDir).delete(recursive: true);
  return results.isEmpty ? [false, null] : results[results.length - 1];
}
