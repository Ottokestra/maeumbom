import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../ui/app_ui.dart';
import '../../ui/layout/app_frame.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  Future<String> _loadPolicy() {
    return rootBundle.loadString('assets/legal/privacy_policy.txt');
  }

  @override
  Widget build(BuildContext context) {
    return AppFrame(
      topBar: TopBar(
        title: '개인정보처리방침',
        leftIcon: Icons.arrow_back,
        onTapLeft: () => Navigator.of(context).pop(),
      ),
      body: FutureBuilder<String>(
        future: _loadPolicy(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Text('내용을 불러올 수 없습니다.\n${snapshot.error}'),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Text(
              snapshot.data ?? '',
              style: const TextStyle(
                color: Color(0xFF6B6B6B),
                fontSize: 18,
                fontFamily: 'Inter',
                height: 1.5,
              ),
            ),
          );
        },
      ),
    );
  }
}
