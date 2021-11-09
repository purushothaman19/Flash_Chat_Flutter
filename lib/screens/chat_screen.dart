import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flashchat/constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';

final _firebase = FirebaseFirestore.instance;
late User currentLoggedInUser;

class ChatScreen extends StatefulWidget {
  static String id = "chat_screen";

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final textEditingController = TextEditingController();
  final _auth = FirebaseAuth.instance;
  late String textMessages;
  late bool isMe;

  void getCurrentUser() {
    try {
      final user = _auth.currentUser;

      if (user != null) {
        currentLoggedInUser = user;
        print(currentLoggedInUser.email);
      }
    } catch (e) {
      print("error: $e");
    }
  }

  @override
  void initState() {
    getCurrentUser();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: null,
        actions: <Widget>[
          IconButton(
              icon: Icon(Icons.close),
              onPressed: () {
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
            MessageStream(),
            Container(
              decoration: kMessageContainerDecoration,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: textEditingController,
                      onChanged: (value) {
                        textMessages = value;
                      },
                      decoration: kMessageTextFieldDecoration,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      textEditingController.clear();
                      //Implement send functionality.
                      _firebase.collection("messages").add({
                        "sender": currentLoggedInUser.email,
                        "message": textMessages,
                        "createdAt": new DateTime.now(),
                      });
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

class MessageBubble extends StatelessWidget {
  final String text;
  final String sender;
  final bool isMe;
  final String date;
  final String time;

  MessageBubble({required this.text, required this.sender, required this.isMe, required this.date, required this.time});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Material(
            borderRadius: isMe
                ? BorderRadius.only(
                    topLeft: Radius.circular(30),
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30))
                : BorderRadius.only(
                    topRight: Radius.circular(30),
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30)),
            elevation: 5,
            color: isMe ? Colors.lightBlueAccent : Colors.white,
            child: Padding(
              padding: EdgeInsets.all(10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "$text",
                    style: TextStyle(
                      color: isMe ? Colors.white : Colors.blueGrey,
                    ),
                  ),
                  Text("$date, $time", style: TextStyle(
                    color: isMe ? Colors.white : Colors.blueGrey,
                    fontSize: 8,
                  ),
                  ),
                ],
              ),
            ),
          ),
          Text(
            "$sender",
            style: TextStyle(color: Colors.white70, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class MessageStream extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firebase.collection("messages").orderBy('createdAt', descending: false).snapshots(),
      builder: (context, snapshots) {
        if (!snapshots.hasData) {
          return Center(
            child: CircularProgressIndicator(
              backgroundColor: Colors.blueAccent,
            ),
          );
        }
        final messages = snapshots.data!.docs.reversed;
        final List<MessageBubble> messagesBubbles = [];

        for (var message in messages) {
          var messageText = message.get("message");
          final messageSender = message.get("sender");
          final date = message["createdAt"].toDate().toString().split(" ")[0];
          final time = message["createdAt"].toDate().toString().split(" ")[1];

          final messagesBubble = MessageBubble(
              text: messageText,
              sender: messageSender,
              isMe: messageSender == currentLoggedInUser.email,
              time: time.substring(0, 5),
              date: date,
          );
          messagesBubbles.add(messagesBubble);
        }
        return Expanded(
          child: ListView(
            children: messagesBubbles,
            shrinkWrap: true,
            reverse: true,
          ),
        );
      },
    );
  }
}
