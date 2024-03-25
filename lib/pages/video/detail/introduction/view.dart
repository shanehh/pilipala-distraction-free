import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:pilipala/common/constants.dart';
import 'package:pilipala/common/widgets/http_error.dart';
import 'package:pilipala/pages/video/detail/index.dart';
import 'package:pilipala/common/widgets/network_img_layer.dart';
import 'package:pilipala/common/widgets/stat/danmu.dart';
import 'package:pilipala/common/widgets/stat/view.dart';
import 'package:pilipala/models/video_detail_res.dart';
import 'package:pilipala/pages/video/detail/introduction/controller.dart';
import 'package:pilipala/pages/video/detail/widgets/ai_detail.dart';
import 'package:pilipala/utils/feed_back.dart';
import 'package:pilipala/utils/storage.dart';
import 'package:pilipala/utils/utils.dart';
import '../widgets/expandable_section.dart';
import 'widgets/action_item.dart';
import 'widgets/fav_panel.dart';
import 'widgets/intro_detail.dart';
import 'widgets/page.dart';
import 'widgets/season.dart';

class VideoIntroPanel extends StatefulWidget {
  final String bvid;
  final String? cid;

  const VideoIntroPanel({super.key, required this.bvid, this.cid});

  @override
  State<VideoIntroPanel> createState() => _VideoIntroPanelState();
}

class _VideoIntroPanelState extends State<VideoIntroPanel>
    with AutomaticKeepAliveClientMixin {
  late String heroTag;
  late VideoIntroController videoIntroController;
  VideoDetailData? videoDetail;
  late Future? _futureBuilderFuture;

  // 添加页面缓存
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();

    /// fix 全屏时参数丢失
    heroTag = Get.arguments['heroTag'];
    videoIntroController =
        Get.put(VideoIntroController(bvid: widget.bvid), tag: heroTag);
    _futureBuilderFuture = videoIntroController.queryVideoIntro();
    videoIntroController.videoDetail.listen((value) {
      videoDetail = value;
    });
  }

  @override
  void dispose() {
    videoIntroController.onClose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return FutureBuilder(
      future: _futureBuilderFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.data == null) {
            return const SliverToBoxAdapter(child: SizedBox());
          }
          if (snapshot.data['status']) {
            // 请求成功
            return Obx(
              () => VideoInfo(
                videoDetail: videoIntroController.videoDetail.value,
                heroTag: heroTag,
                bvid: widget.bvid,
              ),
            );
          } else {
            // 请求错误
            return HttpError(
              errMsg: snapshot.data['msg'],
              btnText: snapshot.data['code'] == -404 ||
                      snapshot.data['code'] == 62002
                  ? '返回上一页'
                  : null,
              fn: () => Get.back(),
            );
          }
        } else {
          return const SliverToBoxAdapter(
            child: SizedBox(
              height: 100,
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          );
        }
      },
    );
  }
}

class VideoInfo extends StatefulWidget {
  final VideoDetailData? videoDetail;
  final String? heroTag;
  final String bvid;

  const VideoInfo({
    Key? key,
    this.videoDetail,
    this.heroTag,
    required this.bvid,
  }) : super(key: key);

  @override
  State<VideoInfo> createState() => _VideoInfoState();
}

class _VideoInfoState extends State<VideoInfo> with TickerProviderStateMixin {
  late String heroTag;
  late final VideoIntroController videoIntroController;
  late final VideoDetailController videoDetailCtr;
  final Box<dynamic> localCache = GStrorage.localCache;
  final Box<dynamic> setting = GStrorage.setting;
  late double sheetHeight;
  late final dynamic owner;
  late final dynamic follower;
  late final dynamic followStatus;
  late int mid;
  late String memberHeroTag;
  late bool enableAi;
  bool isProcessing = false;
  RxBool isExpand = false.obs;
  void Function()? handleState(Future Function() action) {
    return isProcessing
        ? null
        : () async {
            setState(() => isProcessing = true);
            await action();
            setState(() => isProcessing = false);
          };
  }

  @override
  void initState() {
    super.initState();
    heroTag = widget.heroTag!;
    videoIntroController =
        Get.put(VideoIntroController(bvid: widget.bvid), tag: heroTag);
    videoDetailCtr = Get.find<VideoDetailController>(tag: heroTag);
    sheetHeight = localCache.get('sheetHeight');

    owner = widget.videoDetail!.owner;
    follower = Utils.numFormat(videoIntroController.userStat['follower']);
    followStatus = videoIntroController.followStatus;
    enableAi = setting.get(SettingBoxKey.enableAi, defaultValue: true);
  }

