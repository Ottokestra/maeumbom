import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../ui/app_ui.dart';
import '../../core/services/navigation/navigation_service.dart';
import '../../data/api/chat/chat_api_client.dart';
import '../../data/dtos/chat/sessions_response.dart';
import '../../providers/auth_provider.dart';
import '../../core/utils/logger.dart';
import '../../core/config/app_routes.dart';
import 'chat_screen.dart';

class ChatListScreen extends ConsumerStatefulWidget {
  const ChatListScreen({super.key});

  @override
  ConsumerState<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends ConsumerState<ChatListScreen> {
  SessionsResponse? _sessions;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final dio = ref.read(dioWithAuthProvider);
      final apiClient = ChatApiClient(dio);
      final sessions = await apiClient.getSessions();

      if (!mounted) return;
      setState(() {
        _sessions = sessions;
        _isLoading = false;
      });
    } catch (e) {
      appLogger.e('Failed to load sessions', error: e);
      if (!mounted) return;
      setState(() {
        _errorMessage = '대화 히스토리 조회 실패: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppFrame(
      topBar: TopBar(
        title: '대화 히스토리',
        leftIcon: Icons.arrow_back,
        onTapLeft: () => Navigator.pop(context),
      ),
      bottomBar: BottomMenuBar(
        currentIndex: 1,
        onTap: (index) {
           final route = AppRoutes.findByTabIndex(index);
            if (route != null) {
              Navigator.pushReplacementNamed(context, route.routeName);
            }
        },
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_errorMessage!, style: AppTypography.body),
            const SizedBox(height: AppSpacing.md),
            AppButton(
              text: '재시도',
              onTap: _loadSessions,
              variant: ButtonVariant.secondaryRed,
            ),
          ],
        ),
      );
    }

    if (_sessions == null || _sessions!.sessions.isEmpty) {
      return Center(
        child: Text(
          '대화 히스토리가 없습니다.',
          style: AppTypography.body.copyWith(color: AppColors.textSecondary),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: _sessions!.sessions.length,
      itemBuilder: (context, index) {
        final session = _sessions!.sessions[index];
        return _buildSessionItem(session);
      },
    );
  }

  Widget _buildSessionItem(SessionItem session) {
    final dateStr = '${session.createdAt.year}-${session.createdAt.month.toString().padLeft(2, '0')}-${session.createdAt.day.toString().padLeft(2, '0')}';
    final timeStr = '${session.createdAt.hour.toString().padLeft(2, '0')}:${session.createdAt.minute.toString().padLeft(2, '0')}';

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(sessionId: session.sessionId),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.pureWhite,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    session.sessionId,
                    style: AppTypography.bodyBold,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '$dateStr $timeStr',
                    style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                Text(
                  '${session.messageCount}개',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(width: AppSpacing.xs),
                Icon(
                  Icons.chevron_right,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
