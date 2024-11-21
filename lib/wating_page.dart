import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lottie/lottie.dart';
import 'game_page.dart';
import 'network.dart';

class WaitingPage extends StatefulWidget {
  final Network network;
  final String playerName;

  const WaitingPage({Key? key, required this.network, required this.playerName}) : super(key: key);

  @override
  _WaitingPageState createState() => _WaitingPageState();
}

class _WaitingPageState extends State<WaitingPage> {
  String statusMessage = "Waiting for another player to connect...";
  late int player;
  String otherPlayerName = "Opponent";
  bool isReady = false;
  bool isDisconnected = false;

  @override
  void initState() {
    super.initState();
    _setupNetworkCallbacks();
    _connectToServer();
  }

  void _setupNetworkCallbacks() {
    widget.network.onMessageReceived = _onServerMessage;
    widget.network.onDisconnected = _onDisconnected;
  }

  Future<void> _connectToServer() async {
    try {
      await widget.network.connect();
    } catch (e) {
      print('Connection error: $e');
      _handleConnectionError();
    }
  }

  void _handleConnectionError() {
    setState(() {
      statusMessage = "Connection timeout. Returning to home.";
    });
    _navigateBackAfterDelay();
  }

  void _navigateBackAfterDelay() {
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) Navigator.pop(context);
    });
  }

  void _onServerMessage(String message) {
    final decodedMessage = jsonDecode(message);

    if (decodedMessage.containsKey("player")) {
      player = decodedMessage["player"];
    } else if (decodedMessage.containsKey("playerName")) {
      otherPlayerName = decodedMessage["playerName"].isNotEmpty ? decodedMessage["playerName"] : "Opponent";
    } else if (decodedMessage['type'] == 'disconnect') {
      isReady = false;
      isDisconnected = true;
    } else if (decodedMessage['type'] == 'ready') {
      _handleReadyMessage();
    }
  }

  void _handleReadyMessage() {
    setState(() {
      statusMessage = "Player connected! Starting game...";
    });
    widget.network.sendMessage({"playerName": widget.playerName});
    isReady = true;
    _navigateToGameScreenAfterDelay();
  }

  void _navigateToGameScreenAfterDelay() {
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => GameScreen(
              network: widget.network,
              player: player,
              playerName: widget.playerName,
              otherPlayerName: otherPlayerName,
              isDisconnected: isDisconnected,
            ),
          ),
        );
      }
    });
  }

  void _onDisconnected() {
    setState(() {
      statusMessage = "Disconnected from server. Returning to home.";
    });
    _navigateBackAfterDelay();
  }

  @override
  void dispose() {
    if (!isReady) {
      widget.network.onMessageReceived = null;
      widget.network.onDisconnected = null;
      widget.network.disconnect();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvoked: (didPop) {
        isReady = false;
        widget.network.onMessageReceived = null;
        widget.network.onDisconnected = null;
        widget.network.disconnect();
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          title: const Text("Waiting Room"),
          centerTitle: true,
        ),
        body: Stack(
          children: [
            SvgPicture.asset(
              'assets/svg/bg_layout.svg',
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Lottie.asset('animation/loading.json', height: 150),
                    Text(
                      statusMessage,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}