import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:athidihub/core/logging/app_logger.dart';

// ── Owner screens
import 'package:athidihub/features/auth/presentation/screens/splash_screen_new.dart';
import 'package:athidihub/features/auth/presentation/screens/login_screen.dart';
import 'package:athidihub/features/auth/presentation/screens/register_screen.dart';
import 'package:athidihub/features/auth/presentation/screens/otp_screen.dart';
import 'package:athidihub/features/auth/presentation/screens/profile_screen.dart';
import 'package:athidihub/features/onboarding/screens/onboarding_shell.dart';
import 'package:athidihub/features/dashboard/screens/main_shell.dart';
import 'package:athidihub/features/dashboard/screens/owner_dashboard_screen.dart';
import 'package:athidihub/features/properties/presentation/screens/properties_screen.dart';
import 'package:athidihub/features/properties/presentation/screens/property_detail_screen.dart';
import 'package:athidihub/features/properties/presentation/screens/add_property_screen.dart';
import 'package:athidihub/features/beds/presentation/screens/bed_detail_screen.dart';
import 'package:athidihub/features/beds/presentation/screens/add_edit_bed_screen.dart';
import 'package:athidihub/features/rooms/presentation/screens/rooms_screen.dart';
import 'package:athidihub/features/rooms/presentation/screens/add_room_screen.dart';
import 'package:athidihub/features/rooms/presentation/screens/room_detail_screen.dart';
import 'package:athidihub/features/tenants/presentation/screens/tenants_screen.dart';
import 'package:athidihub/features/tenants/presentation/screens/add_tenant_screen.dart';
import 'package:athidihub/features/tenants/presentation/screens/tenant_detail_screen.dart';
import 'package:athidihub/features/tenants/presentation/screens/edit_tenant_screen.dart';
import 'package:athidihub/features/tenants/presentation/screens/assign_bed_screen.dart';
import 'package:athidihub/features/invoices/presentation/screens/invoices_screen.dart';
import 'package:athidihub/features/invoices/presentation/screens/invoice_detail_screen.dart';
import 'package:athidihub/features/payments/presentation/screens/payment_screen.dart';
import 'package:athidihub/features/maintenance/presentation/screens/maintenance_screen.dart';
import 'package:athidihub/features/maintenance/presentation/screens/add_maintenance_screen.dart';
import 'package:athidihub/features/kyc/screens/kyc_initiation_screen.dart';
import 'package:athidihub/features/kyc/screens/kyc_document_upload_screen.dart';
import 'package:athidihub/features/kyc/screens/admin_kyc_review_screen.dart';
import 'package:athidihub/features/organizations/presentation/screens/organization_detail_screen.dart';
import 'package:athidihub/features/organizations/presentation/screens/edit_organization_screen.dart';

// ── Tenant Portal screens
import 'package:athidihub/features/tenant_portal/screens/tenant_shell.dart';
import 'package:athidihub/features/tenant_portal/screens/tenant_dashboard_screen.dart';
import 'package:athidihub/features/tenant_portal/screens/tenant_payment_history_screen.dart';
import 'package:athidihub/features/tenant_portal/screens/tenant_documents_screen.dart';
import 'package:athidihub/features/tenant_portal/screens/tenant_profile_screen.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

// ─── Auth Refresh Listenable ──────────────────────────────────────────────────
class _SupabaseAuthNotifier extends ChangeNotifier {
  late final StreamSubscription<AuthState> _sub;

