import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    final normalizedQuestion = question.trim();
    if (normalizedQuestion.isEmpty) {
      state = state.copyWith(errorMessage: '질문을 먼저 입력해 주세요.');
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
      state = state.copyWith(
        isLoading: false,
        response: response,
        clearError: true,
        lastQuestion: normalizedQuestion,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: error.toString(),
        lastQuestion: normalizedQuestion,
      );
    }
  }
}

final curationControllerProvider =
    NotifierProvider<CurationController, CurationViewState>(
      CurationController.new,
    );
