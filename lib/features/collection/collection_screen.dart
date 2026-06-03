import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';

class CollectionScreen extends StatefulWidget {
  const CollectionScreen({super.key});

  @override
  State<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends State<CollectionScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Шапка
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  Text(AppStrings.tabCollection,
                      style: Theme.of(context).textTheme.headlineMedium),
                ],
              ),
            ),
            // TabBar
            Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(10),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.primary, width: 0.5),
                ),
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                labelStyle: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600),
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(text: AppStrings.myCollection),
                  Tab(text: AppStrings.shop),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _MyCollectionTab(),
                  _ShopTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MyCollectionTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Пустые слоты для MVP
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: 6,
      itemBuilder: (_, i) => i == 0
          ? _AddToySlot()
          : _EmptyToySlot(),
    );
  }
}

class _AddToySlot extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: AppColors.primary.withOpacity(0.3),
            width: 1,
            style: BorderStyle.solid),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_circle_outline,
              size: 32, color: AppColors.primary.withOpacity(0.7)),
          const SizedBox(height: 8),
          Text(
            AppStrings.addToy,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.primary.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _EmptyToySlot extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.border,
          width: 1,
          style: BorderStyle.solid,
        ),
      ),
    );
  }
}

class _ShopTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _ShopSection(title: AppStrings.newItems, items: _mockItems(3, true)),
        const SizedBox(height: 16),
        _ShopSection(title: AppStrings.sale, items: _mockItems(2, false, onSale: true)),
        const SizedBox(height: 16),
        _ShopSection(title: AppStrings.allCollections, items: _mockItems(4, false)),
      ],
    );
  }

  List<Map<String, dynamic>> _mockItems(int count, bool isNew,
      {bool onSale = false}) {
    return List.generate(
      count,
      (i) => {
        'name': 'Котик Мяу #${i + 1}',
        'series': 'Серия ${i + 1}',
        'price': 299.0 + i * 50,
        'salePrice': onSale ? 199.0 + i * 30 : null,
        'isNew': isNew,
      },
    );
  }
}

class _ShopSection extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> items;

  const _ShopSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 10),
        SizedBox(
          height: 180,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (ctx, i) => _ShopCard(item: items[i]),
          ),
        ),
      ],
    );
  }
}

class _ShopCard extends StatelessWidget {
  final Map<String, dynamic> item;

  const _ShopCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final hasDiscount = item['salePrice'] != null;
    return Container(
      width: 130,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Фото-заглушка
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(14)),
              ),
              child: const Center(
                child: Text('🧸', style: TextStyle(fontSize: 40)),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item['name'],
                    style: Theme.of(context).textTheme.labelLarge,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                Text(item['series'],
                    style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '¥${item['salePrice'] ?? item['price']}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: hasDiscount ? AppColors.error : AppColors.primary,
                      ),
                    ),
                    if (hasDiscount) ...[
                      const SizedBox(width: 4),
                      Text(
                        '¥${item['price']}',
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.textHint,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