  _SupabaseAuthNotifier() {
    _sub = Supabase.instance.client.auth.onAuthStateChange.listen((event) {
      AppLogger.authEvent('state_changed', data: {
        'event': event.event.name,
        'hasSession': event.session != null,
      });
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

// ─── Router Provider ──────────────────────────────────────────────────────────
final routerProvider = Provider<GoRouter>((ref) {
  final authNotifier = _SupabaseAuthNotifier();
  ref.onDispose(authNotifier.dispose);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/splash',
    debugLogDiagnostics: false,
    refreshListenable: authNotifier,
    redirect: (context, state) async {
      final session = Supabase.instance.client.auth.currentSession;
      final isLoggedIn = session != null;
      final path = state.fullPath ?? '';

      final isSplash     = path == '/splash';
      final isAuthRoute  = path.startsWith('/auth');
      final isOnboarding = path.startsWith('/onboarding');

      if (isSplash) return null;
      if (!isLoggedIn && !isAuthRoute) return '/auth/login';
      if (isLoggedIn && isAuthRoute) return '/splash';
      if (isOnboarding && isLoggedIn) return null;

      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (c, s) => const SplashScreenNew()),

      // ── Auth ──────────────────────────────────────────────
      GoRoute(path: '/auth/login',    name: 'login',    builder: (c, s) => const LoginScreen()),
      GoRoute(path: '/auth/register', name: 'register', builder: (c, s) => const RegisterScreen()),
      GoRoute(path: '/auth/otp',      name: 'otp',      builder: (c, s) => OtpScreen(phone: s.extra as String? ?? '')),

      // ── KYC ───────────────────────────────────────────────
      GoRoute(
        path: '/kyc/initiation/:tenantId',
        name: 'kyc-initiation',
        builder: (c, s) => KYCInitiationScreen(tenantId: s.pathParameters['tenantId']!),
      ),
      GoRoute(
        path: '/kyc/document-upload/:tenantId',
        name: 'kyc-document-upload',
        builder: (c, s) => KYCDocumentUploadScreen(tenantId: s.pathParameters['tenantId']!),
      ),
      GoRoute(path: '/admin/kyc-review', name: 'admin-kyc-review', builder: (c, s) => const AdminKYCReviewScreen()),

      // ── Onboarding ────────────────────────────────────────
      GoRoute(path: '/onboarding', name: 'onboarding', builder: (c, s) => const OnboardingShell()),

      // ── OWNER / MANAGER shell ──────────────────────────────
      StatefulShellRoute.indexedStack(
        builder: (c, s, nav) => MainShell(navigationShell: nav),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: '/dashboard', name: 'dashboard', builder: (c, s) => const OwnerDashboardScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/properties', name: 'properties',
              builder: (c, s) => const PropertiesScreen(),
              routes: [
                GoRoute(path: 'add', name: 'add-property', builder: (c, s) => const AddEditPropertyScreen()),
                GoRoute(
                  path: ':id', name: 'property-detail',
                  builder: (c, s) => PropertyDetailScreen(propertyId: s.pathParameters['id']!),
                  routes: [
                    GoRoute(path: 'edit', name: 'edit-property', builder: (c, s) => AddEditPropertyScreen(propertyToEdit: s.extra as dynamic)),
                    GoRoute(
                      path: 'rooms', name: 'rooms',
                      builder: (c, s) => RoomsScreen(propertyId: s.pathParameters['id']!),
                      routes: [
                        GoRoute(path: 'add', name: 'add-room', builder: (c, s) => AddEditRoomScreen(propertyId: s.pathParameters['id']!)),
                        GoRoute(
                          path: ':roomId', name: 'room-detail',
                          builder: (c, s) => RoomDetailScreen(roomId: s.pathParameters['roomId']!),
                          routes: [
                            GoRoute(path: 'add-bed', name: 'add-bed', builder: (c, s) => AddEditBedScreen(roomId: s.pathParameters['roomId']!)),
                            GoRoute(path: 'edit', name: 'edit-room', builder: (c, s) => AddEditRoomScreen(propertyId: s.pathParameters['id']!, roomToEdit: s.extra as dynamic)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            GoRoute(path: '/beds/:bedId', name: 'bed-detail', builder: (c, s) => BedDetailScreen(bedId: s.pathParameters['bedId']!)),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/tenants', name: 'tenants',
              builder: (c, s) => const TenantsScreen(),
              routes: [
                GoRoute(path: 'add',       name: 'add-tenant',    builder: (c, s) => const AddTenantScreen()),
                GoRoute(path: ':id',       name: 'tenant-detail', builder: (c, s) => TenantDetailScreen(tenantId: s.pathParameters['id']!)),
                GoRoute(path: ':id/edit',  name: 'edit-tenant',   builder: (c, s) => EditTenantScreen(tenant: s.extra as dynamic)),
                GoRoute(path: ':id/assign',name: 'assign-bed',    builder: (c, s) => AssignBedScreen(tenantId: s.pathParameters['id']!)),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/invoices', name: 'invoices',
              builder: (c, s) => const InvoicesScreen(),
              routes: [
                GoRoute(path: ':id', name: 'invoice-detail', builder: (c, s) => InvoiceDetailScreen(invoiceId: s.pathParameters['id']!)),
              ],
            ),
            GoRoute(path: '/payments', name: 'payments', builder: (c, s) => PaymentScreen(invoiceId: s.extra as String? ?? '')),
            GoRoute(
              path: '/maintenance', name: 'maintenance',
              builder: (c, s) => const MaintenanceScreen(),
              routes: [
                GoRoute(path: 'add', name: 'add-maintenance', builder: (c, s) => const AddMaintenanceScreen()),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/profile', name: 'profile', builder: (c, s) => const ProfileScreen()),
          ]),
        ],
      ),

      // ── Organization Management (outside shell) ───────────
      GoRoute(
        path: '/organization/:id',
        name: 'organization-detail',
        builder: (c, s) => OrganizationDetailScreen(organizationId: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/organization/edit/:id',
        name: 'edit-organization',
        builder: (c, s) => EditOrganizationScreen(organizationId: s.pathParameters['id']!),
      ),

      // ── TENANT PORTAL shell ────────────────────────────────
      StatefulShellRoute.indexedStack(
        builder: (c, s, nav) => TenantShell(navigationShell: nav),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: '/tenant/home', name: 'tenant-home', builder: (c, s) => const TenantDashboardScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/tenant/payments', name: 'tenant-payments', builder: (c, s) => const TenantPaymentHistoryScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/tenant/documents', name: 'tenant-documents', builder: (c, s) => const TenantDocumentsScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/tenant/profile', name: 'tenant-profile', builder: (c, s) => const TenantProfileScreen()),
          ]),
        ],
      ),

      // ── Invoice Details (outside shell) ─────────────────────
      GoRoute(
        path: '/tenant/invoice/:invoiceId',
        name: 'tenant-invoice-details',
        builder: (c, s) {
          // This will be filled from payment history screen
          return const SizedBox();
        },
      ),
    ],
    errorBuilder: (c, s) => Scaffold(
      body: Center(child: Text('Page not found: ${s.fullPath}')),
    ),
  );
});
