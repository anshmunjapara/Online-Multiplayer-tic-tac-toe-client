import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:tic_tac_toe/wating_page.dart';

import 'network.dart';

void main() => runApp(const MaterialApp(
      home: HomePage(),
      debugShowCheckedModeBanner: false,
    ));

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  TextEditingController name = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Stack(
        children: [
          SvgPicture.asset(
            'assets/svg/bg_layout.svg',
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 70),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(
                  height: 5,
                ),
                Column(
                  children: <Widget>[
                    SvgPicture.asset('assets/svg/tic.svg'),
                    const SizedBox(
                      height: 10,
                    ),
                    SvgPicture.asset('assets/svg/tac.svg'),
                    const SizedBox(
                      height: 10,
                    ),
                    SvgPicture.asset('assets/svg/toe.svg'),
                  ],
                ),
                Column(
                  children: [
                    SizedBox(
                      width: screenWidth * 0.9,
                      child: TextField(
                        controller: name,
                        decoration: const InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(),
                          hintText: 'Your Name',
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: Colors.black,
                                width: 2.0), // Border when focused
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Colors.black,
                              width: 2.0,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => WaitingPage(
                              network: Network(
                                serverAddress:
                                    '127.0.0.1' // Put Server Address here
                                ,
                                serverPort: 65431,
                              ),
                              playerName: name.text,
                            ),
                          ),
                        );
                      },
                      child: SvgPicture.asset(
                        'assets/svg/Button.svg',
                        width: screenWidth * 0.9,
                      ),
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
