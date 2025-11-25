import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

void main() {
  runApp(const VideoPlayerApp());
}

class VideoPlayerApp extends StatelessWidget {
  const VideoPlayerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Video Player',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const VideoPlayerScreen(),
    );
  }
}

class VideoPlayerScreen extends StatefulWidget {
  const VideoPlayerScreen({super.key});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _controller;
  late Future<void> _initializeVideoPlayerFuture;

  // GÜNCELLENMİŞ LİSTE: Artık kelebek videosunun kapağında kelebek resmi var.
  final List<Map<String, String>> _videoPlaylist = [
    {
      "url": 'https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4',
      "poster": "https://images.pexels.com/photos/86906/butterfly-macro-insect-garden-86906.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1",
    },
    {
      "url": 'https://assets.mixkit.co/videos/preview/mixkit-forest-stream-in-the-sunlight-529-large.mp4',
      "poster": "https://images.pexels.com/photos/326055/pexels-photo-326055.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1",
    },
    {
      "url": 'https://assets.mixkit.co/videos/preview/mixkit-waves-in-the-water-1164-large.mp4',
      "poster": "https://images.pexels.com/photos/1707010/pexels-photo-1707010.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1",
    }
  ];
  
  int _currentVideoIndex = 0;
  bool _isFullScreen = false;

  @override
  void initState() {
    super.initState();
    _initializeController();
  }

