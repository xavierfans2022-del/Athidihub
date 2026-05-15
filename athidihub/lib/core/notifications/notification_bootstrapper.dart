import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:athidihub/core/notifications/app_notification_service.dart';
import 'package:athidihub/core/providers/supabase_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationBootstrapper extends ConsumerStatefulWidget {
  const NotificationBootstrapper({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<NotificationBootstrapper> createState() => _NotificationBootstrapperState();
}

class _NotificationBootstrapperState extends ConsumerState<NotificationBootstrapper> {
  ProviderSubscription<User?>? _userSubscription;
  late final AppNotificationService _notificationService = ref.read(appNotificationServiceProvider);

  @override
  void initState() {
    super.initState();
    unawaited(_bootstrap());

    _userSubscription = ref.listenManual<User?>(currentUserProvider, (previous, next) {
      unawaited(_notificationService.bindProfile(next?.id));
    });
  }

  Future<void> _bootstrap() async {
    await _notificationService.initialize();
    await _notificationService.bindProfile(ref.read(currentUserProvider)?.id);
  }

  @override
  void dispose() {
    _userSubscription?.close();
    unawaited(_notificationService.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
