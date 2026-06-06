import '../../shared/widgets/translated_text.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/user_model.dart';

class CollectionScreen extends StatefulWidget {
  const CollectionScreen({super.key});

  @override
  State<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends State<CollectionScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  // Мок-магазины партнёры
  final _shops = [
    {'name': 'ToyWorld Москва', 'address': 'ул. Арбат, 24', 'emoji': '🏪', 'x': 0.3, 'y': 0.3},
    {'name': 'MiniCollect', 'address': 'Тверская, 15', 'emoji': '🏬', 'x': 0.6, 'y': 0.25},
    {'name': 'FigureHub', 'address': 'Покровка, 8', 'emoji': '🏯', 'x': 0.7, 'y': 0.55},
    {'name': 'Коллекционер', 'address': 'Садовая, 33', 'emoji': '🏢', 'x': 0.2, 'y': 0.6},
  ];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(child: TabBarView(
              controller: _tab,
              children: [
                _buildMyCollection(),
                _buildShops(),
              ],
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Text('Коллекция',
              style: Theme.of(context).textTheme.headlineMedium),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
          ),
          child: TabBar(
            controller: _tab,
            tabs: const [Tab(text: 'Моя коллекция'), Tab(text: 'Магазины')],
            labelColor: Colors.white,
            unselectedLabelColor: AppColors.textSecondary,
            indicator: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            dividerColor: Colors.transparent,
            indicatorSize: TabBarIndicatorSize.tab,
          ),
        ),
      ],
    );
  }

  Widget _buildMyCollection() {
    final toys = [
      {'name': 'Котик Мяу', 'series': 'Серия 1', 'num': '#0042', 'emoji': '🐱'},
      {'name': 'Лягушонок', 'series': 'Серия 2', 'num': '#0117', 'emoji': '🐸'},
    ];
    final emptySlots = 2;

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: toys.length + emptySlots,
      itemBuilder: (_, i) {
        if (i < toys.length) {
          final toy = toys[i];
          return _ToyCard(toy: toy);
        }
        return _EmptySlot();
      },
    );
  }

  Widget _buildShops() {
    return Stack(
      children: [
        // Карта (заглушка с сеткой)
        Container(color: const Color(0xFF1A1A2E)),
        CustomPaint(size: Size.infinite, painter: _ShopGridPainter()),

        // Магазины на карте
        ..._shops.map((shop) => _ShopPin(
          shop: shop,
          onTap: () => _showShopInfo(shop),
        )),

        // Подпись
        Positioned(
          bottom: 16, left: 0, right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surface.withOpacity(0.9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text('🗺 Магазины-партнёры рядом',
                  style: TextStyle(color: Colors.white, fontSize: 13)),
            ),
          ),
        ),
      ],
    );
  }

  void _showShopInfo(Map<String, dynamic> shop) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4,
            decoration: BoxDecoration(color: AppColors.border,
                borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          Text(shop['emoji'] as String,
              style: const TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          TranslatedText(shop['name'] as String,
              style: const TextStyle(color: Colors.white,
                  fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.location_on_outlined,
                size: 14, color: AppColors.textSecondary),
            const SizedBox(width: 4),
            TranslatedText(shop['address'] as String,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
          ]),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => Get.back(),
              icon: const Icon(Icons.map_outlined, size: 16),
              label: const Text('Построить маршрут'),
            ),
          ),
        ]),
      ),
    );
  }
}

class _ToyCard extends StatelessWidget {
  final Map<String, dynamic> toy;
  const _ToyCard({required this.toy});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(toy['emoji'] as String,
              style: const TextStyle(fontSize: 44)),
          const SizedBox(height: 8),
          TranslatedText(toy['name'] as String,
              style: const TextStyle(color: Colors.white,
                  fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text('${toy['series']} · ${toy['num']}',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text('Привязан',
                style: TextStyle(color: AppColors.success, fontSize: 11)),
          ),
        ],
      ),
    );
  }
}

class _EmptySlot extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Get.snackbar('🎮', 'Функция в разработке',
          duration: const Duration(seconds: 2),
          backgroundColor: AppColors.surface, colorText: Colors.white),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.card.withOpacity(0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: AppColors.border, width: 1,
              style: BorderStyle.values[0]),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle_outline,
                size: 40, color: AppColors.textHint),
            const SizedBox(height: 8),
            const Text('Слот пуст',
                style: TextStyle(color: AppColors.textHint, fontSize: 13)),
            const SizedBox(height: 2),
            const Text('Добавить игрушку',
                style: TextStyle(color: AppColors.primary, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

class _ShopPin extends StatelessWidget {
  final Map<String, dynamic> shop;
  final VoidCallback onTap;
  const _ShopPin({required this.shop, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final x = (shop['x'] as double) * MediaQuery.of(context).size.width;
    final y = (shop['y'] as double) * (MediaQuery.of(context).size.height * 0.7);
    return Positioned(
      left: x - 24, top: y,
      child: GestureDetector(
        onTap: onTap,
        child: Column(children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.9),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(color: AppColors.primary.withOpacity(0.5),
                    blurRadius: 8),
              ],
            ),
            child: Center(child: Text(shop['emoji'] as String,
                style: const TextStyle(fontSize: 22))),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.surface, borderRadius: BorderRadius.circular(6),
            ),
            child: TranslatedText(shop['name'] as String,
                style: const TextStyle(color: Colors.white, fontSize: 9),
                maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ]),
      ),
    );
  }
}

class _ShopGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.border.withOpacity(0.3)
      ..strokeWidth = 0.5;
    const step = 30.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }
  @override bool shouldRepaint(_) => false;
}
