import 'package:flutter/material.dart';

import '../../routes.dart';

class AppFloatingActionButton extends StatelessWidget {
  const AppFloatingActionButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 6,
            spreadRadius: 1,
          ),
        ],
      ),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () {
          Navigator.of(context).pushNamed(chargingScreenRoute);
        },
        child: const Center(
          child: Icon(
            Icons.flash_on,
            color: Colors.grey,
            size: 26,
          ),
        ),
      ),
    );
  }
}
