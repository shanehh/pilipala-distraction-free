import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:pilipala/common/constants.dart';
import 'package:pilipala/common/widgets/badge.dart';
import 'package:pilipala/common/widgets/network_img_layer.dart';
import 'package:pilipala/http/search.dart';
import 'package:pilipala/http/user.dart';
import 'package:pilipala/http/video.dart';
import 'package:pilipala/models/bangumi/info.dart';
import 'package:pilipala/models/common/business_type.dart';
import 'package:pilipala/models/common/search_type.dart';
import 'package:pilipala/models/live/item.dart';
import 'package:pilipala/pages/history_search/index.dart';
import 'package:pilipala/utils/feed_back.dart';
import 'package:pilipala/utils/id_utils.dart';
import 'package:pilipala/utils/utils.dart';

class HistoryItem extends StatelessWidget {
  final dynamic videoItem;
  const HistoryItem({
    super.key,
    required this.videoItem,
  });

  @override
  Widget build(BuildContext context) {
    int aid = videoItem.history.oid;
    String bvid = videoItem.history.bvid ?? IdUtils.av2bv(aid);
    String heroTag = Utils.makeHeroTag(aid);
    return InkWell(
      onTap: () async {
        int cid = videoItem.history.cid ??
            // videoItem.history.oid ??
            await SearchHttp.ab2c(aid: aid, bvid: bvid);
        Get.toNamed('/video?bvid=$bvid&cid=$cid',
            arguments: {'heroTag': heroTag, 'pic': videoItem.cover});
      },
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                StyleString.safeSpace, 5, StyleString.safeSpace, 5),
            child: LayoutBuilder(
              builder: (context, boxConstraints) {
                double width =
                    (boxConstraints.maxWidth - StyleString.cardSpace * 6) / 2;
                return SizedBox(
                  width: MediaQuery.of(context).size.width,
                  height: 100,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Stack(
                        children: [
                          AspectRatio(
                            aspectRatio: StyleString.aspectRatio,
                            child: LayoutBuilder(
                              builder: (context, boxConstraints) {
                                double maxWidth = boxConstraints.maxWidth;
                                double maxHeight = boxConstraints.maxHeight;
                                return Stack(
                                  children: [
                                    Hero(
                                      tag: heroTag,
                                      child: NetworkImgLayer(
                                        src: (videoItem.cover != ''
                                            ? videoItem.cover
                                            : videoItem.covers.first),
                                        width: maxWidth,
                                        height: maxHeight,
                                      ),
                                    ),
                                    if (!BusinessType
                                        .hiddenDurationType.hiddenDurationType
                                        .contains(videoItem.history.business))
                                      PBadge(
                                        text: videoItem.progress == -1
                                            ? '已看完'
                                            : '${Utils.timeFormat(videoItem.progress!)}/${Utils.timeFormat(videoItem.duration!)}',
                                        right: 6.0,
                                        bottom: 6.0,
                                        type: 'gray',
                                      ),
                                    // 右上角
                                    if (BusinessType.showBadge.showBadge
                                            .contains(
                                                videoItem.history.business) ||
                                        videoItem.history.business ==
                                            BusinessType.live.type)
                                      PBadge(
                                        text: videoItem.badge,
                                        top: 6.0,
                                        right: 6.0,
                                        bottom: null,
                                        left: null,
                                      ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                      VideoContent(videoItem: videoItem)
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class VideoContent extends StatelessWidget {
  final dynamic videoItem;
  const VideoContent({super.key, required this.videoItem});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 2, 6, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              videoItem.title,
              textAlign: TextAlign.start,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                letterSpacing: 0.3,
              ),
              maxLines: videoItem.videos > 1 ? 1 : 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (videoItem.showTitle != null) ...[
              const SizedBox(height: 2),
              Text(
                videoItem.showTitle,
                textAlign: TextAlign.start,
                style: TextStyle(
                    fontSize: Theme.of(context).textTheme.labelMedium!.fontSize,
                    fontWeight: FontWeight.w400,
                    color: Theme.of(context).colorScheme.outline),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const Spacer(),
            if (videoItem.authorName != '')
              Row(
                children: [
                  Text(
                    videoItem.authorName,
                    style: TextStyle(
                      fontSize:
                          Theme.of(context).textTheme.labelMedium!.fontSize,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                ],
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  Utils.dateFormat(videoItem.viewAt!),
                  style: TextStyle(
                      fontSize:
                          Theme.of(context).textTheme.labelMedium!.fontSize,
                      color: Theme.of(context).colorScheme.outline),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
