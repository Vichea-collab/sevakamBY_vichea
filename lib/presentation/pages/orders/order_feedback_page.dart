import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../domain/entities/order.dart';
import '../../widgets/app_top_bar.dart';
import '../../widgets/primary_button.dart';

class OrderFeedbackPage extends StatefulWidget {
  final OrderItem order;

  const OrderFeedbackPage({super.key, required this.order});

  @override
  State<OrderFeedbackPage> createState() => _OrderFeedbackPageState();
}

class _OrderFeedbackPageState extends State<OrderFeedbackPage> {
  int _rating = 4;
  final TextEditingController _feedbackController = TextEditingController();

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppTopBar(
                title: 'Give your feedback',
              ),
              const SizedBox(height: 18),
              Text(
                'How was your experience with ${widget.order.provider.name}?',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 14),
              Row(
                children: List.generate(5, (index) {
                  final active = index < _rating;
                  return IconButton(
                    onPressed: () => setState(() => _rating = index + 1),
                    icon: Icon(
                      active ? Icons.star : Icons.star_border,
                      color: active ? AppColors.primary : AppColors.divider,
                      size: 34,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 10),
              Text(
                'Write in below box',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _feedbackController,
                maxLines: 5,
                decoration: const InputDecoration(
                  hintText: 'Write here...',
                  alignLabelWithHint: true,
                ),
              ),
              const Spacer(),
              PrimaryButton(label: 'Send', onPressed: _submit),
            ],
          ),
        ),
      ),
    );
  }

  void _submit() {
    final updated = widget.order.copyWith(
      status: OrderStatus.completed,
      rating: _rating.toDouble(),
    );
    Navigator.pop(context, updated);
  }
}
