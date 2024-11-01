import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:myapp/profile/profile_screen.dart';
import 'package:myapp/services/api_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_tts/flutter_tts.dart';

const String GEMINI_API_KEY =
    String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');
const String ELEVEN_LABS_API_KEY =
    String.fromEnvironment('ELEVEN_LABS_API_KEY', defaultValue: '');

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Story Suno',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
            seedColor: const Color.fromARGB(255, 252, 35, 35)),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color.fromARGB(255, 252, 35, 35),
          foregroundColor: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromARGB(255, 252, 35, 35),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
      home: const MyHomePage(title: 'Story Suno'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController _textController = TextEditingController();
  final List<Map<String, dynamic>> _stories = [];
  final AudioPlayer _audioPlayer = AudioPlayer();
  int _selectedIndex = 0;
  bool _isLoading = false;
  bool _isPlaying = false;
  int? _currentlyPlayingIndex;
  bool _isLoadingAudio = false;

  late final ApiService _apiService;
  late FlutterTts _flutterTts;

  @override
  void initState() {
    super.initState();
    _initializeAudio();
    _apiService = ApiService(
      geminiApiKey: GEMINI_API_KEY,
      elevenLabsApiKey: ELEVEN_LABS_API_KEY,
    );
    _initFlutterTts();

    _audioPlayer.playerStateStream.listen((state) {
      setState(() {
        _isPlaying = state.playing;
        if (state.processingState == ProcessingState.completed) {
          _currentlyPlayingIndex = null;
        }
      });
    });
  }

  Future<void> _initFlutterTts() async {
    _flutterTts = FlutterTts();
    try {
      await _flutterTts.setLanguage('en-US'); // Set language
      await _flutterTts.setSpeechRate(0.5); // Set speech rate
      await _flutterTts.setPitch(1.0); // Set pitch
    } catch (e) {
      print("Error initializing FlutterTts: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error initializing TTS: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _initializeAudio() async {
    try {
      await _audioPlayer.setVolume(20.0);
      // Set audio session configuration
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
    } catch (e) {
      //Improved error handling: Show a SnackBar to the user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error initializing audio: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _generateStory() async {
    if (_textController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a story prompt')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Generate story using Gemini
      final storyData = await _apiService.generateStory(_textController.text);

      // Get the app's documents directory
      final directory = await getApplicationDocumentsDirectory();
      final audioFileName =
          'story_${DateTime.now().millisecondsSinceEpoch}.mp3';
      final audioFile = File('${directory.path}/$audioFileName');

      // Convert to speech and save the audio file
      final Uint8List audioBytes = Uint8List.fromList(
          await _apiService.convertToSpeech(storyData['story']!));

      await audioFile.writeAsBytes(audioBytes);

      // Verify the file exists and has content
      if (!await audioFile.exists()) {
        throw Exception('Failed to save audio file');
      }

      setState(() {
        _stories.add({
          'title': storyData['title'],
          'description': storyData['story'],
          'audioPath': audioFile.path,
          'timestamp': DateTime.now().toIso8601String(),
        });
        _textController.clear();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleAudio(int index) async {
    if (_isLoadingAudio) return; // Prevent multiple taps while loading

    setState(() {
      _isLoadingAudio = true;
    });

    try {
      if (_currentlyPlayingIndex == index && _isPlaying) {
        await _audioPlayer.pause();
        setState(() {
          _isPlaying = false;
        });
      } else {
        // Stop any currently playing audio
        if (_isPlaying) {
          await _audioPlayer.stop();
        }

        final audioFile = File(_stories[index]['audioPath']);
        //Improved error handling: Check if the file exists before playing
        if (!await audioFile.exists()) {
          throw Exception('Audio file not found');
        }

        // Set the audio source and play
        await _audioPlayer.setFilePath(audioFile.path);
        await _audioPlayer.play();

        setState(() {
          _isPlaying = true;
          _currentlyPlayingIndex = index;
        });
      }
    } catch (e) {
      //Improved error handling: Show a SnackBar to the user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error playing audio: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoadingAudio = false;
      });
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _buildStoryList() {
    if (_stories.isEmpty) {
      return const Center(
        child: Text(
          'No stories generated yet\nStart by entering a prompt above!',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: _stories.length,
      itemBuilder: (context, index) {
        final bool isPlaying = _currentlyPlayingIndex == index && _isPlaying;

        // Parse the timestamp string back to DateTime
        DateTime? timestamp;
        try {
          timestamp = DateTime.parse(_stories[index]['timestamp'] as String);
        } catch (e) {
          // Handle parsing error gracefully
          timestamp = null;
        }

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          elevation: 2,
          child: ExpansionTile(
            leading: IconButton(
              icon: Icon(
                isPlaying
                    ? Icons.pause_circle_filled
                    : Icons.play_circle_filled,
                color: const Color.fromARGB(255, 252, 35, 35),
                size: 32,
              ),
              onPressed: () => _toggleAudio(index),
            ),
            title: Text(
              _stories[index]['title']!,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            subtitle: Text(
              'Generated ${_formatTimestamp(timestamp)}',
              style: const TextStyle(fontSize: 12),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  _stories[index]['description']!,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatTimestamp(DateTime? timestamp) {
    if (timestamp == null) return 'just now';

    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> _widgetOptions = <Widget>[
      // Home Screen Content
      Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _textController,
              decoration: InputDecoration(
                hintText: 'Enter an idea for a story...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color.fromARGB(255, 252, 35, 35),
                    width: 2,
                  ),
                ),
              ),
              maxLines: 3,
              enabled: !_isLoading,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _generateStory,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Generate Story',
                      style: TextStyle(fontSize: 16),
                    ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Your Stories',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _buildStoryList(),
            ),
          ],
        ),
      ),
      // Profile Screen
      const ProfileScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        elevation: 2,
      ),
      body: Stack(
        children: [
          Center(
            child: _widgetOptions.elementAt(_selectedIndex),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 20,
            child: Center(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                height: 65,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    NavBarItem(
                      icon: Icons.home_rounded,
                      label: 'Home',
                      isSelected: _selectedIndex == 0,
                      onTap: () => _onItemTapped(0),
                    ),
                    NavBarItem(
                      icon: Icons.person_rounded,
                      label: 'Profile',
                      isSelected: _selectedIndex == 1,
                      onTap: () => _onItemTapped(1),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class NavBarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const NavBarItem({
    Key? key,
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color.fromARGB(255, 252, 35, 35).withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? const Color.fromARGB(255, 252, 35, 35)
                  : Colors.grey,
              size: 24,
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Color.fromARGB(255, 252, 35, 35),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
