import 'package:flutter/material.dart';

class PlayerScreen extends StatefulWidget {
  final Map<String, dynamic> book;
  const PlayerScreen({super.key, required this.book});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  late int elapsed; // seconds
  late int duration; // seconds
  bool playing = true;

  final List<Color> accentGradient = const [Colors.cyan, Colors.greenAccent];
  final Color bgPrimary = const Color(0xFF0D1117);
  final Color bgSecondary = const Color(0xFF132735);

  @override
  void initState() {
    super.initState();
    elapsed = (widget.book['elapsed'] as int?) ?? 0;
    duration = (widget.book['duration'] as int?) ?? 2700;
  }

  String _fmt(int s) {
    final m = (s ~/ 60).toString().padLeft(2, '0');
    final ss = (s % 60).toString().padLeft(2, '0');
    return '$m:$ss';
  }

  @override
  Widget build(BuildContext context) {
    final cover = (widget.book['cover'] ?? '').toString();
    final title = (widget.book['title'] ?? 'Unknown Title').toString();
    final author = (widget.book['author'] ?? 'Unknown Author').toString();
    final desc = (widget.book['desc'] ?? 'No description available for this title.').toString();


    return Scaffold(
      backgroundColor: bgPrimary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: accentGradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ).createShader(bounds),
            child: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: accentGradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(bounds),
          child: const Text(
            'Now Playing',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white, // This gets overridden by shader
            ),
          ),
        ),
        centerTitle: true,
      ),

      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [bgPrimary, bgSecondary],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
        child: Column(
          children: [
            const SizedBox(height: 10),
            // Book Cover
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.network(
                cover,
                height: 260,
                width: 180,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Best Seller',
              style: TextStyle(color: Colors.amber.shade300, fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 22,
              ),
            ),
            Text(
              author,
              style: const TextStyle(color: Colors.white60, fontSize: 13),
            ),
            const SizedBox(height: 16),
            // Description
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  desc,
                  style: const TextStyle(color: Colors.white70, height: 1.4, fontSize: 14),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Slider
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                trackHeight: 4.5,
                activeTrackColor: accentGradient.first,
                inactiveTrackColor: Colors.white24,
                thumbColor: accentGradient.first,
              ),
              child: Slider(
                value: elapsed.clamp(0, duration).toDouble(),
                min: 0,
                max: duration.toDouble(),
                onChanged: (v) => setState(() => elapsed = v.toInt()),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_fmt(elapsed), style: const TextStyle(color: Colors.white70, fontSize: 12)),
                Text(_fmt(duration), style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 10),
            // Controls
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _circleBtn(icon: Icons.replay_10, onTap: () {
                  setState(() => elapsed = (elapsed - 10).clamp(0, duration));
                }),
                const SizedBox(width: 24),
                GestureDetector(
                  onTap: () => setState(() => playing = !playing),
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: accentGradient),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(.35), blurRadius: 14, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Icon(
                      playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      size: 42,
                      color: bgPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                _circleBtn(icon: Icons.forward_10, onTap: () {
                  setState(() => elapsed = (elapsed + 10).clamp(0, duration));
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _circleBtn({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 54,
        height: 54,
        decoration: BoxDecoration(
          color: Colors.white10,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white24),
        ),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }
}
