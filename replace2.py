import re

file_path = r"c:\UBIG\Project\Eschool-Siswa\lib\ui\screens\payment\childFeesScreen.dart"

with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# Chunk 1: The sort logic in _buildFeesContainer
chunk1_old = """    // Apply sorting
    filtered.sort((a, b) {
      if (_sortOption == 'mendekati_tenggat') {
        DateTime dueA = a.dueDate != null
            ? DateTime.tryParse(a.dueDate!) ?? DateTime.fromMillisecondsSinceEpoch(0)
            : DateTime.fromMillisecondsSinceEpoch(0);
        DateTime dueB = b.dueDate != null
            ? DateTime.tryParse(b.dueDate!) ?? DateTime.fromMillisecondsSinceEpoch(0)
            : DateTime.fromMillisecondsSinceEpoch(0);
        int comparison = dueA.compareTo(dueB);
        if (comparison == 0) {
          comparison = (a.id ?? 0).compareTo(b.id ?? 0);
        }
        return comparison;
      }

      DateTime dateA = a.createdAt != null
          ? DateTime.tryParse(a.createdAt!) ?? DateTime.fromMillisecondsSinceEpoch(0)
          : DateTime.fromMillisecondsSinceEpoch(0);
      DateTime dateB = b.createdAt != null
          ? DateTime.tryParse(b.createdAt!) ?? DateTime.fromMillisecondsSinceEpoch(0)
          : DateTime.fromMillisecondsSinceEpoch(0);

      int comparison = dateA.compareTo(dateB);
      if (comparison == 0) {
        comparison = (a.id ?? 0).compareTo(b.id ?? 0);
      }

      return _sortOption == 'terbaru' ? -comparison : comparison;
    });"""

chunk1_new = """    // Apply sorting
    filtered.sort((a, b) {
      if (_sortOption == 'terbesar' || _sortOption == 'terkecil') {
        double amtA = a.getTotalAmount();
        double amtB = b.getTotalAmount();
        int comparison = amtA.compareTo(amtB);
        if (comparison == 0) comparison = (a.id ?? 0).compareTo(b.id ?? 0);
        return _sortOption == 'terbesar' ? -comparison : comparison;
      }

      if (_sortOption == 'mendekati_tenggat') {
        DateTime dueA = a.dueDate != null
            ? DateTime.tryParse(a.dueDate!) ?? DateTime.fromMillisecondsSinceEpoch(0)
            : DateTime.fromMillisecondsSinceEpoch(0);
        DateTime dueB = b.dueDate != null
            ? DateTime.tryParse(b.dueDate!) ?? DateTime.fromMillisecondsSinceEpoch(0)
            : DateTime.fromMillisecondsSinceEpoch(0);
        int comparison = dueA.compareTo(dueB);
        if (comparison == 0) {
          comparison = (a.id ?? 0).compareTo(b.id ?? 0);
        }
        return comparison;
      }

      DateTime _getDate(ChildFeeDetails fee) {
        if (selectedTab == 'paid') {
          // Find the latest payment date if it's paid
          if (fee.bills != null && fee.bills!.isNotEmpty && fee.bills!.first.paymentHistory.isNotEmpty) {
            final history = fee.bills!.first.paymentHistory;
            history.sort((p1, p2) {
              DateTime d1 = p1.date != null ? DateTime.tryParse(p1.date!) ?? DateTime.fromMillisecondsSinceEpoch(0) : DateTime.fromMillisecondsSinceEpoch(0);
              DateTime d2 = p2.date != null ? DateTime.tryParse(p2.date!) ?? DateTime.fromMillisecondsSinceEpoch(0) : DateTime.fromMillisecondsSinceEpoch(0);
              return d1.compareTo(d2);
            });
            return history.last.date != null ? DateTime.tryParse(history.last.date!) ?? DateTime.fromMillisecondsSinceEpoch(0) : DateTime.fromMillisecondsSinceEpoch(0);
          }
        }
        return fee.createdAt != null
            ? DateTime.tryParse(fee.createdAt!) ?? DateTime.fromMillisecondsSinceEpoch(0)
            : DateTime.fromMillisecondsSinceEpoch(0);
      }

      DateTime dateA = _getDate(a);
      DateTime dateB = _getDate(b);

      int comparison = dateA.compareTo(dateB);
      if (comparison == 0) {
        comparison = (a.id ?? 0).compareTo(b.id ?? 0);
      }

      return _sortOption == 'terbaru' ? -comparison : comparison;
    });"""
content = content.replace(chunk1_old, chunk1_new)

