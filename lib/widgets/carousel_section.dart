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

class _CarouselSectionState extends State<CarouselSection>
    with WidgetsBindingObserver {
  static const _interval = Duration(seconds: 3);
  static const _scrollDuration = Duration(milliseconds: 450);

  /// Admin se kiye gaye changes is interval par app me apne aap aa jate hain.
  static const _refreshInterval = Duration(seconds: 10);

  PageController? _controller;
  Timer? _autoTimer;
  Timer? _pollTimer;
  List<CarouselModel> _items = const [];
  bool _loading = true;
  bool _failed = false;
  bool _fetching = false;
  String _signature = '';
  int _currentIndex = 0;

  /// Widget ki height image ke asli ratio se decide hoti hai, isliye image
  /// kabhi cut nahi hoti.
  static const double _fallbackAspectRatio = 2.15;
  double _aspectRatio = _fallbackAspectRatio;
  ImageStream? _ratioStream;
  ImageStreamListener? _ratioListener;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
    _startPolling();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _autoTimer?.cancel();
    _pollTimer?.cancel();
    _stopRatioStream();
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Background me polling band, wapas aate hi turant fresh data + polling.
    if (state == AppLifecycleState.resumed) {
      _load(silent: true);
      _startPolling();
      _startAutoScroll();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _pollTimer?.cancel();
      _autoTimer?.cancel();
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(_refreshInterval, (_) {
      if (mounted) _load(silent: true);
    });
  }

  String _signatureOf(List<CarouselModel> items) => items
      .map((e) => '${e.id}|${e.title}|${e.image}|${e.moreInfoUrl}')
      .join('~');

  Future<void> _load({bool silent = false}) async {
    if (_fetching) return;
    _fetching = true;
    if (!silent) _autoTimer?.cancel();

    if (mounted && !silent && !_loading) {
      setState(() {
        _loading = true;
        _failed = false;
      });
    }

    List<CarouselModel> items;
    var failed = false;
    try {
      items = await ApiService.fetchCarousels();
    } catch (_) {
      items = const [];
      failed = true;
    } finally {
      _fetching = false;
    }
    if (!mounted) return;

    if (failed && _items.isNotEmpty) {
      // Network hiccup: purana carousel hi dikhne do, blank/error mat karo.
      return;
    }

    final visible = items.where((e) => e.image.trim().isNotEmpty).toList();
    final signature = _signatureOf(visible);

    if (signature == _signature) {
      // Data same hai: scroll position aur auto-scroll ko disturb mat karo.
      final showError = failed && visible.isEmpty;
      if (_loading || _failed != showError) {
        setState(() {
          _loading = false;
          _failed = showError;
        });
      }
      // Ratio resolve fail hua tha to polling par dobara try karo.
      if (visible.isNotEmpty && _aspectRatio == _fallbackAspectRatio) {
        _resolveAspectRatio(visible.first.image);
      }
      return;
    }

    _signature = signature;
    final old = _controller;
    final index = visible.isEmpty ? 0 : _currentIndex % visible.length;
    _controller = PageController(
      initialPage: visible.length > 1 ? visible.length * 1000 + index : 0,
    );
    setState(() {
      _items = visible;
      _currentIndex = index;
      _failed = failed && visible.isEmpty;
      _loading = false;
    });
    if (visible.isNotEmpty) _resolveAspectRatio(visible.first.image);
    if (old != null) {
      // PageView naye controller ke saath rebuild hone ke baad purana
      // controller dispose karo.
      WidgetsBinding.instance.addPostFrameCallback((_) => old.dispose());
    }
    _startAutoScroll();
  }

  void _stopRatioStream() {
    final listener = _ratioListener;
    if (listener != null) _ratioStream?.removeListener(listener);
    _ratioListener = null;
    _ratioStream = null;
  }

  /// Image ki asli width/height nikal kar carousel ka aspect ratio set karta
  /// hai, taaki poori image widget ke andar fit ho aur cut na ho.
  void _resolveAspectRatio(String rawImage) {
    final imageUrl = _imageUrl(rawImage);
    if (imageUrl.isEmpty) return;

    _stopRatioStream();
    final stream = NetworkImage(imageUrl).resolve(ImageConfiguration.empty);
    _ratioStream = stream;

    late final ImageStreamListener listener;
    listener = ImageStreamListener(
      (info, _) {
        stream.removeListener(listener);
        if (_ratioStream != stream) return;
        _ratioStream = null;
        _ratioListener = null;
        final width = info.image.width.toDouble();
        final height = info.image.height.toDouble();
        if (!mounted || width <= 0 || height <= 0) return;
        final ratio = (width / height).clamp(0.5, 3.2).toDouble();
        if ((ratio - _aspectRatio).abs() < 0.01) return;
        setState(() => _aspectRatio = ratio);
      },
      onError: (_, __) {
        stream.removeListener(listener);
        if (_ratioStream == stream) {
          _ratioStream = null;
          _ratioListener = null;
        }
      },
    );
    _ratioListener = listener;
    stream.addListener(listener);
  }

  /// Admin may store either a full (ImgBB) URL or a path relative to the API.
  String _imageUrl(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return value;
    final uri = Uri.tryParse(value);
    if (uri != null && uri.hasScheme) return value;
    return '$kApiBaseUrl/${value.replaceFirst(RegExp(r'^/+'), '')}';
  }

  void _startAutoScroll() {
    _autoTimer?.cancel();
    if (_items.length < 2) return;
    _autoTimer = Timer.periodic(_interval, (_) {
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

  void _onPageChanged(int index) {
    if (_items.isEmpty) return;
    _currentIndex = index % _items.length;
  }

  Future<void> _openMoreInfo(String rawUrl) async {
    final uri = Uri.tryParse(rawUrl.trim());
    if (uri == null || !uri.hasScheme) {
      showMsg(context, 'Invalid info link');
      return;
    }
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.platformDefault);
      if (!ok && mounted) showMsg(context, 'Could not open the link');
    } catch (_) {
      if (mounted) showMsg(context, 'Could not open the link');
    }
  }

  Widget _placeholder() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: AspectRatio(
        aspectRatio: _aspectRatio,
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

  Widget _error() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: AspectRatio(
        aspectRatio: _aspectRatio,
        child: DecoratedBox(
          decoration: AppTheme.surfaceCard(radius: 18),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.image_outlined,
                  color: AppColors.mist,
                  size: 26,
                ),
                const SizedBox(height: 6),
                const Text(
                  'Could not load the carousel',
                  style: TextStyle(
                    fontFamily: AppFonts.body,
                    color: AppColors.mist,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextButton(
                  onPressed: _load,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.gold,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Retry',
                    style: TextStyle(
                      fontFamily: AppFonts.body,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _slide(CarouselModel item) {
    final url = item.moreInfoUrl.trim();
    final imageUrl = _imageUrl(item.image);

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: ColoredBox(
        color: AppColors.card,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Image poore widget ko fill karti hai (koi side gap nahi).
            Image.network(
              imageUrl,
              fit: BoxFit.cover,
              alignment: Alignment.center,
              gaplessPlayback: true,
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return const Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.2),
                  ),
                );
              },
              errorBuilder: (_, __, ___) => const Center(
                child: Icon(
                  Icons.image_not_supported_outlined,
                  color: AppColors.mist,
                  size: 32,
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return _placeholder();
    if (_failed) return _error();
    final controller = _controller;
    if (_items.isEmpty || controller == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        alignment: Alignment.topCenter,
        child: AspectRatio(
          aspectRatio: _aspectRatio,
          child: PageView.builder(
            controller: controller,
            itemCount: _items.length == 1 ? 1 : null,
            onPageChanged: _onPageChanged,
            itemBuilder: (context, index) =>
                _slide(_items[index % _items.length]),
          ),
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
