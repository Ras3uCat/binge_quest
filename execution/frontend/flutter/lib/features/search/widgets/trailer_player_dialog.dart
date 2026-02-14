import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import '../../../shared/models/tmdb_video.dart';
import '../../../core/constants/e_colors.dart';
import '../../../core/constants/e_sizes.dart';

class TrailerPlayerDialog extends StatefulWidget {
  final TmdbVideo video;

  const TrailerPlayerDialog({
    super.key,
    required this.video,
  });

  static Future<void> show(BuildContext context, TmdbVideo video) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => TrailerPlayerDialog(video: video),
    );
  }

  @override
  State<TrailerPlayerDialog> createState() => _TrailerPlayerDialogState();
}

class _TrailerPlayerDialogState extends State<TrailerPlayerDialog> {
  late YoutubePlayerController _controller;
  bool _isFullScreen = false;
  bool _hasError = false;
  bool _hasPlayed = false;
  Timer? _fallbackTimer;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController(
      initialVideoId: widget.video.key,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        enableCaption: false,
        hideControls: false,
        controlsVisibleAtStart: true,
      ),
    );

    _controller.addListener(_onControllerUpdate);

    // If video hasn't played within 5 seconds, pop this dialog and show
    // an error dialog instead. We avoid setState entirely because the broken
    // WebView (youtube-nocookie.com cross-origin bug) crashes on rebuild.
    _fallbackTimer = Timer(const Duration(seconds: 5), () {
      if (!_hasPlayed && !_hasError && mounted) {
        _triggerFallback();
      }
    });
  }

  void _onControllerUpdate() {
    // Once error state is triggered, never call setState — the WebView
    // is broken and any rebuild of YoutubePlayerBuilder will crash.
    if (_hasError) return;

    if (_controller.value.isFullScreen != _isFullScreen) {
      setState(() {
        _isFullScreen = _controller.value.isFullScreen;
      });
    }
    if (_controller.value.playerState == PlayerState.playing && !_hasPlayed) {
      _hasPlayed = true;
      _fallbackTimer?.cancel();
    }
    if (_controller.value.hasError) {
      _fallbackTimer?.cancel();
      _triggerFallback();
    }
  }

  /// Pop the broken player dialog and show a clean error dialog.
  /// No setState is called, so the broken YoutubePlayerBuilder is never
  /// rebuilt — it's simply unmounted when the route pops.
  void _triggerFallback() {
    if (_hasError) return;
    _hasError = true;
    _fallbackTimer?.cancel();
    final video = widget.video;
    Navigator.of(context).pop();
    Get.dialog(
      _TrailerErrorDialog(video: video),
      barrierDismissible: true,
    );
  }

  @override
  void dispose() {
    _fallbackTimer?.cancel();
    _controller.removeListener(_onControllerUpdate);
    _controller.dispose();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  Future<void> _openInBrowser() async {
    final url = Uri.parse(widget.video.youtubeUrl);
    Navigator.of(context).pop();
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      Get.snackbar(
        'Error',
        'Could not open YouTube',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: EColors.error,
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return YoutubePlayerBuilder(
      onExitFullScreen: () {
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
      },
      player: YoutubePlayer(
        controller: _controller,
        showVideoProgressIndicator: true,
        progressIndicatorColor: EColors.primary,
        progressColors: const ProgressBarColors(
          playedColor: EColors.primary,
          handleColor: EColors.primary,
        ),
        topActions: [
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.video.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.open_in_new, color: Colors.white),
            tooltip: 'Open in YouTube',
            onPressed: _openInBrowser,
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      builder: (context, player) {
        if (_isFullScreen) {
          return player;
        }
        return Dialog(
          backgroundColor: Colors.black,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 24,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: player,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Standalone error dialog shown after the broken player is popped.
/// Has no WebView — just a message and "Open in YouTube" button.
class _TrailerErrorDialog extends StatelessWidget {
  final TmdbVideo video;

  const _TrailerErrorDialog({required this.video});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: EColors.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ESizes.radiusLg),
      ),
      child: Padding(
        padding: const EdgeInsets.all(ESizes.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: EColors.textTertiary,
            ),
            const SizedBox(height: ESizes.md),
            const Text(
              'Playback Unavailable',
              style: TextStyle(
                fontSize: ESizes.fontLg,
                fontWeight: FontWeight.bold,
                color: EColors.textPrimary,
              ),
            ),
            const SizedBox(height: ESizes.sm),
            const Text(
              'This video could not be played in-app. '
              'Try opening it in YouTube instead.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: ESizes.fontMd,
                color: EColors.textSecondary,
              ),
            ),
            const SizedBox(height: ESizes.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  onPressed: () => Get.back(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton.icon(
                  onPressed: () => _openInYouTube(),
                  icon: const Icon(Icons.open_in_new, size: 18),
                  label: const Text('Open in YouTube'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openInYouTube() async {
    final url = Uri.parse(video.youtubeUrl);
    Get.back();
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      Get.snackbar(
        'Error',
        'Could not open YouTube',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: EColors.error,
        colorText: Colors.white,
      );
    }
  }
}
