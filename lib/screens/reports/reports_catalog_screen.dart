import 'package:flutter/material.dart';

import '../../data/mock_data.dart';
import '../../models/report_category.dart';
import 'report_form_screen.dart';

class ReportsCatalogScreen extends StatefulWidget {
  const ReportsCatalogScreen({super.key});

  @override
  State<ReportsCatalogScreen> createState() => _ReportsCatalogScreenState();
}

class _ReportsCatalogScreenState extends State<ReportsCatalogScreen> {
  String query = '';

  static const Color bgColor = Color(0xFF0B1220);
  static const Color cardColor = Color(0xFF111827);
  static const Color blue = Color(0xFF2563EB);
  static const Color cyan = Color(0xFF06B6D4);

  @override
  Widget build(BuildContext context) {
    final List<ReportCategory> filtered = MockData.categories
        .where(
          (item) =>
              item.title.contains(query) ||
              item.subtitle.contains(query) ||
              item.description.contains(query),
        )
        .toList();

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'اختيار نوع البلاغ',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [blue, cyan],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Row(
              children: [
                Icon(Icons.assignment_outlined, color: Colors.white, size: 34),
                SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'اختر نوع البلاغ المناسب ليتم توجيهك للنموذج الصحيح.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      height: 1.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          TextField(
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'ابحث عن نوع البلاغ',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.45)),
              prefixIcon: const Icon(Icons.search, color: Colors.white54),
              filled: true,
              fillColor: cardColor,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: cyan, width: 1.4),
              ),
            ),
            onChanged: (value) => setState(() => query = value.trim()),
          ),

          const SizedBox(height: 20),

          if (filtered.isEmpty)
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.search_off_rounded,
                    color: Colors.white54,
                    size: 44,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'لا توجد نتائج مطابقة',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.75),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

          ...filtered.map(
            (category) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _CategoryCard(
                category: category,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ReportFormScreen(category: category),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final ReportCategory category;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.category,
    required this.onTap,
  });

  static const Color cardColor = Color(0xFF111827);
  static const Color cyan = Color(0xFF06B6D4);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: cyan.withOpacity(0.12),
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Icon(
                Icons.report_problem_outlined,
                color: cyan,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    category.description,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.62),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: cyan.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'مستوى الخطورة: ${category.riskLevel}',
                      style: const TextStyle(
                        color: cyan,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.white54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}