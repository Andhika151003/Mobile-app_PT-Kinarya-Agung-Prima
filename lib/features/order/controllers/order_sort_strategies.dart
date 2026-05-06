import '../models/order.dart';

abstract class OrderSortStrategy {
  void sort(List<OrderModel> orders);
}

class SortByNewest implements OrderSortStrategy {
  @override
  void sort(List<OrderModel> orders) {
    orders.sort((a, b) =>
        (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
  }
}

class SortByOldest implements OrderSortStrategy {
  @override
  void sort(List<OrderModel> orders) {
    orders.sort((a, b) =>
        (a.createdAt ?? DateTime(0)).compareTo(b.createdAt ?? DateTime(0)));
  }
}

class SortByPriceHighToLow implements OrderSortStrategy {
  @override
  void sort(List<OrderModel> orders) {
    orders.sort((a, b) => b.total.compareTo(a.total));
  }
}

class SortByPriceLowToHigh implements OrderSortStrategy {
  @override
  void sort(List<OrderModel> orders) {
    orders.sort((a, b) => a.total.compareTo(b.total));
  }
}
