import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'template_creation_page.dart';
import 'template_configuration_page.dart';
import 'configuration_upload_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedIndex = 0;

  final _pages = const <Widget>[
    TemplateCreationPage(),
    TemplateConfigurationPage(),
    ConfigurationUploadPage(),
  ];

  final _titles = const [
    'Template Creation',
    'Template Configuration',
    'Configuration Upload',
  ];

  final _icons = const [
    Icons.add_circle_outline,
    Icons.settings_applications_outlined,
    Icons.cloud_upload_outlined,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: AppColors.text),
        title: Row(
          children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                gradient: const LinearGradient(colors: [Color(0xFF004C8F), Color(0xFF0066CC)]),
              ),
              child: const Center(child: Text('H', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800))),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_titles[_selectedIndex], style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.text)),
                const Text('HDFC Pipeline Builder', style: TextStyle(fontSize: 10, color: AppColors.textDim)),
              ],
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.notifications_outlined, size: 20), onPressed: () {}),
          const SizedBox(width: 4),
          Container(
            margin: const EdgeInsets.only(right: 12),
            width: 32, height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF004C8F).withOpacity(0.1),
              border: Border.all(color: const Color(0xFF004C8F).withOpacity(0.2)),
            ),
            child: const Center(child: Icon(Icons.person, size: 16, color: Color(0xFF004C8F))),
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: _pages[_selectedIndex],
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: AppColors.surface,
      child: Column(
        children: [
          // Drawer header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 48, 20, 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [Color(0xFF004C8F), Color(0xFF0066CC)],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.white.withOpacity(0.2),
                  ),
                  child: const Center(child: Text('H', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800))),
                ),
                const SizedBox(height: 12),
                const Text('HDFC Pipeline Builder', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text('Data Configuration Platform', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Menu items
          for (int i = 0; i < _titles.length; i++)
            _drawerItem(i),

          const Spacer(),

          // Logout
          const Divider(color: AppColors.border, height: 1),
          ListTile(
            leading: const Icon(Icons.logout, size: 20, color: Colors.red),
            title: const Text('Logout', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.red)),
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushReplacementNamed('/login');
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _drawerItem(int index) {
    final selected = _selectedIndex == index;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: selected ? const Color(0xFF004C8F).withOpacity(0.08) : Colors.transparent,
      ),
      child: ListTile(
        leading: Icon(
          _icons[index], size: 20,
          color: selected ? const Color(0xFF004C8F) : AppColors.textDim,
        ),
        title: Text(
          _titles[index],
          style: TextStyle(
            fontSize: 13, fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? const Color(0xFF004C8F) : AppColors.text,
          ),
        ),
        trailing: selected
            ? Container(width: 4, height: 20, decoration: BoxDecoration(borderRadius: BorderRadius.circular(2), color: const Color(0xFF004C8F)))
            : null,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        onTap: () {
          setState(() => _selectedIndex = index);
          Navigator.of(context).pop();
        },
      ),
    );
  }
}
