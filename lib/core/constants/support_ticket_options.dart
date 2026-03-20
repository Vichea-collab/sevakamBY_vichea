import 'package:flutter/material.dart';

class SupportTicketSubcategoryOption {
  final String id;
  final String label;
  final String autoReply;
  final String priority;

  const SupportTicketSubcategoryOption({
    required this.id,
    required this.label,
    required this.autoReply,
    required this.priority,
  });
}

class SupportTicketCategoryOption {
  final String id;
  final String label;
  final String description;
  final IconData icon;
  final List<SupportTicketSubcategoryOption> subcategories;

  const SupportTicketCategoryOption({
    required this.id,
    required this.label,
    required this.description,
    required this.icon,
    required this.subcategories,
  });
}

const List<SupportTicketCategoryOption> supportTicketCategories = [
  SupportTicketCategoryOption(
    id: 'payment_charge',
    label: 'Wrong charge / payment',
    description:
        'Billing problems, duplicate charges, refunds, or paid plans not activating.',
    icon: Icons.payments_rounded,
    subcategories: [
      SupportTicketSubcategoryOption(
        id: 'wrong_charge',
        label: 'Wrong charge',
        priority: 'high',
        autoReply:
            'Thanks for reporting a billing issue. Please share your booking or payment ID, the charged amount, the correct amount, and a screenshot of the receipt so our admin team can review it quickly.',
      ),
      SupportTicketSubcategoryOption(
        id: 'double_charge',
        label: 'Double charge',
        priority: 'high',
        autoReply:
            'We can help check a duplicate payment. Please send both charge screenshots, payment date and time, and the related booking or subscription ID.',
      ),
      SupportTicketSubcategoryOption(
        id: 'paid_not_activated',
        label: 'Paid but not activated',
        priority: 'high',
        autoReply:
            'Please send the payment screenshot, the plan name, your account email, and the time you completed payment. We will verify the activation status.',
      ),
      SupportTicketSubcategoryOption(
        id: 'refund_request',
        label: 'Refund request',
        priority: 'normal',
        autoReply:
            'Please explain why you are requesting a refund and include the booking or payment ID, amount paid, and any screenshots that support your request.',
      ),
    ],
  ),
  SupportTicketCategoryOption(
    id: 'provider_issue',
    label: 'Provider issue',
    description:
        'No-show provider, poor service, wrong pricing, or unprofessional behavior.',
    icon: Icons.handyman_rounded,
    subcategories: [
      SupportTicketSubcategoryOption(
        id: 'no_show',
        label: 'Provider did not show up',
        priority: 'high',
        autoReply:
            'Please share the booking ID, provider name, scheduled time, and whether the provider contacted you before missing the booking.',
      ),
      SupportTicketSubcategoryOption(
        id: 'poor_service',
        label: 'Poor service quality',
        priority: 'normal',
        autoReply:
            'Please tell us what service was completed, what went wrong, and include any photos or screenshots if available.',
      ),
      SupportTicketSubcategoryOption(
        id: 'wrong_price',
        label: 'Wrong price or extra charge',
        priority: 'high',
        autoReply:
            'Please share the quoted price, the amount requested by the provider, the booking ID, and any chat or invoice screenshots.',
      ),
      SupportTicketSubcategoryOption(
        id: 'behavior_issue',
        label: 'Behavior or trust issue',
        priority: 'high',
        autoReply:
            'Please describe what happened, when it happened, and include the provider name and booking ID so admin can review the case safely.',
      ),
    ],
  ),
  SupportTicketCategoryOption(
    id: 'finder_issue',
    label: 'Finder issue',
    description:
        'Provider-side reports about abusive, fake, or problematic customer requests.',
    icon: Icons.person_search_rounded,
    subcategories: [
      SupportTicketSubcategoryOption(
        id: 'fake_booking',
        label: 'Fake or invalid booking',
        priority: 'high',
        autoReply:
            'Please share the booking ID, the finder name, and what made the booking invalid or suspicious.',
      ),
      SupportTicketSubcategoryOption(
        id: 'communication_issue',
        label: 'Communication issue',
        priority: 'normal',
        autoReply:
            'Please explain the communication problem and include the finder name, booking ID, and any screenshots if available.',
      ),
      SupportTicketSubcategoryOption(
        id: 'abusive_behavior',
        label: 'Abusive behavior',
        priority: 'high',
        autoReply:
            'Please describe the behavior, when it happened, and attach screenshots if possible so the admin team can investigate.',
      ),
      SupportTicketSubcategoryOption(
        id: 'pricing_dispute',
        label: 'Pricing dispute',
        priority: 'normal',
        autoReply:
            'Please share the booking ID, agreed amount, disputed amount, and any supporting screenshots from chat or quotation.',
      ),
    ],
  ),
  SupportTicketCategoryOption(
    id: 'booking_problem',
    label: 'Booking problem',
    description: 'Problems creating, updating, or tracking a booking.',
    icon: Icons.event_note_rounded,
    subcategories: [
      SupportTicketSubcategoryOption(
        id: 'cannot_book',
        label: 'Cannot create booking',
        priority: 'high',
        autoReply:
            'Please tell us which provider or service you were booking, what step failed, and include a screenshot of the error if possible.',
      ),
      SupportTicketSubcategoryOption(
        id: 'wrong_status',
        label: 'Wrong booking status',
        priority: 'normal',
        autoReply:
            'Please share the booking ID and the status you expected versus the status currently shown in the app.',
      ),
      SupportTicketSubcategoryOption(
        id: 'schedule_issue',
        label: 'Date or time issue',
        priority: 'normal',
        autoReply:
            'Please share the booking ID, expected date and time, shown date and time, and any related screenshots.',
      ),
      SupportTicketSubcategoryOption(
        id: 'cancel_issue',
        label: 'Cancellation issue',
        priority: 'normal',
        autoReply:
            'Please explain what happened when you tried to cancel and include the booking ID and current booking status.',
      ),
    ],
  ),
  SupportTicketCategoryOption(
    id: 'subscription_upgrade',
    label: 'Subscription / upgrade',
    description: 'Upgrade, renewal, or billing questions for provider plans.',
    icon: Icons.workspace_premium_rounded,
    subcategories: [
      SupportTicketSubcategoryOption(
        id: 'upgrade_not_active',
        label: 'Upgrade not active',
        priority: 'high',
        autoReply:
            'Please share the subscription plan, payment screenshot, account email, and the time you completed checkout.',
      ),
      SupportTicketSubcategoryOption(
        id: 'renewal_issue',
        label: 'Renewal issue',
        priority: 'normal',
        autoReply:
            'Please tell us the plan name, when renewal should have happened, and what the app is currently showing.',
      ),
      SupportTicketSubcategoryOption(
        id: 'payment_failed',
        label: 'Payment failed',
        priority: 'normal',
        autoReply:
            'Please describe the payment failure, the method you used, and attach any error screenshot shown during checkout.',
      ),
      SupportTicketSubcategoryOption(
        id: 'billing_question',
        label: 'General billing question',
        priority: 'low',
        autoReply:
            'Please send your question together with the plan name and account email so admin can review the billing history.',
      ),
    ],
  ),
  SupportTicketCategoryOption(
    id: 'account_verification',
    label: 'Account / verification',
    description: 'Problems with login, access, KYC, or verification review.',
    icon: Icons.verified_user_rounded,
    subcategories: [
      SupportTicketSubcategoryOption(
        id: 'login_problem',
        label: 'Login problem',
        priority: 'high',
        autoReply:
            'Please tell us how you sign in, what error appears, and include a screenshot if the app shows one.',
      ),
      SupportTicketSubcategoryOption(
        id: 'verification_pending',
        label: 'Verification still pending',
        priority: 'normal',
        autoReply:
            'Please share when you submitted verification and what status the app is currently showing.',
      ),
      SupportTicketSubcategoryOption(
        id: 'document_issue',
        label: 'Document upload issue',
        priority: 'normal',
        autoReply:
            'Please describe which document failed to upload and include a screenshot of the issue if possible.',
      ),
      SupportTicketSubcategoryOption(
        id: 'account_access',
        label: 'Account access issue',
        priority: 'high',
        autoReply:
            'Please explain what account problem you are facing and include your email plus any error message shown in the app.',
      ),
    ],
  ),
  SupportTicketCategoryOption(
    id: 'app_bug',
    label: 'App bug / technical issue',
    description: 'Crashes, UI bugs, map issues, chat bugs, or broken actions.',
    icon: Icons.bug_report_rounded,
    subcategories: [
      SupportTicketSubcategoryOption(
        id: 'crash',
        label: 'App crash',
        priority: 'high',
        autoReply:
            'Please tell us which screen crashed, what action you took before the crash, and include a screenshot or screen recording if available.',
      ),
      SupportTicketSubcategoryOption(
        id: 'ui_bug',
        label: 'UI layout bug',
        priority: 'normal',
        autoReply:
            'Please share the screen name, what looks wrong, and a screenshot so our team can reproduce the layout issue.',
      ),
      SupportTicketSubcategoryOption(
        id: 'map_location_issue',
        label: 'Map or location issue',
        priority: 'normal',
        autoReply:
            'Please describe the location problem, your device type, and include a screenshot of the map screen if possible.',
      ),
      SupportTicketSubcategoryOption(
        id: 'chat_issue',
        label: 'Chat issue',
        priority: 'normal',
        autoReply:
            'Please describe what is not working in chat and include the related booking or ticket ID if relevant.',
      ),
    ],
  ),
  SupportTicketCategoryOption(
    id: 'other',
    label: 'Other',
    description: 'Anything else that does not fit the categories above.',
    icon: Icons.more_horiz_rounded,
    subcategories: [
      SupportTicketSubcategoryOption(
        id: 'general_question',
        label: 'General question',
        priority: 'low',
        autoReply:
            'Please describe your question clearly and include any related booking, payment, or account details if relevant.',
      ),
      SupportTicketSubcategoryOption(
        id: 'feature_request',
        label: 'Feature request',
        priority: 'low',
        autoReply:
            'Thanks for the suggestion. Please tell us what you want to improve and why it would help your workflow.',
      ),
      SupportTicketSubcategoryOption(
        id: 'other_issue',
        label: 'Other issue',
        priority: 'normal',
        autoReply:
            'Please describe the issue in as much detail as possible and include screenshots or IDs that can help us investigate.',
      ),
    ],
  ),
];

