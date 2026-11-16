
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

void main() => runApp(const JarvisApp());

class JarvisApp extends StatelessWidget {
  const JarvisApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'JARVIS AI',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF07111F),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.cyan,
          brightness: Brightness.dark,
        ),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final input = TextEditingController();
  final speech = stt.SpeechToText();
  final tts = FlutterTts();

  final messages = <Map<String, String>>[];

  String server = '';
  String token = '';
  String voice = 'Female';
  bool busy = false;
  bool listening = false;

  @override
  void initState() {
    super.initState();
    loadSettings();
    messages.add({
      'role': 'assistant',
      'text': 'Hello! I am JARVIS. How can I help you?'
    });
  }

  Future<void> loadSettings() async {
    final p = await SharedPreferences.getInstance();
    setState(() {
      server = p.getString('server') ?? '';
      token = p.getString('token') ?? '';
      voice = p.getString('voice') ?? 'Female';
    });
  }

  Future<void> settings() async {
    final url = TextEditingController(text: server);
    final key = TextEditingController(text: token);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('JARVIS Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: url,
              decoration: const InputDecoration(
                labelText: 'Backend URL',
              ),
            ),
            TextField(
              controller: key,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'JARVIS access token',
              ),
            ),
            DropdownButton<String>(
              value: voice,
              items: ['Male', 'Female'].map((v) =>
                DropdownMenuItem(value: v, child: Text(v))
              ).toList(),
              onChanged: (v) => setState(() => voice = v!),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final p = await SharedPreferences.getInstance();
              await p.setString('server', url.text.trim());
              await p.setString('token', key.text.trim());
              await p.setString('voice', voice);
              setState(() {
                server = url.text.trim();
                token = key.text.trim();
              });
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> speak(String text) async {
    await tts.setLanguage('en-IN');
    await tts.setPitch(voice == 'Female' ? 1.15 : 0.85);
    await tts.speak(text);
  }

  Future<void> listen() async {
    if (listening) {
      await speech.stop();
      setState(() => listening = false);
      return;
    }

    final available = await speech.initialize();

    if (!available) return;

    setState(() => listening = true);

    await speech.listen(
      onResult: (result) {
        setState(() {
          input.text = result.recognizedWords;
          if (result.finalResult) listening = false;
        });
      },
    );
  }

  Future<void> sendMessage() async {
    final question = input.text.trim();

    if (question.isEmpty || busy) return;

    if (server.isEmpty || token.isEmpty) {
      await settings();
      return;
    }

    setState(() {
      messages.add({'role': 'user', 'text': question});
      input.clear();
      busy = true;
    });

    try {
      final response = await http.post(
        Uri.parse(
          '${server.replaceAll(RegExp(r'/+$'), '')}/chat'
        ),
        headers: {
          'Content-Type': 'application/json',
          'X-Jarvis-Token': token,
        },
        body: jsonEncode({
          'message': question,
          'history': messages
              .sublist(0, messages.length - 1)
              .take(12)
              .map((m) => {
                'role': m['role'],
                'content': m['text'],
              }).toList(),
          'memory': '',
          'web_search': false,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Server error: ${response.statusCode}');
      }

      final data = jsonDecode(response.body);
      final answer = data['answer'].toString();

      setState(() {
        messages.add({
          'role': 'assistant',
          'text': answer,
        });
      });

      await speak(answer);

    } catch (e) {
      setState(() {
        messages.add({
          'role': 'assistant',
          'text': 'Connection error. Check your backend settings.',
        });
      });
    } finally {
      setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '⚡ JARVIS AI',
          style: TextStyle(
            color: Colors.cyanAccent,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        actions: [
          IconButton(
            onPressed: settings,
            icon: const Icon(Icons.settings),
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 15),
          const Icon(
            Icons.smart_toy,
            size: 75,
            color: Colors.cyanAccent,
          ),
          const Text(
            'PERSONAL AI ASSISTANT',
            style: TextStyle(
              color: Colors.cyanAccent,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 15),

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final m = messages[index];
                final user = m['role'] == 'user';

                return Align(
                  alignment: user
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.all(14),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * .85,
                    ),
                    decoration: BoxDecoration(
                      color: user
                          ? Colors.blue.shade900
                          : const Color(0xFF14283B),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Text(m['text'] ?? ''),
                  ),
                );
              },
            ),
          ),

          if (busy)
            const Padding(
              padding: EdgeInsets.all(8),
              child: Text('JARVIS is thinking...'),
            ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  IconButton(
                    onPressed: listen,
                    icon: Icon(
                      listening ? Icons.stop : Icons.mic,
                      color: Colors.cyanAccent,
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: input,
                      decoration: const InputDecoration(
                        hintText: 'Ask JARVIS anything...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: busy ? null : sendMessage,
                    icon: const Icon(
                      Icons.send,
                      color: Colors.cyanAccent,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
