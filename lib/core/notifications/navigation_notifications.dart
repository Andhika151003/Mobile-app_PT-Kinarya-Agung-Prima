import 'package:flutter/widgets.dart';

class ChangeTabNotification extends Notification {
  final int index;
  ChangeTabNotification(this.index);
}
