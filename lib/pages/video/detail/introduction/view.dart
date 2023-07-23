import 'package:flutter/gestures.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:pilipala/common/widgets/http_error.dart';
import 'package:pilipala/pages/fav/index.dart';
import 'package:pilipala/pages/video/detail/index.dart';
import 'package:pilipala/common/widgets/network_img_layer.dart';
import 'package:pilipala/common/widgets/stat/danmu.dart';
import 'package:pilipala/common/widgets/stat/view.dart';
import 'package:pilipala/models/video_detail_res.dart';
import 'package:pilipala/pages/video/detail/introduction/controller.dart';
import 'package:pilipala/utils/storage.dart';
import 'package:pilipala/utils/utils.dart';

import 'widgets/action_row_item.dart';
import 'widgets/fav_panel.dart';
import 'widgets/intro_detail.dart';
import 'widgets/season.dart';

class VideoIntroPanel extends StatefulWidget {
  const VideoIntroPanel({Key? key}) : super(key: key);

  @override
  State<VideoIntroPanel> createState() => _VideoIntroPanelState();
}

class _VideoIntroPanelState extends State<VideoIntroPanel>
    with AutomaticKeepAliveClientMixin {
  final VideoIntroController videoIntroController =
      Get.put(VideoIntroController(), tag: Get.arguments['heroTag']);
  VideoDetailData? videoDetail;

  // 添加页面缓存
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
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
    return FutureBuilder(
      future: videoIntroController.queryVideoIntro(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.data['status']) {
            // 请求成功
            // return _buildView(context, false, videoDetail);
            return VideoInfo(loadingStatus: false, videoDetail: videoDetail);
          } else {
            // 请求错误
            return HttpError(
              errMsg: snapshot.data['msg'],
              fn: () => Get.back(),
            );
          }
        } else {
          return VideoInfo(loadingStatus: true, videoDetail: videoDetail);
        }
      },
    );
  }
}

class VideoInfo extends StatefulWidget {
  bool loadingStatus = false;
  VideoDetailData? videoDetail;

  VideoInfo({Key? key, required this.loadingStatus, this.videoDetail})
      : super(key: key);

  @override
  State<VideoInfo> createState() => _VideoInfoState();
}

class _VideoInfoState extends State<VideoInfo> with TickerProviderStateMixin {
  Map videoItem = Get.put(VideoIntroController()).videoItem!;
  final VideoIntroController videoIntroController =
      Get.put(VideoIntroController(), tag: Get.arguments['heroTag']);
  bool isExpand = false;

  /// 手动控制动画的控制器
  late AnimationController? _manualController;

  /// 手动控制
  late Animation<double>? _manualAnimation;

  final FavController _favController = Get.put(FavController());

  late VideoDetailController? videoDetailCtr;
  Box localCache = GStrorage.localCache;
  late double sheetHeight;

  @override
  void initState() {
    super.initState();

    /// 不设置重复，使用代码控制进度，动画时间1秒
    _manualController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _manualAnimation =
        Tween<double>(begin: 0.5, end: 1.5).animate(_manualController!);
    videoDetailCtr =
        Get.find<VideoDetailController>(tag: Get.arguments['heroTag']);
    sheetHeight = localCache.get('sheetHeight');
  }

