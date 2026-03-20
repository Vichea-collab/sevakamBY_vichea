import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../core/constants/app_colors.dart';
import '../core/firebase/firebase_bootstrap.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/page_transition.dart';
import '../core/utils/responsive.dart';
import '../domain/entities/provider.dart';
import 'pages/splash_page.dart';
import 'pages/welcome_page.dart';
import 'pages/onboarding_page.dart';
import 'pages/auth/customer_auth_page.dart';
import 'pages/auth/provider_auth_page.dart';
import 'pages/auth/forgot_password_flow.dart';
import 'pages/home/home_page.dart';
import 'pages/providers/provider_home_page.dart';
import 'pages/providers/provider_posts_page.dart';
import 'pages/search/search_page.dart';
import 'pages/chat/chat_list_page.dart';
import 'pages/chat/chat_conversation_page.dart';
import 'pages/orders/orders_page.dart';
import 'pages/post/client_post_page.dart';
import 'pages/booking/booking_address_page.dart';
import 'pages/notifications/notifications_page.dart';
import 'pages/favorites/favorites_page.dart';
import 'pages/profile/profile_page.dart';
import 'pages/profile/edit_profile_page.dart';
import 'pages/profile/notification_page.dart';
import 'pages/profile/help_support_page.dart';
import 'pages/provider_portal/provider_home_page.dart';
import 'pages/provider_portal/provider_notifications_page.dart';
import 'pages/provider_portal/provider_post_page.dart';
import 'pages/provider_portal/provider_orders_page.dart';
import 'pages/provider_portal/provider_profile_page.dart';
import 'pages/provider_portal/provider_verification_page.dart';
import 'pages/provider_portal/provider_availability_page.dart';
import 'pages/provider_portal/provider_portfolio_page.dart';
import 'pages/main_shell_page.dart';
import 'state/booking_catalog_state.dart';
import 'state/app_role_state.dart';
import 'state/app_state.dart';
import 'state/chat_state.dart';
import 'state/user_notification_state.dart';
import 'widgets/notification_messenger_sheet.dart';

class ServiceFinderApp extends StatefulWidget {
  const ServiceFinderApp({super.key});

  @override
  State<ServiceFinderApp> createState() => _ServiceFinderAppState();
}

