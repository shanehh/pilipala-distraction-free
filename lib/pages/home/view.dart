import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:pilipala/common/widgets/network_img_layer.dart';
import 'package:pilipala/pages/mine/index.dart';
import 'package:pilipala/utils/feed_back.dart';
import './controller.dart';
import 'package:media_kit/media_kit.dart';
import 'package:pilipala/models/user/fav_folder.dart';
import 'package:pilipala/pages/main/index.dart';
import 'package:pilipala/pages/media/index.dart';
import 'package:pilipala/utils/utils.dart';
import 'package:flutter/rendering.dart';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';
import 'package:media_kit/media_kit.dart';
import 'package:pilipala/common/widgets/network_img_layer.dart';
import 'package:pilipala/models/user/fav_folder.dart';
import 'package:pilipala/pages/main/index.dart';
import 'package:pilipala/pages/media/index.dart';
import 'package:pilipala/utils/utils.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  final HomeController _homeController = Get.put(HomeController());
  List videoList = [];
  late Stream<bool> stream;
  late MediaController mediaController;
  late Future _futureBuilderFuture;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    stream = _homeController.searchBarStream.stream;
    mediaController = Get.put(MediaController());
    _futureBuilderFuture = mediaController.queryFavFolder();
    ScrollController scrollController = mediaController.scrollController;
    StreamController<bool> mainStream =
        Get.find<MainController>().bottomBarStream;

    mediaController.userLogin.listen((status) {
      setState(() {
        _futureBuilderFuture = mediaController.queryFavFolder();
      });
    });
    scrollController.addListener(
      () {
        final ScrollDirection direction =
            scrollController.position.userScrollDirection;
        if (direction == ScrollDirection.forward) {
          mainStream.add(true);
        } else if (direction == ScrollDirection.reverse) {
          mainStream.add(false);
        }
      },
    );

  }

  showUserBottomSheet() {
    feedBack();
    showModalBottomSheet(
      context: context,
      builder: (_) => const SizedBox(
        height: 450,
        child: MinePage(),
      ),
      clipBehavior: Clip.hardEdge,
      isScrollControlled: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    Color primary = Theme.of(context).colorScheme.primary;
    Brightness currentBrightness = MediaQuery.of(context).platformBrightness;
    // 设置状态栏图标的亮度
    if (_homeController.enableGradientBg) {
      SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
        statusBarIconBrightness: currentBrightness == Brightness.light
            ? Brightness.dark
            : Brightness.light,
      ));
    }
    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      appBar: _homeController.enableGradientBg
          ? null
          : AppBar(toolbarHeight: 0, elevation: 0),
      body: Stack(
        children: [
          // gradient background
          if (_homeController.enableGradientBg) ...[
            Align(
              alignment: Alignment.topLeft,
              child: Opacity(
                opacity: 0.6,
                child: Container(
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                        colors: [
                          Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.9),
                          Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.5),
                          Theme.of(context).colorScheme.surface
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        stops: const [0, 0.0034, 0.34]),
                  ),
                ),
              ),
            ),
          ],
          Column(
            children: [
              CustomAppBar(
                stream: _homeController.hideSearchBar
                    ? stream
                    : StreamController<bool>.broadcast().stream,
                ctr: _homeController,
                callback: showUserBottomSheet,
              ),
              // padding top
              const SizedBox(height: 22),
              for (var i in mediaController.list) ...[
              ListTile(
                onTap: () => i['onTap'](),
                dense: true,
                leading: Padding(
                  padding: const EdgeInsets.only(left: 15),
                  child: Icon(
                    i['icon'],
                    color: primary,
                  ),
                ),
                contentPadding:
                    const EdgeInsets.only(left: 15, top: 2, bottom: 2),
                minLeadingWidth: 0,
                title: Text(
                  i['title'],
                  style: const TextStyle(fontSize: 15),
                ),
              ),
            ],
            Obx(() => mediaController.userLogin.value
                ? favFolder(mediaController, context)
                : const SizedBox()),
            SizedBox(
              height: MediaQuery.of(context).padding.bottom +
                  kBottomNavigationBarHeight,
            )
            ],
          ),
        ],
      ),
    );
  }

  Widget favFolder(mediaController, context) {
    return Column(
      children: [
        Divider(
          height: 35,
          color: Theme.of(context).dividerColor.withOpacity(0.1),
        ),
        ListTile(
          onTap: () {},
          leading: null,
          dense: true,
          title: Padding(
            padding: const EdgeInsets.only(left: 10),
            child: Obx(
              () => Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '收藏夹 ',
                      style: TextStyle(
                          fontSize:
                              Theme.of(context).textTheme.titleMedium!.fontSize,
                          fontWeight: FontWeight.bold),
                    ),
                    if (mediaController.favFolderData.value.count != null)
                      TextSpan(
                        text: mediaController.favFolderData.value.count
                            .toString(),
                        style: TextStyle(
                          fontSize:
                              Theme.of(context).textTheme.titleSmall!.fontSize,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          trailing: IconButton(
            onPressed: () {
              setState(() {
                _futureBuilderFuture = mediaController.queryFavFolder();
              });
            },
            icon: const Icon(
              Icons.refresh,
              size: 20,
            ),
          ),
        ),
        // const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          height: MediaQuery.textScalerOf(context).scale(200),
          child: FutureBuilder(
              future: _futureBuilderFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  if (snapshot.data == null) {
                    return const SizedBox();
                  }
                  Map data = snapshot.data as Map;
                  if (data['status']) {
                    List favFolderList =
                        mediaController.favFolderData.value.list!;
                    int favFolderCount =
                        mediaController.favFolderData.value.count!;
                    bool flag = favFolderCount > favFolderList.length;
                    return Obx(() => ListView.builder(
                          itemCount:
                              mediaController.favFolderData.value.list!.length +
                                  (flag ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (flag && index == favFolderList.length) {
                              return Padding(
                                  padding: const EdgeInsets.only(
                                      right: 14, bottom: 35),
                                  child: Center(
                                    child: IconButton(
                                      style: ButtonStyle(
                                        padding: MaterialStateProperty.all(
                                            EdgeInsets.zero),
                                        backgroundColor:
                                            MaterialStateProperty.resolveWith(
                                                (states) {
                                          return Theme.of(context)
                                              .colorScheme
                                              .primaryContainer
                                              .withOpacity(0.5);
                                        }),
                                      ),
                                      onPressed: () => Get.toNamed('/fav'),
                                      icon: Icon(
                                        Icons.arrow_forward_ios,
                                        size: 18,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                      ),
                                    ),
                                  ));
                            } else {
                              return FavFolderItem(
                                  item: mediaController
                                      .favFolderData.value.list![index],
                                  index: index);
                            }
                          },
                          scrollDirection: Axis.horizontal,
                        ));
                  } else {
                    return SizedBox(
                      height: 160,
                      child: Center(child: Text(data['msg'])),
                    );
                  }
                } else {
                  // 骨架屏
                  return const SizedBox();
                }
              }),
        ),
      ],
    );
  }
}
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final double height;
  final Stream<bool>? stream;
  final HomeController? ctr;
  final Function? callback;

  const CustomAppBar({
    super.key,
    this.height = kToolbarHeight,
    this.stream,
    this.ctr,
    this.callback,
  });

  @override
  Size get preferredSize => Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: stream,
      initialData: true,
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        final RxBool isUserLoggedIn = ctr!.userLogin;
        final double top = MediaQuery.of(context).padding.top;
        return AnimatedOpacity(
          opacity: snapshot.data ? 1 : 0,
          duration: const Duration(milliseconds: 300),
          child: AnimatedContainer(
            curve: Curves.easeInOutCubicEmphasized,
            duration: const Duration(milliseconds: 500),
            height: snapshot.data ? top + 52 : top,
            padding: EdgeInsets.fromLTRB(14, top + 6, 14, 0),
            child: UserInfoWidget(
              top: top,
              ctr: ctr,
              userLogin: isUserLoggedIn,
              userFace: ctr?.userFace.value,
              callback: () => callback!(),
            ),
          ),
        );
      },
    );
  }
}

