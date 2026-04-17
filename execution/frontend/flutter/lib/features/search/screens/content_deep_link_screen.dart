import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/e_colors.dart';
import '../../../shared/models/tmdb_content.dart';
import '../../../shared/models/watchlist_item.dart';
import '../controllers/search_controller.dart';
import '../widgets/content_detail_sheet.dart';

class ContentDeepLinkScreen extends StatefulWidget {
  final int tmdbId;
  final MediaType mediaType;

  const ContentDeepLinkScreen({super.key, required this.tmdbId, required this.mediaType});

  @override
  State<ContentDeepLinkScreen> createState() => _ContentDeepLinkScreenState();
}

class _ContentDeepLinkScreenState extends State<ContentDeepLinkScreen> {
  @override
  void initState() {
    super.initState();
    if (!Get.isRegistered<ContentSearchController>()) {
      Get.put(ContentSearchController());
    }
  }

  @override
  Widget build(BuildContext context) {
    final stub = TmdbSearchResult(
      id: widget.tmdbId,
      voteAverage: 0,
      mediaTypeString: widget.mediaType == MediaType.tv ? 'tv' : 'movie',
    );
    return Scaffold(
      backgroundColor: EColors.surface,
      body: SafeArea(child: ContentDetailSheet(result: stub)),
    );
  }
}
