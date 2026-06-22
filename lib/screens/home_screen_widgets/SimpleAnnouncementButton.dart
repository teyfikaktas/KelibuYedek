import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../api.dart';

class SimpleAnnouncementButton extends StatefulWidget {
  final VoidCallback onTap;
  final bool isDarkMode;
  final IconData icon;
  final Color color;

  const SimpleAnnouncementButton({
    Key? key,
    required this.onTap,
    required this.isDarkMode,
    this.icon = Icons.campaign_outlined,
    this.color = const Color(0xFFF57C00), // Colors.amber[700]
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
      // Artık yeni eklediğimiz getNotifications'ı kullanıyoruz
      final announcements = await ApiService().getNotifications();
      if (announcements.isNotEmpty) {
        final latestAnnouncementTime =
            announcements.first.publishDate.millisecondsSinceEpoch;

        if (latestAnnouncementTime > lastViewed) {
          if (mounted) {
            setState(() {
              hasUnreadAnnouncements = true;
            });
            _controller.repeat();
          }
        }
      }
    } catch (e) {
    }
  }

  Future<void> _markAsRead() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastViewedKey, DateTime.now().millisecondsSinceEpoch);

    if (mounted) {
      setState(() {
        hasUnreadAnnouncements = false;
      });
      _controller.stop();
    }
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
                hasUnreadAnnouncements ? 1.0 + (0.05 * _controller.value) : 1.0,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: widget.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10.r),
                    border: Border.all(
                      color: widget.color.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Icon(
                      widget.icon,
                      color: widget.color,
                      size: 20.sp,
                    ),
                  ),
                ),
                if (hasUnreadAnnouncements)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      width: 10.w,
                      height: 10.w,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 2,
                            offset: const Offset(0, 1),
                          ),
                        ],
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
