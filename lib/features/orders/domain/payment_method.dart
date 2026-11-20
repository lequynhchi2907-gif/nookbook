/// Phương thức thanh toán chọn ở màn Thanh toán.
/// Backend chưa lưu phương thức này nên app chỉ nhớ trong máy theo mã đơn.
enum PaymentMethod { cod, bank }

extension PaymentMethodX on PaymentMethod {
  String get title => switch (this) {
        PaymentMethod.cod => 'Thanh toán khi nhận hàng',
        PaymentMethod.bank => 'Chuyển khoản ngân hàng',
      };

  String get subtitle => switch (this) {
        PaymentMethod.cod => 'Trả tiền mặt khi nhận sách (COD)',
        PaymentMethod.bank => 'Quét mã QR hoặc chuyển khoản thủ công',
      };

  /// Ngắn gọn, dùng ở trang thành công và chi tiết đơn.
  String get shortLabel => switch (this) {
        PaymentMethod.cod => 'Khi nhận hàng (COD)',
        PaymentMethod.bank => 'Chuyển khoản ngân hàng',
      };
}
