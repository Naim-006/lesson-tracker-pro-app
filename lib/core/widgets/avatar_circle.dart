import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class AvatarCircle extends StatelessWidget {
  final String initials;
  final double size;
  final Color? backgroundColor;
  final String? imageUrl;

  const AvatarCircle({
    super.key,
    required this.initials,
    this.size = 40,
    this.backgroundColor,
    this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl != null) {
      return CircleAvatar(
        radius: size / 2,
        backgroundImage: NetworkImage(imageUrl!),
        backgroundColor: AppColors.lightBorder,
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.sunsetBright.withValues(alpha: 0.2),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            color: backgroundColor != null ? Colors.white : AppColors.sunsetBright,
            fontSize: size * 0.38,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
