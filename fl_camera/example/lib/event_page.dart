import 'package:example/main.dart';
import 'package:fl_camera/fl_camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_waya/flutter_waya.dart';

class FlCameraEventPage extends StatefulWidget {
  const FlCameraEventPage({Key? key}) : super(key: key);

  @override
  State<FlCameraEventPage> createState() => _FlCameraEventPageState();
}

class _FlCameraEventPageState extends State<FlCameraEventPage> {
  String stateText = '未初始化';
  ValueNotifier<List<String>> text = ValueNotifier<List<String>>(<String>[]);
  FlCameraEvent? event;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text('FlCamera Event')),
        body: Column(children: [
          showText('state', stateText),
          Universal(
              width: double.infinity,
              wrapSpacing: 15,
              wrapAlignment: WrapAlignment.center,
              direction: Axis.horizontal,
              isWrap: true,
              children: <Widget>[
                ElevatedText(onPressed: start, text: '注册消息通道'),
                ElevatedText(
                    onPressed: () async {
                      final bool? state =
                          await event?.addListener((dynamic data) {
                        text.value.add(data.toString());
                      });
                      stateText = '添加监听 $state';
                      setState(() {});
                    },
                    text: '添加消息监听'),
                ElevatedText(onPressed: send, text: '发送消息'),
                ElevatedText(
                    onPressed: () {
                      final bool? state = event?.pause();
                      stateText = '暂停消息流监听 $state';
                      setState(() {});
                    },
                    text: '暂停消息流监听'),
                ElevatedText(
                    onPressed: () {
                      final bool? state = event?.resume();
                      stateText = '重新开始监听 $state';
                      setState(() {});
                    },
                    text: '重新开始监听'),
                ElevatedText(onPressed: stop, text: '销毁消息通道'),
              ]),
          const SizedBox(height: 20),
          ValueListenableBuilder<List<String>>(
              valueListenable: text,
              builder: (_, List<String> value, __) {
                return ListView.builder(
                    reverse: true,
                    itemCount: value.length,
                    itemBuilder: (BuildContext context, int index) =>
                        showText(index, value[index]));
              }).expandedNull
        ]));
  }

  Future<void> start() async {
    FlCameraController();
    event = FlCameraEvent();
    final bool eventState = await event!.initialize();
    if (eventState) {
      stateText = '初始化成功';
      setState(() {});
    }
  }

  Future<void> send() async {
    final bool? status = await event?.sendEvent('这条消息是从Flutter 传递到原生');
    stateText = (status ?? false) ? '发送成功' : '发送失败';
    setState(() {});
  }

  Future<void> stop() async {
    final bool? status = await event?.dispose();
    stateText = (status ?? false) ? '已销毁' : '销毁失败';
    text.value.clear();
    setState(() {});
  }
}
