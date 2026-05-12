import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../api.dart';

class SimpleAnnouncementButton extends StatefulWidget {
  final VoidCallback onTap;
  final bool isDarkMode;

  const SimpleAnnouncementButton({
    Key? key,
    required this.onTap,
    required this.isDarkMode,
  }) : super(key: key);

  @override
  State<SimpleAnnouncementButton> createState() =>
      _SimpleAnnouncementButtonState();
}

class _SimpleAnnouncementButtonState extends State<SimpleAnnouncementButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool hasUnreadAnnouncements = false;
  static const String _lastViewedKey = 'last_viewed_announcements_time';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _checkUnreadAnnouncements();
  }

  Future<void> _checkUnreadAnnouncements() async {
    final prefs = await SharedPreferences.getInstance();
    final lastViewed = prefs.getInt(_lastViewedKey) ?? 0;

    try {
      final announcements = await ApiService().getAnnouncements();
      if (announcements.isNotEmpty) {
        final latestAnnouncementTime =
            announcements.first.publishDate.millisecondsSinceEpoch;

        if (latestAnnouncementTime > lastViewed) {
          setState(() {
            hasUnreadAnnouncements = true;
          });
          _controller.repeat();
        }
      }
    } catch (e) {
    }
  }

  Future<void> _markAsRead() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastViewedKey, DateTime.now().millisecondsSinceEpoch);

    setState(() {
      hasUnreadAnnouncements = false;
    });
    _controller.stop();
    widget.onTap();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _markAsRead,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale:
                hasUnreadAnnouncements ? 1.0 + (0.1 * _controller.value) : 1.0,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: EdgeInsets.all(10.w),
                  decoration: BoxDecoration(
                    color: Colors.amber[700]!.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: Colors.amber[700]!.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    Icons.campaign_outlined,
                    color: Colors.amber[700],
                    size: 24.sp,
                  ),
                ),
                if (hasUnreadAnnouncements)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      width: 8.w,
                      height: 8.w,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
