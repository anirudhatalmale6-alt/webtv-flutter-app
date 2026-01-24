import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/app_config.dart';

class AdvertiseScreen extends StatelessWidget {
  const AdvertiseScreen({super.key});

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
        title: const Text('Advertise With Us'),
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
                    'Advertise With Us',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
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
            // Why Advertise Here
            const Text(
              'Why Advertise Here?',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Our independent Kashmiri channel delivers unbiased news, cultural programs, documentaries, and community stories trusted by local and diaspora viewers.',
              style: TextStyle(fontSize: 15, color: Colors.white70, height: 1.6),
            ),
            const SizedBox(height: 12),
            const Text(
              'We prioritize Kashmiri voices, offering high engagement in a niche market underserved by mainstream media.',
              style: TextStyle(fontSize: 15, color: Colors.white70, height: 1.6),
            ),
            const SizedBox(height: 12),
            const Text(
              'Advertisers gain credibility by associating with authentic, community-focused content.',
              style: TextStyle(fontSize: 15, color: Colors.white70, height: 1.6),
            ),
            const SizedBox(height: 28),
            // Our Audience
            const Text(
              'Our Audience',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            _buildAudienceCard(
              icon: Icons.people,
              title: 'Primary Viewers',
              description: 'Kashmiri speakers in Kashmir Valley (ages 18-55), with strong viewership among families, professionals, and youth interested in local news and culture.',
            ),
            const SizedBox(height: 12),
            _buildAudienceCard(
              icon: Icons.public,
              title: 'Extended Reach',
              description: 'Jammu & Kashmir (13.6M+ population) and international diaspora via digital platforms.',
            ),
            const SizedBox(height: 12),
            _buildAudienceCard(
              icon: Icons.verified,
              title: 'High Trust',
              description: 'High trust in independent channels for Kashmir-specific events and issues.',
            ),
            const SizedBox(height: 32),
            // CTA
            Center(
              child: Column(
                children: [
                  const Text(
                    'Interested in advertising?',
                    style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Get in touch with us to discuss advertising packages',
                    style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.6)),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () => _contactForAds(context),
                      icon: const Icon(Icons.email, color: Colors.white),
                      label: const Text(
                        'Contact Us',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(AppConfig.primaryColorValue),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  static Widget _buildAudienceCard({
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

  void _contactForAds(BuildContext context) async {
    const mailtoUrl = 'mailto:contact@jktv.live?subject=Advertising%20Inquiry';
    try {
      final uri = Uri.parse(mailtoUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No email app found. Please email contact@jktv.live')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open email app.')),
        );
      }
    }
  }
}
