import 'package:flutter/material.dart';
import 'sign_up1.dart';
import 'sign_up2.dart';
import 'sign_up3.dart';
import 'sign_up4.dart';
import 'sign_up5.dart';

/// 회원가입 슬라이드 화면
///
/// sign_up1 ~ sign_up5 화면을 슬라이드 형식으로 보여줍니다.
class SignUpSlideScreen extends StatefulWidget {
  const SignUpSlideScreen({super.key});

  @override
  State<SignUpSlideScreen> createState() => _SignUpSlideScreenState();
}

class _SignUpSlideScreenState extends State<SignUpSlideScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // 각 페이지별로 완료 여부를 추적
  final List<bool> _pageCompleted = [false, false, false, false, false];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // 다음 페이지로 이동
  void _goToNextPage() {
    if (_currentPage < 4) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // 마지막 페이지에서는 완료 처리 (sign_up5에서 API 호출)
      // Navigator.pushReplacementNamed(context, '/');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // 상단 진행 바
            _buildProgressBar(),

            // 페이지 뷰
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(), // 스와이프 비활성화 (버튼으로만 이동)
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                children: [
                  _SignUpPage1Wrapper(onNext: _goToNextPage),
                  _SignUpPage2Wrapper(onNext: _goToNextPage),
                  _SignUpPage3Wrapper(onNext: _goToNextPage),
                  _SignUpPage4Wrapper(onNext: _goToNextPage),
                  _SignUpPage5Wrapper(onNext: _goToNextPage),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 상단 진행률 표시 바
  Widget _buildProgressBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: [
          Row(
            children: [
              // 뒤로가기 버튼
              if (_currentPage > 0)
                GestureDetector(
                  onTap: () {
                    _pageController.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  child: const Icon(Icons.arrow_back, size: 24),
                )
              else
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close, size: 24),
                ),
              const SizedBox(width: 16),

              // 진행률 바
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (_currentPage + 1) / 5,
                    backgroundColor: const Color(0xFFF0EAE8),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFFC03846),
                    ),
                    minHeight: 8,
                  ),
                ),
              ),

              const SizedBox(width: 16),

              // 페이지 번호
              Text(
                '${_currentPage + 1}/5',
                style: const TextStyle(
                  fontSize: 14,
                  fontFamily: 'Pretendard',
                  color: Color(0xFF6B6B6B),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// SignUp1 래퍼
class _SignUpPage1Wrapper extends StatelessWidget {
  final VoidCallback onNext;

  const _SignUpPage1Wrapper({required this.onNext});

  @override
  Widget build(BuildContext context) {
    return SignUp1Screen(onNext: onNext);
  }
}

// SignUp2 래퍼
class _SignUpPage2Wrapper extends StatelessWidget {
  final VoidCallback onNext;

  const _SignUpPage2Wrapper({required this.onNext});

  @override
  Widget build(BuildContext context) {
    return SignUp2Screen(onNext: onNext);
  }
}

// SignUp3 래퍼
class _SignUpPage3Wrapper extends StatelessWidget {
  final VoidCallback onNext;

  const _SignUpPage3Wrapper({required this.onNext});

  @override
  Widget build(BuildContext context) {
    return SignUp3Screen(onNext: onNext);
  }
}

// SignUp4 래퍼
class _SignUpPage4Wrapper extends StatelessWidget {
  final VoidCallback onNext;

  const _SignUpPage4Wrapper({required this.onNext});

  @override
  Widget build(BuildContext context) {
    return SignUp4Screen(onNext: onNext);
  }
}

// SignUp5 래퍼
class _SignUpPage5Wrapper extends StatelessWidget {
  final VoidCallback onNext;

  const _SignUpPage5Wrapper({required this.onNext});

  @override
  Widget build(BuildContext context) {
    return SignUp5Screen(onNext: onNext);
  }
}