SupportTicketCategoryOption supportTicketCategoryById(String id) {
  return supportTicketCategories.firstWhere(
    (item) => item.id == id,
    orElse: () => supportTicketCategories.last,
  );
}

SupportTicketSubcategoryOption supportTicketSubcategoryById({
  required String categoryId,
  required String subcategoryId,
}) {
  final category = supportTicketCategoryById(categoryId);
  return category.subcategories.firstWhere(
    (item) => item.id == subcategoryId,
    orElse: () => category.subcategories.first,
  );
}

String supportTicketCategoryLabel(String id) {
  return supportTicketCategoryById(id).label;
}

String supportTicketSubcategoryLabel({
  required String categoryId,
  required String subcategoryId,
}) {
  return supportTicketSubcategoryById(
    categoryId: categoryId,
    subcategoryId: subcategoryId,
  ).label;
}

String supportTicketAutoReply({
  required String categoryId,
  required String subcategoryId,
}) {
  return supportTicketSubcategoryById(
    categoryId: categoryId,
    subcategoryId: subcategoryId,
  ).autoReply;
}

String supportTicketPriority({
  required String categoryId,
  required String subcategoryId,
}) {
  return supportTicketSubcategoryById(
    categoryId: categoryId,
    subcategoryId: subcategoryId,
  ).priority;
}
