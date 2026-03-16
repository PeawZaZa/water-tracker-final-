import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/water_log.dart';
import '../providers/water_log_provider.dart';
import 'add_edit_screen.dart';

class DetailScreen extends StatelessWidget {
  final WaterLog log;
  const DetailScreen({super.key, required this.log});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<WaterLogProvider>();
    final drinkType = provider.getDrinkTypeByName(log.drinkType);

    return Scaffold(
      appBar: AppBar(
        title: const Text('รายละเอียด', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => AddEditScreen(log: log)),
              );
              if (result == true && context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('✅ แก้ไขสำเร็จ'), backgroundColor: Colors.green),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('ยืนยันการลบ'),
                  content: const Text('ต้องการลบรายการนี้ใช่หรือไม่?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('ยกเลิก')),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      child: const Text('ลบ'),
                    ),
                  ],
                ),
              );
              if (confirm == true && context.mounted) {
                await provider.deleteLog(log.id!);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('🗑️ ลบรายการสำเร็จ'), backgroundColor: Colors.red),
                );
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Hero card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  children: [
                    Text(drinkType?.emoji ?? '💧', style: const TextStyle(fontSize: 56)),
                    const SizedBox(height: 12),
                    Text(log.drinkType,
                        style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('${log.amountMl} มล.',
                        style: const TextStyle(color: Colors.white70, fontSize: 36, fontWeight: FontWeight.w300)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Details
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  _DetailRow(Icons.calendar_today, 'วันที่', log.date.toIso8601String().split('T')[0]),
                  const Divider(height: 1, indent: 56),
                  _DetailRow(Icons.access_time, 'เวลา', log.time),
                  const Divider(height: 1, indent: 56),
                  _DetailRow(Icons.water_drop, 'ปริมาณ', '${log.amountMl} มล.'),
                  const Divider(height: 1, indent: 56),
                  _DetailRow(Icons.local_drink, 'ประเภท', log.drinkType),
                  if (log.note != null && log.note!.isNotEmpty) ...[
                    const Divider(height: 1, indent: 56),
                    _DetailRow(Icons.notes, 'หมายเหตุ', log.note!),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _DetailRow(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue),
      title: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
      subtitle: Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: Colors.black87)),
    );
  }
}
