import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:hive/hive.dart';
import 'package:iChan/services/exports.dart';
import 'package:iChan/widgets/shimmer_widget.dart';
import 'package:iChan/services/my.dart' as my;

class WelcomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    my.contextTools.init(context);

    const String rules = """You should agree with following rules:

    - Be more than 18+ years old
    - Do not discriminate other about religion, race, sexual orientation, gender, national/ethnic origin
    - Do not violate any copyright
    - Do not post realistic portrayals of people or animals being killed, maimed, tortured, or abused, or content that encourages violence
    - Do not create posts about illegal or reckless use of weapons and dangerous objects
    - Do not post sexual or pornographic materials
    - Do not bully other users
    - Your posts could be reported and you will be banned in case of rules violation
    """;

    return CupertinoPageScaffold(
        child:
            Column(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: Consts.sidePadding),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const ShimmerLoader(text: "Welcome. Again."),
          SingleChildScrollView(
              child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(rules,
                style: TextStyle(
                    color: my.theme.foregroundBrightColor, fontSize: 14)),
          ))
        ]),
      ),
      Container(
          decoration: BoxDecoration(
              color: my.theme.primaryColor,
              borderRadius: BorderRadius.circular(10.0)),
          child: CupertinoButton(
              key: const ValueKey('accept'),
              onPressed: () {
                HapticFeedback.heavyImpact();
                Hive.box('prefs').put('agreement', true);
                Navigator.of(context).pushNamedAndRemoveUntil(
                    '/', (Route<dynamic> route) => false);
              },
              child: Text("ACCEPT",
                  style: TextStyle(color: my.theme.postBackgroundColor)))),
    ]));
  }
}
