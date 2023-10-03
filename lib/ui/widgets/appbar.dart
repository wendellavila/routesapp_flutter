import 'package:flutter/material.dart';

class TopBar extends StatelessWidget implements PreferredSizeWidget {
  const TopBar({super.key});

  final double appBarSize = 65.0;

  @override
  Size get preferredSize => Size.fromHeight(appBarSize);

  @override
  Widget build(BuildContext context) {
    return AppBar(
        toolbarHeight: appBarSize,
        title: IntrinsicHeight(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset(
                'assets/img/logo.png',
                height: 45,
              ),
              const VerticalDivider(
                color: Colors.white,
                thickness: 2,
                indent: 5,
                endIndent: 5,
                width: 30,
              ),
              const Flexible(
                  child: Text(
                "ROUTESAPP",
                overflow: TextOverflow.ellipsis,
              )),
            ],
          ),
        ),
        centerTitle: true);
  }
}
