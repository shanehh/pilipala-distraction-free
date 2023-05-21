import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:pilipala/http/video.dart';
import 'package:pilipala/models/common/reply_type.dart';

class VideoReplyNewDialog extends StatefulWidget {
  int? oid;
  int? root;
  String? replyLevel;
  int? parent;

  VideoReplyNewDialog({
    this.oid,
    this.root,
    this.replyLevel,
    this.parent,
  });

  @override
  State<VideoReplyNewDialog> createState() => _VideoReplyNewDialogState();
}

class _VideoReplyNewDialogState extends State<VideoReplyNewDialog>
    with WidgetsBindingObserver {
  final TextEditingController _replyContentController = TextEditingController();
  final FocusNode replyContentFocusNode = FocusNode();
  final GlobalKey _formKey = GlobalKey<FormState>();
  double _keyboardHeight = 0.0; // 键盘高度
  final _debouncer = Debouncer(milliseconds: 100); // 设置延迟时间
  bool ableClean = false;
  bool autoFocus = false;
  Timer? timer;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    // 监听输入框聚焦
    // replyContentFocusNode.addListener(_onFocus);
    _replyContentController.addListener(_printLatestValue);
    // 界面观察者 必须
    WidgetsBinding.instance.addObserver(this);
    // 自动聚焦
    _autoFocus();
  }

  _autoFocus() async {
    await Future.delayed(const Duration(milliseconds: 300));
    FocusScope.of(context).requestFocus(replyContentFocusNode);
  }

  _printLatestValue() {
    setState(() {
      ableClean = _replyContentController.text != '';
    });
  }

  Future submitReplyAdd() async {
    String message = _replyContentController.text;
    print(widget.oid);
    var result = await VideoHttp.replyAdd(
      type: ReplyType.video,
      oid: widget.oid!,
      root: widget.root!,
      parent: widget.parent!,
      message: message,
    );
    if (result['status']) {
      SmartDialog.showToast(result['data']['success_toast']);
    } else {
    }
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 键盘高度
      final viewInsets = EdgeInsets.fromWindowPadding(
          WidgetsBinding.instance.window.viewInsets,
          WidgetsBinding.instance.window.devicePixelRatio);
      _debouncer.run(() {
        if (mounted) {
          setState(() {
            _keyboardHeight =
                _keyboardHeight == 0.0 ? viewInsets.bottom : _keyboardHeight;
          });
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height - MediaQuery.of(context).size.width * 9 / 16 - 48,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
          color: Theme.of(context).colorScheme.background),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 55,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(width: 20),
                Text('发表评论', style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                IconButton(
                  onPressed: () => Get.back(),
                  icon: const Icon(Icons.close),
                ),
                const SizedBox(width: 12),
              ],
            ),
          ),
          Divider(
            height: 1,
            color: Theme.of(context).dividerColor.withOpacity(0.1),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.only(
                  top: 12, right: 15, left: 15, bottom: 10),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.background,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: TextField(
                  controller: _replyContentController,
                  minLines: 1,
                  maxLines: null,
                  autofocus: false,
                  focusNode: replyContentFocusNode,
                  decoration: const InputDecoration(
                      hintText: "输入回复内容", border: InputBorder.none),
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            ),
          ),
          Divider(
            height: 1,
            color: Theme.of(context).dividerColor.withOpacity(0.1),
          ),
          Container(
            height: 52,
            padding: const EdgeInsets.only(left: 12, right: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(
                  width: 36,
                  height: 36,
                  child: IconButton(
                      onPressed: () {
                        FocusScope.of(context)
                            .requestFocus(replyContentFocusNode);
                      },
                      icon: Icon(Icons.keyboard,
                          size: 22,
                          color: Theme.of(context).colorScheme.onBackground),
                      highlightColor:
                          Theme.of(context).colorScheme.onInverseSurface,
                      style: ButtonStyle(
                        padding: MaterialStateProperty.all(EdgeInsets.zero),
                        backgroundColor:
                            MaterialStateProperty.resolveWith((states) {
                          return Theme.of(context).highlightColor;
                        }),
                      )),
                ),
                const Spacer(),
                TextButton(onPressed: () => submitReplyAdd(), child: const Text('发送'))
              ],
            ),
          ),
          AnimatedSize(
            curve: Curves.easeInOut,
            duration: const Duration(milliseconds: 500),
            child: SizedBox(
              width: double.infinity,
              height: _keyboardHeight,
            ),
          ),
        ],
      ),
    );
  }
}

typedef void DebounceCallback();

class Debouncer {
  DebounceCallback? callback;
  final int? milliseconds;
  Timer? _timer;

  Debouncer({this.milliseconds});

  run(DebounceCallback callback) {
    if (_timer != null) {
      _timer!.cancel();
    }
    _timer = Timer(Duration(milliseconds: milliseconds!), () {
      callback();
    });
  }
}