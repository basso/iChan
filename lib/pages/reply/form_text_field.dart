import 'package:flutter/cupertino.dart';
import 'package:iChan/services/exports.dart';
import 'package:iChan/services/my.dart' as my;

class FormTextField extends StatelessWidget {
  const FormTextField({
    Key key,
    @required this.controller,
    this.placeholder,
  }) : super(key: key);

  final TextEditingController controller;
  final String placeholder;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(bottom: 5.0, top: 5.0),
      child: CupertinoTextField(
        keyboardAppearance: Consts.keyboardAppearance,
        keyboardType: TextInputType.multiline,
        textCapitalization: TextCapitalization.sentences,
        autofocus: false,
        placeholder: placeholder,
        style: TextStyle(
          color: my.theme.editFieldContrastingColor,
        ),
        decoration: BoxDecoration(
          color: my.theme.formBackgroundColor,
          borderRadius: BorderRadius.circular(6),
        ),
        controller: controller,
      ),
    );
  }
}