  void _initializeController() {
    final videoUrl = _videoPlaylist[_currentVideoIndex]['url']!;
    _controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
    _initializeVideoPlayerFuture = _controller.initialize().then((_) {
      _controller.addListener(() {
        if (mounted) setState(() {});
      });
      _controller.setLooping(false);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    // Çıkışta ekranı normale döndür
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  void _changeVideo(int index) {
    if (index < 0 || index >= _videoPlaylist.length) return;
    setState(() {
      _controller.pause();
      _controller.removeListener(() {});
      _controller.dispose();
      _currentVideoIndex = index;
      _initializeController();
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  void _seekRelative(int seconds) {
    final currentPosition = _controller.value.position;
    var targetPosition = currentPosition + Duration(seconds: seconds);
    if (targetPosition < Duration.zero) targetPosition = Duration.zero;
    if (targetPosition > _controller.value.duration) targetPosition = _controller.value.duration;
    _controller.seekTo(targetPosition);
  }

  void _toggleMute() {
    setState(() {
      final newVolume = _controller.value.volume > 0 ? 0.0 : 1.0;
      _controller.setVolume(newVolume);
    });
  }

  void _toggleFullScreen() {
    setState(() {
      _isFullScreen = !_isFullScreen;
      if (_isFullScreen) {
        // Tam ekran: Durum çubuğunu gizle ve yatay yap
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight
        ]);
      } else {
        // Normal ekran: Dikey yap
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
        SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
      }
    });
  }

  // Video Oynatıcı Widget'ını (Stack) dışarı çıkardım, hem normal hem tam ekranda kullanmak için
  Widget _buildVideoPlayer() {
    return FutureBuilder(
      future: _initializeVideoPlayerFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return GestureDetector(
            onHorizontalDragUpdate: (details) {
              int sensitivity = 100;
              int seekSeconds = (details.primaryDelta! / (MediaQuery.of(context).size.width / sensitivity)).round();
              _seekRelative(seekSeconds);
            },
            child: AspectRatio(
              aspectRatio: _controller.value.aspectRatio,
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  VideoPlayer(_controller),
                  // Poster
                  if (!_controller.value.isPlaying && _controller.value.position == Duration.zero)
                    Image.network(
                      _videoPlaylist[_currentVideoIndex]['poster']!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  // Büyük Play Butonu
                  if (!_controller.value.isPlaying)
                    Center(
                      child: IconButton(
                        icon: const Icon(Icons.play_circle_fill, color: Colors.white, size: 64),
                        onPressed: () => setState(() => _controller.play()),
                      ),
                    ),
                  // Tam ekranda iken ekrana dokunarak çıkmak için buton (İsteğe bağlı)
                  if (_isFullScreen)
                    Positioned(
                      top: 20,
                      right: 20,
                      child: IconButton(
                        icon: const Icon(Icons.fullscreen_exit, color: Colors.white, size: 30),
                        onPressed: _toggleFullScreen,
                      ),
                    ),
                ],
              ),
            ),
          );
        } else if (snapshot.hasError) {
          return const Center(child: Text("Video yüklenemedi", style: TextStyle(color: Colors.white)));
        } else {
          return const Center(child: CircularProgressIndicator());
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final duration = _controller.value.duration;
    final position = _controller.value.position;
    final primaryColor = Theme.of(context).colorScheme.primary;

    // --- TAM EKRAN İSE FARKLI BİR ARAYÜZ DÖNDÜR ---
    if (_isFullScreen) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: _buildVideoPlayer(), // Sadece videoyu ortala
        ),
      );
    }

    // --- NORMAL EKRAN ---
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter Video Player'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.grey[100],
      body: SingleChildScrollView( // Sadece dikey modda kaydırma olsun
        child: Column(
          children: [
            // 1. VIDEO ALANI (Siyah Kutu içinde)
            Container(
              color: Colors.black,
              constraints: const BoxConstraints(maxHeight: 300), // Çok büyümemesi için sınır
              child: Center(child: _buildVideoPlayer()),
            ),
            
            const SizedBox(height: 10),

            // 2. ZAMAN ÇUBUĞU
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_formatDuration(position)),
                      Text(_formatDuration(duration)),
                    ],
                  ),
                  Slider(
                    value: position.inSeconds.toDouble(),
                    min: 0.0,
                    max: duration.inSeconds.toDouble(),
                    activeColor: primaryColor,
                    inactiveColor: primaryColor.withOpacity(0.3),
                    onChanged: (value) => _controller.seekTo(Duration(seconds: value.toInt())),
                  ),
                ],
              ),
            ),

            // 3. KONTROLLER (Sığması için 2 Satıra böldük)
            
            // ÜST SATIR: Oynatma Kontrolleri
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.skip_previous),
                  color: _currentVideoIndex > 0 ? primaryColor : Colors.grey,
                  onPressed: () => _changeVideo(_currentVideoIndex - 1),
                ),
                IconButton(
                  icon: const Icon(Icons.replay_10),
                  color: primaryColor,
                  onPressed: () => _seekRelative(-10),
                ),
                IconButton(
                  icon: Icon(_controller.value.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill),
                  iconSize: 64,
                  color: primaryColor,
                  onPressed: () => setState(() => _controller.value.isPlaying ? _controller.pause() : _controller.play()),
                ),
                IconButton(
                  icon: const Icon(Icons.forward_10),
                  color: primaryColor,
                  onPressed: () => _seekRelative(10),
                ),
                IconButton(
                  icon: const Icon(Icons.skip_next),
                  color: _currentVideoIndex < _videoPlaylist.length - 1 ? primaryColor : Colors.grey,
                  onPressed: () => _changeVideo(_currentVideoIndex + 1),
                ),
              ],
            ),

            // ALT SATIR: Araçlar (Ses, Loop, Fullscreen)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: Icon(_controller.value.volume > 0 ? Icons.volume_up : Icons.volume_off),
                  color: primaryColor,
                  tooltip: "Sesi Aç/Kapat",
                  onPressed: _toggleMute,
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _controller.value.isLooping ? primaryColor.withOpacity(0.1) : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Text("Loop", style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
                      Switch(
                        value: _controller.value.isLooping,
                        activeColor: primaryColor,
                        onChanged: (val) => setState(() => _controller.setLooping(val)),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.fullscreen),
                  iconSize: 32,
                  color: primaryColor,
                  tooltip: "Tam Ekran",
                  onPressed: _toggleFullScreen,
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}