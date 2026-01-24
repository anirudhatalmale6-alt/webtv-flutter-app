import 'dart:math';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/app_config.dart';

class ContactScreen extends StatefulWidget {
  const ContactScreen({super.key});

  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _subjectController = TextEditingController();
  final _feedbackController = TextEditingController();
  final _messageController = TextEditingController();
  final _captchaController = TextEditingController();
  bool _isSending = false;

  late int _captchaA;
  late int _captchaB;

  @override
  void initState() {
    super.initState();
    _generateCaptcha();
  }

  void _generateCaptcha() {
    final rand = Random();
    _captchaA = rand.nextInt(9) + 1;
    _captchaB = rand.nextInt(9) + 1;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _subjectController.dispose();
    _feedbackController.dispose();
    _messageController.dispose();
    _captchaController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSending = true);

    final subject = Uri.encodeComponent(_subjectController.text);
    final body = Uri.encodeComponent(
      'Name: ${_nameController.text}\n'
      'Email: ${_emailController.text}\n'
      'Feedback Type: ${_feedbackController.text}\n\n'
      'Message:\n${_messageController.text}',
    );
    final mailtoUrl = 'mailto:contact@jktv.live?subject=$subject&body=$body';

    try {
      final uri = Uri.parse(mailtoUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No email app found. Please email contact@jktv.live directly.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open email app.')),
        );
      }
    }

    setState(() => _isSending = false);
  }

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
        title: const Text('Contact Us'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Center(
              child: Column(
                children: [
                  Image.asset(
                    'assets/images/logo.png',
                    width: 80,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Get In Touch',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Contact us for more info about investment and ideas',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.6),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Contact info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Column(
                children: [
                  _buildContactRow(Icons.email, 'contact@jktv.live'),
                  const SizedBox(height: 12),
                  _buildContactRow(Icons.language, 'jammukashmir.tv'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Form
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Send a Message',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _nameController,
                    label: 'Your Name',
                    icon: Icons.person,
                    validator: (v) => v == null || v.isEmpty ? 'Please enter your name' : null,
                  ),
                  const SizedBox(height: 14),
                  _buildTextField(
                    controller: _emailController,
                    label: 'Your Email',
                    icon: Icons.email,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Please enter your email';
                      if (!v.contains('@')) return 'Please enter a valid email';
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  _buildTextField(
                    controller: _subjectController,
                    label: 'Subject',
                    icon: Icons.subject,
                    validator: (v) => v == null || v.isEmpty ? 'Please enter a subject' : null,
                  ),
                  const SizedBox(height: 14),
                  _buildTextField(
                    controller: _feedbackController,
                    label: 'Feedback Type (e.g. General, Bug, Suggestion)',
                    icon: Icons.feedback,
                    validator: (v) => v == null || v.isEmpty ? 'Please enter feedback type' : null,
                  ),
                  const SizedBox(height: 14),
                  _buildTextField(
                    controller: _messageController,
                    label: 'Message',
                    icon: Icons.message,
                    maxLines: 5,
                    validator: (v) => v == null || v.isEmpty ? 'Please enter your message' : null,
                  ),
                  const SizedBox(height: 20),
                  // Spam protection - simple math captcha
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.security, color: Color(AppConfig.primaryColorValue), size: 18),
                            const SizedBox(width: 8),
                            const Text(
                              'Spam Protection',
                              style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'What is $_captchaA + $_captchaB = ?',
                          style: const TextStyle(color: Colors.white, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _captchaController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Your answer',
                            hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.05),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Please answer the question';
                            final answer = int.tryParse(v.trim());
                            if (answer != _captchaA + _captchaB) {
                              _generateCaptcha();
                              return 'Incorrect answer. Try again.';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isSending ? null : _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(AppConfig.primaryColorValue),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: _isSending
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text(
                              'Send Message',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
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

  Widget _buildContactRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Color(AppConfig.primaryColorValue), size: 20),
        const SizedBox(width: 12),
        Text(text, style: const TextStyle(color: Colors.white70, fontSize: 14)),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
        prefixIcon: maxLines == 1 ? Icon(icon, color: Colors.white38, size: 20) : null,
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Color(AppConfig.primaryColorValue)),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.red),
        ),
      ),
    );
  }
}
