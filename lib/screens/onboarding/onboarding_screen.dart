import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/auth_provider.dart';
import '../main_scaffold.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  final _apiKeyController = TextEditingController();
  int _page = 0;
  bool _keyVisible = false;
  bool _loading = false;

  @override
  void dispose() {
    _pageController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  void _next() {
    if (_page < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _finish({bool withKey = true}) async {
    setState(() => _loading = true);
    final auth = context.read<AuthProvider>();
    final key = withKey ? _apiKeyController.text.trim() : null;
    await auth.completeOnboarding(apiKey: key?.isEmpty == true ? null : key);
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainScaffold()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  theme.colorScheme.primary.withValues(alpha: 0.12),
                  theme.colorScheme.surface,
                ],
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Progress dots
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                  child: Row(
                    children: List.generate(3, (i) => Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        height: 3,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(2),
                          color: i <= _page
                              ? theme.colorScheme.primary
                              : theme.colorScheme.outlineVariant,
                        ),
                      ),
                    )),
                  ),
                ),

                // Pages
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    onPageChanged: (i) => setState(() => _page = i),
                    children: [
                      _WelcomePage(onNext: _next),
                      _FeaturesPage(onNext: _next),
                      _ApiKeyPage(
                        controller: _apiKeyController,
                        visible: _keyVisible,
                        onToggleVisible: () =>
                            setState(() => _keyVisible = !_keyVisible),
                        onFinish: _finish,
                        loading: _loading,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Page 1: Welcome ────────────────────────────────────────────────────────

class _WelcomePage extends StatelessWidget {
  final VoidCallback onNext;
  const _WelcomePage({required this.onNext});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Logo
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.tertiary,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withValues(alpha: 0.3),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.speed_rounded,
              size: 52,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 40),
          Text(
            'Welcome to Pace',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Your speedrun companion.\nBrowse leaderboards, follow runners and track world records — all powered by speedrun.com.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 56),
          FilledButton(
            onPressed: onNext,
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('Get Started',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

// ── Page 2: Features ──────────────────────────────────────────────────────

class _FeaturesPage extends StatelessWidget {
  final VoidCallback onNext;
  const _FeaturesPage({required this.onNext});

  static const _features = [
    (
      icon: Icons.leaderboard_rounded,
      title: 'Leaderboards',
      desc: 'Full category leaderboards with subcategory filters and WR history charts.',
    ),
    (
      icon: Icons.search_rounded,
      title: 'Search',
      desc: 'Find any game or runner instantly with smart relevance sorting.',
    ),
    (
      icon: Icons.favorite_rounded,
      title: 'Favorites',
      desc: 'Save your favorite games for quick access from the home screen.',
    ),
    (
      icon: Icons.live_tv_rounded,
      title: 'Live Indicator',
      desc: 'See who is currently streaming a speedrun live on Twitch.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Everything you need',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 32),
          ..._features.map((f) => Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(f.icon,
                          color: theme.colorScheme.onPrimaryContainer,
                          size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(f.title,
                              style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold)),
                          Text(f.desc,
                              style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant)),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: onNext,
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('Next',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

// ── Page 3: API Key ───────────────────────────────────────────────────────

class _ApiKeyPage extends StatelessWidget {
  final TextEditingController controller;
  final bool visible;
  final VoidCallback onToggleVisible;
  final Future<void> Function({bool withKey}) onFinish;
  final bool loading;

  const _ApiKeyPage({
    required this.controller,
    required this.visible,
    required this.onToggleVisible,
    required this.onFinish,
    required this.loading,
  });

  Future<void> _openApiPage() async {
    final uri = Uri.parse('https://www.speedrun.com/settings/api');
    if (await canLaunchUrl(uri)) {
      launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _paste(BuildContext context) async {
    final data = await Clipboard.getData('text/plain');
    if (data?.text != null) {
      controller.text = data!.text!.trim();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          // Icon + title
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.key_rounded,
                    color: theme.colorScheme.onSecondaryContainer),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Connect your account',
                      style: theme.textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  Text('Optional — you can skip this',
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 28),

          // Info card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline_rounded,
                        size: 16, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Text('With your API key you get:',
                        style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 10),
                ...[
                  'Your profile auto-loads on the Profile tab',
                  'Access to your personal runs & stats',
                  'Moderator actions (verify/reject runs)',
                  'Submit & manage your own runs',
                ].map((t) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle_rounded,
                              size: 14, color: theme.colorScheme.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(t,
                                style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme
                                        .onPrimaryContainer)),
                          ),
                        ],
                      ),
                    )),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Warning card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.errorContainer.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber_rounded,
                    size: 16, color: theme.colorScheme.error),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Never share your API key. It gives full access to your speedrun.com account.',
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onErrorContainer),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // API key field
          TextField(
            controller: controller,
            obscureText: !visible,
            decoration: InputDecoration(
              labelText: 'API Key',
              hintText: 'Paste your speedrun.com API key',
              prefixIcon: const Icon(Icons.vpn_key_rounded),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(visible
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded),
                    onPressed: onToggleVisible,
                    tooltip: visible ? 'Hide' : 'Show',
                  ),
                  IconButton(
                    icon: const Icon(Icons.content_paste_rounded),
                    onPressed: () => _paste(context),
                    tooltip: 'Paste',
                  ),
                ],
              ),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              filled: true,
            ),
          ),
          const SizedBox(height: 12),

          // Get API key link
          InkWell(
            onTap: _openApiPage,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.open_in_browser_rounded,
                      size: 16, color: theme.colorScheme.primary),
                  const SizedBox(width: 6),
                  Text(
                    'Get your API key at speedrun.com/settings/api',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                      decoration: TextDecoration.underline,
                      decorationColor: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Continue with key
          FilledButton(
            onPressed: loading ? null : () => onFinish(withKey: true),
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            child: loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Connect & Continue',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 12),

          // Skip
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              onPressed: loading ? null : () => onFinish(withKey: false),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Skip — use without account'),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
