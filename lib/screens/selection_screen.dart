import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'home_screen.dart';
import 'live_tv_screen.dart';

class SelectionScreen extends StatefulWidget {
  const SelectionScreen({super.key});

  @override
  State<SelectionScreen> createState() => _SelectionScreenState();
}

class _SelectionScreenState extends State<SelectionScreen> {
  int _selectedIndex = 0;

  void _selectOption(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _openSelected() {
    if (_selectedIndex == 0) {
      // JKTV Live - Live streaming
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LiveTVScreen()),
      );
    } else {
      // JKTV Play - Video on Demand
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Options
              isLandscape
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildOptionCard(
                          index: 0,
                          icon: Icons.live_tv,
                          title: 'JKTV Live',
                          subtitle: 'Watch Live 24/7',
                          tagline: 'The Voice of Voiceless',
                          color: Colors.red,
                          width: screenWidth * 0.35,
                        ),
                        const SizedBox(width: 30),
                        _buildOptionCard(
                          index: 1,
                          icon: Icons.play_circle_filled,
                          title: 'JKTV Play',
                          subtitle: 'Video on Demand',
                          tagline: 'VOD Library',
                          color: Colors.blue,
                          width: screenWidth * 0.35,
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        _buildOptionCard(
                          index: 0,
                          icon: Icons.live_tv,
                          title: 'JKTV Live',
                          subtitle: 'Watch Live 24/7',
                          tagline: 'The Voice of Voiceless',
                          color: Colors.red,
                          width: screenWidth * 0.8,
                        ),
                        const SizedBox(height: 20),
                        _buildOptionCard(
                          index: 1,
                          icon: Icons.play_circle_filled,
                          title: 'JKTV Play',
                          subtitle: 'Video on Demand',
                          tagline: 'VOD Library',
                          color: Colors.blue,
                          width: screenWidth * 0.8,
                        ),
                      ],
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionCard({
    required int index,
    required IconData icon,
    required String title,
    required String subtitle,
    required String tagline,
    required Color color,
    required double width,
  }) {
    final isSelected = _selectedIndex == index;
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return Focus(
      autofocus: index == 0,
      onFocusChange: (hasFocus) {
        if (hasFocus) {
          _selectOption(index);
        }
      },
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.select ||
              event.logicalKey == LogicalKeyboardKey.enter ||
              event.logicalKey == LogicalKeyboardKey.gameButtonA) {
            _openSelected();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: () {
          _selectOption(index);
          _openSelected();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: width,
          padding: EdgeInsets.all(isLandscape ? 24 : 20),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.2) : const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? color : Colors.white24,
              width: isSelected ? 3 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
          transform: isSelected
              ? (Matrix4.identity()..scale(1.05))
              : Matrix4.identity(),
          transformAlignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: isLandscape ? 60 : 50,
                color: isSelected ? color : Colors.white70,
              ),
              SizedBox(height: isLandscape ? 16 : 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: isLandscape ? 28 : 24,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? color : Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: isLandscape ? 18 : 16,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                tagline,
                style: TextStyle(
                  fontSize: isLandscape ? 14 : 12,
                  color: Colors.white54,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