# Chunk 2: The PopupMenuButton
chunk2_old = """                                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                                  PopupMenuItem<String>(
                                    value: 'terbaru',
                                    child: Row(
                                      children: [
                                        Icon(Icons.arrow_downward_rounded, size: 20, color: _sortOption == 'terbaru' ? Theme.of(context).colorScheme.primary : Colors.grey),
                                        const SizedBox(width: 8),
                                        Text('Terbaru', style: TextStyle(fontWeight: _sortOption == 'terbaru' ? FontWeight.bold : FontWeight.normal)),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem<String>(
                                    value: 'terlama',
                                    child: Row(
                                      children: [
                                        Icon(Icons.arrow_upward_rounded, size: 20, color: _sortOption == 'terlama' ? Theme.of(context).colorScheme.primary : Colors.grey),
                                        const SizedBox(width: 8),
                                        Text('Terlama', style: TextStyle(fontWeight: _sortOption == 'terlama' ? FontWeight.bold : FontWeight.normal)),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem<String>(
                                    value: 'mendekati_tenggat',
                                    child: Row(
                                      children: [
                                        Icon(Icons.access_time_rounded, size: 20, color: _sortOption == 'mendekati_tenggat' ? Theme.of(context).colorScheme.primary : Colors.grey),
                                        const SizedBox(width: 8),
                                        Text('Mendekati Tenggat', style: TextStyle(fontWeight: _sortOption == 'mendekati_tenggat' ? FontWeight.bold : FontWeight.normal)),
                                      ],
                                    ),
                                  ),
                                ],"""

chunk2_new = """                                itemBuilder: (BuildContext context) {
                                  List<PopupMenuEntry<String>> items = [];
                                  
                                  // Common items
                                  items.add(PopupMenuItem<String>(
                                    value: 'terbaru',
                                    child: Row(
                                      children: [
                                        Icon(Icons.arrow_downward_rounded, size: 20, color: _sortOption == 'terbaru' ? Theme.of(context).colorScheme.primary : Colors.grey),
                                        const SizedBox(width: 8),
                                        Text(selectedTab == 'paid' ? 'Pembayaran Terbaru' : 'Terbaru', style: TextStyle(fontWeight: _sortOption == 'terbaru' ? FontWeight.bold : FontWeight.normal)),
                                      ],
                                    ),
                                  ));
                                  items.add(PopupMenuItem<String>(
                                    value: 'terlama',
                                    child: Row(
                                      children: [
                                        Icon(Icons.arrow_upward_rounded, size: 20, color: _sortOption == 'terlama' ? Theme.of(context).colorScheme.primary : Colors.grey),
                                        const SizedBox(width: 8),
                                        Text(selectedTab == 'paid' ? 'Pembayaran Terlama' : 'Terlama', style: TextStyle(fontWeight: _sortOption == 'terlama' ? FontWeight.bold : FontWeight.normal)),
                                      ],
                                    ),
                                  ));

                                  if (selectedTab == 'paid') {
                                    items.add(PopupMenuItem<String>(
                                      value: 'terbesar',
                                      child: Row(
                                        children: [
                                          Icon(Icons.monetization_on_outlined, size: 20, color: _sortOption == 'terbesar' ? Theme.of(context).colorScheme.primary : Colors.grey),
                                          const SizedBox(width: 8),
                                          Text('Nominal Terbesar', style: TextStyle(fontWeight: _sortOption == 'terbesar' ? FontWeight.bold : FontWeight.normal)),
                                        ],
                                      ),
                                    ));
                                    items.add(PopupMenuItem<String>(
                                      value: 'terkecil',
                                      child: Row(
                                        children: [
                                          Icon(Icons.money_off, size: 20, color: _sortOption == 'terkecil' ? Theme.of(context).colorScheme.primary : Colors.grey),
                                          const SizedBox(width: 8),
                                          Text('Nominal Terkecil', style: TextStyle(fontWeight: _sortOption == 'terkecil' ? FontWeight.bold : FontWeight.normal)),
                                        ],
                                      ),
                                    ));
                                  } else {
                                    items.add(PopupMenuItem<String>(
                                      value: 'mendekati_tenggat',
                                      child: Row(
                                        children: [
                                          Icon(Icons.access_time_rounded, size: 20, color: _sortOption == 'mendekati_tenggat' ? Theme.of(context).colorScheme.primary : Colors.grey),
                                          const SizedBox(width: 8),
                                          Text('Mendekati Tenggat', style: TextStyle(fontWeight: _sortOption == 'mendekati_tenggat' ? FontWeight.bold : FontWeight.normal)),
                                        ],
                                      ),
                                    ));
                                  }
                                  
                                  return items;
                                },"""

content = content.replace(chunk2_old, chunk2_new)

# Chunk 3: ensure that switching tabs resets or preserves valid sortOptions
chunk3_old = """  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,"""

chunk3_new = """  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,"""

chunk3_old2 = """    return GestureDetector(
      onTap: () {
        setState(() => selectedTab = value);
        Navigator.pop(context);
      },
      child: Container("""

chunk3_new2 = """    return GestureDetector(
      onTap: () {
        setState(() {
          selectedTab = value;
          if (value == 'paid' && _sortOption == 'mendekati_tenggat') {
            _sortOption = 'terbaru';
          } else if (value != 'paid' && (_sortOption == 'terbesar' || _sortOption == 'terkecil')) {
            _sortOption = 'terbaru';
          }
        });
        Navigator.pop(context);
      },
      child: Container("""
content = content.replace(chunk3_old2, chunk3_new2)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)

print("Replacement done for step 2.")
