import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../viewmodels/auth_viewmodel.dart';
import 'package:intl/intl.dart';
import '../../utils/app_theme.dart';
import '../../services/api_service.dart';
import '../../models/wallet_model.dart';
import '../../widgets/app_dialogs.dart';

/// Wallet screen for users
class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  List<WalletTransaction> _transactions = [];
  bool _isLoading = true;
  String _filter = 'All';

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() => _isLoading = true);
    try {
      if (mounted) {
        context.read<AuthViewModel>().refreshProfile();
      }
      final transactions = await apiService.getTransactions();
      setState(() {
        _transactions = transactions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  List<WalletTransaction> get _filteredTransactions {
    if (_filter == 'All') return _transactions;
    return _transactions.where((t) => t.type == _filter).toList();
  }

  void _showDepositForm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DepositFormSheet(
        onDepositRequested: () {
          Navigator.pop(context);
          _loadTransactions();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context);
    final balance = authViewModel.currentUser?.walletBalance ?? 0.0;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        title: const Text('Ví của tôi'),
        automaticallyImplyLeading: false,
      ),
      body: RefreshIndicator(
        onRefresh: _loadTransactions,
        color: AppColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Balance Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary,
                      AppColors.primary.withOpacity(0.7),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Text(
                      'Số dư hiện tại',
                      style: TextStyle(color: Colors.black54, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${NumberFormat('#,###', 'vi_VN').format(balance)} VND',
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _showDepositForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black.withOpacity(0.2),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        icon: const Icon(Icons.add),
                        label: const Text(
                          'Nạp tiền',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Filter chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('All', 'Tất cả'),
                    _buildFilterChip('Deposit', 'Nạp tiền'),
                    _buildFilterChip('Payment', 'Thanh toán'),
                    _buildFilterChip('Refund', 'Hoàn tiền'),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Transaction history
              Text(
                'Lịch sử giao dịch',
                style: AppTypography.heading2.copyWith(fontSize: 18),
              ),
              const SizedBox(height: 12),

              if (_isLoading)
                const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                )
              else if (_filteredTransactions.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: Text(
                      'Không có giao dịch',
                      style: AppTypography.bodyMedium,
                    ),
                  ),
                )
              else
                ..._filteredTransactions.map((t) => _buildTransactionCard(t)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _filter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) => setState(() => _filter = value),
        backgroundColor: AppColors.surfaceDark,
        selectedColor: AppColors.primary,
        labelStyle: TextStyle(color: isSelected ? Colors.black : Colors.white),
        checkmarkColor: Colors.black,
      ),
    );
  }

  String _getValidImageUrl(String path) {
    if (path.startsWith('http')) return path;
    // Remove leading slash if present
    final cleanPath = path.startsWith('/') ? path.substring(1) : path;
    return '${ApiService.baseUrl.replaceAll('/api', '')}/$cleanPath';
  }

  void _showTransactionDetail(WalletTransaction tx) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Chi tiết giao dịch',
                      style: AppTypography.heading2.copyWith(fontSize: 20),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.textMuted),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(color: AppColors.borderDark, height: 32),

              // Amount and Type
              Center(
                child: Column(
                  children: [
                    Text(
                      tx.typeDisplay.toUpperCase(),
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${tx.type == 'Payment' ? '-' : '+'}${NumberFormat('#,###', 'vi_VN').format(tx.amount.abs())} VND',
                      style: const TextStyle(
                        fontFamily: 'Lexend',
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildStatusBadge(tx.status, isLarge: true),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Details
              _buildDetailRow('Mã giao dịch', '#${tx.id}'),
              _buildDetailRow(
                'Thời gian',
                DateFormat('dd/MM/yyyy HH:mm').format(tx.createdAt),
              ),
              if (tx.description != null && tx.description!.isNotEmpty)
                _buildDetailRow('Nội dung', tx.description!),

              // Proof Image
              if (tx.proofImageUrl != null && tx.proofImageUrl!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'Ảnh chứng từ:',
                  style: TextStyle(color: AppColors.textMuted),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (_) => Dialog(
                        backgroundColor: Colors.transparent,
                        insetPadding: EdgeInsets.zero,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            InteractiveViewer(
                              child: Image.network(
                                _getValidImageUrl(tx.proofImageUrl!),
                                fit: BoxFit.contain,
                              ),
                            ),
                            Positioned(
                              top: 40,
                              right: 20,
                              child: IconButton(
                                icon: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 30,
                                ),
                                onPressed: () => Navigator.pop(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      _getValidImageUrl(tx.proofImageUrl!),
                      height: 150,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Center(
                        child: Text(
                          'Không thể tải ảnh',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(color: AppColors.textMuted),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(WalletTransaction tx) {
    final isDeposit = tx.type == 'Deposit';
    final isPayment = tx.type == 'Payment';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: InkWell(
        onTap: () => _showTransactionDetail(tx),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color:
                      (isDeposit
                              ? Colors.green
                              : isPayment
                              ? Colors.red
                              : Colors.blue)
                          .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isDeposit
                      ? Icons.add_circle
                      : isPayment
                      ? Icons.remove_circle
                      : Icons.refresh,
                  color: isDeposit
                      ? Colors.green
                      : isPayment
                      ? Colors.red
                      : Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tx.typeDisplay,
                      style: AppTypography.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      DateFormat('dd/MM/yyyy HH:mm').format(tx.createdAt),
                      style: AppTypography.bodyMedium.copyWith(fontSize: 12),
                    ),
                    if (tx.description != null && tx.description!.isNotEmpty)
                      Text(
                        tx.description!,
                        style: AppTypography.bodyMedium.copyWith(fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${isPayment ? '-' : '+'}${NumberFormat('#,###', 'vi_VN').format(tx.amount.abs())} VND',
                    style: TextStyle(
                      color: isDeposit
                          ? Colors.green
                          : isPayment
                          ? Colors.red
                          : Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  _buildStatusBadge(tx.status),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status, {bool isLarge = false}) {
    Color color;
    switch (status) {
      case 'Pending':
        color = Colors.orange;
        break;
      case 'Completed':
        color = Colors.green;
        break;
      case 'Rejected':
        color = Colors.red;
        break;
      default:
        color = AppColors.textMuted;
    }

    final tx = WalletTransaction(
      id: 0,
      amount: 0,
      type: '',
      status: status,
      createdAt: DateTime.now(),
    );

    return Container(
      margin: EdgeInsets.only(top: isLarge ? 0 : 4),
      padding: EdgeInsets.symmetric(
        horizontal: isLarge ? 12 : 6,
        vertical: isLarge ? 6 : 2,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(isLarge ? 8 : 4),
      ),
      child: Text(
        tx.statusDisplay,
        style: TextStyle(
          color: color,
          fontSize: isLarge ? 14 : 10,
          fontWeight: isLarge ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}

/// Deposit form bottom sheet
class DepositFormSheet extends StatefulWidget {
  final VoidCallback onDepositRequested;

  const DepositFormSheet({super.key, required this.onDepositRequested});

  @override
  State<DepositFormSheet> createState() => _DepositFormSheetState();
}

class _DepositFormSheetState extends State<DepositFormSheet> {
  final _amountController = TextEditingController(text: '100000');
  final _descController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  File? _proofImage;
  bool _isLoading = false;

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (pickedFile != null) {
        setState(() {
          _proofImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      print('Picker Error: $e');
      if (mounted) {
        showErrorDialog(context, message: 'Lỗi chọn ảnh: $e');
      }
    }
  }

  Future<void> _submitDeposit() async {
    final amount = double.tryParse(_amountController.text.replaceAll(',', ''));
    if (amount == null || amount <= 0) {
      showErrorDialog(context, message: 'Vui lòng nhập số tiền hợp lệ');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Upload ảnh chứng từ trước nếu có
      String? proofImageUrl;
      if (_proofImage != null) {
        proofImageUrl = await apiService.uploadAvatar(_proofImage!);
      }

      await apiService.requestDeposit(
        amount: amount,
        description: _descController.text,
        proofImageUrl: proofImageUrl,
      );
      await showSuccessDialog(
        context,
        message: 'Yêu cầu nạp tiền đã được gửi. Vui lòng chờ admin duyệt.',
      );
      widget.onDepositRequested();
    } catch (e) {
      await showErrorDialog(
        context,
        message: e.toString().replaceAll('Exception: ', ''),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textMuted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Nạp tiền',
            style: AppTypography.heading2.copyWith(fontSize: 20),
          ),
          const SizedBox(height: 20),

          // Amount
          Text('Số tiền (VND)', style: AppTypography.bodyLarge),
          const SizedBox(height: 8),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            style: AppTypography.bodyLarge,
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.surfaceDark,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.attach_money),
            ),
          ),
          const SizedBox(height: 16),

          // Description
          Text('Ghi chú', style: AppTypography.bodyLarge),
          const SizedBox(height: 8),
          TextField(
            controller: _descController,
            style: AppTypography.bodyLarge,
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.surfaceDark,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              hintText: 'VD: Nạp tiền qua MoMo',
            ),
          ),
          const SizedBox(height: 16),

          // Image Picker
          Text('Ảnh chứng từ', style: AppTypography.bodyLarge),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              height: 150,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.surfaceDark,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderDark),
              ),
              child: _proofImage != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        _proofImage!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                      ),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(
                          Icons.add_photo_alternate_outlined,
                          size: 48,
                          color: AppColors.textMuted,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Nhấn để chọn ảnh chứng từ',
                          style: TextStyle(color: AppColors.textMuted),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 24),

          // Submit
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submitDeposit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text(
                      'Gửi yêu cầu',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descController.dispose();
    super.dispose();
  }
}
