import 'dart:convert';
import 'dart:io';

import 'package:flutter_svg/svg.dart';
import 'package:tic_tac_toe/main.dart';
import 'package:tic_tac_toe/wating_page.dart';

import 'network.dart';
import 'package:flutter/material.dart';

class GameScreen extends StatefulWidget {
  Network network;
  int player;
  String playerName, otherPlayerName;
  bool isDisconnected;

  GameScreen({
    super.key,
    required this.network,
    required this.player,
    required this.playerName,
    required this.otherPlayerName,
    required this.isDisconnected,
  });

  @override
  _GameScreenState createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final List<String> _board = List.filled(9, '');
  bool canMove = false;
  bool gameEnded = false;

  @override
  void initState() {
    super.initState();

    if (widget.player == 1) {
      canMove = true;
    }
    widget.network.onMessageReceived = _onServerMessage;
    widget.network.onDisconnected = _onDisconnected;
    Future.delayed(Duration.zero, () {
      if (widget.isDisconnected) {
        _onDisconnected();
      }
    });
  }

  void _onServerMessage(String message) {
    final decodedMessage = jsonDecode(message);

    if (decodedMessage.containsKey("move")) {
      int index = int.parse(decodedMessage["move"]);
      String symbol = decodedMessage["symbol"];

      setState(() {
        _board[index] = symbol;
        canMove = !canMove;
      });
      _checkWinner();
    } else if (decodedMessage["type"] == "disconnect") {
      _onDisconnected();
    } else if (decodedMessage.containsKey("playerName")) {
      setState(() {
        widget.otherPlayerName = decodedMessage["playerName"];
      });
    }
  }

  void _makeMove(int index) {
    if (_board[index].isEmpty && canMove && !gameEnded) {
      String symbol = widget.player == 1 ? "X" : "O";

      setState(() {
        _board[index] = symbol;
        canMove = false;
      });

      widget.network.sendMessage({"move": index.toString(), "symbol": symbol});
      _checkWinner();
    }
  }

  void _checkWinner() {
    List<List<int>> winningCombinations = [
      [0, 1, 2], [3, 4, 5], [6, 7, 8], // Rows
      [0, 3, 6], [1, 4, 7], [2, 5, 8], // Columns
      [0, 4, 8], [2, 4, 6] // Diagonals
    ];

    for (var combination in winningCombinations) {
      if (_board[combination[0]] != '' &&
          _board[combination[0]] == _board[combination[1]] &&
          _board[combination[1]] == _board[combination[2]]) {
        _showResultDialog(
            _board[combination[0]] == (widget.player == 1 ? "X" : "O")
                ? "You Won :D"
                : "You Lost :(");
        return;
      }
    }

    if (!_board.contains('')) {
      _showResultDialog("Draw :|");
    }
  }

  // returns the current player "X" || "O"
  String whichPlayer() {
    if (widget.player == 1) {
      return canMove ? "X" : "O";
    } else {
      return canMove ? "O" : "X";
    }
  }

  // returns what to place on the cell
  Widget cell(int index) {
    if (_board[index] == "X") {
      return SvgPicture.asset("assets/svg/X.svg");
    } else if (_board[index] == "O") {
      return SvgPicture.asset("assets/svg/O.svg");
    } else {
      return const Text("");
    }
  }

  void _showResultDialog(String result) {
    setState(() {
      gameEnded = true;
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      builder: (BuildContext context) {
        double height = MediaQuery.of(context).size.height;
        return Dialog(
          insetPadding: EdgeInsets.zero, // Remove default padding
          backgroundColor: Colors.white70,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                result,
                style: TextStyle(
                  color: Colors.black,
                  fontFamily: 'Array',
                  fontSize: height * 0.06,
                ),
                textAlign: TextAlign.center,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).pop(); // Close the dialog
                      widget.network.onMessageReceived = null;
                      widget.network.onDisconnected = null;
                      widget.network.disconnect();
                      Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => WaitingPage(
                                network: Network(
                                  serverAddress:
                                      '127.0.0.1' // Put Server Address here
                                  ,
                                  serverPort: 65431,
                                ),
                                playerName: widget.playerName),
                          ));
                    },
                    child: SvgPicture.asset(
                      "assets/svg/Again.svg",
                      height: height * 0.05,
                    ),
                  ),
                  const SizedBox(
                    width: 40,
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).pop(); // Close the dialog
                      Navigator.of(context).pop(); // Go back to main menu
                    },
                    child: SvgPicture.asset(
                      "assets/svg/Home.svg",
                      height: height * 0.05,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _onDisconnected() {
    widget.network.onMessageReceived = null;
    widget.network.onDisconnected = null;
    widget.network.disconnect();
    if (!gameEnded) {
      _showResultDialog("Opponent Disconnected");
    }
  }

  @override
  void dispose() {
    widget.network.onMessageReceived = null;
    widget.network.onDisconnected = null;
    widget.network.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String symbol = widget.player == 1 ? "X" : "O";
    double height = MediaQuery.of(context).size.height;
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.grey.shade200,
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                flex: 1,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: SvgPicture.asset(
                        "assets/svg/leave.svg",
                        height: height * 0.05,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 3,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Positioned(
                                  top: -constraints.maxHeight * 0.25,
                                  left: 0,
                                  right: 0,
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Opacity(
                                        opacity: canMove ? 1 : 0.5,
                                        child: Column(
                                          children: [
                                            Text(
                                              "You - $symbol",
                                              style: const TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            SvgPicture.asset(
                                                "assets/svg/player-1.svg"),
                                          ],
                                        ),
                                      ),
                                      Opacity(
                                        opacity: canMove ? 0.5 : 1,
                                        child: Column(
                                          children: [
                                            Text(
                                              "${widget.otherPlayerName} - ${symbol == "X" ? "O" : "X"}",
                                              style: const TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            SvgPicture.asset(
                                              "assets/svg/player-2.svg",
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  decoration: const BoxDecoration(
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black,
                                        offset: Offset(-10, 10),
                                        blurRadius: 0,
                                        spreadRadius: 0,
                                      ),
                                    ],
                                  ),
                                  child: GridView.builder(
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    shrinkWrap: true,
                                    gridDelegate:
                                        const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 3, // 3 columns
                                    ),
                                    itemCount: 9,
                                    itemBuilder: (context, index) {
                                      return GestureDetector(
                                        onTap: () => _makeMove(index),
                                        child: Container(
                                          margin: EdgeInsets.zero,
                                          // Remove the margin between cells
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            border: Border(
                                              top: BorderSide(
                                                  width: index < 3 ? 4 : 3,
                                                  color: Colors.black),
                                              // Top border
                                              left: BorderSide(
                                                  width: index % 3 == 0 ? 4 : 3,
                                                  color: Colors.black),
                                              // Left border
                                              right: BorderSide(
                                                  width: (index + 1) % 3 == 0
                                                      ? 4
                                                      : 1,
                                                  color: Colors.black),
                                              // Right border
                                              bottom: BorderSide(
                                                  width: index >= 6 ? 4 : 1,
                                                  color: Colors
                                                      .black), // Bottom border
                                            ),
                                          ),
                                          child: Center(
                                            child: cell(index),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 1,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        SvgPicture.asset("assets/svg/${whichPlayer()}.svg"),
                        Padding(
                          padding:
                              EdgeInsets.symmetric(vertical: height * 0.02),
                          child: Text(
                            canMove ? "Your Move" : "Opponent's Move",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 26,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
