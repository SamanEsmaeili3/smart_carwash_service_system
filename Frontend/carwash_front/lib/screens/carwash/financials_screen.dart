import 'package:carwash_front/services/utiles.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/financials_provider.dart';
import '../../constants/app_colors.dart';
import '../../models/financials_model.dart';

class FinancialsScreen extends StatefulWidget {
  const FinancialsScreen({super.key});

  @override
  State<FinancialsScreen> createState() => _FinancialsScreenState();
}

class _FinancialsScreenState extends State<FinancialsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<FinancialsProvider>(context, listen: false).fetchFinancials();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FinancialsProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.financialSummary == null) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Error: ${provider.error}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => provider.fetchFinancials(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (provider.financialSummary == null) {
          return const Center(child: Text('No financial data available.'));
        }

        final summary = provider.financialSummary!;

        return RefreshIndicator(
          onRefresh: () => provider.fetchFinancials(),
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              _TotalEarningsCard(totalEarnings: summary.totalEarnings),
              const SizedBox(height: 24),
              Text(
                'Transaction History',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              _TransactionList(transactions: summary.transactions),
            ],
          ),
        );
      },
    );
  }
}

class _TotalEarningsCard extends StatelessWidget {
  final double totalEarnings;

  const _TotalEarningsCard({required this.totalEarnings});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      color: AppColors.secondary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Text(
              'Total Earnings',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${formatMoney(totalEarnings)} Toman',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TransactionList extends StatelessWidget {
  final List<Transaction> transactions;

  const _TransactionList({required this.transactions});

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) {
      return const Center(child: Text('No transactions yet.'));
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final transaction = transactions[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            title: Text(
              'Order #${transaction.id}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('Customer: ${transaction.customerName}'),
            trailing: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${formatMoney(transaction.totalPrice)} Toman',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  transaction.completedAt,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

