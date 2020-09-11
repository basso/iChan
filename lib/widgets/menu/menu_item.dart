import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:iChan/services/my.dart' as my;

class MenuItem extends StatelessWidget {
  const MenuItem({
    Key key,
    @required this.name,
    @required this.page,
    this.isFirst = false,
    this.isLast = false,
  }) : super(key: key);

  final String name;
  final Widget page;
  final bool isFirst;
  final bool isLast;

  static const borderRadiusAmount = 15.0;

  @override
  Widget build(BuildContext context) {
    final borderRadius = isFirst
        ? const BorderRadius.only(
            topLeft: Radius.circular(borderRadiusAmount),
            topRight: Radius.circular(borderRadiusAmount))
        : isLast
            ? const BorderRadius.only(
                bottomLeft: Radius.circular(borderRadiusAmount),
                bottomRight: Radius.circular(borderRadiusAmount))
            : BorderRadius.zero;

    return GestureDetector(
      onTap: () {
        Navigator.push(context, CupertinoPageRoute(builder: (context) => page));
      },
      child: Container(
          decoration: BoxDecoration(color: my.theme.backgroudMenuColor, borderRadius: borderRadius),
          padding: const EdgeInsets.fromLTRB(15.0, 12.0, 15.0, 12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(name,
                  style: TextStyle(
                      color: my.theme.foregroundBrightColor, fontWeight: FontWeight.w400)),
              Icon(CupertinoIcons.forward, color: my.theme.foregroundBrightColor),
            ],
          )),
    );
  }
}
