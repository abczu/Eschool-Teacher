import re

file_path = r"c:\UBIG\Project\Eschool-Siswa\lib\ui\screens\payment\childFeesScreen.dart"

with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# Chunk 1
content = content.replace("  String selectedTab = 'unpaid';\n  bool _isSortDescending = true;", "  String selectedTab = 'unpaid';\n  String _sortOption = 'terbaru';")

# Chunk 2
chunk2_old = """    // Apply sorting
    filtered.sort((a, b) {
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

      return _isSortDescending ? -comparison : comparison;
    });"""

chunk2_new = """    // Apply sorting
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

content = content.replace(chunk2_old, chunk2_new)

# Chunk 3
chunk3_old = """            if (index == 0) {
              return FeeOverviewBoard(
                fees: filtered,
                selectedTab: selectedTab,
                isSortDescending: _isSortDescending,
                accentGreen: accentGreen,
              );
            }"""

chunk3_new = """            if (index == 0) {
              return FeeOverviewBoard(
                fees: filtered,
                selectedTab: selectedTab,
                isSortDescending: _sortOption == 'terbaru',
                accentGreen: accentGreen,
              );
            }"""

content = content.replace(chunk3_old, chunk3_new)

# Chunk 4
chunk4_old = """                            const SizedBox(width: 10),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withValues(alpha: 0.4),
                                ),
                              ),
                              child: IconButton(
                                icon: Transform.scale(
                                  scaleY: _isSortDescending ? 1.0 : -1.0,
                                  child: Icon(
                                    Icons.filter_list_rounded,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary,
                                  ),
                                ),
                                tooltip: _isSortDescending
                                    ? 'Terbaru di atas'
                                    : 'Terlama di atas',
                                onPressed: () => setState(() =>
                                    _isSortDescending = !_isSortDescending),
                              ),
                            ),
                          ],"""

chunk4_new = """                            const SizedBox(width: 10),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withValues(alpha: 0.4),
                                ),
                              ),
                              child: PopupMenuButton<String>(
                                offset: const Offset(0, 40),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                icon: Icon(
                                  Icons.filter_list_rounded,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                tooltip: 'Urutkan berdasarkan',
                                onSelected: (String value) {
                                  setState(() {
                                    _sortOption = value;
                                  });
                                },
                                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
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
                                ],
                              ),
                            ),
                          ],"""

content = content.replace(chunk4_old, chunk4_new)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)

print("Replacement done.")
