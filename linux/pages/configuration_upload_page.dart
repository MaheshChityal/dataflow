import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ConfigurationUploadPage extends StatelessWidget {
  const ConfigurationUploadPage({super.key});

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
              color: AppColors.green.withOpacity(0.1),
            ),
            child: const Icon(Icons.cloud_upload_outlined, size: 32, color: AppColors.green),
          ),
          const SizedBox(height: 16),
          const Text('Configuration Upload', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.text)),
          const SizedBox(height: 8),
          const Text('Upload and manage pipeline configurations', style: TextStyle(fontSize: 13, color: AppColors.textDim)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.upload_file, size: 18),
            label: const Text('Upload Configuration'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.green,
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
