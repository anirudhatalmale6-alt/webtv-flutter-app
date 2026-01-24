import 'package:flutter/material.dart';
import '../config/app_config.dart';

class WhoWeAreScreen extends StatelessWidget {
  const WhoWeAreScreen({super.key});

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
        title: const Text('Who We Are'),
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
              'Who We Are',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'After two successful satellite television channels some of more dedicated and committed British Kashmiris have come together to build an Internet Protocol Television (IPTV).',
              style: TextStyle(fontSize: 15, color: Colors.white70, height: 1.6),
            ),
            const SizedBox(height: 16),
            const Text(
              'This is a grassroots cooperative venture funded by various groups and individuals who believe in independent media for the Kashmiri community.',
              style: TextStyle(fontSize: 15, color: Colors.white70, height: 1.6),
            ),
            const SizedBox(height: 24),
            // Team highlights
            _buildInfoCard(
              icon: Icons.videocam,
              title: 'Media Professionals',
              description: 'Experienced broadcast journalists, producers, and technical staff with background in satellite television.',
            ),
            const SizedBox(height: 12),
            _buildInfoCard(
              icon: Icons.language,
              title: 'Global Network',
              description: 'Serving communities in Britain, Europe, the Middle East, Canada, and the United States.',
            ),
            const SizedBox(height: 12),
            _buildInfoCard(
              icon: Icons.location_city,
              title: 'Production Facilities',
              description: 'Recording studios in London and Manchester, with Birmingham also in the pipeline.',
            ),
            const SizedBox(height: 12),
            _buildInfoCard(
              icon: Icons.groups,
              title: 'Cooperative Model',
              description: 'A grassroots cooperative funded by community groups and individuals.',
            ),
            const SizedBox(height: 24),
            const Text(
              'What We Do',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            _buildValueItem('Online news, talk shows and documentaries from across Kashmir'),
            const SizedBox(height: 8),
            _buildValueItem('Accurate and informative picture of Kashmiri history and politics'),
            const SizedBox(height: 8),
            _buildValueItem('Promote opportunities and talent in arts, culture, economy, media and education'),
            const SizedBox(height: 8),
            _buildValueItem('Raise awareness about regional problems and opportunities'),
            const SizedBox(height: 8),
            _buildValueItem('Multilingual content reflecting political and cultural diversity'),
            const SizedBox(height: 8),
            _buildValueItem('Productive knowledge link between Kashmir and the diaspora'),
            const SizedBox(height: 28),
            // Our Team
            const Text(
              'Our Team',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            _buildTeamMember('Talat Bhat', 'Executive Director'),
            const SizedBox(height: 10),
            _buildTeamMember('Shams Rehman', 'Director Programming'),
            const SizedBox(height: 10),
            _buildTeamMember('Salamat Hussain', 'Director News & Editor in Chief'),
            const SizedBox(height: 10),
            _buildTeamMember('Kabir Ahmed', 'Director Public Affairs'),
            const SizedBox(height: 10),
            _buildTeamMember('Wahid Kashir', 'Director Current Affairs'),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  static Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Color(AppConfig.primaryColorValue), size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(fontSize: 13, color: Colors.white60, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildTeamMember(String name, String role) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: Color(AppConfig.primaryColorValue).withOpacity(0.2),
            child: Icon(Icons.person, color: Color(AppConfig.primaryColorValue), size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  role,
                  style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.6)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildValueItem(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.check_circle, color: Color(AppConfig.primaryColorValue), size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 14, color: Colors.white70, height: 1.4),
          ),
        ),
      ],
    );
  }
}
