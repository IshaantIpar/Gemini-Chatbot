import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:image_picker/image_picker.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();

    Timer(
      const Duration(milliseconds: 2000),
      () {
        setState(
          () {
            ChatMessage string = ChatMessage(
              user: geminiUser,
              createdAt: DateTime.now(),
              text:
                  "Welcome to Google's AI Assistant Gemini. I am here to help you!",
            );
            messages = [string, ...messages];
          },
        );
      },
    );
  }

  final Gemini gemini = Gemini.instance;

  List<ChatMessage> messages = [];

  ChatUser currentUser = ChatUser(id: "0", firstName: 'User');
  ChatUser geminiUser = ChatUser(id: '1', firstName: 'Gemini');
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 231, 231, 231),
        title: const Center(
          child: Text('Gemini Chat'),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.fromARGB(255, 75, 237, 255), // #4b90ff
              Color(0xFFff5546), // #ff5546
            ],
            transform: GradientRotation(
              16 * (3.141592653589793 / 180),
            ),
          ),
        ),
        child: _buildUI(),
      ),
    );
  }

  Widget _buildUI() {
    return DashChat(
      typingUsers: const [],
      inputOptions: InputOptions(
        trailing: [
          IconButton(
            onPressed: _sendMediaMessage,
            icon: const Icon(Icons.image),
          ),
        ],
      ),
      currentUser: currentUser,
      onSend: _sendMessage,
      messages: messages,
      messageOptions: MessageOptions(
        showTime: false,
        timeTextColor: Colors.black,
        onLongPressMessage: (ChatMessage message) {
          final RenderBox messageRenderBox =
              context.findRenderObject() as RenderBox;
          final Offset globalPosition =
              messageRenderBox.localToGlobal(Offset.zero);

          final RenderBox overlay =
              Overlay.of(context).context.findRenderObject() as RenderBox;
          final Offset overlayGlobalPosition =
              overlay.localToGlobal(Offset.zero);

          final Offset relativePosition = Offset(
            globalPosition.dx - overlayGlobalPosition.dx,
            globalPosition.dy - overlayGlobalPosition.dy,
          );
          final Size screenSize = MediaQuery.of(context).size;

          final double top = relativePosition.dy + messageRenderBox.size.height;
          final double left = relativePosition.dx;

          final double right =
              screenSize.width - (left + messageRenderBox.size.width);
          final double bottom =
              screenSize.height - (top + messageRenderBox.size.height);
          showMenu(
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(20)),
            ),
            context: context,
            position: RelativeRect.fromLTRB(left, top, right, bottom),
            items: [
              const PopupMenuItem(
                value: 'copy',
                child: Text('Copy'),
              ),
              const PopupMenuItem(
                value: 'reply',
                child: Text('Reply'),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Text('Delete'),
              ),
            ],
          ).then((value) {
            if (value == 'copy') {
              Clipboard.setData(ClipboardData(text: message.text));
            } else if (value == 'reply') {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Reply feature coming soon!'),
                ),
              );
            } else if (value == 'delete') {
              setState(() {
                messages.remove(message);
              });
            }
          });
        },
      ),
    );
  }

  void _sendMessage(ChatMessage chatMessage) {
    setState(() {
      messages = [chatMessage, ...messages];
    });
    try {
      String question = chatMessage.text;
      List<Uint8List>? images;
      if (chatMessage.medias?.isNotEmpty ?? false) {
        images = [
          File(chatMessage.medias!.first.url).readAsBytesSync(),
        ];
      }
      gemini
          .streamGenerateContent(
        question,
        images: images,
      )
          .listen((event) {
        ChatMessage? lastMessage = messages.firstOrNull;
        if (lastMessage != null && lastMessage.user == geminiUser) {
          lastMessage = messages.removeAt(0);
          String response = event.content!.parts?.fold(
                  "", (previous, current) => "$previous ${current.text}") ??
              "";
          response = _formatResponse(response); // Format response
          lastMessage.text += response;
          setState(() {
            messages = [lastMessage!, ...messages];
          });
        } else {
          String response = event.content!.parts?.fold(
                  "", (previous, current) => "$previous ${current.text}") ??
              "";
          response = _formatResponse(response); // Format response
          ChatMessage message = ChatMessage(
            user: geminiUser,
            createdAt: DateTime.now(),
            text: response,
          );
          setState(() {
            messages = [message, ...messages];
          });
        }
      });
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }
  }

  String _formatResponse(String response) {
    List<String> rArr = response.split("**");
    String nResponse = "";
    for (int i = 0; i < rArr.length; i++) {
      nResponse += rArr[i];
    }
    String _formatResponse(String response) {
    List<String> rArr = response.split("*");
    String nResponse = "";
    for (int i = 0; i < rArr.length; i++) {
      nResponse += rArr[i];
    }
    return nResponse;
  }

  void _sendMediaMessage() async {
    ImagePicker picker = ImagePicker();
    XFile? file = await picker.pickImage(
      source: ImageSource.gallery,
    );
    if (file != null) {
      ChatMessage chatMessage = ChatMessage(
        user: currentUser,
        createdAt: DateTime.now(),
        text: "Describe the image in 4-5 sentences.",
        medias: [
          ChatMedia(
            url: file.path,
            fileName: "",
            type: MediaType.image,
          )
        ],
      );
      _sendMessage(chatMessage);
    }
  }
}
