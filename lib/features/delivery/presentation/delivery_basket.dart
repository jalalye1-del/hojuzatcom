import 'package:flutter/foundation.dart';
import '../../bookings/presentation/provider_booking_flow.dart';

class DeliveryCartItem {
  DeliveryCartItem({
    required this.id,
    required this.name,
    required this.category,
    required this.unitPrice,
    this.quantity = 1,
  });

  final String id;
  final String name;
  final String category;
  final int unitPrice;
  int quantity;

  int get total => unitPrice * quantity;
}

class DeliveryBasket extends ChangeNotifier {
  final List<DeliveryCartItem> items = [];

  String? deliveryLocation;

  void setDeliveryLocation(String value) {
    deliveryLocation = value.trim().isEmpty ? null : value.trim();
    notifyListeners();
  }

  void add(DeliveryCartItem item) {
    final existing = items
        .where((element) => element.id == item.id)
        .firstOrNull;
    if (existing == null) {
      items.add(item);
    } else {
      existing.quantity += item.quantity;
    }
    notifyListeners();
  }

  void change(DeliveryCartItem item, int value) {
    item.quantity = value < 0 ? 0 : value;
    if (item.quantity == 0) items.remove(item);
    notifyListeners();
  }

  int get subtotal => items.fold(0, (sum, item) => sum + item.total);
  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);
  int get deliveryFee =>
      items.isEmpty || ProviderBookingFlow.current != null ? 0 : 600;
  int get total => subtotal + deliveryFee;

  void clear() {
    items.clear();
    notifyListeners();
  }
}
