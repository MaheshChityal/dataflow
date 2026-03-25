import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../controllers/pipeline_controller.dart';

class TopBar extends StatelessWidget {
  const TopBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Logo
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(7),
              gradient: const LinearGradient(colors: [Color(0xFF1D4ED8), Color(0xFF3B82F6)]),
            ),
            child: const Center(child: Text('🏦', style: TextStyle(fontSize: 14))),
          ),
          const SizedBox(width: 8),
          const Text('DataFlow Builder', style: AppTextStyles.topBarTitle),
          const SizedBox(width: 12),
          Container(width: 1, height: 24, color: AppColors.border2),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: AppColors.blue.withOpacity(0.12),
              border: Border.all(color: AppColors.blue.withOpacity(0.25)),
            ),
            child: const Text('Pipeline View', style: TextStyle(color: AppColors.blue, fontSize: 11, fontWeight: FontWeight.w600)),
          ),
          const Spacer(),
          _btn('🗑 Clear', () => context.read<PipelineController>().clearCanvas()),
          const SizedBox(width: 8),
          _btn('💾 Save', () {}, primary: true),
          const SizedBox(width: 8),
          _btn('▶ Run Pipeline', () {}, green: true),
        ],
      ),
    );
  }

  Widget _btn(String label, VoidCallback onTap, {bool primary = false, bool green = false}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(7),
          color: green ? AppColors.green : primary ? AppColors.blue : Colors.transparent,
          border: (!primary && !green) ? Border.all(color: AppColors.border2) : null,
        ),
        child: Text(label, style: TextStyle(
          color: (primary || green) ? Colors.white : AppColors.textDim,
          fontSize: 12.5, fontWeight: FontWeight.w600,
        )),
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// SIDEBAR (same as HTML .sidebar with dept/template/source palette)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
