import 'package:dartssh2/dartssh2.dart';
import 'package:path_provider/path_provider.dart';
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

Future<List> SshTryServer(SshServerInfo serverInfo) async {
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

Future<List> SshConnectServer(SshServerInfo serverInfo) async {
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

Future<List> SshSendCommand(SSHClient client, String command) async {
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

Future<List> SshDisconnectServer(SSHClient client) async {
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

Future<List> SftpReceiveFile(SSHClient client, String remoteFile, String localFile) async {
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

Future<String> saveToLocal(String content) async {
  String? result;
  try {
    final directory = await getApplicationCacheDirectory();
    var file = File('${directory.path}/test.txt');
    print(content);
    file.writeAsString(content);
    result = directory.path;
  } catch (err) {
    result = err.toString();
  }
  return result;
}
