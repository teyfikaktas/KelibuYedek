import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kelibu/screens/connectivyplus.dart';

class ConnectivityWrapper extends StatelessWidget {
  final Widget child;

  const ConnectivityWrapper({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectivityService>(
      builder: (context, connectivity, _) {
        if (!connectivity.isConnected) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (ModalRoute.of(context)?.settings.name != '/noInternet') {
              Navigator.of(context).pushNamed('/noInternet');
            }
          });
        }
        return child;
      },
    );
  }
}