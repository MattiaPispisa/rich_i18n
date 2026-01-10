import 'package:flutter/material.dart';
import 'package:flutter_example/rich_text.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorScheme: .fromSeed(seedColor: Colors.deepPurple)),
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
  late final TextEditingController _controller;

  // Example text to demonstrate capabilities on startup
  static const String _initialText =
      'Hello, this is a <b>Rich Text</b> editor!\n\n'
      'You can use tags like <u>underline</u>, <s>strike</s>, or combine '
      '<b><u>different styles</u></b>.\n\n'
      'We also support colors: <span color="red">Red</span>, '
      '<span color="blue" font-size="20">Big Blue</span>, and '
      '<span background-color="yellow">Highlighted</span>.\n\n'
      'Here is a <a href="https://flutter.dev">link to Flutter</a> to try out.';

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _initialText);

    // Add a listener: every time the user types, invoke setState
    // to update the UI and thus the RichI18nText widget
    _controller.addListener(() {
      setState(() {
        // Empty setState forces widget rebuild, passing the new
        // _controller.text value to RichI18nText
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rich I18n Editor'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Input Section ---
              const Text(
                'XML Source:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Expanded(
                flex: 1,
                child: TextField(
                  controller: _controller,
                  maxLines: null, // Allows infinite multiline
                  expands: true, // Fills available vertical space
                  textAlignVertical: TextAlignVertical.top,
                  decoration: InputDecoration(
                    hintText: 'Type your text with XML tags here...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.grey.withValues(alpha: .1),
                  ),
                  style: const TextStyle(
                    fontFamily: 'Courier',
                  ), // Monospace font for code
                ),
              ),

              const SizedBox(height: 16),
              const Divider(thickness: 2),
              const SizedBox(height: 16),

              // --- Output Section (RichI18nText) ---
              const Text(
                'Rendered Preview:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Expanded(
                flex: 1,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: .05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    child: RichI18nText(_controller.text),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
