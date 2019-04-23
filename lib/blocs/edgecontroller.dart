import 'package:logging/logging.dart';
import 'package:mqtt_client/mqtt_client.dart';

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

