import 'package:flutter/material.dart';
import '../config/app_config.dart';

class IntroductionScreen extends StatelessWidget {
  const IntroductionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('About Us'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Logo and title header
            Center(
              child: Column(
                children: [
                  Image.asset(
                    'assets/images/logo.png',
                    width: 100,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'JKTV Live',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '24/7 The Voice of Voiceless',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            // Divider
            Container(
              height: 2,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Color(AppConfig.primaryColorValue),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Content
            const Text(
              'About Us',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Jammu Kashmir TV in short is a New Media venture by British Kashmiris to open up new channels for connecting Kashmiris across the globe and provide them with information, news, entertainment and education about issues and opportunities that effect their lives.',
              style: TextStyle(fontSize: 15, color: Colors.white70, height: 1.6),
            ),
            const SizedBox(height: 16),
            const Text(
              'After two successful satellite television channels some of more dedicated and committed British Kashmiris have come together to build an Internet Protocol Television (IPTV).',
              style: TextStyle(fontSize: 15, color: Colors.white70, height: 1.6),
            ),
            const SizedBox(height: 16),
            const Text(
              'This is a grassroots cooperative venture with recording studios in London and Manchester and Birmingham is also in the pipeline. The idea is to build a capability for online news, talk shows and documentaries from across Kashmir and the Kashmiri diaspora worldwide.',
              style: TextStyle(fontSize: 15, color: Colors.white70, height: 1.6),
            ),
            const SizedBox(height: 16),
            const Text(
              'This channel will serve diverse viewpoints and provide coverage from Britain, Europe, the Middle East, Canada and the United States. It aims to provide an accurate and informative picture of Kashmiri history and politics and promote opportunities and talent in the fields of arts, culture, economy, media and education.',
              style: TextStyle(fontSize: 15, color: Colors.white70, height: 1.6),
            ),
            const SizedBox(height: 16),
            const Text(
              'The primary focus will be to raise awareness about regional problems and opportunities in an era of globalisation, and encourage the new generation of Kashmiris in the diaspora to contribute their skills and knowledge to the development of Kashmir.',
              style: TextStyle(fontSize: 15, color: Colors.white70, height: 1.6),
            ),
            const SizedBox(height: 16),
            const Text(
              'This channel is multilingual and committed to reflecting the political and cultural diversity of Kashmir and to promote a productive knowledge link between Kashmir and countries where Kashmiris have settled.',
              style: TextStyle(fontSize: 15, color: Colors.white70, height: 1.6),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