  // 收藏
  showFavBottomSheet({type = 'tap'}) {
    if (videoIntroController.userInfo == null) {
      SmartDialog.showToast('账号未登录');
      return;
    }
    final bool enableDragQuickFav =
        setting.get(SettingBoxKey.enableQuickFav, defaultValue: false);
    // 快速收藏 &
    // 点按 收藏至默认文件夹
    // 长按选择文件夹
    if (enableDragQuickFav) {
      if (type == 'tap') {
        if (!videoIntroController.hasFav.value) {
          videoIntroController.actionFavVideo(type: 'default');
        } else {
          showModalBottomSheet(
            context: context,
            useRootNavigator: true,
            isScrollControlled: true,
            builder: (BuildContext context) {
              return FavPanel(ctr: videoIntroController);
            },
          );
        }
      } else {
        showModalBottomSheet(
          context: context,
          useRootNavigator: true,
          isScrollControlled: true,
          builder: (BuildContext context) {
            return FavPanel(ctr: videoIntroController);
          },
        );
      }
    } else if (type != 'longPress') {
      showModalBottomSheet(
        context: context,
        useRootNavigator: true,
        isScrollControlled: true,
        builder: (BuildContext context) {
          return FavPanel(ctr: videoIntroController);
        },
      );
    }
  }

  // 视频介绍
  showIntroDetail() {
    feedBack();
    isExpand.value = !(isExpand.value);
  }

  // 用户主页
  onPushMember() {
    feedBack();
    mid = widget.videoDetail!.owner!.mid!;
    memberHeroTag = Utils.makeHeroTag(mid);
    String face = widget.videoDetail!.owner!.face!;
    Get.toNamed('/member?mid=$mid',
        arguments: {'face': face, 'heroTag': memberHeroTag});
  }

