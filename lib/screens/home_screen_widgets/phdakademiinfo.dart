import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class PhdAkademiInfo extends StatefulWidget {
  final bool isDarkMode;

  const PhdAkademiInfo({Key? key, required this.isDarkMode}) : super(key: key);

  @override
  _PhdAkademiInfoState createState() => _PhdAkademiInfoState();
}

class _PhdAkademiInfoState extends State<PhdAkademiInfo> {
  bool _isPressed = false;

  void _onTapDown(TapDownDetails details) {
    setState(() {
      _isPressed = true;
    });
  }

  void _onTapUp(TapUpDetails details) {
    setState(() {
      _isPressed = false;
    });
  }

  void _onTapCancel() {
    setState(() {
      _isPressed = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: () {
        // TODO: Implement action when tapped (e.g., open PhD Akademi page)
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 12.w),
        decoration: BoxDecoration(
          color: widget.isDarkMode
              ? (_isPressed ? Colors.blue.shade800 : Colors.blue.shade900)
              : (_isPressed ? Colors.blue.shade200 : Colors.blue.shade100),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.school,
              color: widget.isDarkMode ? Colors.white : Colors.blue.shade900,
              size: 18.sp,
            ),
            SizedBox(width: 8.w),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "PhD Akademi",
                    style: TextStyle(
                      color: widget.isDarkMode ? Colors.white : Colors.blue.shade900,
                      fontWeight: FontWeight.bold,
                      fontSize: 12.sp,
                    ),
                  ),
                  Text(
                    "Profesyonel dil eğitimi",
                    style: TextStyle(
                      color: widget.isDarkMode ? Colors.white70 : Colors.blue.shade800,
                      fontSize: 9.sp,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}