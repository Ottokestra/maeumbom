import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../ui/app_ui.dart';
import '../../ui/layout/app_frame.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  Future<String> _loadTerms() {
    return rootBundle.loadString('assets/legal/terms_of_service.txt');
  }

  @override
  Widget build(BuildContext context) {
    return AppFrame(
      topBar: TopBar(
        title: '서비스 이용약관',
        leftIcon: Icons.arrow_back,
        onTapLeft: () => Navigator.of(context).pop(),
      ),
      body: FutureBuilder<String>(
        future: _loadTerms(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Text(
              snapshot.data!,
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
