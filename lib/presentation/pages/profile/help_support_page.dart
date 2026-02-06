import 'package:flutter/material.dart';
import '../../../core/constants/app_spacing.dart';

class HelpSupportPage extends StatelessWidget {
  static const String routeName = '/profile/help';

  const HelpSupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back),
                  ),
                  Text('Help & support', style: Theme.of(context).textTheme.titleMedium),
                  const Spacer(),
                  TextButton(onPressed: () {}, child: const Text('live chat')),
                ],
              ),
              const SizedBox(height: 12),
              const Center(
                child: Icon(Icons.support_agent, size: 100, color: Colors.blue),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text('Hello, how can we assist you?', style: Theme.of(context).textTheme.bodyLarge),
              ),
              const SizedBox(height: 20),
              Text('Title', style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 6),
              const TextField(decoration: InputDecoration(hintText: 'Enter the title of your issue')),
              const SizedBox(height: 12),
              Text('Write in below box', style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 6),
              const TextField(
                maxLines: 4,
                decoration: InputDecoration(hintText: 'Write here..'),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {},
                  child: const Text('Send'),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: const Text('Live chat'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
