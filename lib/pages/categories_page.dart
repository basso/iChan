import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:iChan/blocs/blocs.dart';
import 'package:iChan/pages/categories/category_list.dart';
import 'package:iChan/pages/thread/thread.dart';
import 'package:iChan/services/exports.dart';
import 'package:iChan/services/my.dart' as my;

class CategoriesPage extends StatefulWidget {
  const CategoriesPage({Key key}) : super(key: key);

  @override
  CategoriesPageState createState() => CategoriesPageState();
}

class CategoriesPageState extends State<CategoriesPage> {
  final addCategoryController = TextEditingController();
  final searchController = TextEditingController();
  FocusNode focusNode;

  @override
  void initState() {
    super.initState();
    focusNode = FocusNode();
    my.categoryBloc.fetchBoards();
  }

  @override
  void dispose() {
    addCategoryController.dispose();
    searchController.dispose();
    // focusNode.unfocus();
    focusNode.dispose();
    super.dispose();
  }

  void searchStart(String val) {
    my.boardBloc.add(BoardSearchTyped(query: val));
  }

  @override
  Widget build(BuildContext context) {
    final Widget addButton = GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        showDialog(context);
      },
      child: Icon(CupertinoIcons.add, color: my.theme.navbarFontColor),
    );

    return HeaderNavbar(
      backGesture: false,
      middleText: "Boards",
      trailing: addButton,
      child: CupertinoScrollbar(
        child: CategoryList(
          searchController: searchController,
          focusNode: focusNode,
        ),
      ),
    );
  }

  Future showDialog(BuildContext context) {
    final action = CupertinoDialogAction(
      isDefaultAction: true,
      child: const Text("Add"),
      onPressed: () {
        my.categoryBloc.favoriteBoard(boardName: addCategoryController.text.toLowerCase());
        Navigator.of(context).pop();
        addCategoryController.text = '';
      },
    );

    return Interactive(context).modalTextField(
      controller: addCategoryController,
      header: "Add to favorites",
      action: action,
    );
  }
}
