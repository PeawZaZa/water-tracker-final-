import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/water_log_provider.dart';
import '../models/water_log.dart';
import 'add_edit_screen.dart';
import 'detail_screen.dart';

class ListScreen extends StatefulWidget {
  const ListScreen({super.key});

  @override
  State<ListScreen> createState() => _ListScreenState();
}

class _ListScreenState extends State<ListScreen> {
  DateTime? _selectedDate;

  Future<void> _pickDate(BuildContext context) async {
    final provider = context.read<WaterLogProvider>();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
      final dateStr = DateFormat('yyyy-MM-dd').format(picked);
      provider.setDateFilter(dateStr);
    }
  }

  void _clearDateFilter(BuildContext context) {
    setState(() => _selectedDate = null);
    context.read<WaterLogProvider>().setDateFilter('');
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WaterLogProvider>(
      builder: (context, provider, _) {
        final logs = provider.logs;
        final dateLabel = _selectedDate != null
            ? DateFormat('d MMM yyyy', 'th').format(_selectedDate!)
            : 'เลือกวันที่';

        return Scaffold(
          appBar: AppBar(
            title: const Text('รายการดื่มน้ำ', style: TextStyle(fontWeight: FontWeight.bold)),
            backgroundColor: const Color(0xFF1565C0),
            foregroundColor: Colors.white,
            automaticallyImplyLeading: false,
          ),
          body: Column(
            children: [
              // Filter bar
              Container(
                color: Colors.blue.shade50,
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    // Date picker
                    Expanded(
                      child: InkWell(
                        onTap: () => _pickDate(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.calendar_today, size: 16, color: Colors.blue.shade700),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(dateLabel,
                                    style: TextStyle(
                                      color: _selectedDate != null ? Colors.blue.shade800 : Colors.grey,
                                      fontSize: 13,
                                    )),
                              ),
                              if (_selectedDate != null)
                                GestureDetector(
                                  onTap: () => _clearDateFilter(context),
                                  child: const Icon(Icons.close, size: 16, color: Colors.grey),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Drink type dropdown
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: provider.selectedDrinkType,
                            isExpanded: true,
                            style: const TextStyle(fontSize: 13, color: Colors.black87),
                            onChanged: (val) {
                              if (val != null) provider.setDrinkTypeFilter(val);
                            },
                            items: provider.drinkTypeNames.map((t) {
                              return DropdownMenuItem(value: t, child: Text(t));
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Count bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('พบ ${logs.length} รายการ', style: const TextStyle(color: Colors.grey)),
                    if (provider.selectedDate.isNotEmpty || provider.selectedDrinkType != 'ทั้งหมด')
                      TextButton.icon(
                        onPressed: () {
                          setState(() => _selectedDate = null);
                          provider.clearFilters();
                        },
                        icon: const Icon(Icons.clear, size: 14),
                        label: const Text('ล้างตัวกรอง'),
                        style: TextButton.styleFrom(foregroundColor: Colors.red),
                      ),
                  ],
                ),
              ),

              // List
              Expanded(
                child: logs.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('💧', style: TextStyle(fontSize: 48)),
                            SizedBox(height: 8),
                            Text('ไม่พบรายการ', style: TextStyle(color: Colors.grey, fontSize: 16)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: logs.length,
                        padding: const EdgeInsets.only(bottom: 80),
                        itemBuilder: (context, i) {
                          final log = logs[i];
                          return _LogCard(log: log);
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LogCard extends StatelessWidget {
  final WaterLog log;
  const _LogCard({required this.log});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<WaterLogProvider>();
    final drinkType = provider.getDrinkTypeByName(log.drinkType);

    return Dismissible(
      key: Key('log_${log.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
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
      },
      onDismissed: (_) async {
        await provider.deleteLog(log.id!);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('🗑️ ลบรายการสำเร็จ'), backgroundColor: Colors.red),
          );
        }
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.blue.shade50,
            child: Text(drinkType?.emoji ?? '💧', style: const TextStyle(fontSize: 22)),
          ),
          title: Text(log.drinkType, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text('${log.date.toIso8601String().split('T')[0]}  ${log.time}'
              '${log.note != null && log.note!.isNotEmpty ? '\n${log.note}' : ''}'),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('${log.amountMl}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
              const Text('มล.', style: TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => DetailScreen(log: log)),
          ),
        ),
      ),
    );
  }
}
