import 'package:characters/characters.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'emotion_report_chat_model.dart';
import 'emotion_report_chat_repository.dart';

final weeklyEmotionReportChatProvider =
    FutureProvider<EmotionReportChat>((ref) async {
  final repo = ref.watch(emotionReportChatRepositoryProvider);
  return repo.fetchWeeklyChat();
});

class EmotionReportChatPage extends ConsumerWidget {
  const EmotionReportChatPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncChat = ref.watch(weeklyEmotionReportChatProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('이번 주 감정 리포트'),
      ),
      body: asyncChat.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(
          child: Text('리포트를 불러오지 못했어요.\n$e'),
        ),
        data: (chat) {
          final avatar = _buildCharacterAvatar(chat.character);
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    avatar,
                    const SizedBox(height: 12),
                    Text(
                      chat.headline,
                      style: Theme.of(context).textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: chat.bubbles.length,
                  itemBuilder: (context, index) {
                    final bubble = chat.bubbles[index];
                    final isCharacter =
                        bubble.role == BubbleRole.character;

                    return Align(
                      alignment: isCharacter
                          ? Alignment.centerLeft
                          : Alignment.centerRight,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 12,
                        ),
                        decoration: BoxDecoration(
                          color: isCharacter
                              ? Colors.white
                              : Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Text(
                          bubble.text,
                          style: TextStyle(
                            color: isCharacter
                                ? Colors.black
                                : Colors.white,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCharacterAvatar(EmotionReportCharacterMeta character) {
    final assetPath = _characterAssetsByKey[character.key] ??
        _characterAssetsByMood[character.mood];

    if (assetPath != null) {
      return CircleAvatar(
        radius: 36,
        backgroundColor: Colors.white,
        child: ClipOval(
          child: Image.asset(
            assetPath,
            width: 64,
            height: 64,
            errorBuilder: (context, error, stackTrace) {
              return _fallbackAvatar(character.displayName);
            },
          ),
        ),
      );
    }

    return _fallbackAvatar(character.displayName);
  }

  Widget _fallbackAvatar(String name) {
    final initial = name.isNotEmpty ? name.characters.first : '?';
    return CircleAvatar(
      radius: 36,
      backgroundColor: Colors.blueGrey.shade100,
      child: Text(
        initial,
        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
      ),
    );
  }
}

const Map<String, String> _characterAssetsByKey = {
  'worried_fox': 'assets/characters/worried_fox.png',
};

const Map<String, String> _characterAssetsByMood = {
  'worry': 'assets/characters/worry.png',
};
