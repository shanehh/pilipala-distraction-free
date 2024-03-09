import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pilipala/models/video_detail_res.dart';
import 'package:pilipala/pages/video/detail/index.dart';
import 'package:pilipala/utils/id_utils.dart';

class PagesPanel extends StatefulWidget {
  const PagesPanel({
    super.key,
    required this.pages,
    this.cid,
    this.sheetHeight,
    this.changeFuc,
  });
  final List<Part> pages;
  final int? cid;
  final double? sheetHeight;
  final Function? changeFuc;

  @override
  State<PagesPanel> createState() => _PagesPanelState();
}

class _PagesPanelState extends State<PagesPanel> {
  late List<Part> episodes;
  late int cid;
  late int currentIndex;
  final String heroTag = Get.arguments['heroTag'];
  late VideoDetailController _videoDetailController;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    cid = widget.cid!;
    episodes = widget.pages;
    _videoDetailController = Get.find<VideoDetailController>(tag: heroTag);
    currentIndex = episodes.indexWhere((Part e) => e.cid == cid);
    _videoDetailController.cid.listen((int p0) {
      cid = p0;
      setState(() {});
      currentIndex = episodes.indexWhere((Part e) => e.cid == cid);
    });
  }

  void changeFucCall(item, i) async {
    await widget.changeFuc!(
      IdUtils.av2bv(item.aid),
      item.cid,
      item.aid,
    );
    currentIndex = i;
    Get.back();
    setState(() {});
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Widget buildEpisodeListItem(
    Part episode,
    int index,
    bool isCurrentIndex,
  ) {
    Color primary = Theme.of(context).colorScheme.primary;
    return ListTile(
      onTap: () {
        changeFucCall(episode, index);
        Get.back();
      },
      dense: false,
      leading: isCurrentIndex
          ? Image.asset(
              'assets/images/live.gif',
              color: primary,
              height: 12,
            )
          : null,
      title: Text(
        episode.pagePart!,
        style: TextStyle(
          fontSize: 14,
          color: isCurrentIndex
              ? primary
              : Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(top: 10, bottom: 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('视频选集 '),
              Expanded(
                child: Text(
                  ' 正在播放：${widget.pages[currentIndex].pagePart}',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 34,
                child: TextButton(
                  style: ButtonStyle(
                    padding: MaterialStateProperty.all(EdgeInsets.zero),
                  ),
                  onPressed: () {
                    showBottomSheet(
                      context: context,
                      builder: (BuildContext context) {
                        return StatefulBuilder(builder:
                            (BuildContext context, StateSetter setState) {
                          WidgetsBinding.instance
                              .addPostFrameCallback((_) async {
                            await Future.delayed(
                                const Duration(milliseconds: 200));
                            _scrollController.jumpTo(currentIndex * 56);
                          });
                          return Container(
                            height: widget.sheetHeight,
                            color: Theme.of(context).colorScheme.background,
                            child: Column(
                              children: [
                                Container(
                                  height: 45,
                                  padding: const EdgeInsets.only(
                                      left: 14, right: 14),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '合集（${episodes.length}）',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium,
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.close),
                                        onPressed: () => Navigator.pop(context),
                                      ),
                                    ],
                                  ),
                                ),
                                Divider(
                                  height: 1,
                                  color: Theme.of(context)
                                      .dividerColor
                                      .withOpacity(0.1),
                                ),
                                Expanded(
                                  child: Material(
                                    child: ListView.builder(
                                      controller: _scrollController,
                                      itemCount: episodes.length + 1,
                                      itemBuilder:
                                          (BuildContext context, int index) {
                                        bool isLastItem =
                                            index == episodes.length;
                                        bool isCurrentIndex =
                                            currentIndex == index;
                                        return isLastItem
                                            ? SizedBox(
                                                height: MediaQuery.of(context)
                                                        .padding
                                                        .bottom +
                                                    20,
                                              )
                                            : buildEpisodeListItem(
                                                episodes[index],
                                                index,
                                                isCurrentIndex,
                                              );
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        });
                      },
                    );
                  },
                  child: Text(
                    '共${widget.pages.length}集',
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          height: 35,
          margin: const EdgeInsets.only(bottom: 8),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: widget.pages.length,
            itemExtent: 150,
            itemBuilder: (BuildContext context, int i) {
              bool isCurrentIndex = currentIndex == i;
              return Container(
                width: 150,
                margin: const EdgeInsets.only(right: 10),
                child: Material(
                  color: Theme.of(context).colorScheme.onInverseSurface,
                  borderRadius: BorderRadius.circular(6),
                  clipBehavior: Clip.hardEdge,
                  child: InkWell(
                    onTap: () => changeFucCall(widget.pages[i], i),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 8),
                      child: Row(
                        children: <Widget>[
                          if (isCurrentIndex) ...<Widget>[
                            Image.asset(
                              'assets/images/live.gif',
                              color: Theme.of(context).colorScheme.primary,
                              height: 12,
                            ),
                            const SizedBox(width: 6)
                          ],
                          Expanded(
                              child: Text(
                            widget.pages[i].pagePart!,
                            maxLines: 1,
                            style: TextStyle(
                                fontSize: 13,
                                color: isCurrentIndex
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).colorScheme.onSurface),
                            overflow: TextOverflow.ellipsis,
                          ))
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        )
      ],
    );
  }
}
