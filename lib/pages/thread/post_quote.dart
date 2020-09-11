import 'package:flutter/cupertino.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:iChan/services/exports.dart';
import 'package:iChan/services/htmlz.dart';
import 'package:iChan/services/my.dart' as my;

import 'thread.dart';

class PostQuote extends HookWidget {
  const PostQuote({
    Key key,
    @required this.post,
    @required this.thread,
  }) : super(key: key);

  final Thread thread;
  final Post post;

  Future<bool> processResult(BuildContext context, Future<dynamic> result) async {
    result.then((e) {
      if (e == true) {
        Navigator.of(context).pop();
      }
    });
    return true;
  }

  void selectText(BuildContext context, TextEditingController controller) {
    final sel = controller.selection;
    final text = sel.isValid && sel.baseOffset != sel.extentOffset
        ? sel.textInside(controller.text)
        : controller.text;

    final fav = ThreadStorage.findById(thread.toJsonId);
    my.postBloc.addQuote(postId: post.outerId, text: text, fav: fav);

    final Future<dynamic> result = Routz.of(context)
        .toPage(NewPostPage(thread: thread), title: thread.trimTitle(Consts.navLeadingTrimSize));
    processResult(context, result);
  }

  @override
  Widget build(BuildContext context) {
    final controller = useTextEditingController();

    controller.text = Htmlz.toHuman(post.body.replaceAll(Consts.youMark, ''));
    final lines = my.contextTools.isVerySmallHeight ? 6 : (my.contextTools.isSmallHeight ? 8 : 12);

    return HeaderNavbar(
      backgroundColor: my.theme.backgroundColor,
      middleText: "Quote",
      child: Container(
        height: context.screenHeight,
        width: context.screenWidth,
        padding: const EdgeInsets.only(
          top: Consts.topPadding,
          left: Consts.sidePadding,
          right: Consts.sidePadding,
        ),
        child: Wrap(
          runSpacing: 20,
          children: [
            CupertinoTextField(
              style: TextStyle(
                color: my.theme.editFieldContrastingColor,
              ),
              decoration: BoxDecoration(
                color: my.theme.formBackgroundColor,
                borderRadius: BorderRadius.circular(6),
              ),
              autofocus: true,
              enableSuggestions: false,
              controller: controller,
              minLines: lines,
              maxLines: lines,
            ),
            Center(
              child: CupertinoButton(
                  color: my.theme.primaryColor,
                  onPressed: () {
                    selectText(context, controller);
                  },
                  child: const Text("Quote")),
            )
          ],
        ),
      ),
    );
  }
}
