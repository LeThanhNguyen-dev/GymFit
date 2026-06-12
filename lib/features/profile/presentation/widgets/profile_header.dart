import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_image.dart';
import '../../data/models/profile_model.dart';

class ProfileHeaderWidget extends StatelessWidget {
  const ProfileHeaderWidget({
    super.key,
    required this.profile,
    this.onEditTap,
  });

  final ProfileModel profile;
  final VoidCallback? onEditTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 36,
          backgroundColor: AppColors.surfaceContainerHighest,
          child: ClipOval(
            child: profile.avatarUrl != null
                ? AppImage(
                    imageUrl: profile.avatarUrl,
                    width: 72,
                    height: 72,
                  )
                : Text(
                    profile.initials,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                profile.fullName ?? profile.email,
                style: AppTextStyles.titleMedium,
              ),
              const SizedBox(height: 2),
              Text(
                profile.email,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: onEditTap,
          icon: const Icon(Icons.edit_outlined),
          tooltip: 'Chỉnh sửa',
        ),
      ],
    );
  }
}
