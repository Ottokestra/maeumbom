import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import '../../ui/app_ui.dart';
import '../../core/services/navigation/navigation_service.dart';
import '../../core/services/chat/bom_chat_service.dart';

class AlarmScreen extends ConsumerWidget {
  const AlarmScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navigationService = NavigationService(context, ref);

    return AppFrame(
      topBar: TopBar(
        title: '알람',
      ),
      bottomBar: BottomMenuBar(
        currentIndex: 1,
        onTap: (index) {
          navigationService.navigateToTab(index);
        },
      ),
      body: const AlarmContent(),
    );
  }
}

class AlarmContent extends StatefulWidget {
  const AlarmContent({super.key});

  @override
  State<AlarmContent> createState() => _AlarmContentState();
}

class _AlarmContentState extends State<AlarmContent> {
  final TextEditingController _textController = TextEditingController();
  Map<String, dynamic>? _responseData;
  bool _isLoading = false;
  String? _error;

  // WebSocket을 통한 텍스트 전송 (기존 음성 채팅 서비스 활용)
  Future<void> _sendViaWebSocket() async {
    if (_textController.text.isEmpty) {
      setState(() => _error = '텍스트를 입력하세요');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _responseData = null;
    });

    try {
      final service = BomChatService();

      // 응답 수신 리스너
      service.onResponse = (response) {
        debugPrint('[AlarmTest] 응답 수신: $response');
        setState(() {
          _responseData = response;
          _isLoading = false;
        });
        service.stopVoiceChat();
      };

      service.onError = (error) {
        setState(() {
          _error = error;
          _isLoading = false;
        });
        service.stopVoiceChat();
      };

      // WebSocket 연결 및 텍스트 전송
      // Note: 현재 구조는 음성 전용이므로 텍스트 API는 별도 구현 필요
      setState(() {
        _error = 'WebSocket은 음성 전용입니다. REST API 구현이 필요합니다.';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = '전송 실패: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            '알람 API 테스트',
            style: AppTypography.h2,
          ),
          const SizedBox(height: AppSpacing.md),

          // 입력 필드
          TextField(
            controller: _textController,
            decoration: const InputDecoration(
              labelText: '텍스트 입력',
              hintText: '예: 내일 오후 2시에 알람',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: AppSpacing.sm),

          // 전송 버튼
          ElevatedButton(
            onPressed: _isLoading ? null : _sendViaWebSocket,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('전송', style: TextStyle(fontSize: 16)),
          ),
          const SizedBox(height: AppSpacing.lg),

          // 에러 표시
          if (_error != null)
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                border: Border.all(color: Colors.red),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            ),

          // 응답 표시
          if (_responseData != null) ...[
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'JSON 응답:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatJson(_responseData!),
                    style: const TextStyle(fontFamily: 'monospace'),
                  ),
                  const SizedBox(height: 12),
                  _buildResponseChip(),
                  if (_responseData!['alarm_info'] != null) ...[
                    const SizedBox(height: 12),
                    _buildAlarmInfo(),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatJson(Map<String, dynamic> json) {
    try {
      return const JsonEncoder.withIndent('  ').convert(json);
    } catch (e) {
      return json.toString();
    }
  }

  Widget _buildResponseChip() {
    final type = _responseData!['response_type'] ?? 'unknown';
    Color color;
    IconData icon;

    switch (type) {
      case 'alarm':
        color = Colors.green;
        icon = Icons.alarm;
        break;
      case 'warning':
        color = Colors.orange;
        icon = Icons.warning;
        break;
      default:
        color = Colors.grey;
        icon = Icons.chat;
    }

    return Chip(
      avatar: Icon(icon, color: Colors.white, size: 16),
      label: Text('Type: $type', style: const TextStyle(color: Colors.white)),
      backgroundColor: color,
    );
  }

  Widget _buildAlarmInfo() {
    final alarmInfo = _responseData!['alarm_info'] as Map<String, dynamic>;
    final count = alarmInfo['count'] ?? 0;
    final message = alarmInfo['message'] as String?;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        border: Border.all(color: Colors.blue.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '알람 정보 ($count개)',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          if (message != null)
            Text(message, style: const TextStyle(color: Colors.orange)),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }
}