  showFavBottomSheet() {
    if (videoIntroController.user.get(UserBoxKey.userMid) == null) {
      SmartDialog.showToast('账号未登录');
      return;
    }
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      builder: (context) {
        return FavPanel(ctr: videoIntroController);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.only(left: 12, right: 12, top: 15),
      sliver: SliverToBoxAdapter(
        child: !widget.loadingStatus || videoItem.isNotEmpty
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          !widget.loadingStatus
                              ? widget.videoDetail!.title
                              : videoItem['title'],
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium!
                              .copyWith(
                                  letterSpacing: 0.5,
                                  fontWeight: FontWeight.bold),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 20),
                      SizedBox(
                        width: 34,
                        height: 34,
                        child: IconButton(
                          style: ButtonStyle(
                            padding: MaterialStateProperty.all(EdgeInsets.zero),
                            backgroundColor:
                                MaterialStateProperty.resolveWith((states) {
                              return Theme.of(context)
                                  .highlightColor
                                  .withOpacity(0.2);
                            }),
                          ),
                          onPressed: () {
                            showBottomSheet(
                                context: context,
                                enableDrag: true,
                                builder: (BuildContext context) {
                                  return IntroDetail(
                                      videoDetail: widget.videoDetail!);
                                });
                          },
                          icon: const Icon(Icons.more_horiz),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const SizedBox(width: 2),
                      StatView(
                        theme: 'black',
                        view: !widget.loadingStatus
                            ? widget.videoDetail!.stat!.view
                            : videoItem['stat'].view,
                        size: 'medium',
                      ),
                      const SizedBox(width: 10),
                      StatDanMu(
                        theme: 'black',
                        danmu: !widget.loadingStatus
                            ? widget.videoDetail!.stat!.danmaku
                            : videoItem['stat'].danmaku,
                        size: 'medium',
                      ),
                      const SizedBox(width: 10),
                      Text(
                        Utils.dateFormat(
                            !widget.loadingStatus
                                ? widget.videoDetail!.pubdate
                                : videoItem['pubdate'],
                            formatType: 'detail'),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                  // 点赞收藏转发
                  Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: actionRow(
                        context,
                        videoIntroController,
                        videoDetailCtr,
                      ),
                    ),
                  ),
                  // 合集
                  if (!widget.loadingStatus &&
                      widget.videoDetail!.ugcSeason != null) ...[
                    seasonPanel(widget.videoDetail!.ugcSeason!,
                        widget.videoDetail!.pages!.first.cid, sheetHeight)
                  ],
                  Divider(
                    height: 26,
                    color: Theme.of(context).dividerColor.withOpacity(0.1),
                  ),
                  GestureDetector(
                    onTap: () {
                      int mid = !widget.loadingStatus
                          ? widget.videoDetail!.owner!.mid
                          : videoItem['owner'].mid;
                      String face = !widget.loadingStatus
                          ? widget.videoDetail!.owner!.face
                          : videoItem['owner'].face;
                      Get.toNamed('/member?mid=$mid', arguments: {
                        'face': face,
                        'heroTag': (mid + 99).toString()
                      });
                    },
                    child: Row(
                      children: [
                        NetworkImgLayer(
                          type: 'avatar',
                          src: !widget.loadingStatus
                              ? widget.videoDetail!.owner!.face
                              : videoItem['owner'].face,
                          width: 34,
                          height: 34,
                          fadeInDuration: Duration.zero,
                          fadeOutDuration: Duration.zero,
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(!widget.loadingStatus
                                ? widget.videoDetail!.owner!.name
                                : videoItem['owner'].name),
                            // const SizedBox(width: 10),
                            Text(
                              widget.loadingStatus
                                  ? '- 粉丝'
                                  : '${Utils.numFormat(videoIntroController.userStat['follower'])}粉丝',
                              style: TextStyle(
                                  fontSize: Theme.of(context)
                                      .textTheme
                                      .labelSmall!
                                      .fontSize,
                                  color: Theme.of(context).colorScheme.outline),
                            ),
                          ],
                        ),
                        const Spacer(),
                        AnimatedOpacity(
                          opacity: widget.loadingStatus ? 0 : 1,
                          duration: const Duration(milliseconds: 150),
                          child: SizedBox(
                            height: 34,
                            child: Obx(
                              () => videoIntroController.followStatus.isNotEmpty
                                  ? ElevatedButton(
                                      onPressed: () => videoIntroController
                                          .actionRelationMod(),
                                      child: Text(videoIntroController
                                                  .followStatus['attribute'] ==
                                              0
                                          ? '关注'
                                          : '已关注'),
                                    )
                                  : ElevatedButton(
                                      onPressed: () => videoIntroController
                                          .actionRelationMod(),
                                      child: const Text('关注'),
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Divider(
                    height: 12,
                    color: Theme.of(context).dividerColor.withOpacity(0.1),
                  ),
                ],
              )
            : const SizedBox(
                height: 100,
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              ),
      ),
    );
  }

  Widget actionRow(BuildContext context, videoIntroController, videoDetailCtr) {
    return Row(children: [
      Obx(
        () => ActionRowItem(
          icon: const Icon(FontAwesomeIcons.thumbsUp),
          onTap: () => videoIntroController.actionLikeVideo(),
          selectStatus: videoIntroController.hasLike.value,
          loadingStatus: widget.loadingStatus,
          text: !widget.loadingStatus
              ? widget.videoDetail!.stat!.like!.toString()
              : '-',
        ),
      ),
      const SizedBox(width: 8),
      Obx(
        () => ActionRowItem(
          icon: const Icon(FontAwesomeIcons.b),
          onTap: () => videoIntroController.actionCoinVideo(),
          selectStatus: videoIntroController.hasCoin.value,
          loadingStatus: widget.loadingStatus,
          text: !widget.loadingStatus
              ? widget.videoDetail!.stat!.coin!.toString()
              : '-',
        ),
      ),
      const SizedBox(width: 8),
      Obx(
        () => ActionRowItem(
          icon: const Icon(FontAwesomeIcons.heart),
          onTap: () => showFavBottomSheet(),
          selectStatus: videoIntroController.hasFav.value,
          loadingStatus: widget.loadingStatus,
          text: !widget.loadingStatus
              ? widget.videoDetail!.stat!.favorite!.toString()
              : '-',
        ),
      ),
      const SizedBox(width: 8),
      ActionRowItem(
        icon: const Icon(FontAwesomeIcons.comment),
        onTap: () {
          videoDetailCtr.tabCtr.animateTo(1);
        },
        selectStatus: false,
        loadingStatus: widget.loadingStatus,
        text: !widget.loadingStatus
            ? widget.videoDetail!.stat!.reply!.toString()
            : '-',
      ),
      const SizedBox(width: 8),
      ActionRowItem(
        icon: const Icon(FontAwesomeIcons.share),
        onTap: () => videoIntroController.actionShareVideo(),
        selectStatus: false,
        loadingStatus: widget.loadingStatus,
        text: !widget.loadingStatus
            ? widget.videoDetail!.stat!.share!.toString()
            : '-',
      ),
    ]);
  }

  InlineSpan buildContent(BuildContext context, content) {
    String desc = content.desc;
    List descV2 = content.descV2;
    // type
    // 1 普通文本
    // 2 @用户
    List<InlineSpan> spanChilds = [];
    if (descV2.isNotEmpty) {
      for (var i = 0; i < descV2.length; i++) {
        if (descV2[i].type == 1) {
          spanChilds.add(TextSpan(text: descV2[i].rawText));
        } else if (descV2[i].type == 2) {
          spanChilds.add(
            TextSpan(
              text: '@${descV2[i].rawText}',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  String heroTag = Utils.makeHeroTag(descV2[i].bizId);
                  Get.toNamed(
                    '/member?mid=${descV2[i].bizId}',
                    arguments: {'face': '', 'heroTag': heroTag},
                  );
                },
            ),
          );
        }
      }
    } else {
      spanChilds.add(TextSpan(text: desc));
    }
    return TextSpan(children: spanChilds);
  }
}
