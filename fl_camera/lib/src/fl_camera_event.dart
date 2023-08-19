part of '../fl_camera.dart';

typedef CameraEventListen = void Function(dynamic data);

class FlCameraEvent {
  factory FlCameraEvent() => _singleton ??= FlCameraEvent._();

  FlCameraEvent._();

  static FlCameraEvent? _singleton;

  /// 订阅流
  /// Subscription flow
  StreamSubscription<dynamic>? _streamSubscription;

  /// 创建流
  /// Create stream
  Stream<dynamic>? _stream;

  MethodChannel? _channel;

  /// 消息通道
  /// Message channel
  EventChannel? _eventChannel;

  bool get isPaused =>
      _streamSubscription != null && _streamSubscription!.isPaused;

  /// 第一步 先设置 channel
  /// The first step is to set the channel
  void setMethodChannel(MethodChannel channel) {
    _channel = channel;
  }

  /// 第二步 初始化消息通道
  /// Step 2: initialize the message channel
  Future<bool> initialize() async {
    assert(_channel != null, 'You must call setMethodChannel() first');
    if (!_supportPlatform || _channel == null) return false;
    bool? state = await _channel!.invokeMethod<bool?>('startEvent');
    if (state == true && _eventChannel == null) {
      _eventChannel = const EventChannel('fl.camera.event');
      _stream = _eventChannel!.receiveBroadcastStream();
    }
    return state == true && _eventChannel != null && _stream != null;
  }

  /// 第三步 添加消息流监听
  /// Step 3: add message flow listening
  Future<bool> addListener(CameraEventListen eventListen) async {
    assert(_channel != null, 'You must call setMethodChannel() first');
    if (!_supportPlatform || _channel == null) return false;
    if (_eventChannel != null && _stream != null) {
      if (_streamSubscription != null) {
        await _streamSubscription!.cancel();
        _streamSubscription = null;
      }
      try {
        _streamSubscription = _stream!.listen(eventListen);
        return true;
      } catch (e) {
        debugPrint(e.toString());
        return false;
      }
    }
    return false;
  }

  /// 调用原生方法 发送消息
  /// Call native methods to send messages
  Future<bool> sendEvent(dynamic arguments) async {
    assert(_channel != null, 'You must call setMethodChannel() first');
    if (!_supportPlatform ||
        _eventChannel == null ||
        _streamSubscription == null ||
        _channel == null ||
        _streamSubscription!.isPaused) return false;
    final bool? state =
        await _channel!.invokeMethod<bool?>('sendEvent', arguments);
    return state ?? false;
  }

  /// 暂停消息流监听
  /// Pause message flow listening
  bool pause() {
    assert(_channel != null, 'You must call setMethodChannel() first');
    if (!_supportPlatform || _channel == null) return false;
    if (_streamSubscription != null && !_streamSubscription!.isPaused) {
      _streamSubscription!.pause();
      return true;
    }
    return false;
  }

  /// 重新开始监听
  /// Restart listening
  bool resume() {
    assert(_channel != null, 'You must call setMethodChannel() first');
    if (!_supportPlatform || _channel == null) return false;
    if (_streamSubscription != null && _streamSubscription!.isPaused) {
      _streamSubscription!.resume();
      return true;
    }
    return false;
  }

  /// 关闭并销毁消息通道
  /// Close and destroy the message channel
  Future<bool> dispose() async {
    assert(_channel != null, 'You must call setMethodChannel() first');
    if (!_supportPlatform || _channel == null) return false;
    await _streamSubscription?.cancel();
    _streamSubscription = null;
    _stream = null;
    _eventChannel = null;
    final bool? state = await _channel!.invokeMethod<bool>('stopEvent');
    return state ?? false;
  }
}
