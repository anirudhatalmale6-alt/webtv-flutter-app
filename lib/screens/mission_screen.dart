import 'package:flutter/material.dart';
import '../config/app_config.dart';

class MissionScreen extends StatelessWidget {
  const MissionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mission Statement'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Logo
            Center(
              child: Image.asset(
                'assets/images/logo.png',
                height: 80,
              ),
            ),
            const SizedBox(height: 24),

            // Title
            Center(
              child: Text(
                'JKTV — The Voice of the Voiceless',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(AppConfig.primaryColorValue),
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),

            // Mission content
            const Text(
              'JKTV is an independent bridge across the divided lands and scattered hearts of Jammu & Kashmir.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 16),

            const Text(
              'In a world of censorship and echoing agendas, we stand for truth, dignity, and dialogue.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 16),

            const Text(
              'We amplify unheard voices—of resistance, culture, and hope—guided by fairness, accuracy, and courage.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 16),

            const Text(
              'Our space welcomes every shade of belief and perspective, uniting stories beyond borders.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 16),

            const Text(
              'Through journalism and exchange, we seek to turn silence into conversation, fear into trust, and division into understanding.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 24),

            // Vision section
            Text(
              'Our Vision',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(AppConfig.primaryColorValue),
              ),
            ),
            const SizedBox(height: 12),

            const Text(
              'A shared future of peace, equality, and open expression—where dialogue outlives conflict, and the bridges we build render borders obsolete.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 24),

            // Tagline
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: Color(AppConfig.primaryColorValue).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Color(AppConfig.primaryColorValue).withOpacity(0.5),
                  ),
                ),
                child: Text(
                  'JKTV — For dialogue, dignity, and peace towards South Asian Union.',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(AppConfig.primaryColorValue),
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
