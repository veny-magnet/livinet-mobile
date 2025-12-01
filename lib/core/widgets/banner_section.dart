import 'package:flutter/material.dart';
import '../services/banner_service.dart' as banner_service;
import '../services/app_logger.dart';

class BannerSection extends StatefulWidget {
  const BannerSection({super.key});

  @override
  State<BannerSection> createState() => _BannerSectionState();
}

class _BannerSectionState extends State<BannerSection> {
  final banner_service.BannerService _bannerService =
      banner_service.BannerService.instance;
  List<banner_service.Banner> _banners = [];
  bool _isLoading = true;
  final _logger = AppLogger.instance;

  @override
  void initState() {
    super.initState();
    _loadBanners();
  }

  Future<void> _loadBanners() async {
    try {
      final result = await _bannerService.getBanners(
        bannerType: 'promotion_home',
      );

      if (mounted) {
        setState(() {
          _banners = result['success']
              ? (result['data'] as List<dynamic>).cast<banner_service.Banner>()
              : [];
          _isLoading = false;
        });
      }
    } catch (e) {
      _logger.error('Error loading banners in BannerSection', e);
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: SizedBox(
          height: 150,
          child: Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.secondary,
              ),
            ),
          ),
        ),
      );
    }

    if (_banners.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        height: 150,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: _banners.length,
          itemBuilder: (context, index) {
            final banner = _banners[index];
            return Container(
              width: 283,
              margin: EdgeInsets.only(
                right: index < _banners.length - 1 ? 12 : 0,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                image: DecorationImage(
                  image: NetworkImage(banner.target ?? ''),
                  fit: BoxFit.cover,
                  onError: (exception, stackTrace) {
                    _logger.error(
                      'Error loading banner image: ${banner.path}',
                      exception,
                    );
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
