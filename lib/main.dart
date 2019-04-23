import 'package:flutter/material.dart';

import 'blocs/ledarray_provider.dart';
import 'ui/ledarray_controller.dart';

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
        child: LEDArrayController('1234ABCD1234'), // ChipID
      ),
    );
  }
}
