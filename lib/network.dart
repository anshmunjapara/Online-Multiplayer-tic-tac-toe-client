import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';

class Network {
  Socket? _socket;
  bool isConnected = false;
  late final String serverAddress;
  late final int serverPort;
  Function(String)? onMessageReceived;
  Function? onDisconnected;

  Network({required this.serverAddress, required this.serverPort});

  Future<void> connect() async {
    try {
      _socket = await Socket.connect(serverAddress, serverPort).timeout(
        const Duration(seconds: 2),
        onTimeout: () {
          throw const SocketException("Connection Timeout");
        },
      );
      isConnected = true;
      _socket!.listen(
        (data) {
          final messages = String.fromCharCodes(data).split('\n');
          for (var message in messages) {
            if (message.isNotEmpty) {
              print("Received raw message: $message"); // Debug print
              if (onMessageReceived != null) {
                onMessageReceived!(message);
              }
            }
          }
        },
        onDone: () => _handleDisconnect(),
        onError: (error) => _handleDisconnect(),
      );
      print("Connected to server"); // Debug print
    } catch (e) {
      rethrow;
    }
  }

  void _handleDisconnect() {
    isConnected = false;
    if (onDisconnected != null) {
      onDisconnected!();
    }
    _socket?.destroy();
  }

  void sendMessage(Map<String, dynamic> data) {
    if (isConnected && _socket != null) {
      final jsonString = jsonEncode(data);
      print("Sending message: $jsonString"); // Debug print
      _socket!.write('$jsonString\n'); // Add newline as message delimiter
    }
  }

  void disconnect() {
    _handleDisconnect();
  }
}
