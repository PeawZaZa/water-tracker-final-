import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/water_log.dart';
import '../providers/water_log_provider.dart';

class AddEditScreen extends StatefulWidget {
  final WaterLog? log;
  const AddEditScreen({super.key, this.log});

  @override
  State<AddEditScreen> createState() => _AddEditScreenState();
}

class _AddEditScreenState extends State<AddEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  late TextEditingController _amountCtrl;
  late TextEditingController _noteCtrl;
  String? _selectedDrinkType;
  bool _isSaving = false;

  final List<int> _quickAmounts = [150, 200, 250, 300, 350, 500];

  @override
  void initState() {
    super.initState();
    final log = widget.log;
    _selectedDate = log?.date ?? DateTime.now();
    final timeParts = log?.time.split(':') ?? [TimeOfDay.now().hour.toString(), TimeOfDay.now().minute.toString()];
    _selectedTime = TimeOfDay(hour: int.parse(timeParts[0]), minute: int.parse(timeParts[1]));
    _amountCtrl = TextEditingController(text: log?.amountMl.toString() ?? '');
    _noteCtrl = TextEditingController(text: log?.note ?? '');
    _selectedDrinkType = log?.drinkType;
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _selectedTime);
    if (picked != null) setState(() => _selectedTime = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDrinkType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ กรุณาเลือกประเภทเครื่องดื่ม'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isSaving = true);
    final provider = context.read<WaterLogProvider>();
    final timeStr = '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}';

    final log = WaterLog(
      id: widget.log?.id,
      date: _selectedDate,
      time: timeStr,
      amountMl: int.parse(_amountCtrl.text.trim()),
      drinkType: _selectedDrinkType!,
      note: _noteCtrl.text.trim(),
    );

    bool success;
    if (widget.log == null) {
      success = await provider.addLog(log);
    } else {
      success = await provider.updateLog(log);
    }

    setState(() => _isSaving = false);

    if (mounted) {
      if (success) {
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ เกิดข้อผิดพลาด'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.log != null;
    final provider = context.watch<WaterLogProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'แก้ไขรายการ' : 'บันทึกการดื่ม',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Date & Time row
            Row(
              children: [
                Expanded(
                  child: _FieldCard(
                    label: 'วันที่',
                    child: InkWell(
                      onTap: _pickDate,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          suffixIcon: Icon(Icons.calendar_today, size: 18),
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        child: Text(DateFormat('dd/MM/yyyy').format(_selectedDate)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _FieldCard(
                    label: 'เวลา',
                    child: InkWell(
                      onTap: _pickTime,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          suffixIcon: Icon(Icons.access_time, size: 18),
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        child: Text(_selectedTime.format(context)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Drink type
            _FieldCard(
              label: 'ประเภทเครื่องดื่ม *',
              child: DropdownButtonFormField<String>(
                value: _selectedDrinkType,
                decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
                hint: const Text('เลือกประเภท'),
                items: provider.drinkTypes.map((t) {
                  return DropdownMenuItem(
                    value: t.name,
                    child: Row(
                      children: [
                        Text(t.emoji),
                        const SizedBox(width: 8),
                        Text(t.name),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedDrinkType = val),
                validator: (val) => val == null ? 'กรุณาเลือกประเภทเครื่องดื่ม' : null,
              ),
            ),
            const SizedBox(height: 16),

            // Amount
            _FieldCard(
              label: 'ปริมาณ (มล.) *',
              child: TextFormField(
                controller: _amountCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  isDense: true,
                  suffixText: 'มล.',
                  hintText: 'เช่น 250',
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'กรุณากรอกปริมาณ';
                  final n = int.tryParse(val.trim());
                  if (n == null || n <= 0) return 'ปริมาณต้องเป็นตัวเลขที่มากกว่า 0';
                  if (n > 5000) return 'ปริมาณไม่ควรเกิน 5,000 มล.';
                  return null;
                },
              ),
            ),
            const SizedBox(height: 8),

            // Quick select amount
            Wrap(
              spacing: 8,
              children: _quickAmounts.map((a) {
                return ActionChip(
                  label: Text('$a มล.'),
                  backgroundColor: Colors.blue.shade50,
                  onPressed: () => setState(() => _amountCtrl.text = a.toString()),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Note
            _FieldCard(
              label: 'หมายเหตุ',
              child: TextFormField(
                controller: _noteCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  isDense: true,
                  hintText: 'บันทึกเพิ่มเติม (ไม่บังคับ)',
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Save button
            SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _save,
                icon: _isSaving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.save),
                label: Text(isEdit ? 'บันทึกการแก้ไข' : 'บันทึก',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1565C0),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FieldCard extends StatelessWidget {
  final String label;
  final Widget child;
  const _FieldCard({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black87)),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}
