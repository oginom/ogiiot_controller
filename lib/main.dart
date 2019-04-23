import 'package:mqtt_client/mqtt_client.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'dart:math';
import 'dart:async';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OgiIoT Controller',
      theme: ThemeData(
        primarySwatch: Colors.red,
        primaryColor: Colors.green,
      ),
      home: LEDArrayBlocProvider(
        child: LEDArrayController('AAAA'),
      ),
    );
  }
}

class LEDArrayController extends StatelessWidget {
  String cid;
  LEDArrayController(this.cid);
  @override
  Widget build(BuildContext context) {
    final bloc = LEDArrayBlocProvider.of(context).bloc(cid);
    return Scaffold(
      body: Column(
        children: <Widget>[
          Expanded(
            child: Container(
              child: _strengthSeek(bloc),
            ),
          ),
          Expanded(
            child: Container(
              child: _colorPick(bloc),
            ),
          ),
          Expanded(
            child: Container(),
          ),
        ],
      ),
    );
  }

  Widget _strengthSeek(LEDArrayBloc bloc) {
    return StreamBuilder(
      stream: bloc.onChangeStrength,
      builder: (context, snapshot) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Flexible(
              flex: 1,
              child: Slider(
                activeColor: Colors.indigoAccent,
                min: 0.0,
                max: 8.0,
                onChanged: (newStrength) =>
                    bloc.changeStrength.add(newStrength),
                value: snapshot.hasData ? snapshot.data.toDouble() : 0,
              ),
            ),
            Container(
              width: 70.0,
              alignment: Alignment.center,
              child: Text(snapshot.hasData ? '${snapshot.data.toInt()}' : '0',
                  style: Theme.of(context).textTheme.display1),
            ),
          ],
        );
      },
    );
  }

  Widget _colorPick(LEDArrayBloc bloc) {
    return Column(children: [
      Expanded(
        child: Row(
          children: <Widget>[
            _colorButton(bloc, Color.fromARGB(255, 255, 255, 255)),
            _colorButton(bloc, Color.fromARGB(255, 255, 253, 231)),
            _colorButton(bloc, Color.fromARGB(255, 255, 245, 157)),
            _colorButton(bloc, Color.fromARGB(255, 255, 183, 77)),
          ],
        ),
      ),
      Expanded(
        child: Row(
          children: <Widget>[
            _colorButton(bloc, Color.fromARGB(255, 224, 247, 250)),
            _colorButton(bloc, Color.fromARGB(255, 3, 169, 244)),
            _colorButton(bloc, Color.fromARGB(255, 252, 228, 240)),
            _colorButton(bloc, Color.fromARGB(255, 248, 187, 208)),
          ],
        ),
      ),
    ]);
  }

  Widget _colorButton(LEDArrayBloc bloc, Color col) {
    return Container(
      margin: EdgeInsets.only(left: 32.0),
      child: FloatingActionButton(
        backgroundColor: col,
        onPressed: () => bloc.changeColor.add(col),
      ),
    );
  }
}

class LEDArrayBloc {
  final _changeStrengthController = StreamController<double>();
  final _changeColorController = StreamController<Color>();
  final _strengthController = StreamController<int>();

  Sink<double> get changeStrength => _changeStrengthController.sink;
  Sink<Color> get changeColor => _changeColorController.sink;

  Stream<int> get onChangeStrength => _strengthController.stream;

  int _strength = 4;
  Color _col = Color.fromARGB(255, 255, 255, 255);

  EdgeController _controller;

  LEDArrayBloc(String cid) {
    _controller = EdgeController(cid);
    _changeStrengthController.stream
        .listen((strength) => _changeStrength(strength));
    _changeColorController.stream.listen((color) => _changeColor(color));
  }

  void _changeStrength(double strength) {
    int newstrength = strength.toInt();
    if (newstrength != _strength) {
      _strength = newstrength;
      _strengthController.sink.add(_strength);
      sendData();
    }
  }

  void _changeColor(Color col) {
    if (col != _col) {
      _col = col;
      sendData();
    }
  }

  void sendData() {
    int s = 8 - _strength;
    int r = _col.red >> s;
    int g = _col.green >> s;
    int b = _col.blue >> s;
    _controller.send('$r,$g,$b');
  }
}

class LEDArrayBlocProvider extends InheritedWidget {
  const LEDArrayBlocProvider({Key key, Widget child})
      : super(key: key, child: child);

