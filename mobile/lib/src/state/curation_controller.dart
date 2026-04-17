import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/security/input_sanitizer.dart';
import '../domain/entities/curated_response.dart';
import '../providers.dart';

class CurationViewState {
  const CurationViewState({
    this.isLoading = false,
    this.response,
    this.errorMessage,
    this.lastQuestion = '',
  });

  final bool isLoading;
  final CuratedResponse? response;
  final String? errorMessage;
  final String lastQuestion;

  CurationViewState copyWith({
    bool? isLoading,
    CuratedResponse? response,
    String? errorMessage,
    bool clearError = false,
    String? lastQuestion,
  }) {
    return CurationViewState(
      isLoading: isLoading ?? this.isLoading,
      response: response ?? this.response,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      lastQuestion: lastQuestion ?? this.lastQuestion,
    );
  }
}

class CurationController extends Notifier<CurationViewState> {
  @override
  CurationViewState build() {
    return const CurationViewState();
  }

  Future<void> submitQuestion(String question) async {
    late final String normalizedQuestion;
    try {
      normalizedQuestion = InputSanitizer.sanitizeQuestion(question);
    } on InputValidationException catch (error) {
      state = state.copyWith(errorMessage: error.message);
      return;
    } catch (error) {
      state = state.copyWith(errorMessage: error.toString());
      return;
    }

    state = state.copyWith(
      isLoading: true,
      clearError: true,
      lastQuestion: normalizedQuestion,
    );

    try {
      final useCase = ref.read(requestCurationUseCaseProvider);
      final response = await useCase(normalizedQuestion);
      ref.invalidate(onDeviceRuntimeStatusProvider);
      state = state.copyWith(
        isLoading: false,
        response: response,
        clearError: true,
        lastQuestion: normalizedQuestion,
      );
    } catch (error) {
      ref.invalidate(onDeviceRuntimeStatusProvider);
      state = state.copyWith(
        isLoading: false,
        errorMessage: error.toString(),
        lastQuestion: normalizedQuestion,
      );
    }
  }

  void startNewQuestion() {
    state = const CurationViewState();
  }
}

final curationControllerProvider =
    NotifierProvider<CurationController, CurationViewState>(
      CurationController.new,
    );
