import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'AccountProfilePage.dart';
import 'behavior_settings/behavior_settings_provider.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.grey[900],
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          _buildSettingCard(
            icon: Icons.person,
            title: 'Account and Profile',
            subtitle: 'Change your account settings',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AccountProfilePage()),
            ),
          ),
          _buildSettingCard(
            icon: Icons.settings,
            title: 'Behavior',
            subtitle: 'Adjust app behavior',
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => const BehaviorSettingsDialog(),
              );
            },
          ),
          _buildSettingCard(
            icon: Icons.feedback,
            title: 'Send Feedback',
            subtitle: 'Send us your feedback',
            onTap: () => showDialog(
              context: context,
              builder: (_) => const FeedbackDialog(),
            ),
          ),
          _buildSettingCard(
            icon: Icons.info,
            title: 'About Us',
            subtitle: 'Learn more about us',
            onTap: () => showDialog(
              context: context,
              builder: (_) => const AboutUsDialog(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      color: Colors.grey[900],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: Colors.deepPurpleAccent),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        subtitle: Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        trailing: const Icon(Icons.chevron_right, color: Colors.white70),
      ),
    );
  }
}


class FeedbackDialog extends StatefulWidget {
  const FeedbackDialog({Key? key}) : super(key: key);

  @override
  State<FeedbackDialog> createState() => _FeedbackDialogState();
}

class _FeedbackDialogState extends State<FeedbackDialog> {
  final _controller = TextEditingController();
  bool _isSubmitting = false;

  Future<void> _submitFeedback() async {
    final message = _controller.text.trim();
    if (message.isEmpty) return;

    setState(() => _isSubmitting = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      await FirebaseFirestore.instance.collection('feedback').add({
        'uid': user?.uid ?? 'anonymous',
        'message': message,
        'timestamp': FieldValue.serverTimestamp(),
      });

      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Feedback submitted!')),
      );
    } catch (e) {
      debugPrint('Error submitting feedback: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to submit feedback.')),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return AlertDialog(
      backgroundColor: Colors.grey[900],
      title: const Text('Send Feedback', style: TextStyle(color: Colors.white)),
      content: SizedBox(
        width: screenWidth * 0.8,
        height: 180, // Fixed vertical height
        child: TextField(
          controller: _controller,
          maxLines: null,
          expands: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Write your feedback here...',
            hintStyle: const TextStyle(color: Colors.white60),
            filled: true,
            fillColor: Colors.grey[850],
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submitFeedback,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
          child: _isSubmitting
              ? const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
          )
              : const Text('Submit'),
        ),
      ],
    );
  }
}


class AboutUsDialog extends StatelessWidget {
  const AboutUsDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.grey[900],
      title: const Text('About Us', style: TextStyle(color: Colors.white)),
      content: const SingleChildScrollView(
        child: Text(
          '''
This is a Flutter-based cryptocurrency tracking app.

• Real-time price updates are powered by the Binance WebSocket API.
• Coin data is fetched from Binance REST API.
• News updates are pulled from the Coinbase News API.
• Firebase is used for authentication and cloud storage.
• Riverpod is used for state management throughout the app.

Thank you for using our app!

— Made by Vivek Mule
          ''',
          style: TextStyle(fontSize: 13.5, color: Colors.white70),
        ),
      ),
      actions: [
        TextButton(
          child: const Text('Close', style: TextStyle(color: Colors.deepPurpleAccent)),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}


class BehaviorSettingsDialog extends ConsumerWidget {
  const BehaviorSettingsDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(behaviorSettingsProvider);
    final notifier = ref.read(behaviorSettingsProvider.notifier);
    final screenWidth = MediaQuery.of(context).size.width;

    return Dialog(
      backgroundColor: Colors.grey[900],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: screenWidth * 0.85,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Behavior Settings',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),

            // Refresh News Option
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Refresh News Page', style: TextStyle(color: Colors.white70)),
            ),
            const SizedBox(height: 8),
            RadioListTile<bool>(
              activeColor: Colors.deepPurple,
              title: const Text('Enabled', style: TextStyle(color: Colors.white)),
              value: true,
              groupValue: settings.refreshNews,
              onChanged: (val) => notifier.setRefreshNews(val!),
            ),
            RadioListTile<bool>(
              activeColor: Colors.deepPurple,
              title: const Text('Disabled', style: TextStyle(color: Colors.white)),
              value: false,
              groupValue: settings.refreshNews,
              onChanged: (val) => notifier.setRefreshNews(val!),
            ),

            const Divider(color: Colors.white24, height: 32),

            // Open in WebView Option
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Open News in WebView', style: TextStyle(color: Colors.white70)),
            ),
            const SizedBox(height: 8),
            RadioListTile<bool>(
              activeColor: Colors.deepPurple,
              title: const Text('Yes', style: TextStyle(color: Colors.white)),
              value: true,
              groupValue: settings.openInWebView,
              onChanged: (val) => notifier.setOpenInWebView(val!),
            ),
            RadioListTile<bool>(
              activeColor: Colors.deepPurple,
              title: const Text('No', style: TextStyle(color: Colors.white)),
              value: false,
              groupValue: settings.openInWebView,
              onChanged: (val) => notifier.setOpenInWebView(val!),
            ),

            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(foregroundColor: Colors.deepPurple),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

