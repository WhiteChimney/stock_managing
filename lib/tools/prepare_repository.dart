import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dartssh2/dartssh2.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

import 'package:stock_managing/tools/data_processing.dart';
import 'package:stock_managing/tools/my_ssh.dart';

Future<List> makeSureServerIsReady () async {
  // 加载配置
  var pref = await loadUserPreferences();
  SshServerInfo serverInfo = loadSshServerInfoFromPref(pref);

  // 连接服务器
  SSHClient client;
  var result = await sshConnectServer(serverInfo);
  if (!result[0]) return [result[0], result[1]];
  client = result[2];
  var sftp = await client.sftp();

  // 看仓库是否存在，如果不在，则新建
  var remoteStockingsDir = '/home/${serverInfo.username}/stockings';
  try {
    await sftp.stat(remoteStockingsDir);
  } catch (err) {
    if (err.toString() == SFTP_NO_SUCH_FILE_ERROR) {
      await sftp.mkdir(remoteStockingsDir);
    } else {
      return [false, err.toString()];
    }
  }
  try {
    await sftp.stat('${remoteStockingsDir}/items');
  } catch (err) {
    if (err.toString() == SFTP_NO_SUCH_FILE_ERROR) {
      await sftp.mkdir('${remoteStockingsDir}/items');
    } else {
      return [false, err.toString()];
    }
  }
  try {
    await sftp.stat('${remoteStockingsDir}/items.json');
  } catch (err) {
    if (err.toString() == SFTP_NO_SUCH_FILE_ERROR) {
      final file = await sftp.open('${remoteStockingsDir}/items.json', 
        mode: SftpFileOpenMode.write | SftpFileOpenMode.create | SftpFileOpenMode.truncate);
      await file.writeBytes(utf8.encode('{}') as Uint8List);
      return result;
    } else {
      return [false, err.toString()];
    }
  }
  result = await sshDisconnectServer(client);
  if (!result[0]) return result;
  return [true, 'Repository ready. '];
}

Future<List> makeSureLocalRepositoryIsReady () async {
  // 加载配置
  var pref = await loadUserPreferences();
  SshServerInfo serverInfo = loadSshServerInfoFromPref(pref);

  // 看本地仓库是否存在，如果不在，则新建
  var cacheDir = await getApplicationCacheDirectory();
  var localStockingsDir = path.join(cacheDir.path,serverInfo.username,'stockings','items');
  if (!(await Directory(localStockingsDir).exists())) {
    await Directory(localStockingsDir).create(recursive: true);
  }
  var mainJson = path.join(cacheDir.path,serverInfo.username,'stockings','items.json');
  if (!File(mainJson).existsSync()) {
    File(mainJson).writeAsStringSync('{}');
  }
  return [true, 'Repository ready. '];
}
