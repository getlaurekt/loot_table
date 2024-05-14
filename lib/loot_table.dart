library loot_table;

import 'dart:math';

class LootTableInfo {
  final int itemId;
  final int amount;

  const LootTableInfo({
    required this.itemId,
    required this.amount,
  });
}

abstract class LootTableItem {
  final int weight;
  final bool droppable;
  List<LootTableInfo> getItems();

  const LootTableItem({
    required this.weight,
    this.droppable = true,
  }) : assert(
            weight == -1 || weight >= 1, 'Weight must be -1 or greater than 0');
}

class LootTableEmpty extends LootTableItem {
  LootTableEmpty({required int weight})
      : super(weight: weight, droppable: false) {
    assert(weight >= 1, 'Weight must be greater than 0 for LootTableEmpty.');
  }

  @override
  List<LootTableInfo> getItems() {
    return List.empty();
  }
}

class LootTableSingle extends LootTableItem {
  LootTableInfo item;

  LootTableSingle({
    required super.weight,
    required this.item,
  });

  @override
  List<LootTableInfo> getItems() {
    return [item];
  }
}

class LootTableSet extends LootTableItem {
  List<LootTableInfo> items;

  LootTableSet({
    required super.weight,
    required this.items,
  });

  @override
  List<LootTableInfo> getItems() {
    return List.from(items);
  }
}

class LootTableItemWithRanges extends LootTableItem {
  final int minDropRange;
  final int maxDropRange;
  List<LootTableInfo> items;

  LootTableItemWithRanges({
    required super.weight,
    required this.items,
    required this.minDropRange,
    required this.maxDropRange,
  });

  @override
  List<LootTableInfo> getItems() {
    return List.from(items);
  }
}

class LootTable {
  final List<LootTableItem> items;

  const LootTable({required this.items});

  static List<LootTableInfo> droppedItems = [];

  List<LootTableItemWithRanges> _getRanges() {
    List<LootTableItemWithRanges> itemListOfRanges = [];
    List<LootTableItem> filteredItems =
        items.where((item) => item.weight != -1).toList();

    filteredItems.asMap().forEach(
      (index, item) {
        if (itemListOfRanges.isEmpty) {
          itemListOfRanges.add(
            LootTableItemWithRanges(
              weight: item.weight,
              items: item.getItems(),
              minDropRange: 1,
              maxDropRange: item.weight,
            ),
          );
        } else {
          itemListOfRanges.add(
            LootTableItemWithRanges(
              weight: item.weight,
              items: item.getItems(),
              minDropRange: itemListOfRanges[index - 1].maxDropRange + 1,
              maxDropRange:
                  itemListOfRanges[index - 1].maxDropRange + item.weight,
            ),
          );
        }
      },
    );

    return itemListOfRanges;
  }

  int _getTotalWeight() {
    return items
        .where((item) => item.weight != -1)
        .map((item) => item.weight)
        .reduce((a, b) => a + b);
  }

  int _getNumberWithingRange() {
    Random random = Random();
    final totalWeight = _getTotalWeight();
    const int minWeight = 1;
    int randomNumber = minWeight + random.nextInt(totalWeight);

    return randomNumber;
  }

  LootTableItemWithRanges _pickItem() {
    final randomRangeNumber = _getNumberWithingRange();
    final itemRanges = _getRanges();

    final pickItem = itemRanges.firstWhere((item) {
      bool isWithinRange = randomRangeNumber >= item.minDropRange &&
          randomRangeNumber <= item.maxDropRange;

      return isWithinRange;
    });

    return pickItem;
  }

  void dropItems() {
    droppedItems.clear();

    for (var item in items) {
      if (item.weight == -1) {
        for (var info in item.getItems()) {
          droppedItems.add(info);
        }
      }
    }

    LootTableItemWithRanges pickedItem = _pickItem();

    for (var item in pickedItem.items) {
      droppedItems.add(item);
    }
  }
}
