import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../utils/app_theme.dart';
import '../../services/api_service.dart';
import '../../models/wallet_model.dart';
import '../../widgets/app_dialogs.dart';

// Helper để tạo full URL cho ảnh uploads
String? _getValidImageUrl(String? url) {
  if (url == null || url.isEmpty) return null;
  if (url.startsWith('http')) return url;
  // Backend trả về "/uploads/...", cần thêm base URL
  return '${ApiService.baseUrl.replaceAll("/api", "")}$url';
}

class WalletManagementScreen extends StatefulWidget {
  const WalletManagementScreen({Key? key}) : super(key: key);

  @override
  State<WalletManagementScreen> createState() => _WalletManagementScreenState();
}

class _WalletManagementScreenState extends State<WalletManagementScreen> {
  List<WalletTransaction> _transactions = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final transactions = await apiService.getAllTransactions();
      setState(() {
        _transactions = transactions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _approveDeposit(WalletTransaction transaction) async {
    final confirm = await showConfirmDialog(
      context,
      title: 'Duyệt nạp tiền',
      message: 'Xác nhận duyệt nạp ${_formatCurrency(transaction.amount)} VND?',
    );

    if (confirm) {
      try {
        await apiService.approveDeposit(transaction.id);
        await showSuccessDialog(
          context,
          message: 'Đã duyệt giao dịch thành công',
        );
        _loadTransactions();
      } catch (e) {
        await showErrorDialog(
          context,
          message: e.toString().replaceAll('Exception: ', ''),
        );
      }
    }
  }

  String _formatCurrency(double amount) {
    return NumberFormat('#,###', 'vi_VN').format(amount);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        title: const Text('Quản lý ví tiền'),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : _error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: AppColors.error,
                  ),
                  const SizedBox(height: 16),
                  Text(_error!, style: AppTypography.bodyMedium),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadTransactions,
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            )
          : DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  const TabBar(
                    indicatorColor: AppColors.primary,
                    labelColor: AppColors.primary,
                    unselectedLabelColor: AppColors.textMuted,
                    tabs: [
                      Tab(text: 'Chờ duyệt'),
                      Tab(text: 'Tất cả'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildTransactionList(
                          _transactions.where((t) => t.isPending).toList(),
                        ),
                        _buildTransactionList(_transactions),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildTransactionList(List<WalletTransaction> list) {
    if (list.isEmpty) {
      return const Center(
        child: Text('Không có giao dịch nào', style: AppTypography.bodyMedium),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadTransactions,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: list.length,
        itemBuilder: (context, index) => _buildTransactionCard(list[index]),
      ),
    );
  }

  Widget _buildTransactionCard(WalletTransaction tx) {
    final isDeposit = tx.type == 'Deposit';
    final isPending = tx.isPending;

    // Fallback: extract image URL from description if proofImageUrl is empty (for old transactions)
    String? displayImageUrl = tx.proofImageUrl;
    String displayDescription = tx.description ?? '';

    if ((displayImageUrl == null || displayImageUrl.isEmpty) &&
        displayDescription.contains('| Proof: ')) {
      final parts = displayDescription.split('| Proof: ');
      displayDescription = parts[0].trim();
      if (parts.length > 1) {
        displayImageUrl = parts[1].trim();
      }
    }

    // Convert relative URL to absolute URL
    displayImageUrl = _getValidImageUrl(displayImageUrl);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPending
              ? Colors.orange.withOpacity(0.5)
              : AppColors.borderDark,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (isDeposit ? Colors.green : Colors.red).withOpacity(
                    0.1,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isDeposit ? Icons.add_circle : Icons.remove_circle,
                  color: isDeposit ? Colors.green : Colors.red,
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
                    if (tx.memberName != null)
                      Text(
                        'Thành viên: ${tx.memberName}',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    Text(
                      DateFormat('dd/MM/yyyy HH:mm').format(tx.createdAt),
                      style: AppTypography.bodyMedium.copyWith(fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${isDeposit ? '+' : '-'}${_formatCurrency(tx.amount)} VND',
                    style: AppTypography.bodyLarge.copyWith(
                      color: isDeposit ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  _buildStatusBadge(tx.status),
                ],
              ),
            ],
          ),
          if (displayDescription.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(displayDescription, style: AppTypography.bodyMedium),
          ],
          if (displayImageUrl != null && displayImageUrl.isNotEmpty) ...[
            const SizedBox(height: 12),
            InkWell(
              onTap: () => _viewFullImage(displayImageUrl!),
              child: Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.borderDark),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    displayImageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Center(
                      child: Text('Không thể tải ảnh minh chứng'),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Link: $displayImageUrl',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.primary,
                fontSize: 11,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (isPending && isDeposit) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _approveDeposit(tx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
                child: const Text(
                  'Duyệt nạp tiền',
                  style: TextStyle(color: Colors.black),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        tx.statusDisplay,
        style: AppTypography.bodyMedium.copyWith(color: color, fontSize: 11),
      ),
    );
  }

  void _viewFullImage(String url) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              child: Image.network(
                url,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const Center(
                  child: Text(
                    'Lỗi tải ảnh',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
