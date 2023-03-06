import 'package:bubble/bubble.dart';
import 'package:dart_openai/openai.dart';
import 'package:flutter/material.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  ChatScreenState createState() => ChatScreenState();
}

class ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final List<ChatMessage> _messages = <ChatMessage>[];

  void _handleSubmitted(String text) async {
    _textController.clear();
    ChatMessage message = ChatMessage(
      text: text,
      type: RoleType.user,
    );
    setState(() {
      _messages.insert(0, message);
    });

    OpenAIChatCompletionModel chatCompletion =
        await OpenAI.instance.chat.create(
      model: "gpt-3.5-turbo",
      messages: [
        OpenAIChatCompletionChoiceMessageModel(content: text, role: "user"),
      ],
    );

    debugPrint('chatCompletion.choices: ${chatCompletion.choices}');

    for (var element in chatCompletion.choices) {
      ChatMessage message = ChatMessage(
        text: element.message.content.trim(),
        type: RoleType.bot,
      );
      setState(() {
        _messages.insert(0, message);
      });
    }
  }

  Widget _buildTextComposer() {
    return SafeArea(
      child: IconTheme(
        data: const IconThemeData(
          color: Colors.blue,
        ),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            children: <Widget>[
              Flexible(
                child: TextField(
                  controller: _textController,
                  onSubmitted: _handleSubmitted,
                  decoration: const InputDecoration.collapsed(
                    hintText: 'Type your message',
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 4.0),
                child: IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () => _handleSubmitted(_textController.text),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat'),
      ),
      body: Column(
        children: <Widget>[
          Flexible(
            child: ListView.builder(
              padding: const EdgeInsets.all(8.0),
              reverse: true,
              itemBuilder: (_, int index) => _messages[index],
              itemCount: _messages.length,
            ),
          ),
          const Divider(
            height: 1.0,
          ),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
            ),
            child: _buildTextComposer(),
          ),
        ],
      ),
    );
  }
}

enum RoleType { user, bot }

enum MessageType { info, error }

class ChatMessage extends StatelessWidget {
  final String text;
  final RoleType type;
  final MessageType? messageType;

  const ChatMessage(
      {super.key, required this.text, required this.type, this.messageType});

  @override
  Widget build(BuildContext context) {
    const nickNameStyle = TextStyle(
        color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 12);
    final _messageType = messageType ?? MessageType.info;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10.0),
      child: type == RoleType.user
          ? ListTile(
              trailing: const CircleAvatar(child: Text('User')),
              title: const Text(
                'User',
                textAlign: TextAlign.end,
                style: nickNameStyle,
              ),
              subtitle: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Bubble(
                    nip: BubbleNip.rightTop,
                    color: Colors.blue[100],
                    padding: const BubbleEdges.all(10),
                    child: Text(
                      text,
                      softWrap: true,
                      overflow: TextOverflow.visible,
                    ),
                  ),
                ],
              ),
            )
          : ListTile(
              leading: const CircleAvatar(child: Text('Bot')),
              title: const Text('Bot', style: nickNameStyle),
              subtitle: Row(
                children: [
                  Bubble(
                    nip: BubbleNip.leftTop,
                    padding: const BubbleEdges.all(10),
                    child: Text(
                      text,
                      softWrap: true,
                      overflow: TextOverflow.visible,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
