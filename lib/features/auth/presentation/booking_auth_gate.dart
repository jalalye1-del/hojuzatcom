import 'package:flutter/material.dart';

typedef BookingAuthNavigator =
    void Function(
      BuildContext context,
      Widget nextScreen,
      String serviceTitle,
      int servicePrice,
      String imageAsset,
    );

BookingAuthNavigator? _bookingAuthNavigator;

void registerBookingAuthNavigator(BookingAuthNavigator navigator) {
  _bookingAuthNavigator = navigator;
}

void openProtectedBooking(
  BuildContext context, {
  required Widget nextScreen,
  required String serviceTitle,
  int servicePrice = 0,
  String imageAsset = 'assets/images/services.jpg',
}) {
  final navigator = _bookingAuthNavigator;

  if (navigator == null) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => nextScreen));
    return;
  }

  navigator(context, nextScreen, serviceTitle, servicePrice, imageAsset);
}
