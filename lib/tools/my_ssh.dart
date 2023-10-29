import 'package:dartssh2/dartssh2.dart';
import 'dart:io';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

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
    return [success, client, result];
  } catch (err) {
    result = err.toString();
    success = false;
    return [success, null, result];
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
      mode: SftpFileOpenMode.truncate | SftpFileOpenMode.write,
    );
    await file.write(File(localFile).openRead().cast()).done;
    success = true;
  } catch (err) {
    result = err.toString();
    success = false;
  }
  return [success, result];
}

// 列出远程文件夹下的文件
// final items = await sftp.listdir('/');
//
// for (final item in items) {
//   print(item.longname);
//   print('${item.filename} (${item.attr.type?.name})');
// }

// 远程文件状态
// final stat = await sftp.stat('/usr');
// print(stat.size);
// print(stat.mode);






// Future<String> saveToLocal(String content) async {
//   String? result;
//   try {
//     final directory = await getApplicationCacheDirectory();
//     var file = File('${directory.path}/test.txt');
//     print(content);
//     file.writeAsString(content);
//     result = directory.path;
//   } catch (err) {
//     result = err.toString();
//   }
//   return result;
// }
