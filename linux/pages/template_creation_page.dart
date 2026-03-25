import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class TemplateCreationPage extends StatelessWidget {
  const TemplateCreationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: AppColors.blue.withOpacity(0.1),
            ),
            child: const Icon(Icons.add_circle_outline, size: 32, color: AppColors.blue),
          ),
          const SizedBox(height: 16),
          const Text('Template Creation', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.text)),
          const SizedBox(height: 8),
          const Text('Create and manage email, PDF, SMS templates', style: TextStyle(fontSize: 13, color: AppColors.textDim)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Create New Template'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }
}
