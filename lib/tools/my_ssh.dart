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

Future<String> tryServer(SshServerInfo serverInfo) async {
  final socket = await SSHSocket.connect(
    serverInfo.ip,
    serverInfo.port,
  );

  final client = SSHClient(
    socket,
    username: serverInfo.username,
    onPasswordRequest: () => serverInfo.password,
  );

  String? result;
  try {
    final uptime = await client.run('uptime');
    result = utf8.decode(uptime);
    client.close();
    await client.done;
  } catch (err) {
    result = err.toString();
  }

  return result;
}

Future<List> connectServer() async {
  final socket = await SSHSocket.connect('192.168.50.17', 22);

  final client = SSHClient(
    socket,
    username: 'noland',
    identities: [
      ...SSHKeyPair.fromPem(
          await File('C:/Users/79082/.ssh/id_ecdsa').readAsString())
    ],
  );

  String? result;
  try {
    await client.run('uptime');
    result = 'successfully connected';
  } catch (err) {
    result = err.toString();
  }
  return [result, client];
}

Future<String> sendCommand(String command, SSHClient client) async {
  String? result;
  try {
    final msg = await client.run(command);
    result = utf8.decode(msg);
  } catch (err) {
    result = err.toString();
  }
  return result;
}

Future<String> disconnectServer(SSHClient client) async {
  String? result;
  try {
    client.close();
    await client.done;
    result = 'successfully closed.';
  } catch (err) {
    result = err.toString();
  }
  return result;
}

Future<String> receiveTestFile(SSHClient client) async {
  String? result;
  try {
    final sftp = await client.sftp();
    final file = await sftp.open('/home/noland/test.txt');
    final content = await file.readBytes();
    result = latin1.decode(content);
  } catch (err) {
    result = err.toString();
  }
  return result;
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
