import 'package:dart_openai/openai.dart';
import 'package:flutter/material.dart';
import 'package:markdown_widget/widget/markdown.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  ChatScreenState createState() => ChatScreenState();
}

class ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final List<ChatMessage> _messages = <ChatMessage>[];
  final ScrollController scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    scrollController.addListener(() {
      if (scrollController.position.pixels ==
          scrollController.position.maxScrollExtent) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  void _handleSubmitted(String text) async {
    if (text.isEmpty) return;

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
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: const Text('Chat'),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 50.0),
        child: FloatingActionButton(
          onPressed: () {
            scrollController.animateTo(
              scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOut,
            );
          },
          child: const Icon(Icons.arrow_downward),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              controller: scrollController,
              child: Column(
                children: <Widget>[
                  ListView.separated(
                      padding: const EdgeInsets.all(8.0),
                      physics: const NeverScrollableScrollPhysics(),
                      reverse: true,
                      shrinkWrap: true,
                      itemBuilder: (_, int index) => _messages[index],
                      itemCount: _messages.length,
                      separatorBuilder: (BuildContext context, int index) =>
                          const SizedBox(height: 8.0))
                ],
              ),
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
        color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12);
    final _messageType = messageType ?? MessageType.info;

    return type == RoleType.user
        ? ListTile(
            title: const Text(
              'User',
              textAlign: TextAlign.end,
              style: nickNameStyle,
            ),
            subtitle: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8.0),
                    color: Colors.blue.shade100,
                  ),
                  child: Text(
                    text,
                    textAlign: TextAlign.end,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            contentPadding: EdgeInsets.zero)
        : ListTile(
            title: const Text(
              'Bot',
              textAlign: TextAlign.start,
              style: nickNameStyle,
            ),
            subtitle: Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8.0),
                color: _messageType == MessageType.info
                    ? Colors.white
                    : Colors.red[200],
              ),
              child: MarkdownWidget(
                data: text,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                selectable: true,
              ),
            ),
            contentPadding: EdgeInsets.zero);
  }
}
