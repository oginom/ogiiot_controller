import 'dart:async';
import 'package:flutter/material.dart';

import 'edgecontroller.dart';

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
