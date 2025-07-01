import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

final isChangingProvider = StateProvider<bool>((_) => false);

class AccountProfilePage extends ConsumerStatefulWidget {
  const AccountProfilePage({Key? key}) : super(key: key);

  @override
  ConsumerState<AccountProfilePage> createState() => _AccountProfilePageState();
}

class _AccountProfilePageState extends ConsumerState<AccountProfilePage> {
  final _newPassController = TextEditingController();
  final _confirmPassController = TextEditingController();

  void _showThemedSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.grey[900],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  void dispose() {
    _newPassController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isChanging = ref.watch(isChangingProvider);
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.grey[900],
        title: const Text('Account & Profile'),
        centerTitle: true,
        titleTextStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Email Info
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                title: const Text('UserId', style: TextStyle(color: Colors.white70, fontSize: 14)),
                subtitle: Text(
                  user?.email ?? '',
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
                leading: const Icon(Icons.email, color: Colors.white70),
              ),
            ),

            const SizedBox(height: 16),

            // Change Password Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showChangePasswordDialog(context, isChanging),
                icon: const Icon(Icons.lock_reset),
                label: const Text('Change Password'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[850],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 28),

            // Divider & Label
            Row(
              children: const [
                Expanded(child: Divider(color: Colors.white24, thickness: 1)),
                SizedBox(width: 8),
                Text('Account Actions', style: TextStyle(color: Colors.white70, fontSize: 14)),
                SizedBox(width: 8),
                Expanded(child: Divider(color: Colors.white24, thickness: 1)),
              ],
            ),

            const SizedBox(height: 24),

            // Sign Out
            ElevatedButton.icon(
              onPressed: _signOut,
              icon: const Icon(Icons.logout),
              label: const Text('Sign Out'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),

            const SizedBox(height: 12),

            // Delete Account
            ElevatedButton.icon(
              onPressed: _deleteAccount,
              icon: const Icon(Icons.delete_forever),
              label: const Text('Delete Account'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[700],
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }


  void _showChangePasswordDialog(BuildContext context, bool isChanging) {
    final screenWidth = MediaQuery.of(context).size.width;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: screenWidth * 0.85,
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Change Password',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _newPassController,
                decoration: _inputDecoration('New Password'),
                obscureText: true,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _confirmPassController,
                decoration: _inputDecoration('Confirm Password'),
                obscureText: true,
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: isChanging ? null : () => _changePassword(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                    ),
                    child: isChanging
                        ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                        : const Text('Update'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.white24),
        borderRadius: BorderRadius.circular(12),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.deepPurple),
        borderRadius: BorderRadius.circular(12),
      ),
      filled: true,
      fillColor: Colors.grey[850],
    );
  }

  Future<void> _changePassword(BuildContext dialogContext) async {
    final newPass = _newPassController.text.trim();
    final confirmPass = _confirmPassController.text.trim();

    final passwordRegex = RegExp(r'^(?=.*[A-Z])(?=.*\d).{6,}$');

    if (newPass.isEmpty || confirmPass.isEmpty) {
      _showThemedSnackBar('Please fill in both password fields');
      return;
    }

    if (newPass != confirmPass) {
      _showThemedSnackBar('Passwords do not match');
      return;
    }

    if (!passwordRegex.hasMatch(newPass)) {
      _showThemedSnackBar(
          'Password must be at least 6 characters, include 1 uppercase letter and 1 number.');
      return;
    }

    ref.read(isChangingProvider.notifier).state = true;

    try {
      await FirebaseAuth.instance.currentUser!.updatePassword(newPass);
      Navigator.of(dialogContext).pop();
      _showThemedSnackBar('Password updated successfully');
    } catch (e) {
      _showThemedSnackBar('Error: $e');
    } finally {
      ref.read(isChangingProvider.notifier).state = false;
      _newPassController.clear();
      _confirmPassController.clear();
    }
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    Navigator.of(context).pushReplacementNamed('/login');
  }

  Future<void> _deleteAccount() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Account', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to permanently delete your account?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseAuth.instance.currentUser!.delete();
        Navigator.of(context).pushReplacementNamed('/signup');
      } catch (e) {
        _showThemedSnackBar('Error deleting account: $e');
      }
    }
  }
}
