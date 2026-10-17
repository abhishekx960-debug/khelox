import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'auth_widgets.dart';

/// Home carousel fed by the admin "Manage Carousels" page.
///
/// Shows exactly one slide at a time and auto scrolls every 3 seconds.
class CarouselSection extends StatefulWidget {
  const CarouselSection({super.key});

  @override
  State<CarouselSection> createState() => _CarouselSectionState();
}

class _CarouselSectionState extends State<CarouselSection> {
  static const _interval = Duration(seconds: 3);
  static const _scrollDuration = Duration(milliseconds: 450);

  PageController? _controller;
  Timer? _timer;
  List<CarouselModel> _items = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    List<CarouselModel> items;
    try {
      items = await ApiService.fetchCarousels();
    } catch (_) {
      items = const [];
    }
    if (!mounted) return;
    setState(() {
      _items = items.where((e) => e.image.trim().isNotEmpty).toList();
      _loading = false;
      _controller = PageController(initialPage: _items.length * 1000);
    });
    _startAutoScroll();
  }

  void _startAutoScroll() {
    _timer?.cancel();
    if (_items.length < 2) return;
    _timer = Timer.periodic(_interval, (_) {
      final controller = _controller;
      if (controller == null || !controller.hasClients) return;
      final next = (controller.page ?? 0).round() + 1;
      controller.animateToPage(
        next,
        duration: _scrollDuration,
        curve: Curves.easeInOutCubic,
      );
    });
  }

  Future<void> _openMoreInfo(String rawUrl) async {
    final uri = Uri.tryParse(rawUrl.trim());
    if (uri == null || !uri.hasScheme) {
      showMsg(context, 'Invalid info link');
      return;
    }
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.platformDefault);
      if (!ok && mounted) showMsg(context, 'Link open nahi hua');
    } catch (_) {
      if (mounted) showMsg(context, 'Link open nahi hua');
    }
  }

  Widget _placeholder() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: AspectRatio(
        aspectRatio: 2.15,
        child: DecoratedBox(
          decoration: AppTheme.surfaceCard(radius: 18),
          child: const Center(
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.2),
            ),
          ),
        ),
      ),
    );
  }

  Widget _slide(CarouselModel item) {
    final url = item.moreInfoUrl.trim();
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            item.image,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return const ColoredBox(
                color: AppColors.card,
                child: Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.2),
                  ),
                ),
              );
            },
            errorBuilder: (_, __, ___) => const ColoredBox(
              color: AppColors.card,
              child: Center(
                child: Icon(
                  Icons.image_not_supported_outlined,
                  color: AppColors.mist,
                  size: 32,
                ),
              ),
            ),
          ),
          if (url.isNotEmpty)
            Positioned(
              right: 12,
              bottom: 12,
              child: _MoreInfoButton(
                title: item.title,
                onTap: () => _openMoreInfo(url),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return _placeholder();
    final controller = _controller;
    if (_items.isEmpty || controller == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: AspectRatio(
        aspectRatio: 2.15,
        child: PageView.builder(
          controller: controller,
          itemCount: _items.length == 1 ? 1 : null,
          itemBuilder: (context, index) =>
              _slide(_items[index % _items.length]),
        ),
      ),
    );
  }
}

class _MoreInfoButton extends StatelessWidget {
  final String title;
  final VoidCallback onTap;

  const _MoreInfoButton({required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: title.isEmpty ? 'More info' : '$title - More info',
      child: Material(
        color: AppColors.gold,
        borderRadius: BorderRadius.circular(30),
        elevation: 0,
        child: InkWell(
          borderRadius: BorderRadius.circular(30),
          onTap: onTap,
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.info_outline_rounded,
                    size: 16, color: AppColors.navy),
                SizedBox(width: 6),
                Text(
                  'More info',
                  style: TextStyle(
                    fontFamily: AppFonts.body,
                    color: AppColors.navy,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
