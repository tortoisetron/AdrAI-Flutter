import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Header
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 35,
                    backgroundColor: Color(0xFF1D4ED8),
                    child: Text(
                      'T',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'tanish@mindwebtree.com',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'tortoisetrone',
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                      Text(
                        'Free Member',
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Subscription Section
            _buildSectionHeader('Subscription'),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: _buildListTile(
                icon: Icons.stars,
                iconColor: Colors.orange,
                title: 'Upgrade to Pro',
                onTap: () {},
              ),
            ),
            const SizedBox(height: 24),

            // Account Section
            _buildSectionHeader('Account'),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _buildListTile(
                    icon: Icons.person,
                    iconColor: Colors.blue,
                    title: 'Edit Username',
                    onTap: () {},
                  ),
                  const Divider(height: 1),
                  _buildListTile(
                    icon: Icons.edit,
                    iconColor: Colors.blue,
                    title: 'Select Course',
                    onTap: () {},
                  ),
                  const Divider(height: 1),
                  _buildListTile(
                    icon: Icons.handshake,
                    iconColor: Colors.purple,
                    title: 'Take an Oath',
                    onTap: () {},
                  ),
                  const Divider(height: 1),
                  _buildListTile(
                    icon: Icons.people,
                    iconColor: Colors.blue,
                    title: 'Friends',
                    onTap: () {},
                  ),
                  const Divider(height: 1),
                  _buildListTile(
                    icon: Icons.auto_awesome,
                    iconColor: Colors.blue,
                    title: 'SRS Algorithm Settings',
                    onTap: () {},
                  ),
                  const Divider(height: 1),
                  _buildListTile(
                    icon: Icons.psychology,
                    iconColor: Colors.blue,
                    title: 'Select AI Model',
                    onTap: () {},
                  ),
                  const Divider(height: 1),
                  _buildListTile(
                    icon: Icons.card_giftcard,
                    iconColor: Colors.green,
                    title: 'Add Referral Code',
                    onTap: () {},
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

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.blueGrey[700],
        ),
      ),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: iconColor),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }
}