class _ServiceFinderAppState extends State<ServiceFinderApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppState.themeMode,
      builder: (context, themeMode, _) {
        return MaterialApp(
          navigatorKey: _navigatorKey,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: themeMode,
          initialRoute: SplashPage.routeName,
          builder: (context, child) {
            final responsive = context.rs;
            final brightness = Theme.of(context).brightness;
            final scaledTheme = brightness == Brightness.dark
                ? AppTheme.dark(scale: responsive.shortestSide / 390)
                : AppTheme.light(scale: responsive.shortestSide / 390);
            final mediaQuery = MediaQuery.of(context);

            return MediaQuery(
              data: mediaQuery.copyWith(
                textScaler: mediaQuery.textScaler.clamp(
                  minScaleFactor: 0.9,
                  maxScaleFactor: 1.15,
                ),
              ),
              child: Theme(
                data: scaledTheme,
                child: _GlobalNotificationHost(
                  navigatorKey: _navigatorKey,
                  child: child ?? const SizedBox.shrink(),
                ),
              ),
            );
          },
          onGenerateRoute: (settings) {
            Widget page;
            switch (settings.name) {
              case SplashPage.routeName:
                page = const SplashPage();
                break;
              case MainShellPage.routeName:
                page = const MainShellPage();
                break;
              case WelcomePage.routeName:
                page = const WelcomePage();
                break;
              case OnboardingPage.routeName:
                page = const OnboardingPage();
                break;
              case CustomerAuthPage.routeName:
                page = const CustomerAuthPage();
                break;
              case ProviderAuthPage.routeName:
                page = const ProviderAuthPage();
                break;
              case ForgotPasswordFlow.routeName:
                page = const ForgotPasswordFlow();
                break;
              case HomePage.routeName:
                page = const HomePage();
                break;
              case ProviderHomePage.routeName:
                page = const ProviderHomePage();
                break;
              case ProviderPostsPage.routeName:
                page = const ProviderPostsPage();
                break;
              case SearchPage.routeName:
                page = const SearchPage();
                break;
              case ChatListPage.routeName:
                page = const ChatListPage();
                break;
              case OrdersPage.routeName:
                page = const OrdersPage();
                break;
              case ClientPostPage.routeName:
                page = const ClientPostPage();
                break;
              case NotificationsPage.routeName:
                page = const NotificationsPage();
                break;
              case FavoritesPage.routeName:
                page = const FavoritesPage();
                break;
              case '/booking/address':
                page = BookingAddressPage(
                  draft: BookingCatalogState.defaultBookingDraft(
                    provider: const ProviderItem(
                      uid: 'default-provider',
                      name: 'Service Provider',
                      role: 'Cleaner',
                      rating: 0,
                      imagePath: '',
                      accentColor: Color(0xFFEAF1FF),
                    ),
                  ),
                );
                break;
              case ProfilePage.routeName:
                page = const ProfilePage();
                break;
              case EditProfilePage.routeName:
                page = const EditProfilePage();
                break;
              case ProfileNotificationPage.routeName:
                page = const ProfileNotificationPage();
                break;
              case HelpSupportPage.routeName:
                page = const HelpSupportPage();
                break;
              case ProviderPortalHomePage.routeName:
                page = const ProviderPortalHomePage();
                break;
              case ProviderNotificationsPage.routeName:
                page = const ProviderNotificationsPage();
                break;
              case ProviderPostPage.routeName:
                page = const ProviderPostPage();
                break;
              case ProviderOrdersPage.routeName:
                page = const ProviderOrdersPage();
                break;
              case ProviderProfilePage.routeName:
                page = const ProviderProfilePage();
                break;
              case ProviderVerificationPage.routeName:
                page = const ProviderVerificationPage();
                break;
              case ProviderPortfolioPage.routeName:
                page = const ProviderPortfolioPage();
                break;
              case '/provider/availability':
                page = const ProviderAvailabilityPage();
                break;
              default:
                return null;
            }
            return slideFadeRoute(page);
          },
        );
      },
    );
  }
}

class _GlobalNotificationHost extends StatefulWidget {
  final Widget child;
  final GlobalKey<NavigatorState> navigatorKey;

  const _GlobalNotificationHost({
    required this.child,
    required this.navigatorKey,
  });

  @override
  State<_GlobalNotificationHost> createState() =>
      _GlobalNotificationHostState();
}

class _GlobalNotificationHostState extends State<_GlobalNotificationHost> {
  final Set<String> _seenNoticeIds = <String>{};
  OverlayEntry? _activeBannerEntry;
  Timer? _activeBannerTimer;
  StreamSubscription<RemoteMessage>? _pushForegroundSubscription;
  StreamSubscription<RemoteMessage>? _pushOpenSubscription;
  Timer? _heartbeatTimer;
  bool _primed = false;

  @override
  void initState() {
    super.initState();
    UserNotificationState.notices.addListener(_onNoticesChanged);
    unawaited(_setupPushHandlers());
    _startGlobalHeartbeat();
  }

  @override
  void dispose() {
    _heartbeatTimer?.cancel();
    UserNotificationState.notices.removeListener(_onNoticesChanged);
    _pushForegroundSubscription?.cancel();
    _pushOpenSubscription?.cancel();
    _removeActiveBanner();
    super.dispose();
  }

