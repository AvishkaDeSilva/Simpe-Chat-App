import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flash_chat/constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final _firestore = FirebaseFirestore.instance;
User loggedInUser;

class ChatScreen extends StatefulWidget {
  static const String id = "chat_screen";
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final messageController = TextEditingController();
  final _auth = FirebaseAuth.instance;

  String messages;

  @override
  void initState() {
    super.initState();
    getCurrentUser();
    print(loggedInUser.email);
  }

  void getCurrentUser() {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        loggedInUser = user;
        print(loggedInUser.email);
      }
    } catch (e) {
      print(e);
    }
  }

  // void getMessage() async{
  //   final messages = await _firestore.collection('messages').get();
  //   for(var message in messages.docs){
  //     print(message.data());
  //   }
  // }
  // void messageStream() async {
  //   await for (var snapShot in _firestore.collection('messages').snapshots()) {
  //     for (var message in snapShot.docs) {
  //       print(message.data());
  //     }
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    bool state = false;
    return Scaffold(
      appBar: AppBar(
        leading: null,
        actions: <Widget>[
          IconButton(
              icon: Icon(Icons.close),
              onPressed: () {
                //messageStream();
                _auth.signOut();
                Navigator.pop(context);
              }),
        ],
        title: Text('⚡️Chat'),
        backgroundColor: Colors.lightBlueAccent,
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            MessageStream(logger: loggedInUser.email),
            Container(
              decoration: kMessageContainerDecoration,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: messageController,
                      onChanged: (value) {
                        messages = value;
                      },
                      decoration: kMessageTextFieldDecoration,
                    ),
                  ),
                  FlatButton(
                    onPressed: () {
                      messageController.clear();
                      //Implement send functionality.
                      try {
                        _firestore.collection('messages').add({
                          'sender': loggedInUser.email,
                          'text': messages,
                        });
                      } catch (e) {
                        print(e);
                      }
                    },
                    child: Text(
                      'Send',
                      style: kSendButtonTextStyle,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MessageStream extends StatelessWidget {
  final logger;

  const MessageStream({this.logger});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('messages').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return CircularProgressIndicator(
              backgroundColor: Colors.lightBlueAccent,
            );
          }
          final messages = snapshot.data.docs.reversed;
          List<MessageBubble> messageBubbles = [];
          for (var message in messages) {
            final messageText = message['text'];
            final messageSender = message['sender'];
            final alignment = (messageSender == logger)
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start;
            final messageBubble = MessageBubble(
              alignment: alignment,
              sender: messageSender,
              message: messageText,
            );

            messageBubbles.add(messageBubble);
          }
          return Expanded(
            child: ListView(
              reverse: true,
              padding: EdgeInsets.symmetric(horizontal: 15, vertical: 20),
              children: messageBubbles,
            ),
          );
        });
  }
}

class MessageBubble extends StatelessWidget {
  final String sender;
  final String message;
  Color color;
  final alignment;
  var radius;

  MessageBubble({this.sender, this.message, this.alignment});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignment,
      children: [
        Text(
          '$sender',
          style: TextStyle(
              color: Colors.black54, fontSize: 12, fontStyle: FontStyle.italic),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 15.0),
          child: Material(
              elevation: 8,
              borderRadius: BorderRadius.only(
                  topLeft: radius = (loggedInUser.email == sender)
                      ? Radius.circular(20)
                      : Radius.circular(0),
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                  topRight: radius = (loggedInUser.email == sender)
                      ? Radius.circular(0)
                      : Radius.circular(20)),
              color: color = (loggedInUser.email == sender)
                  ? Colors.lightBlueAccent
                  : Colors.blue,
              child: Padding(
                padding: EdgeInsets.all(15.0),
                child: Text(
                  '$message',
                  style: TextStyle(color: Colors.white, fontSize: 15),
                ),
              )),
        ),
      ],
    );
  }
}
