import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/pipeline_controller.dart';
import '../widgets/pipeline_canvas_page.dart';

class TemplateConfigurationPage extends StatelessWidget {
  const TemplateConfigurationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PipelineController(),
      child: const PipelineCanvasPage(),
    );
  }
}
