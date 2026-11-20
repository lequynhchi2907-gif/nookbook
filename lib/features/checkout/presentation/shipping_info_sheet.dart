import 'package:flutter/material.dart';
import 'package:nookbook/core/widgets/app_sheet.dart';
import 'package:nookbook/features/account/application/profile_providers.dart';

/// Sheet nhập / đổi tên, số điện thoại, địa chỉ nhận hàng.
/// Trả về hồ sơ đã sửa, hoặc null nếu đóng.
Future<UserProfile?> showShippingInfoSheet(
    BuildContext context, UserProfile current) {
  return showAppSheet<UserProfile>(
    context,
    title: 'Địa chỉ nhận hàng',
    builder: (_) => _ShippingForm(current: current),
  );
}

class _ShippingForm extends StatefulWidget {
  const _ShippingForm({required this.current});

  final UserProfile current;

  @override
  State<_ShippingForm> createState() => _ShippingFormState();
}

class _ShippingFormState extends State<_ShippingForm> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.current.name);
  late final _phone = TextEditingController(text: widget.current.phone);
  late final _address = TextEditingController(text: widget.current.address);

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _address.dispose();
    super.dispose();
  }

  String? _required(String? v, String msg) =>
      (v == null || v.trim().isEmpty) ? msg : null;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _name,
            decoration: const InputDecoration(hintText: 'Họ và tên người nhận'),
            validator: (v) => _required(v, 'Nhập họ tên'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(hintText: 'Số điện thoại'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _address,
            maxLines: 2,
            decoration: const InputDecoration(hintText: 'Địa chỉ nhận hàng'),
            validator: (v) => _required(v, 'Nhập địa chỉ'),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              if (!_formKey.currentState!.validate()) return;
              Navigator.of(context).pop(widget.current.copyWith(
                name: _name.text.trim(),
                phone: _phone.text.trim(),
                address: _address.text.trim(),
              ));
            },
            child: const Text('Lưu địa chỉ'),
          ),
        ],
      ),
    );
  }
}
