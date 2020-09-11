import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:iChan/blocs/favorite_bloc.dart';
import 'package:iChan/blocs/thread/data.dart';
import 'package:iChan/models/post.dart';
import 'package:iChan/models/thread.dart';
import 'package:iChan/models/thread_storage.dart';
import 'package:iChan/pages/activity/history_list.dart';
import 'package:iChan/pages/thread/animated_opacity_item.dart';
import 'package:iChan/pages/thread/post_item.dart';
import 'package:iChan/services/exports.dart';
import 'package:iChan/services/my.dart' as my;
import 'package:iChan/widgets/dash_separator.dart';

class ActivityPage extends StatefulWidget {
  @override
  _ActivityPageState createState() => _ActivityPageState();
}

class _ActivityPageState extends State<ActivityPage> {
  final scrollController = ScrollController();
  String mode = 'replies';

  List<Post> myPosts;
  List<Post> replies;
  int visitedAt;
  List<ThreadStorage> items;

  @override
  Widget build(BuildContext context) {
    final segmentedControl = ValueListenableBuilder(
        valueListenable: my.prefs.box.listenable(keys: ['history_disabled']),
        builder: (context, val, widget) {
          final historyDisabled = my.prefs.getBool('history_disabled');

          if (historyDisabled && mode == 'history') {
            mode = 'replies';
          }

          return CupertinoSegmentedControl(
            groupValue: mode,
            padding: const EdgeInsets.symmetric(
                vertical: Consts.sidePadding, horizontal: Consts.sidePadding),
            selectedColor: my.theme.primaryColor,
            unselectedColor: my.theme.backgroundColor,
            onValueChanged: (val) {
              setState(() {
                mode = val;
              });
            },
            children: <String, Widget>{
              'replies': const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(
                  'Replies',
                  style: TextStyle(fontSize: 15.0),
                ),
              ),
              'posts': const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(
                  'Posts',
                  style: TextStyle(fontSize: 15.0),
                ),
              ),
              if (!historyDisabled) ...{
                'history': const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    'History',
                    style: TextStyle(fontSize: 15.0),
                  ),
                ),
              }
            },
          );
        });

    final divider = Divider(
      color: my.theme.dividerColor,
      height: 1,
    );

    return HeaderNavbar(
      middleText: "Activity",
      backGesture: false,
      onStatusBarTap: () {
        scrollController.jumpTo(0.0);
      },
      trailing: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () {
            void delete(Post post) => post.delete();

            if (mode == "replies") {
              Interactive(context).modalDelete(text: "Clean all replies").then((confirmed) {
                if (confirmed) {
                  my.posts.replies.forEach(delete);
                }
              });
            } else if (mode == "posts") {
              Interactive(context).modalDelete(text: "Clean your posts").then((confirmed) {
                if (confirmed) {
                  my.posts.own.forEach(delete);
                }
              });
            } else if (mode == "history") {
              Interactive(context).modalDelete(text: "Clean history").then((confirmed) {
                if (confirmed) {
                  my.favoriteBloc.add(const FavoriteClearVisited());
                }
              });
            }
          },
          child: Text("Clean", style: TextStyle(color: my.theme.navbarFontColor))),
      child: ValueListenableBuilder(
          valueListenable: my.favs.box.listenable(),
          builder: (context, val, widget) {
            return ValueListenableBuilder(
                valueListenable: my.posts.box.listenable(),
                builder: (context, val, widget) {
                  myPosts = my.posts.own;
                  replies = my.posts.replies;

                  final unreadIndex = replies.where((e) => e.isUnread).lastIndex ?? -1;

                  visitedAt = my.prefs.getInt('visited_cleared_at');

                  items = my.favs.box.values
                      .where((e) => e.visitedAt > visitedAt)
                      .sortedByNum((e) => e.visitedAt * -1)
                      .toList();

                  if (unreadIndex != -1) {
                    Future.delayed(2.5.seconds).then((value) {
                      final posts = replies.where((e) => e.isUnread).toList();
                      for (final post in posts) {
                        post.isUnread = false;
                        post.save();
                      }
                    });
                  }

                  final animatedDivider = Stack(
                    children: [
                      AnimatedOpacityItem(
                        delay: 2,
                        runPostFrame: false,
                        child: Divider(
                          color: my.theme.dividerColor,
                          height: 1,
                        ),
                      ),
                      const AnimatedOpacityItem(
                        delay: 2,
                        runPostFrame: false,
                        reverse: true,
                        child: DashSeparator(height: 1.5),
                      ),
                    ],
                  );

                  return CupertinoScrollbar(
                    child: CustomScrollView(
                      semanticChildCount: 1,
                      controller: scrollController,
                      physics: my.prefs.scrollPhysics,
                      slivers: [
                        SliverList(
                          delegate: SliverChildListDelegate(
                            [
                              segmentedControl,
                            ],
                          ),
                        ),
                        if (mode == 'replies') ...[
                          SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                if (replies.isEmpty) {
                                  return Center(
                                    child: FaIcon(FontAwesomeIcons.ghost,
                                        size: 60, color: my.theme.inactiveColor),
                                  );
                                }

                                final post = replies[index];
                                final threadData = buildThreadData(post);
                                final isLast = index == replies.length - 1;

                                return Column(
                                  children: [
                                    divider,
                                    PostItem(
                                      post: post,
                                      threadData: threadData,
                                      origin: Origin.activity,
                                      isLast: isLast,
                                    ),
                                    if (index == unreadIndex) animatedDivider else divider,
                                  ],
                                );
                              },
                              childCount: replies.length,
                            ),
                          ),
                          SliverList(
                            delegate: SliverChildListDelegate(
                              [
                                const SizedBox(height: 100),
                              ],
                            ),
                          ),
                        ],
                        if (mode == 'posts') ...[
                          SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final post = myPosts[index];
                                final threadData = buildThreadData(post);
                                final isLast = index == replies.length - 1;

                                return Column(
                                  children: [
                                    divider,
                                    PostItem(
                                      post: post,
                                      threadData: threadData,
                                      origin: Origin.activity,
                                    ),
                                    if (isLast) divider,
                                  ],
                                );
                              },
                              childCount: myPosts.length,
                            ),
                          ),
                          SliverList(
                            delegate: SliverChildListDelegate(
                              [
                                const SizedBox(height: 100),
                              ],
                            ),
                          ),
                        ],
                        if (mode == 'history') ...[
                          SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                return Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 2.5, horizontal: 5.0),
                                  child: HistoryRow(item: items[index]),
                                );
                              },
                              childCount: items.length,
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                });
          }),
    );
  }

  ThreadData buildThreadData(Post post) {
    post.replies ??= [];
    final threadData = my.threadBloc.getThreadData(post.toThreadKey);

    if (threadData != null) {
      return threadData;
    }

    final ts = my.favs.get(post.toThreadKey);

    final thread = ts == null
        ? Thread(post.threadId, post.boardName, post.threadId, post.platform)
        : Thread.fromThreadStorage(ts);

    thread.mediaFiles = [];
    final _threadData = ThreadData(thread: thread);

    final List<Post> parentReplies = [];
    final List<Post> childReplies = [];

    _threadData.thread.mediaFiles += post.mediaFiles;

    for (final postId in post.repliesParent) {
      final _post = my.posts.get("${post.platform.toString()}-${post.boardName}-$postId");
      if (_post != null) {
        parentReplies.add(_post);
        _threadData.thread.mediaFiles += _post.mediaFiles;
      }
    }

    for (final postId in post.replies) {
      final _post = my.posts.get("${post.platform.toString()}-${post.boardName}-$postId");
      if (_post != null) {
        childReplies.add(_post);
        _threadData.thread.mediaFiles += _post.mediaFiles;
      }
    }

    _threadData.posts = parentReplies + childReplies;

    return _threadData;
  }
}
