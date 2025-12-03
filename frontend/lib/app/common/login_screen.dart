import 'package:flutter/material.dart';
import '../../ui/app_ui.dart';

/// 로그인 화면
///
/// 3개의 슬라이드 페이지와 소셜 로그인 버튼을 포함합니다.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    return AppFrame(
      topBar: TopBar(
        title: '',
        leftIcon: Icons.arrow_back,
        onTapLeft: () => Navigator.pop(context),
      ),
      body: Column(
        children: [
          // 상단 슬라이드 영역
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              children: const [
                _Slide1(),
                _Slide2(),
                _Slide3(),
              ],
            ),
          ),
          
          // 페이지 인디케이터
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (index) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: _currentPage == index ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: _currentPage == index
                      ? AppColors.natureGreen
                      : AppColors.borderLightGray,
                ),
              );
            }),
          ),
          
          const SizedBox(height: 40),

          // 소셜 로그인 버튼 (고정)
          const _SocialLoginButtons(),
          
          const SizedBox(height: 80), // 하단 여백
        ],
      ),
    );
  }
}

/// 첫 번째 슬라이드 (기본 캐릭터)
class _Slide1 extends StatelessWidget {
  const _Slide1();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 248,
            height: 248,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              image: const DecorationImage(
                image: AssetImage('assets/characters/normal/char_relief.png'),
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            '마음봄 시작하기',
            style: AppTypography.h2,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// 두 번째 슬라이드 (다양한 요소)
class _Slide2 extends StatelessWidget {
  const _Slide2();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 248,
            height: 248,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              image: const DecorationImage(
                image: AssetImage('assets/characters/normal/char_excitement.png'),
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            '매일의 감정을 기록해보세요',
            style: AppTypography.h2,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// 세 번째 슬라이드 (이미지)
class _Slide3 extends StatelessWidget {
  const _Slide3();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 256,
            height: 256,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              image: const DecorationImage(
                image: AssetImage('assets/characters/normal/char_interest.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            '마음봄과 함께 시작해보세요',
            style: AppTypography.h2,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// 소셜 로그인 버튼 그룹
class _SocialLoginButtons extends StatelessWidget {
  const _SocialLoginButtons();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 카카오
        _SocialButton(
          color: const Color(0xFFFEE500),
          text: 'K',
          textColor: const Color(0xFF3C1E1E),
          onTap: () {
            print('Kakao Login Tapped');
          },
        ),
        const SizedBox(width: 40),
        // 네이버
        _SocialButton(
          color: const Color(0xFF03C75A),
          text: 'N',
          textColor: Colors.white,
          onTap: () {
            print('Naver Login Tapped');
          },
        ),
        const SizedBox(width: 40),
        // 구글
        _SocialButton(
          color: Colors.white,
          text: 'G',
          textColor: const Color(0xFF5F6368),
          hasBorder: true,
          onTap: () {
            print('Google Login Tapped');
          },
        ),
      ],
    );
  }
}

/// 소셜 로그인 원형 버튼
class _SocialButton extends StatelessWidget {
  final Color color;
  final String text;
  final Color textColor;
  final VoidCallback onTap;
  final bool hasBorder;

  const _SocialButton({
    required this.color,
    required this.text,
    required this.textColor,
    required this.onTap,
    this.hasBorder = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: hasBorder
              ? Border.all(color: AppColors.borderLight, width: 1)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Text(
            text,
            style: AppTypography.h2.copyWith(
              color: textColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
