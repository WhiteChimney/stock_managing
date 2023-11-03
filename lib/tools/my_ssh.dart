import 'dart:ffi';
import 'dart:typed_data';

import 'package:dartssh2/dartssh2.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'dart:io';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stock_managing/tools/data_processing.dart';

const String SFTP_NO_SUCH_FILE_ERROR = 'SftpStatusError: No such file(code 2)';
class SshServerInfo {
  String ip = '127.0.0.1';
  int port = 22;
  String username = 'guest';
  String password = 'password';

  SshServerInfo(
    String? m_ip, 
    int? m_port, 
    String? m_username, 
    String? m_password) {
      if (m_ip != null) ip = m_ip;
      if (m_port != null) port = m_port;
      if (m_username != null) username = m_username;
      if (m_password != null) password = m_password;
    }
}

SshServerInfo loadSshServerInfoFromPref (SharedPreferences pref) {
  return SshServerInfo(
    pref.getString('ip'),
    pref.getInt('port'),
    pref.getString('username'),
    pref.getString('password'),
    );
}

Future<List> sshTryServer(SshServerInfo serverInfo) async {
  String? result;
  bool success = false;
  try {
    final socket = await SSHSocket.connect(
      serverInfo.ip,
      serverInfo.port,
    );
    final client = SSHClient(
      socket,
      username: serverInfo.username,
      onPasswordRequest: () => serverInfo.password,
    );
    final uptime = await client.run('uptime');
    result = '连接成功！服务器运行信息：\n${utf8.decode(uptime)}';
    client.close();
    await client.done;
    success = true;
  } catch (err) {
    result = '连接失败！错误信息：\n${err.toString()}';
    success = false;
  }
  return [success, result];
}

Future<List> sshConnectServer(SshServerInfo serverInfo) async {
  String? result;
  bool success = false;
  try {
    final socket = await SSHSocket.connect(serverInfo.ip, serverInfo.port);

    final client = SSHClient(
      socket,
      username: serverInfo.username,
      // identities: [
      //   ...SSHKeyPair.fromPem(
      //       await File('C:/Users/79082/.ssh/id_ecdsa').readAsString())
      // ],
      onPasswordRequest: () => serverInfo.password,
    );
    
    var msg = await client.run('uptime');
    result = utf8.decode(msg);
    success = true;
    return [success, result, client];
  } catch (err) {
    result = err.toString();
    success = false;
    return [success, result, null];
  }
}

Future<List> sshSendCommand(SSHClient client, String command) async {
  String? result;
  bool success = false;
  try {
    final msg = await client.run(command);
    result = utf8.decode(msg);
    success = true;
  } catch (err) {
    result = err.toString();
    success = false;
  }
  return [success, result];
}

Future<List> sshDisconnectServer(SSHClient client) async {
  String? result;
  bool success = false;
  try {
    client.close();
    await client.done;
    result = 'successfully closed.';
    success = true;
  } catch (err) {
    result = err.toString();
    success = false;
  }
  return [success, result];
}

Future<List> sftpReceiveFile(SSHClient client, String remoteFile, String localFile) async {
  String? result;
  bool success = false;
  try {
    final sftp = await client.sftp();
    final fRemote = await sftp.open(remoteFile);
    final content = await fRemote.readBytes();
    final fLocal = File(localFile);
    fLocal.writeAsBytes(content);
    success = true;
  } catch (err) {
    result = err.toString();
    success = false;
  }
  return [success, result];
}

Future<List> sftpUploadFile(SSHClient client, String localFile, String remoteFile) async {
  String? result;
  bool success = false;
  try {
    final sftp = await client.sftp();
    final file = await sftp.open(
      remoteFile,
      mode: SftpFileOpenMode.create | SftpFileOpenMode.truncate | SftpFileOpenMode.write,
    );
    await file.write(File(localFile).openRead().cast()).done.whenComplete(() => print('upload completed'));
    success = true;
  } catch (err) {
    result = err.toString();
    success = false;
  }
  return [success, result];
}

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

Future<List> downloadJsonFromServer () async {
  makeSureServerIsReady();

  // 加载配置
  var pref = await loadUserPreferences();
  SshServerInfo serverInfo = loadSshServerInfoFromPref(pref);

  // 连接服务器
  SSHClient client;
  var result = await sshConnectServer(serverInfo);
  if (!result[0]) return [result[0], result[1]];
  client = result[2];
  var sftp = await client.sftp();

  // 将远程 items.json 文件下载下来进行物品清单比对
  var remoteMainJson = ('/home/${serverInfo.username}/stockings/items.json');
  var cacheDir = await getApplicationCacheDirectory();
  var localMainJson = path.join(cacheDir.path,serverInfo.username,'stockings','items.json');
  Map<String,dynamic> mainJson = jsonDecode(await File(localMainJson).readAsString());
  final fRemoteMainJson = await sftp.open(remoteMainJson);
  final content = await fRemoteMainJson.readBytes();
  mainJson.addAll(jsonDecode(latin1.decode(content)));
  await File(localMainJson).writeAsString(jsonEncode(mainJson));

  result = await sshDisconnectServer(client);
  return result;
}

Future<List> uploadItemInfoToServer (String itemId) async {
  
  var cacheDir = await getApplicationCacheDirectory();
  var userDir = path.join(cacheDir.path, 'noland');
  var stockingDir = path.join(userDir, 'stockings');

  // 上传文件至服务器
  SharedPreferences pref = await loadUserPreferences();
  SshServerInfo serverInfo = loadSshServerInfoFromPref(pref);
  var result = await sshConnectServer(serverInfo);
  if (!result[0]) return [result[0],result[1]];
  SSHClient client = result[2];
  result = await sftpUploadFile(
    client, 
    path.join(stockingDir, 'items.json'), 
    '/home/${serverInfo.username}/stockings/items.json');
  if (!result[0]) return result;
  return (await sshDisconnectServer(client));

}