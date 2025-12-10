import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// 알람 API 테스트 화면
/// 텍스트 입력 후 백엔드 응답의 JSON 데이터를 확인할 수 있음
class AlarmTestScreen extends StatefulWidget {
  const AlarmTestScreen({super.key});

  @override
  State<AlarmTestScreen> createState() => _AlarmTestScreenState();
}

class _AlarmTestScreenState extends State<AlarmTestScreen> {
  final TextEditingController _textController = TextEditingController();
  Map<String, dynamic>? _responseData;
  bool _isLoading = false;
  String? _error;

  // 백엔드 API 호출
  Future<void> _sendRequest() async {
    if (_textController.text.isEmpty) {
      setState(() {
        _error = '텍스트를 입력하세요';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _responseData = null;
    });

    try {
      final response = await http.post(
        Uri.parse('http://localhost:8000/api/agent/v2/text'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_text': _textController.text,
          'user_id': 1,
          'session_id': 'test_${DateTime.now().millisecondsSinceEpoch}',
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          _responseData = jsonDecode(response.body);
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Error: ${response.statusCode} - ${response.body}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = '요청 실패: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('알람 API 테스트'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
            const SizedBox(height: 16),

            // 전송 버튼
            ElevatedButton(
              onPressed: _isLoading ? null : _sendRequest,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      '전송',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
            ),
            const SizedBox(height: 24),

            // 응답 표시
            if (_error != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  border: Border.all(color: Colors.red),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),

            if (_responseData != null)
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'JSON 응답:',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SelectableText(
                          const JsonEncoder.withIndent('  ')
                              .convert(_responseData),
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildResponseTypeChip(),
                        const SizedBox(height: 16),
                        if (_responseData!['alarm_info'] != null)
                          _buildAlarmInfo(),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildResponseTypeChip() {
    final responseType = _responseData!['response_type'] ?? 'unknown';
    Color color;
    IconData icon;

    switch (responseType) {
      case 'alarm':
        color = Colors.green;
        icon = Icons.alarm;
        break;
      case 'warning':
        color = Colors.orange;
        icon = Icons.warning;
        break;
      case 'list':
        color = Colors.blue;
        icon = Icons.list;
        break;
      default:
        color = Colors.grey;
        icon = Icons.chat;
    }

    return Chip(
      avatar: Icon(icon, color: Colors.white, size: 18),
      label: Text(
        'Response Type: $responseType',
        style: const TextStyle(color: Colors.white),
      ),
      backgroundColor: color,
    );
  }

  Widget _buildAlarmInfo() {
    final alarmInfo = _responseData!['alarm_info'] as Map<String, dynamic>;
    final count = alarmInfo['count'] ?? 0;
    final data = alarmInfo['data'] as List<dynamic>? ?? [];
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
          Row(
            children: [
              const Icon(Icons.alarm, color: Colors.blue),
              const SizedBox(width: 8),
              Text(
                '알람 정보 (${count}개)',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          if (message != null) ...[
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(
                color: Colors.orange,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          if (data.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...data.asMap().entries.map((entry) {
              final idx = entry.key;
              final alarm = entry.value as Map<String, dynamic>;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildAlarmCard(idx + 1, alarm),
              );
            }).toList(),
          ],
        ],
      ),
    );
  }

  Widget _buildAlarmCard(int index, Map<String, dynamic> alarm) {
    final isValid = alarm['is_valid_alarm'] ?? false;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: isValid ? Colors.green.shade200 : Colors.red.shade200,
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '알람 #$index',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            '날짜: ${alarm['year']}년 ${alarm['month']}월 ${alarm['day']}일',
          ),
          if (alarm['week'] != null)
            Text('요일: ${(alarm['week'] as List).join(', ')}'),
          if (isValid && alarm['time'] != null)
            Text(
              '시간: ${alarm['am_pm'] == 'pm' ? '오후' : '오전'} ${alarm['time']}시 ${alarm['minute']}분',
            ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                isValid ? Icons.check_circle : Icons.cancel,
                size: 16,
                color: isValid ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 4),
              Text(
                isValid ? '유효한 알람' : '과거 날짜 (무효)',
                style: TextStyle(
                  color: isValid ? Colors.green : Colors.red,
                  fontSize: 12,
                ),
              ),
            ],
          ),
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