class UserInfoWidget extends StatelessWidget {
  const UserInfoWidget({
    Key? key,
    required this.top,
    required this.userLogin,
    required this.userFace,
    required this.callback,
    required this.ctr,
  }) : super(key: key);

  final double top;
  final RxBool userLogin;
  final String? userFace;
  final VoidCallback? callback;
  final HomeController? ctr;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SearchBar(ctr: ctr),
        if (userLogin.value) ...[
          const SizedBox(width: 4),
          ClipRect(
            child: IconButton(
              onPressed: () => Get.toNamed('/whisper'),
              icon: const Icon(Icons.notifications_none),
            ),
          )
        ],
        const SizedBox(width: 8),
        Obx(
          () => userLogin.value
              ? Stack(
                  children: [
                    NetworkImgLayer(
                      type: 'avatar',
                      width: 34,
                      height: 34,
                      src: userFace,
                    ),
                    Positioned.fill(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => callback?.call(),
                          splashColor: Theme.of(context)
                              .colorScheme
                              .primaryContainer
                              .withOpacity(0.3),
                          borderRadius: const BorderRadius.all(
                            Radius.circular(50),
                          ),
                        ),
                      ),
                    )
                  ],
                )
              : DefaultUser(callback: () => callback!()),
        ),
      ],
    );
  }
}

