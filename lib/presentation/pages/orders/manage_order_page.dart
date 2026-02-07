import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/page_transition.dart';
import '../../../domain/entities/order.dart';
import '../../widgets/app_top_bar.dart';
import 'cancel_booking_page.dart';

class ManageOrderPage extends StatelessWidget {
  final OrderItem order;

  const ManageOrderPage({super.key, required this.order});

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
                title: 'Manage Orders',
              ),
              const SizedBox(height: 20),
              Text(
                'Make changes to your orders',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.primary,
                    ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.divider),
                ),
                child: ListTile(
                  title: Text(
                    'Cancel Booking',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.primary,
                        ),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    final result = await Navigator.push<OrderItem>(
                      context,
                      slideFadeRoute(CancelBookingPage(order: order)),
                    );
                    if (!context.mounted) return;
                    Navigator.pop(context, result);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
