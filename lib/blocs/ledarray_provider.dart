import 'package:flutter/material.dart';

import 'ledarray_bloc.dart';

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

