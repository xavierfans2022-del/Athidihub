import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:athidihub/core/network/dio_provider.dart';

class NavigationData {
  final String route;
  final bool isTenant;
  final bool isOwner;
  final bool hasOrganization;
  final bool hasAssignment;
  final OnboardingProgress? onboardingProgress;

  NavigationData({
    required this.route,
    required this.isTenant,
    required this.isOwner,
    required this.hasOrganization,
    required this.hasAssignment,
    this.onboardingProgress,
  });

  factory NavigationData.fromJson(Map<String, dynamic> json) {
    return NavigationData(
      route: json['route'] as String,
      isTenant: json['isTenant'] as bool,
      isOwner: json['isOwner'] as bool,
      hasOrganization: json['hasOrganization'] as bool,
      hasAssignment: json['hasAssignment'] as bool,
      onboardingProgress: json['onboardingProgress'] != null
          ? OnboardingProgress.fromJson(json['onboardingProgress'])
          : null,
    );
  }
}

class OnboardingProgress {
  final String id;
  final int currentStep;
  final String onboardingStatus;
  final bool organizationCreated;
  final bool propertyCreated;
  final bool roomCreated;
  final bool bedCreated;
  final String? organizationId;
  final String? propertyId;
  final String? roomId;

  OnboardingProgress({
    required this.id,
    required this.currentStep,
    required this.onboardingStatus,
    required this.organizationCreated,
    required this.propertyCreated,
    required this.roomCreated,
    required this.bedCreated,
    this.organizationId,
    this.propertyId,
    this.roomId,
  });

  factory OnboardingProgress.fromJson(Map<String, dynamic> json) {
    return OnboardingProgress(
      id: json['id'] as String,
      currentStep: json['currentStep'] as int,
      onboardingStatus: json['onboardingStatus'] as String,
      organizationCreated: json['organizationCreated'] as bool? ?? false,
      propertyCreated: json['propertyCreated'] as bool? ?? false,
      roomCreated: json['roomCreated'] as bool? ?? false,
      bedCreated: json['bedCreated'] as bool? ?? false,
      organizationId: json['organizationId'] as String?,
      propertyId: json['propertyId'] as String?,
      roomId: json['roomId'] as String?,
    );
  }
}

class NavigationService {
  final Dio _dio;

  NavigationService(this._dio);

  Future<NavigationData> getNavigationData({int retries = 3}) async {
    for (int attempt = 0; attempt < retries; attempt++) {
      try {
        final response = await _dio.get('/dashboard/user/navigation');
        return NavigationData.fromJson(response.data);
      } on DioException catch (e) {
        if (attempt == retries - 1) rethrow;
        if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout ||
            e.type == DioExceptionType.connectionError) {
          await Future.delayed(Duration(seconds: attempt + 1));
          continue;
        }
        rethrow;
      }
    }
    throw Exception('Failed to fetch navigation data');
  }

  Future<OnboardingProgress> getOnboardingProgress() async {
    final response = await _dio.get('/dashboard/user/onboarding');
    return OnboardingProgress.fromJson(response.data);
  }

  Future<OnboardingProgress> updateOnboardingStep({
    required int step,
    String? organizationId,
    String? propertyId,
    String? roomId,
  }) async {
    final response = await _dio.post('/dashboard/user/onboarding/step', data: {
      'step': step,
      if (organizationId != null) 'organizationId': organizationId,
      if (propertyId != null) 'propertyId': propertyId,
      if (roomId != null) 'roomId': roomId,
    });
    return OnboardingProgress.fromJson(response.data);
  }

  Future<void> completeOnboarding() async {
    await _dio.patch('/dashboard/user/onboarding/complete');
  }
}

final navigationServiceProvider = Provider<NavigationService>((ref) {
  final dio = ref.watch(dioProvider);
  return NavigationService(dio);
});

final navigationDataProvider = FutureProvider<NavigationData>((ref) async {
  final service = ref.watch(navigationServiceProvider);
  return service.getNavigationData();
});

final onboardingProgressProvider = FutureProvider<OnboardingProgress>((ref) async {
  final service = ref.watch(navigationServiceProvider);
  return service.getOnboardingProgress();
});
