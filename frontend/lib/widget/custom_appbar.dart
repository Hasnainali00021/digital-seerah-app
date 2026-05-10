import 'package:flutter/material.dart';
import 'package:seerah_timeline/constants/app_colors.dart';
import '../widget/custom_back_button.dart';

class CustomAppbar extends StatefulWidget implements PreferredSizeWidget {
  final String titleOne;
  final String titleTwo;
  final double titleSize;

  const CustomAppbar({
    super.key,
    required this.titleOne,
    required this.titleTwo,
    this.titleSize = 22,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  State<CustomAppbar> createState() => _CustomAppbarState();
}

class _CustomAppbarState extends State<CustomAppbar> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AppBar(
      backgroundColor: isDark ? const Color(0xFF1A1A1A) : AppColors.scaffoldBackground,
      scrolledUnderElevation: 0,
      centerTitle: true,
      elevation: 0,

      title: LayoutBuilder(
        builder: (context, constraints) {
          return Transform.translate(
            offset: const Offset(-8, 0),
            child: SizedBox(
              width: constraints.maxWidth,
              child: Text.rich(
                TextSpan(
                  style: TextStyle(
                    fontSize: widget.titleSize,
                    fontWeight: FontWeight.bold,
                  ),
                  children: [
                    TextSpan(
                      text: widget.titleOne,
                      style: const TextStyle(color: AppColors.primary),
                    ),
                    TextSpan(
                      text: widget.titleTwo,
                      style: const TextStyle(color: AppColors.accent),
                    ),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          );
        },
      ),

      leading: CustomBackButton(),

      automaticallyImplyLeading: false,
    );
  }
}
