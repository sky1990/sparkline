import 'package:flutter/material.dart';

class SparkLineStockModel {
  double value; //价格
  String time; //时间
  String riseAndFall; //涨跌
  String amplitude; //涨跌幅

  SparkLineStockModel({
    @required this.value,
    @required this.time,
    @required this.riseAndFall,
    @required this.amplitude,
  });
}