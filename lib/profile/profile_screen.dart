import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(
            radius: 50,
            backgroundColor: Color.fromARGB(255, 252, 35, 35),
            child: Icon(
              Icons.person,
              size: 50,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'My Profile',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildProfileItem(Icons.history, 'Story History', '${DateTime.now().year}'),
          _buildProfileItem(Icons.settings, 'Settings', ''),
          _buildProfileItem(Icons.help_outline, 'Help & Support', ''),
          _buildProfileItem(Icons.info_outline, 'About', 'v1.0.0'),
        ],
      ),
    );
  }

  Widget _buildProfileItem(IconData icon, String title, String trailing) {
    return ListTile(
      leading: Icon(icon, color: const Color.fromARGB(255, 252, 35, 35)),
      title: Text(title),
      trailing: trailing.isNotEmpty
          ? Text(
              trailing,
              style: const TextStyle(color: Colors.grey),
            )
          : const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () {
        // Handle navigation or action
      },
    );
  }
}