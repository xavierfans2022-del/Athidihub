import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:athidihub/core/constants/app_constants.dart';
import 'package:athidihub/features/onboarding/data/onboarding_repository.dart';
import 'package:athidihub/features/onboarding/providers/navigation_provider.dart';

class OnboardingState {
  final String? orgId;
  final String? propertyId;
  final String? roomId;
  final bool isLoading;
  final String? error;
  // Pre-filled data from backend for editing
  final Map<String, dynamic>? orgData;
  final Map<String, dynamic>? propertyData;
  final Map<String, dynamic>? roomData;

  OnboardingState({
    this.orgId,
    this.propertyId,
    this.roomId,
    this.isLoading = false,
    this.error,
    this.orgData,
    this.propertyData,
    this.roomData,
  });

  OnboardingState copyWith({
    String? orgId,
    String? propertyId,
    String? roomId,
    bool? isLoading,
    String? error,
    Map<String, dynamic>? orgData,
    Map<String, dynamic>? propertyData,
    Map<String, dynamic>? roomData,
  }) {
    return OnboardingState(
      orgId: orgId ?? this.orgId,
      propertyId: propertyId ?? this.propertyId,
      roomId: roomId ?? this.roomId,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      orgData: orgData ?? this.orgData,
      propertyData: propertyData ?? this.propertyData,
      roomData: roomData ?? this.roomData,
    );
  }
}

class OnboardingNotifier extends StateNotifier<OnboardingState> {
  final OnboardingRepository _repo;
  final Ref _ref;

  OnboardingNotifier(this._repo, this._ref) : super(OnboardingState()) {
    _hydrateFromBackend();
  }

  /// On init, fetch onboarding progress from backend and pre-load existing IDs + data.
  Future<void> _hydrateFromBackend() async {
    try {
      final progress = await _ref.read(onboardingProgressProvider.future);
      String? orgId = progress.organizationId;
      String? propertyId = progress.propertyId;
      String? roomId = progress.roomId;

      Map<String, dynamic>? orgData;
      Map<String, dynamic>? propertyData;
      Map<String, dynamic>? roomData;

      if (orgId != null) {
        orgData = await _repo.fetchOrganization(orgId);
      }
      if (propertyId != null) {
        propertyData = await _repo.fetchProperty(propertyId);
      }
      if (roomId != null) {
        roomData = await _repo.fetchRoom(roomId);
      }

      state = state.copyWith(
        orgId: orgId,
        propertyId: propertyId,
        roomId: roomId,
        orgData: orgData,
        propertyData: propertyData,
        roomData: roomData,
      );
    } catch (_) {
      // Hydration failure is non-fatal — user can still fill forms fresh
    }
  }

  Future<bool> createOrganization(Map<String, dynamic> data) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      String orgId;
      if (state.orgId != null) {
        // Already created — update instead
        await _repo.updateOrganization(state.orgId!, data);
        orgId = state.orgId!;
      } else {
        orgId = await _repo.createOrganization(data);
      }
      await _ref.read(navigationServiceProvider).updateOnboardingStep(
        step: 1,
        organizationId: orgId,
      );
      state = state.copyWith(isLoading: false, orgId: orgId, orgData: data);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> createProperty(Map<String, dynamic> data) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      if (state.orgId == null) throw Exception('Organization not created yet');
      data['organizationId'] = state.orgId;
      String propertyId;
      if (state.propertyId != null) {
        await _repo.updateProperty(state.propertyId!, data);
        propertyId = state.propertyId!;
      } else {
        propertyId = await _repo.createProperty(data);
      }
      await _ref.read(navigationServiceProvider).updateOnboardingStep(
        step: 2,
        organizationId: state.orgId,
        propertyId: propertyId,
      );
      state = state.copyWith(isLoading: false, propertyId: propertyId, propertyData: data);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> createRoom(Map<String, dynamic> data) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      if (state.propertyId == null) throw Exception('Property not created yet');
      data['propertyId'] = state.propertyId;
      String roomId;
      if (state.roomId != null) {
        await _repo.updateRoom(state.roomId!, data);
        roomId = state.roomId!;
      } else {
        roomId = await _repo.createRoom(data);
      }
      await _ref.read(navigationServiceProvider).updateOnboardingStep(
        step: 3,
        organizationId: state.orgId,
        propertyId: state.propertyId,
        roomId: roomId,
      );
      state = state.copyWith(isLoading: false, roomId: roomId, roomData: data);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> createBed(Map<String, dynamic> data) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      if (state.roomId == null) throw Exception('Room not created yet');
      data['roomId'] = state.roomId;
      await _repo.createBed(data);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<void> markOnboardingCompleted() async {
    await _ref.read(navigationServiceProvider).completeOnboarding();
  }
}

final onboardingNotifierProvider =
    StateNotifierProvider<OnboardingNotifier, OnboardingState>((ref) {
  return OnboardingNotifier(ref.read(onboardingRepositoryProvider), ref);
});
