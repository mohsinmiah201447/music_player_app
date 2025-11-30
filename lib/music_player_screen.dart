import 'dart:math';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';

class MusicPlayerScreen extends StatefulWidget {
  const MusicPlayerScreen({super.key});

  @override
  State<MusicPlayerScreen> createState() => _MusicPlayerScreenState();
}

class _MusicPlayerScreenState extends State<MusicPlayerScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();

  final List<Song> _playList = [
    Song(
      title: "Demo Song 1",
      artist: "Zayed Khan",
      url: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3",
    ),
    Song(
      title: "Demo Song 2",
      artist: "Hero Alam",
      url: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3",
    ),
    Song(
      title: "Demo Song 3",
      artist: "Sheikh Hasina",
      url: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3",
    ),
  ];

  int _currentIndex = 0;
  bool _isPlaying = false;

  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _initAudioSession();
    _setupListeners();
    _playSong(0);
  }

  Future<void> _initAudioSession() async {
    final session = await AudioSession.instance;
    await session.configure(AudioSessionConfiguration.music());
  }

  void _setupListeners() {
    _audioPlayer.durationStream.listen((d) {
      if (d != null) {
        setState(() => _duration = d);
      }
    });

    _audioPlayer.positionStream.listen((p) {
      setState(() => _position = p);
    });

    _audioPlayer.playerStateStream.listen((state) {
      setState(() => _isPlaying = state.playing);
      if (state.processingState == ProcessingState.completed) _next();
    });
  }

  Future<void> _playSong(int index) async {
    _currentIndex = index;

    setState(() {
      _position = Duration.zero;
      _duration = Duration.zero;
    });

    await _audioPlayer.setUrl(_playList[index].url);
    await _audioPlayer.play();
  }

  Future<void> _next() async {
    final next = (_currentIndex + 1) % _playList.length;
    _playSong(next);
  }

  Future<void> _previous() async {
    final prev = (_currentIndex - 1 + _playList.length) % _playList.length;
    _playSong(prev);
  }

  Future<void> _togglePlay() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.play();
    }
  }

  String _format(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return "$m:${s.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    final song = _playList[_currentIndex];

    double maxSec = max(_duration.inSeconds.toDouble(), 1);
    double posSec = min(_position.inSeconds.toDouble(), maxSec);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text("Music Player", style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),

      body: Column(
        children: [
          cardTopUI(song, posSec, maxSec),
          Expanded(child: playlistUI()),
        ],
      ),
    );
  }

  Widget cardTopUI(song, posSec, maxSec) {
    return Card(
      color: Colors.grey.shade900,
      margin: EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 6,
      shadowColor: Colors.greenAccent.shade400,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              song.title,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 4),
            Text(
              song.artist,
              style: TextStyle(fontSize: 16, color: Colors.white70),
            ),
            SizedBox(height: 20),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                thumbColor: Colors.greenAccent,
                activeTrackColor: Colors.greenAccent,
                inactiveTrackColor: Colors.white24,
              ),
              child: Slider(
                value: posSec,
                min: 0,
                max: maxSec,
                onChanged: (value) =>
                    _audioPlayer.seek(Duration(seconds: value.toInt())),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _format(_position),
                  style: TextStyle(color: Colors.white70),
                ),
                Text(
                  _format(_duration),
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: Icon(
                    Icons.skip_previous,
                    color: Colors.white,
                    size: 34,
                  ),
                  onPressed: _previous,
                ),
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.greenAccent,
                  ),
                  child: IconButton(
                    icon: Icon(
                      _isPlaying ? Icons.pause : Icons.play_arrow,
                      color: Colors.black,
                    ),
                    onPressed: _togglePlay,
                    iconSize: 36,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.skip_next, color: Colors.white, size: 34),
                  onPressed: _next,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget playlistUI() {
    return ListView.builder(
      itemCount: _playList.length,
      itemBuilder: (context, i) {
        final s = _playList[i];
        final isCurrent = i == _currentIndex;

        return Card(
          color: Colors.grey.shade900.withOpacity(0.7),
          elevation: isCurrent ? 8 : 3,
          shadowColor: isCurrent ? Colors.greenAccent : Colors.white24,
          margin: EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isCurrent ? Colors.greenAccent : Colors.white24,
              child: Text("${i + 1}", style: TextStyle(color: Colors.black)),
            ),
            title: Text(
              s.title,
              style: TextStyle(
                color: isCurrent ? Colors.greenAccent : Colors.white,
                fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            subtitle: Text(s.artist, style: TextStyle(color: Colors.white60)),
            trailing: Icon(
              Icons.play_arrow,
              color: isCurrent ? Colors.greenAccent : Colors.white,
            ),
            onTap: () => _playSong(i),
          ),
        );
      },
    );
  }
}

class Song {
  final String title;
  final String artist;
  final String url;

  Song({required this.title, required this.artist, required this.url});
}