  void _startGlobalHeartbeat() {
    ChatState.updateHeartbeat();
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(minutes: 2), (_) {
      ChatState.updateHeartbeat();
    });
  }

  void _onNoticesChanged() {
    if (!mounted) return;
    final notices = UserNotificationState.notices.value;
    if (notices.isEmpty) {
      _seenNoticeIds.clear();
      _primed = false;
      return;
    }

    if (!_primed) {
      _seenNoticeIds.addAll(notices.map((item) => item.id));
      _primed = true;
      return;
    }

    final fresh = notices
        .where((item) => !_seenNoticeIds.contains(item.id))
        .toList(growable: false);
    if (fresh.isEmpty) return;

    _seenNoticeIds.addAll(fresh.map((item) => item.id));
    final latest = fresh.reduce((left, right) {
      final leftTime = left.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final rightTime =
          right.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return rightTime.isAfter(leftTime) ? right : left;
    });

    final summary = latest.message.trim().isEmpty
        ? 'You have a new notification.'
        : latest.message.trim();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _showTopBanner(
        title: latest.title.trim(),
        message: summary,
        onReply: () {
          _removeActiveBanner();
          _openQuickMessenger();
        },
      );
    });
  }

  Future<void> _setupPushHandlers() async {
    if (!FirebaseBootstrap.isConfigured) return;
    try {
      await FirebaseMessaging.instance.requestPermission();
      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
            alert: true,
            badge: true,
            sound: true,
          );
    } catch (error) {
      debugPrint('Push permission setup skipped: $error');
    }

    try {
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
        final apnsToken = await FirebaseMessaging.instance.getAPNSToken();
        if (apnsToken == null || apnsToken.trim().isEmpty) {
          debugPrint(
            'FCM token fetch deferred until APNS token is available on iOS.',
          );
        } else {
          final token = await FirebaseMessaging.instance.getToken();
          if (token != null && token.trim().isNotEmpty) {
            debugPrint('FCM token ready (mobile): $token');
          }
        }
      } else {
        final token = await FirebaseMessaging.instance.getToken();
        if (token != null && token.trim().isNotEmpty) {
          debugPrint('FCM token ready (${kIsWeb ? 'web' : 'mobile'}): $token');
        }
      }
    } catch (error) {
      debugPrint('FCM token fetch skipped: $error');
    }

    try {
      _pushForegroundSubscription?.cancel();
      _pushOpenSubscription?.cancel();

      _pushForegroundSubscription = FirebaseMessaging.onMessage.listen(
        _onForegroundPush,
      );
      _pushOpenSubscription = FirebaseMessaging.onMessageOpenedApp.listen(
        _onPushOpened,
      );

      final initialMessage = await FirebaseMessaging.instance
          .getInitialMessage();
      if (initialMessage != null) {
        _onPushOpened(initialMessage);
      }
    } catch (error) {
      debugPrint('Push listener setup skipped: $error');
    }
  }

  void _onForegroundPush(RemoteMessage message) {
    final notification = message.notification;
    final title = (notification?.title ?? '').trim();
    final body = (notification?.body ?? '').trim();
    final fallbackSummary = body.isEmpty ? 'You have a new message.' : body;
    _showTopBanner(
      title: title.isEmpty ? 'New notification' : title,
      message: fallbackSummary,
      onView: () {
        _removeActiveBanner();
        unawaited(_openDeepLinkFromData(message.data));
      },
      onReply: () {
        _removeActiveBanner();
        _openQuickMessenger();
      },
    );
  }

  void _onPushOpened(RemoteMessage message) {
    unawaited(_openDeepLinkFromData(message.data));
  }

  Future<void> _openDeepLinkFromData(Map<String, dynamic> data) async {
    final roleRaw = (data['role'] ?? '').toString().trim().toLowerCase();
    if (roleRaw == 'provider') {
      AppRoleState.setProvider(true);
    } else if (roleRaw == 'finder') {
      AppRoleState.setProvider(false);
    }

    final target = (data['target'] ?? data['type'] ?? '')
        .toString()
        .trim()
        .toLowerCase();
    final threadId = (data['threadId'] ?? data['chatId'] ?? '')
        .toString()
        .trim();

    if (threadId.isNotEmpty ||
        target == 'chat' ||
        target == 'message' ||
        target == 'messages') {
      await _openChatThread(threadId);
      return;
    }

    final navigator = widget.navigatorKey.currentState;
    if (navigator == null) return;
    if (target == 'order' || target == 'orders') {
      navigator.pushNamed(AppRoleState.orderRoute());
      return;
    }
    if (target == 'home') {
      navigator.pushNamed(AppRoleState.homeRoute());
      return;
    }
    navigator.pushNamed(AppRoleState.notificationRoute());
  }

  Future<void> _openChatThread(String threadId) async {
    final navigator = widget.navigatorKey.currentState;
    if (navigator == null) return;
    final id = threadId.trim();
    if (id.isEmpty) {
      navigator.pushNamed(ChatListPage.routeName);
      return;
    }
    try {
      final thread = await ChatState.fetchThreadById(id);
      if (thread == null) {
        navigator.pushNamed(ChatListPage.routeName);
        return;
      }
      navigator.push(slideFadeRoute(ChatConversationPage(thread: thread)));
      unawaited(ChatState.markThreadAsRead(thread.id, syncThreads: true));
    } catch (_) {
      navigator.pushNamed(ChatListPage.routeName);
    }
  }

  void _showTopBanner({
    required String title,
    required String message,
    VoidCallback? onView,
    VoidCallback? onReply,
  }) {
    final overlay = widget.navigatorKey.currentState?.overlay;
    if (overlay == null) return;
    _removeActiveBanner();
    final banner = OverlayEntry(
      builder: (context) {
        final safeTop = MediaQuery.of(context).padding.top + 10;
        return Positioned(
          top: safeTop,
          left: 12,
          right: 12,
          child: _TopNoticeBanner(
            title: title.isEmpty ? 'Platform update' : title,
            message: message,
            onView:
                onView ??
                () {
                  _removeActiveBanner();
                  final route = AppRoleState.notificationRoute();
                  widget.navigatorKey.currentState?.pushNamed(route);
                },
            onReply: onReply,
            onDismiss: _removeActiveBanner,
          ),
        );
      },
    );
    _activeBannerEntry = banner;
    overlay.insert(banner);
    _activeBannerTimer = Timer(const Duration(seconds: 5), _removeActiveBanner);
  }

  Future<void> _openQuickMessenger() async {
    final context = widget.navigatorKey.currentContext;
    if (context == null) return;
    try {
      await ChatState.refresh(page: 1);
      await ChatState.refreshUnreadCount();
    } catch (_) {}
    if (!context.mounted) return;
    await showNotificationMessengerSheet(
      context,
      title: 'Messenger',
      subtitle: 'Recent conversations',
      threads: ChatState.threads.value,
      accentColor: AppColors.primary,
    );
  }

  void _removeActiveBanner() {
    _activeBannerTimer?.cancel();
    _activeBannerTimer = null;
    _activeBannerEntry?.remove();
    _activeBannerEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

class _TopNoticeBanner extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback onView;
  final VoidCallback onDismiss;
  final VoidCallback? onReply;

  const _TopNoticeBanner({
    required this.title,
    required this.message,
    required this.onView,
    required this.onDismiss,
    this.onReply,
  });

  @override
  Widget build(BuildContext context) {
    const surfaceColor = Colors.white;
    const textColor = Color(0xFF0F172A);
    const subColor = Color(0xFF64748B);
    const accentColor = AppColors.primary;

    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.divider),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A0F172A),
              blurRadius: 24,
              offset: Offset(0, 12),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: onView,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.notifications_active_rounded,
                        color: accentColor,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              color: textColor,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            message,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: subColor,
                              fontSize: 13.5,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: onDismiss,
                      icon: const Icon(
                        Icons.close_rounded,
                        size: 20,
                        color: subColor,
                      ),
                      constraints: const BoxConstraints.tightFor(
                        width: 32,
                        height: 32,
                      ),
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
            ),
            Container(
              height: 1,
              color: AppColors.divider.withValues(alpha: 0.5),
            ),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: onView,
                    child: Container(
                      height: 48,
                      alignment: Alignment.center,
                      child: const Text(
                        'View Details',
                        style: TextStyle(
                          color: accentColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ),
                if (onReply != null) ...[
                  Container(
                    width: 1,
                    height: 24,
                    color: AppColors.divider.withValues(alpha: 0.5),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: onReply,
                      child: Container(
                        height: 48,
                        alignment: Alignment.center,
                        child: const Text(
                          'Reply',
                          style: TextStyle(
                            color: accentColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