class DefaultUser extends StatelessWidget {
  const DefaultUser({super.key, this.callback});
  final Function? callback;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 38,
      height: 38,
      child: IconButton(
        style: ButtonStyle(
          padding: MaterialStateProperty.all(EdgeInsets.zero),
          backgroundColor: MaterialStateProperty.resolveWith((states) {
            return Theme.of(context).colorScheme.onInverseSurface;
          }),
        ),
        onPressed: () => callback?.call(),
        icon: Icon(
          Icons.person_rounded,
          size: 22,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

class CustomTabs extends StatefulWidget {
  const CustomTabs({super.key});

  @override
  State<CustomTabs> createState() => _CustomTabsState();
}

class _CustomTabsState extends State<CustomTabs> {
  final HomeController _homeController = Get.put(HomeController());

  void onTap(int index) {
    feedBack();
    if (_homeController.initialIndex.value == index) {
      _homeController.tabsCtrList[index]().animateToTop();
    }
    _homeController.initialIndex.value = index;
    _homeController.tabController.index = index;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      margin: const EdgeInsets.only(top: 4),
      child: Obx(
        () => ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 14.0),
          scrollDirection: Axis.horizontal,
          itemCount: _homeController.tabs.length,
          separatorBuilder: (BuildContext context, int index) {
            return const SizedBox(width: 10);
          },
          itemBuilder: (BuildContext context, int index) {
            String label = _homeController.tabs[index]['label'];
            return Obx(
              () => CustomChip(
                onTap: () => onTap(index),
                label: label,
                selected: index == _homeController.initialIndex.value,
              ),
            );
          },
        ),
      ),
    );
  }
}

class CustomChip extends StatelessWidget {
  final Function onTap;
  final String label;
  final bool selected;
  const CustomChip({
    super.key,
    required this.onTap,
    required this.label,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorTheme = Theme.of(context).colorScheme;
    final Color secondaryContainer = colorTheme.secondaryContainer;
    final TextStyle chipTextStyle = selected
        ? const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)
        : const TextStyle(fontSize: 13);
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    const VisualDensity visualDensity =
        VisualDensity(horizontal: -4.0, vertical: -2.0);
    return InputChip(
      side: BorderSide(
        color: selected
            ? colorScheme.onSecondaryContainer.withOpacity(0.2)
            : Colors.transparent,
      ),
      backgroundColor: secondaryContainer,
      selectedColor: secondaryContainer,
      color: MaterialStateProperty.resolveWith<Color>(
          (Set<MaterialState> states) => secondaryContainer.withAlpha(200)),
      padding: const EdgeInsets.fromLTRB(7, 1, 7, 1),
      label: Text(label, style: chipTextStyle),
      onPressed: () => onTap(),
      selected: selected,
      showCheckmark: false,
      visualDensity: visualDensity,
    );
  }
}

class SearchBar extends StatelessWidget {
  const SearchBar({
    Key? key,
    required this.ctr,
  }) : super(key: key);

  final HomeController? ctr;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Container(
        width: 250,
        height: 44,
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
        ),
        child: Material(
          color: colorScheme.onSecondaryContainer.withOpacity(0.05),
          child: InkWell(
            splashColor: colorScheme.primaryContainer.withOpacity(0.3),
            onTap: () => Get.toNamed(
              '/search',
              parameters: {'hintText': ctr!.defaultSearch.value},
            ),
            child: Row(
              children: [
                const SizedBox(width: 14),
                Icon(
                  Icons.search_outlined,
                  color: colorScheme.onSecondaryContainer,
                ),
                const SizedBox(width: 10),
                Obx(
                  () => Expanded(
                    child: Text(
                      ctr!.defaultSearch.value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: colorScheme.outline),
                    ),
                  ),
                ),
                const SizedBox(width: 15),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


class FavFolderItem extends StatelessWidget {
  const FavFolderItem({super.key, this.item, this.index});
  final FavFolderItemData? item;
  final int? index;
  @override
  Widget build(BuildContext context) {
    String heroTag = Utils.makeHeroTag(item!.fid);

    return Container(
      margin: EdgeInsets.only(left: index == 0 ? 20 : 0, right: 14),
      child: GestureDetector(
        onTap: () => Get.toNamed('/favDetail',
            arguments: item,
            parameters: {'mediaId': item!.id.toString(), 'heroTag': heroTag}),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 180,
              height: 110,
              margin: const EdgeInsets.only(bottom: 8),
              clipBehavior: Clip.hardEdge,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Theme.of(context).colorScheme.onInverseSurface,
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.onInverseSurface,
                    offset: const Offset(4, -12), // 阴影与容器的距离
                    blurRadius: 0.0, // 高斯的标准偏差与盒子的形状卷积。
                    spreadRadius: 0.0, // 在应用模糊之前，框应该膨胀的量。
                  ),
                ],
              ),
              child: LayoutBuilder(
                builder: (context, BoxConstraints box) {
                  return Hero(
                    tag: heroTag,
                    child: NetworkImgLayer(
                      src: item!.cover,
                      width: box.maxWidth,
                      height: box.maxHeight,
                    ),
                  );
                },
              ),
            ),
            Text(
              ' ${item!.title}',
              overflow: TextOverflow.fade,
              maxLines: 1,
            ),
            Text(
              ' 共${item!.mediaCount}条视频',
              style: Theme.of(context)
                  .textTheme
                  .labelSmall!
                  .copyWith(color: Theme.of(context).colorScheme.outline),
            )
          ],
        ),
      ),
    );
  }
}
