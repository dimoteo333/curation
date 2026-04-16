import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/curated_response.dart';
import '../../state/curation_controller.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: '나 요즘 왜 이렇게 무기력하지?');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(curationControllerProvider);
    final controller = ref.read(curationControllerProvider.notifier);
    final theme = Theme.of(context);

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: <Color>[
              Color(0xFFF7F2E9),
              Color(0xFFE6F1EC),
              Color(0xFFF3E8D5),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            children: [
              Text(
                '큐레이터',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF163333),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '기록 속 패턴을 다시 읽어 지금의 질문과 연결합니다.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: const Color(0xFF345454),
                ),
              ),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '오늘의 질문',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        key: const Key('questionTextField'),
                        controller: _controller,
                        minLines: 3,
                        maxLines: 5,
                        decoration: const InputDecoration(
                          hintText: '요즘 떠오르는 고민이나 감정을 적어 주세요.',
                        ),
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        key: const Key('submitQuestionButton'),
                        onPressed: state.isLoading
                            ? null
                            : () => controller.submitQuestion(_controller.text),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF0B5D5E),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: Text(
                          state.isLoading ? '기록을 찾는 중...' : '기록 연결하기',
                        ),
                      ),
                      if (state.errorMessage != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          state.errorMessage!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.error,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              if (state.response != null)
                _ResultSection(
                  response: state.response!,
                  lastQuestion: state.lastQuestion,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultSection extends StatelessWidget {
  const _ResultSection({required this.response, required this.lastQuestion});

  final CuratedResponse response;
  final String lastQuestion;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      key: const Key('responseSection'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '질문',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: const Color(0xFF6A7B7B),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  lastQuestion,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  response.insightTitle,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0B5D5E),
                  ),
                ),
                const SizedBox(height: 10),
                Text(response.summary, style: theme.textTheme.bodyLarge),
                const SizedBox(height: 16),
                Text(
                  response.answer,
                  style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1E5D0),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    response.suggestedFollowUp,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF6A4B17),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          '연결된 기록',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: const Color(0xFF163333),
          ),
        ),
        const SizedBox(height: 12),
        for (final record in response.supportingRecords) ...[
          _SupportingRecordCard(record: record),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _SupportingRecordCard extends StatelessWidget {
  const _SupportingRecordCard({required this.record});

  final SupportingRecord record;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5F0EE),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    record.source,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: const Color(0xFF0B5D5E),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  _formatDate(record.createdAt),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF6A7B7B),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              record.title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(record.excerpt, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 10),
            Text(
              record.relevanceReason,
              style: theme.textTheme.bodySmall?.copyWith(
                color: const Color(0xFF5B4A25),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatDate(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }
}
