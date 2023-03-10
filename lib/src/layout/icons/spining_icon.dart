import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:animator/animator.dart';

class SpinningIcon extends StatelessWidget {
	final IconData iconData;
	final Color color;
	final double size;
	const SpinningIcon(this.iconData, {this.color = Colors.white, this.size = 24});
	
	@override
	Widget build(BuildContext context) {
		return Animator<double>(
			tween: Tween<double>(begin: 0, end: pi),
			repeats: 1000,
			duration: Duration(milliseconds: 500),
			builder: (ctx, state, widget){
				return Transform.rotate(
					angle: state.value,
					child: Icon(iconData, color: color, size: size),
				);
			},
		);
	}
}
