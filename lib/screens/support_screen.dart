import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/app_config.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

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
        title: const Text('Support Us'),
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
                    'Support JKTV',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Kashmir\'s First Independent Channel',
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
            // Main appeal text
            const Text(
              'Empower the silenced—stand with JKTV, the pioneering independent voice from Jammu Kashmir. Your recurring gift of \u00a35, \u00a310, or \u00a320 per month fuels fearless journalism, breaking censorship and amplifying unheard stories in a restricted media landscape.',
              style: TextStyle(fontSize: 16, color: Colors.white, height: 1.7),
            ),
            const SizedBox(height: 32),
            // Why Support Matters
            const Text(
              'Why Support Matters',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Independent channels like JKTV face intense pressures in Kashmir, where state crackdowns have silenced outlets. Monthly contributions ensure reliable coverage of human rights, conflict, and local issues that mainstream media often ignores.',
              style: TextStyle(fontSize: 15, color: Colors.white70, height: 1.6),
            ),
            const SizedBox(height: 24),
            // Donation options
            const Text(
              'Monthly Donation Options',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildDonationCard('\u00a35', 'per month')),
                const SizedBox(width: 12),
                Expanded(child: _buildDonationCard('\u00a310', 'per month')),
                const SizedBox(width: 12),
                Expanded(child: _buildDonationCard('\u00a320', 'per month')),
              ],
            ),
            const SizedBox(height: 28),
            // Impact points
            const Text(
              'Your Support Helps',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            _buildImpactItem(Icons.mic, 'Fearless journalism from the ground'),
            const SizedBox(height: 10),
            _buildImpactItem(Icons.visibility_off, 'Breaking censorship barriers'),
            const SizedBox(height: 10),
            _buildImpactItem(Icons.record_voice_over, 'Amplifying unheard stories'),
            const SizedBox(height: 10),
            _buildImpactItem(Icons.shield, 'Independent media free from state control'),
            const SizedBox(height: 10),
            _buildImpactItem(Icons.people, 'Human rights & conflict coverage'),
            const SizedBox(height: 32),
            // CTA
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () => _openSupportLink(context),
                icon: const Icon(Icons.favorite, color: Colors.white),
                label: const Text(
                  'Support Us',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                'You will be directed to our secure support page',
                style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.5)),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  static Widget _buildDonationCard(String amount, String period) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(AppConfig.primaryColorValue).withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            amount,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(AppConfig.primaryColorValue),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            period,
            style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.6)),
          ),
        ],
      ),
    );
  }

  static Widget _buildImpactItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.red, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 14, color: Colors.white70, height: 1.4),
          ),
        ),
      ],
    );
  }

  void _openSupportLink(BuildContext context) async {
    try {
      final uri = Uri.parse('https://jktv.live');
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open support page.')),
        );
      }
    }
  }
}