  // ai总结
  showAiBottomSheet() {
    showBottomSheet(
      context: context,
      enableDrag: true,
      builder: (BuildContext context) {
        return AiDetail(modelResult: videoIntroController.modelResult);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData t = Theme.of(context);
    final Color outline = t.colorScheme.outline;
    return SliverPadding(
      padding: const EdgeInsets.only(
        left: StyleString.safeSpace,
        right: StyleString.safeSpace,
        top: 16,
      ),
      sliver: SliverToBoxAdapter(
          child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => showIntroDetail(),
            child: Text(
              widget.videoDetail!.title!,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Stack(
            children: [
              GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () => showIntroDetail(),
                child: Padding(
                  padding: const EdgeInsets.only(top: 7, bottom: 6),
                  child: Row(
                    children: [
                      StatView(
                        theme: 'gray',
                        view: widget.videoDetail!.stat!.view,
                        size: 'medium',
                      ),
                      const SizedBox(width: 10),
                      StatDanMu(
                        theme: 'gray',
                        danmu: widget.videoDetail!.stat!.danmaku,
                        size: 'medium',
                      ),
                      const SizedBox(width: 10),
                      Text(
                        Utils.dateFormat(widget.videoDetail!.pubdate,
                            formatType: 'detail'),
                        style: TextStyle(
                          fontSize: 12,
                          color: t.colorScheme.outline,
                        ),
                      ),
                      const SizedBox(width: 10),
                      if (videoIntroController.isShowOnlineTotal)
                        Obx(
                          () => Text(
                            '${videoIntroController.total.value}人在看',
                            style: TextStyle(
                              fontSize: 12,
                              color: t.colorScheme.outline,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              if (false)
                Positioned(
                  right: 10,
                  top: 6,
                  child: GestureDetector(
                    onTap: () async {
                      final res = await videoIntroController.aiConclusion();
                      if (res['status']) {
                        showAiBottomSheet();
                      }
                    },
                    child: Image.asset('assets/images/ai.png', height: 22),
                  ),
                )
            ],
          ),

          /// 视频简介
          Obx(
            () => ExpandedSection(
              expand: isExpand.value,
              begin: 0,
              end: 1,
              child: IntroDetail(videoDetail: widget.videoDetail!),
            ),
          ),

          /// 点赞收藏转发
          actionGrid(context, videoIntroController),
          // 合集
          if (widget.videoDetail!.ugcSeason != null) ...[
            Obx(
              () => SeasonPanel(
                ugcSeason: widget.videoDetail!.ugcSeason!,
                cid: videoIntroController.lastPlayCid.value != 0
                    ? videoIntroController.lastPlayCid.value
                    : widget.videoDetail!.pages!.first.cid,
                sheetHeight: sheetHeight,
                changeFuc: (bvid, cid, aid) =>
                    videoIntroController.changeSeasonOrbangu(bvid, cid, aid),
              ),
            )
          ],
          if (widget.videoDetail!.pages != null &&
              widget.videoDetail!.pages!.length > 1) ...[
            Obx(() => PagesPanel(
                  pages: widget.videoDetail!.pages!,
                  cid: videoIntroController.lastPlayCid.value,
                  sheetHeight: sheetHeight,
                  changeFuc: (cid) => videoIntroController.changeSeasonOrbangu(
                      videoIntroController.bvid, cid, null),
                ))
          ],
          GestureDetector(
            onTap: onPushMember,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
              child: Row(
                children: [
                  NetworkImgLayer(
                    type: 'avatar',
                    src: widget.videoDetail!.owner!.face,
                    width: 34,
                    height: 34,
                    fadeInDuration: Duration.zero,
                    fadeOutDuration: Duration.zero,
                  ),
                  const SizedBox(width: 10),
                  Text(owner.name, style: const TextStyle(fontSize: 13)),
                  const SizedBox(width: 6),
                  Text(
                    follower,
                    style: TextStyle(
                      fontSize: t.textTheme.labelSmall!.fontSize,
                      color: outline,
                    ),
                  ),
                  const Spacer(),
                  Obx(() => AnimatedOpacity(
                        opacity:
                            videoIntroController.followStatus.isEmpty ? 0 : 1,
                        duration: const Duration(milliseconds: 50),
                        child: SizedBox(
                          height: 32,
                          child: Obx(
                            () => videoIntroController.followStatus.isNotEmpty
                                ? TextButton(
                                    onPressed:
                                        videoIntroController.actionRelationMod,
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.only(
                                          left: 8, right: 8),
                                      foregroundColor:
                                          followStatus['attribute'] != 0
                                              ? outline
                                              : t.colorScheme.onPrimary,
                                      backgroundColor:
                                          followStatus['attribute'] != 0
                                              ? t.colorScheme.onInverseSurface
                                              : t.colorScheme
                                                  .primary, // 设置按钮背景色
                                    ),
                                    child: Text(
                                      followStatus['attribute'] != 0
                                          ? '已关注'
                                          : '关注',
                                      style: TextStyle(
                                          fontSize: t
                                              .textTheme.labelMedium!.fontSize),
                                    ),
                                  )
                                : ElevatedButton(
                                    onPressed:
                                        videoIntroController.actionRelationMod,
                                    child: const Text('关注'),
                                  ),
                          ),
                        ),
                      )),
                ],
              ),
            ),
          ),
        ],
      )),
    );
  }

  Widget actionGrid(BuildContext context, videoIntroController) {
    return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
      return Container(
        margin: const EdgeInsets.only(top: 6, bottom: 4),
        height: constraints.maxWidth / 5 * 0.8,
        child: GridView.count(
          physics: const NeverScrollableScrollPhysics(),
          primary: false,
          padding: EdgeInsets.zero,
          crossAxisCount: 5,
          childAspectRatio: 1.25,
          children: <Widget>[
            Obx(
              () => ActionItem(
                  icon: const Icon(FontAwesomeIcons.thumbsUp),
                  selectIcon: const Icon(FontAwesomeIcons.solidThumbsUp),
                  onTap: handleState(videoIntroController.actionLikeVideo),
                  selectStatus: videoIntroController.hasLike.value,
                  text: widget.videoDetail!.stat!.like!.toString()),
            ),
            Obx(
              () => ActionItem(
                icon: const Icon(FontAwesomeIcons.b),
                selectIcon: const Icon(FontAwesomeIcons.b),
                onTap: handleState(videoIntroController.actionCoinVideo),
                selectStatus: videoIntroController.hasCoin.value,
                text: widget.videoDetail!.stat!.coin!.toString(),
              ),
            ),
            Obx(
              () => ActionItem(
                icon: const Icon(FontAwesomeIcons.star),
                selectIcon: const Icon(FontAwesomeIcons.solidStar),
                onTap: () => showFavBottomSheet(),
                onLongPress: () => showFavBottomSheet(type: 'longPress'),
                selectStatus: videoIntroController.hasFav.value,
                text: widget.videoDetail!.stat!.favorite!.toString(),
              ),
            ),
            ActionItem(
              icon: const Icon(FontAwesomeIcons.clock),
              onTap: () => videoIntroController.actionShareVideo(),
              selectStatus: false,
              text: '稍后看',
            ),
            ActionItem(
              icon: const Icon(FontAwesomeIcons.shareFromSquare),
              onTap: () => videoIntroController.actionShareVideo(),
              selectStatus: false,
              text: '分享',
            ),
          ],
        ),
      );
    });
  }
}
