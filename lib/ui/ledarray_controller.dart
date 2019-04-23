import 'package:flutter/material.dart';

import '../blocs/edgecontroller.dart';
import '../blocs/ledarray_bloc.dart';
import '../blocs/ledarray_provider.dart';

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
