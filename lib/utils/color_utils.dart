import 'package:flutter/material.dart';

//trasforma la stringa esadecimale AARRGGBB o RRGGBB in un Color
Color parseHexColor(String hexString) {
  //rimuoviamo l'eventuale # e assicuro 8 cifre
  final buffer = StringBuffer();
  if (hexString.length == 6) buffer.write('FF'); //se manca l'alpha
  buffer.write(hexString.replaceFirst('#', ''));
  return Color(int.parse(buffer.toString(), radix: 16));
}
