import 'dart:async';

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/app_toast.dart';
import '../../../core/utils/page_transition.dart';
import '../../../data/network/backend_api_client.dart';
import '../../../domain/entities/order.dart';
import '../../state/order_state.dart';
import '../../widgets/app_top_bar.dart';
import '../../widgets/primary_button.dart';
import 'booking_confirmation_page.dart';

class BookingPaymentPage extends StatefulWidget {
  final BookingDraft draft;

  const BookingPaymentPage({super.key, required this.draft});

  @override
  State<BookingPaymentPage> createState() => _BookingPaymentPageState();
}

class _BookingPaymentPageState extends State<BookingPaymentPage> {
  late PaymentMethod _selectedMethod;
  late TextEditingController _promoController;
  BookingPriceQuote? _quote;
  Timer? _quoteDebounce;
  bool _quoting = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _selectedMethod = widget.draft.paymentMethod;
    _promoController = TextEditingController(text: widget.draft.promoCode);
    unawaited(_refreshQuote());
  }

  @override
  void dispose() {
    _quoteDebounce?.cancel();
    _promoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final draft = widget.draft.copyWith(
      paymentMethod: _selectedMethod,
      promoCode: _promoController.text.trim(),
    );
    final quote = _quote ?? BookingPriceQuote.fromDraft(draft);
    final promoText = quote.promoMessage.trim();
    final promoMessageColor = quote.promoApplied
        ? AppColors.success
        : promoText.isNotEmpty
        ? AppColors.danger
        : AppColors.textSecondary;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: ListView(
            children: [
              const AppTopBar(title: 'Payment'),
              const SizedBox(height: 14),
              Text(
                'Select Payment method',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 10),
              _PaymentTile(
                label: 'Credit Card',
                icon: Icons.credit_card,
                subtitle: 'Visa / Mastercard',
                selected: _selectedMethod == PaymentMethod.creditCard,
                onTap: () =>
                    setState(() => _selectedMethod = PaymentMethod.creditCard),
              ),
              _PaymentTile(
                label: 'Bank account',
                icon: Icons.account_balance,
                subtitle: 'ABA, Acleda, Wing',
                selected: _selectedMethod == PaymentMethod.bankAccount,
                onTap: () =>
                    setState(() => _selectedMethod = PaymentMethod.bankAccount),
              ),
              _PaymentTile(
                label: 'Cash',
                icon: Icons.payments_outlined,
                subtitle: 'Pay after service completion',
                selected: _selectedMethod == PaymentMethod.cash,
                onTap: () =>
                    setState(() => _selectedMethod = PaymentMethod.cash),
              ),
              _PaymentTile(
                label: 'Bakong KHQR',
                icon: Icons.qr_code_2_rounded,
                subtitle: 'Scan and pay before booking confirmation',
                selected: _selectedMethod == PaymentMethod.khqr,
                onTap: () =>
                    setState(() => _selectedMethod = PaymentMethod.khqr),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _promoController,
                decoration: const InputDecoration(
                  hintText: 'Promo code',
                  prefixIcon: Icon(Icons.local_offer_outlined),
                ),
                onChanged: (_) => _queueQuoteRefresh(),
              ),
              if (_quoting) ...[
                const SizedBox(height: 8),
                const LinearProgressIndicator(minHeight: 2),
              ],
              if (promoText.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  promoText,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: promoMessageColor,
                    fontWeight: quote.promoApplied
                        ? FontWeight.w600
                        : FontWeight.w500,
                  ),
                ),
              ],
              const SizedBox(height: 14),
              Text(
                'Order Summary',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _InfoRow(label: 'Service', value: draft.serviceName),
                    _InfoRow(label: 'Provider', value: draft.provider.name),
                    _InfoRow(
                      label: 'Date',
                      value: _dateLabel(draft.preferredDate),
                    ),
                    _InfoRow(
                      label: 'Time slot',
                      value: draft.preferredTimeSlot,
                    ),
                    _InfoRow(
                      label: 'Duration',
                      value: '${draft.hours} hour(s)',
                    ),
                    _InfoRow(label: 'Workers', value: '${draft.workers}'),
                    _InfoRow(
                      label: 'Home type',
                      value: _homeTypeLabel(draft.homeType),
                    ),
                    _InfoRow(
                      label: 'Address',
                      value:
                          '${draft.address?.street ?? ''}, ${draft.address?.city ?? ''}',
                    ),
                    if (draft.additionalService.trim().isNotEmpty)
                      _InfoRow(
                        label: 'Additional service',
                        value: draft.additionalService,
                      ),
                    _InfoRow(
                      label: 'Payment method',
                      value: _paymentLabel(_selectedMethod),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Column(
                  children: [
                    _AmountRow(label: 'Sub Total', amount: quote.subtotal),
                    _AmountRow(
                      label: 'Processing fee',
                      amount: quote.processingFee,
                    ),
                    _AmountRow(
                      label: draft.promoCode.trim().isEmpty
                          ? 'Promo code'
                          : 'Promo code (${draft.promoCode.trim()})',
                      amount: -quote.discount,
                    ),
                    const Divider(height: 20),
                    _AmountRow(
                      label: 'Booking Cost',
                      amount: quote.total,
                      bold: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              PrimaryButton(
                label: _submitting
                    ? 'Processing...'
                    : (_selectedMethod == PaymentMethod.khqr
                          ? 'Create KHQR & Pay'
                          : 'Confirm Booking'),
                icon: Icons.check_circle_outline_rounded,
                onPressed: _submitting || _quoting
                    ? null
                    : () => _placeBooking(draft),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _placeBooking(BookingDraft draft) async {
    final latestQuote = await _refreshQuote();
    if (!mounted) return;
    if (draft.promoCode.trim().isNotEmpty && latestQuote.promoApplied != true) {
      AppToast.error(
        context,
        latestQuote.promoMessage.trim().isNotEmpty
            ? latestQuote.promoMessage
            : 'Promo code is invalid. Please update promo code.',
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final createdOrder = await OrderState.createFinderOrder(draft);
      OrderItem order = createdOrder;

      if (_selectedMethod == PaymentMethod.khqr) {
        final verified = await _openKhqrCheckout(order);
        if (verified == null) {
          if (mounted) {
            AppToast.info(
              context,
              'Booking is waiting for KHQR payment confirmation.',
            );
          }
          return;
        }
        order = verified;
      }

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        slideFadeRoute(BookingConfirmationPage(order: order)),
      );
    } catch (error) {
      if (!mounted) return;
      final reason = error is BackendApiException
          ? error.message
          : 'Please check backend connection and try again.';
      AppToast.error(context, 'Failed to place booking. $reason');
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  void _queueQuoteRefresh() {
    setState(() {});
    _quoteDebounce?.cancel();
    _quoteDebounce = Timer(const Duration(milliseconds: 420), () {
      if (!mounted) return;
      unawaited(_refreshQuote());
    });
  }

  Future<BookingPriceQuote> _refreshQuote() async {
    final draft = widget.draft.copyWith(
      paymentMethod: _selectedMethod,
      promoCode: _promoController.text.trim(),
    );
    if (mounted) {
      setState(() => _quoting = true);
    }
    try {
      final quote = await OrderState.quoteFinderOrder(draft);
      if (mounted) {
        setState(() {
          _quote = quote;
          _quoting = false;
        });
      } else {
        _quote = quote;
      }
      return quote;
    } catch (_) {
      final fallback = BookingPriceQuote.fromDraft(draft);
      if (mounted) {
        setState(() {
          _quote = fallback;
          _quoting = false;
        });
      } else {
        _quote = fallback;
      }
      return fallback;
    }
  }

  Future<OrderItem?> _openKhqrCheckout(OrderItem order) async {
    final session = await OrderState.createKhqrPaymentSession(
      orderId: order.id,
    );
    if (!mounted) return null;
    return showModalBottomSheet<OrderItem>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _KhqrCheckoutSheet(session: session, order: order),
    );
  }

  String _paymentLabel(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.creditCard:
        return 'Credit Card';
      case PaymentMethod.bankAccount:
        return 'Bank account';
      case PaymentMethod.cash:
        return 'Cash';
      case PaymentMethod.khqr:
        return 'Bakong KHQR';
    }
  }

  String _homeTypeLabel(HomeType value) {
    switch (value) {
      case HomeType.apartment:
        return 'Apartment';
      case HomeType.flat:
        return 'Flat';
      case HomeType.villa:
        return 'Villa';
      case HomeType.office:
        return 'Office';
    }
  }

  String _dateLabel(DateTime date) {
    return MaterialLocalizations.of(context).formatMediumDate(date);
  }
}

class _AmountRow extends StatelessWidget {
  final String label;
  final double amount;
  final bool bold;

  const _AmountRow({
    required this.label,
    required this.amount,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          const Spacer(),
          Text(
            '\$${amount.toStringAsFixed(0)}',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: bold ? AppColors.primary : AppColors.textPrimary,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentTile extends StatelessWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _PaymentTile({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFEAF1FF) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.divider,
            width: selected ? 1.6 : 1,
          ),
          boxShadow: selected
              ? const [
                  BoxShadow(
                    color: Color(0x1F1D4ED8),
                    blurRadius: 14,
                    offset: Offset(0, 5),
                  ),
                ]
              : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : const Color(0xFFEAF1FF),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(
                icon,
                size: 19,
                color: selected ? Colors.white : AppColors.primary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              selected ? Icons.check_circle : Icons.radio_button_unchecked,
              color: selected ? AppColors.primary : AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

class _KhqrCheckoutSheet extends StatefulWidget {
  final KhqrPaymentSession session;
  final OrderItem order;

  const _KhqrCheckoutSheet({required this.session, required this.order});

  @override
  State<_KhqrCheckoutSheet> createState() => _KhqrCheckoutSheetState();
}

class _KhqrCheckoutSheetState extends State<_KhqrCheckoutSheet> {
  bool _verifying = false;
  String _statusMessage = '';

  @override
  Widget build(BuildContext context) {
    final payload = widget.session.qrPayload.trim();
    final imageUrl = widget.session.qrImageUrl.trim();
    final amount = widget.session.amount.toStringAsFixed(2);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        18,
        8,
        18,
        18 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pay with Bakong KHQR',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Order #${widget.order.id}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Text(
            'Amount: \$$amount ${widget.session.currency}',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.divider),
            ),
            child: Column(
              children: [
                if (imageUrl.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      imageUrl,
                      height: 220,
                      width: 220,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) =>
                          _KhqrPayloadBox(payload: payload),
                    ),
                  )
                else
                  _KhqrPayloadBox(payload: payload),
                const SizedBox(height: 10),
                Text(
                  'Merchant ref: ${widget.session.merchantReference}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          if (_statusMessage.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              _statusMessage,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: PrimaryButton(
                  label: 'Not now',
                  isOutlined: true,
                  tone: PrimaryButtonTone.neutral,
                  onPressed: _verifying ? null : () => Navigator.pop(context),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: PrimaryButton(
                  label: _verifying ? 'Verifying...' : "I've Paid",
                  icon: Icons.verified_rounded,
                  onPressed: _verifying ? null : _verifyPayment,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _verifyPayment() async {
    setState(() {
      _verifying = true;
      _statusMessage = '';
    });
    try {
      final result = await OrderState.verifyKhqrPayment(
        orderId: widget.order.id,
        transactionId: widget.session.transactionId,
      );
      if (!mounted) return;
      if (result.paid) {
        Navigator.pop(context, result.order);
        return;
      }
      setState(() {
        _statusMessage =
            'Payment is still pending. Please complete payment in your banking app and try again.';
      });
    } catch (error) {
      if (!mounted) return;
      final reason = error is BackendApiException
          ? error.message
          : 'Unable to verify payment.';
      setState(() {
        _statusMessage = reason;
      });
    } finally {
      if (mounted) {
        setState(() => _verifying = false);
      }
    }
  }
}

class _KhqrPayloadBox extends StatelessWidget {
  final String payload;

  const _KhqrPayloadBox({required this.payload});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAFF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.divider),
      ),
      child: SelectableText(
        payload.isEmpty ? 'KHQR payload is unavailable.' : payload,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
