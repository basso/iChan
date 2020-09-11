import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:iChan/pages/settings/platforms_links_page.dart';
import 'package:iChan/repositories/4chan/fourchan_api.dart';
import 'package:iChan/services/exports.dart';
import 'package:iChan/widgets/menu/menu.dart';
import 'package:iChan/services/my.dart' as my;

class FourchanSettingsPage extends HookWidget {
  String setDomain(String domain) {
    final result = domain
        .replaceAll('www.', '')
        .replaceAll('http://', '')
        .replaceAll('https://', '')
        .replaceAll('/', '');

    return "https://$result";
  }

  @override
  Widget build(BuildContext context) {
    return HeaderNavbar(
      backgroundColor: my.theme.secondaryBackgroundColor,
      previousPageTitle: PlatformsLinksPage.header,
      middleText: '4chan',
      child: Container(
        height: context.screenHeight,
        child: ListView(
          children: [
            menuDivider,
            MenuSwitch(
              label: 'Enabled',
              field: 'fourchan_enabled',
              defaultValue: false,
              onChanged: (val) {
                final List<Platform> platforms = my.prefs.platforms;

                if (val == true) {
                  const actions = [ActionSheet(text: "Use as default platform", value: "default")];
                  Interactive(context).modal(actions).then((val) {
                    if (val == 'default') {
                      platforms.insert(0, Platform.fourchan);
                    } else {
                      platforms.add(Platform.fourchan);
                    }
                    my.prefs.put('platforms', platforms.toSet().toList());
                    my.categoryBloc.setPlatform();
                  });
                } else {
                  platforms.remove(Platform.fourchan);
                  my.prefs.put('platforms', platforms.toList());
                }
                my.categoryBloc.setPlatform();
              },
            ),
            MenuTextField(
              label: 'Domain',
              boxField: 'fourchan_domain',
              onChanged: (val) {
                if (val.isEmpty) {
                  my.prefs.put('fourchan_domain', FourchanApi.defaultDomain);
                  my.fourchanApi.domain = setDomain(FourchanApi.defaultDomain);
                } else {
                  my.prefs.put('fourchan_domain', val);
                  my.fourchanApi.domain = setDomain(val);
                  my.prefs.delete('json_cache');
                }
                my.categoryBloc.fetchBoards(Platform.fourchan);
                return false;
              },
            ),
            menuDivider,
            MenuSwitch(
              label: 'Passcode enabled',
              field: 'fourchan_passcode_enabled',
              defaultValue: false,
              onChanged: (v) {
                my.prefs.put('fourchan_passcode_enabled', v);
                my.contextTools.init(context);
                return false;
              },
            ),
            ValueListenableBuilder(
              valueListenable: my.prefs.box.listenable(keys: ['fourchan_passcode_enabled']),
              builder: (BuildContext context, dynamic value, Widget child) {
                if (my.prefs.getBool('fourchan_passcode_enabled')) {
                  return MenuTextField(
                    label: 'Code',
                    boxField: 'fourchan_passcode',
                    enabled: my.prefs.getBool('fourchan_passcode_enabled'),
                  );
                } else {
                  return Container();
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