  LEDArrayBloc bloc(String cid) => LEDArrayBloc(cid);

  @override
  bool updateShouldNotify(_) => true;

  static LEDArrayBlocProvider of(BuildContext context) {
    return context.inheritFromWidgetOfExactType(LEDArrayBlocProvider);
  }
}

class EdgeController {
  AppMqttTransactions _at;
  String _topic;
  EdgeController(String cid) {
    _topic = 'ogiiot/ctrl/$cid';
    _at = new AppMqttTransactions();
    _at.subscribe('ogiiot/#');
  }

  void send(String msg) {
    _at.publish(_topic, msg);
  }
}

class AppMqttTransactions {
  Logger log;
  AppMqttTransactions() {
    log = Logger('main.dart');
  }
  MqttClient client;

  //for now limit to one subscription at a time.
  String previousTopic;
  bool bAlreadySubscribed = false;

  Future<bool> subscribe(String topic) async {
    if (await _connectToClient() == true) {
      client.onDisconnected = _onDisconnected;
      client.onConnected = _onConnected;
      client.onSubscribed = _onSubscribed;
      _subscribe(topic);
    }
    return true;
  }

  Future<bool> _connectToClient() async {
    if (client != null &&
        client.connectionStatus.state == MqttConnectionState.connected) {
      log.info('already logged in');
    } else {
      client = await _login();
      if (client == null) {
        return false;
      }
    }
    return true;
  }

  void _onSubscribed(String topic) {
    log.info('Subscription confirmed for topic $topic');
    this.bAlreadySubscribed = true;
    this.previousTopic = topic;
  }

  void _onDisconnected() {
    log.info('OnDisconnected client callback - Client disconnection');
    if (client.connectionStatus.returnCode == MqttConnectReturnCode.solicited) {
      log.info(':OnDisconnected callback is solicited, this is correct');
    }
    client.disconnect();
  }

  void _onConnected() {
    log.info('OnConnected client callback - Client connection was sucessful');
  }

//  Future<Map> _getBrokerAndKey() async {
//    // TODO: Check if private.json does not exist or expected key/values are not there.
//    String connect = await rootBundle.loadString('config/private.json');
//    return (json.decode(connect));
//  }

  Future<MqttClient> _login() async {
    //Map connectJson = await _getBrokerAndKey();
    Map connectJson = {
      'broker': '192.168.2.114', // Your Broker IP
      'key': '',
      'username': '',
    };
    log.info('in _login....broker  : ${connectJson['broker']}');
    log.info('in _login....key     : ${connectJson['key']}');
    log.info('in _login....username: ${connectJson['username']}');

    client = MqttClient(connectJson['broker'], connectJson['key']);
    client.logging(on: true);
    final MqttConnectMessage connMess = MqttConnectMessage()
        .authenticateAs(connectJson['username'], connectJson['key'])
        .withClientIdentifier('myClientID')
        .keepAliveFor(60)
        .withWillTopic('willtopic')
        .withWillMessage('My Will message')
        .startClean()
        .withWillQos(MqttQos.atMostOnce);
    log.info('connecting....');
    client.connectionMessage = connMess;

    try {
      await client.connect();
    } on Exception catch (e) {
      log.severe('EXCEPTION::client exception - $e');
      client.disconnect();
      client = null;
      return client;
    }

    if (client.connectionStatus.state == MqttConnectionState.connected) {
      log.info('connected');
    } else {
      log.info(
          'connection failed - disconnecting, status is ${client.connectionStatus}');
      client.disconnect();
      client = null;
    }
    return client;
  }

  Future _subscribe(String topic) async {
    if (this.bAlreadySubscribed == true) {
      client.unsubscribe(this.previousTopic);
    }
    log.info('Subscribing to the topic $topic');
    client.subscribe(topic, MqttQos.atMostOnce);

    client.updates.listen((List<MqttReceivedMessage<MqttMessage>> c) {
      final MqttPublishMessage recMess = c[0].payload;
      final String pt =
          MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
      log.info(
          'Change notification:: topic is <${c[0].topic}>, payload is <-- $pt -->');
      return pt;
    });
  }

  Future<void> publish(String topic, String value) async {
    if (await _connectToClient() == true) {
      final MqttClientPayloadBuilder builder = MqttClientPayloadBuilder();
      builder.addString(value);
      client.publishMessage(topic, MqttQos.atMostOnce, builder.payload);
    }
  }
}
