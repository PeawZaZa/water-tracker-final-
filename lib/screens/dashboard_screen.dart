import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/water_log_provider.dart';
import 'list_screen.dart';
import 'add_edit_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WaterLogProvider>().init();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          _HomeTab(),
          ListScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        selectedItemColor: const Color(0xFF2196F3),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'แดชบอร์ด'),
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'รายการ'),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddEditScreen()),
          );
          if (result == true && mounted) {
            context.read<WaterLogProvider>().loadDashboard();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✅ บันทึกข้อมูลสำเร็จ'),
                backgroundColor: Colors.green,
              ),
            );
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('บันทึกการดื่ม'),
        backgroundColor: const Color(0xFF2196F3),
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<WaterLogProvider>(
      builder: (context, provider, _) {
        final stats = provider.dashboardStats;
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final todayTotal = stats['todayTotal'] ?? 0;
        final totalAmount = stats['totalAmount'] ?? 0;
        final totalCount = stats['totalCount'] ?? 0;
        final avgPerDay = stats['avgPerDay'] ?? 0;
        final goalMl = 2000;
        final progress = (todayTotal / goalMl).clamp(0.0, 1.0);

        final typeStats = (stats['typeStats'] as List<dynamic>?) ?? [];
        final dateStats = (stats['dateStats'] as List<dynamic>?) ?? [];

        return CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 180,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                title: const Text('💧 Water Tracker', style: TextStyle(fontWeight: FontWeight.bold)),
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
              ),
              backgroundColor: const Color(0xFF1565C0),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Today's progress card
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('วันนี้', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                Text('$todayTotal / $goalMl มล.',
                                    style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.w600)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value: progress,
                                minHeight: 16,
                                backgroundColor: Colors.blue.shade100,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  progress >= 1.0 ? Colors.green : Colors.blue,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              progress >= 1.0 ? '🎉 ถึงเป้าหมายแล้ว!' : '${(progress * 100).toStringAsFixed(0)}% ของเป้าหมาย',
                              style: TextStyle(
                                color: progress >= 1.0 ? Colors.green : Colors.grey,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Stats row
                    Row(
                      children: [
                        _StatCard('รายการทั้งหมด', '$totalCount', Icons.format_list_numbered, Colors.blue),
                        const SizedBox(width: 8),
                        _StatCard('ปริมาณรวม', '${(totalAmount / 1000).toStringAsFixed(1)} ล.', Icons.water_drop, Colors.cyan),
                        const SizedBox(width: 8),
                        _StatCard('เฉลี่ย/วัน', '$avgPerDay มล.', Icons.today, Colors.teal),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Bar chart - last 7 days
                    if (dateStats.isNotEmpty) ...[
                      const Text('7 วันล่าสุด (มล.)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 8),
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: SizedBox(
                            height: 180,
                            child: _buildBarChart(dateStats),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Drink type breakdown
                    if (typeStats.isNotEmpty) ...[
                      const Text('ประเภทเครื่องดื่ม', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 8),
                      ...typeStats.map((t) {
                        final drinkType = provider.getDrinkTypeByName(t['drink_type'] as String);
                        final pct = totalAmount > 0 ? (t['total'] as int) / totalAmount : 0.0;
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: Text(drinkType?.emoji ?? '💧', style: const TextStyle(fontSize: 24)),
                            title: Text(t['drink_type'] as String),
                            subtitle: LinearProgressIndicator(
                              value: pct,
                              backgroundColor: Colors.grey.shade200,
                              valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                            ),
                            trailing: Text('${t['total']} มล.\n${t['count']} ครั้ง',
                                textAlign: TextAlign.right,
                                style: const TextStyle(fontSize: 12)),
                          ),
                        );
                      }),
                    ],

                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _StatCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 4),
              Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 15)),
              Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey), textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBarChart(List<dynamic> dateStats) {
    final reversed = dateStats.reversed.toList();
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        barGroups: reversed.asMap().entries.map((e) {
          final val = (e.value['total'] as int).toDouble();
          return BarChartGroupData(x: e.key, barRods: [
            BarChartRodData(toY: val, color: Colors.blue, width: 16, borderRadius: BorderRadius.circular(4)),
          ]);
        }).toList(),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (val, meta) {
                final idx = val.toInt();
                if (idx < 0 || idx >= reversed.length) return const SizedBox();
                final date = reversed[idx]['date'] as String;
                final parts = date.split('-');
                return Text('${parts[2]}/${parts[1]}', style: const TextStyle(fontSize: 10));
              },
              reservedSize: 28,
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        gridData: const FlGridData(show: false),
      ),
    );
  }
}
