//widgets/financial_chart.dart

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class FinancialDashboardChart extends StatefulWidget {
  final Map<String, dynamic> analytics;

  const FinancialDashboardChart({
    super.key,
    required this.analytics,
  });

  @override
  State<FinancialDashboardChart> createState() =>
      _FinancialDashboardChartState();
}

class _FinancialDashboardChartState extends State<FinancialDashboardChart> {
  String? selectedBranch;

List<dynamic> get data {
  final br = widget.analytics['branch_revenue'] 
        ?? widget.analytics['branchRevenue'] 
        ?? widget.analytics['branches'];
  if (br is List) return br;
  return [];
}
  List<dynamic> get filteredData {
    if (selectedBranch == null) return data;
    return data.where((e) => e['branch'] == selectedBranch).toList();
  }

  @override
  Widget build(BuildContext context) {
 final online =
    (widget.analytics['online_percentage'] as num?)?.toDouble() ?? 0.0;
final cash =
    (widget.analytics['cash_percentage'] as num?)?.toDouble() ?? 0.0;
    final tokenAmount = widget.analytics['total_token_amount'] ?? 0;

    final branchTotal = selectedBranch == null
        ? (widget.analytics['total_amount'] ?? 0).toDouble()
        : filteredData.fold<double>(
            0.0,
            (sum, item) =>
              sum + ((item['total'] as num?)?.toDouble() ?? 0.0),
          );
    if (widget.analytics.isEmpty) {
  return const Center(child: Text("No Analytics Data"));
}
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _infoCard(
                        "Payment Mode",
                        "Online: ${online.toInt()}% | Cash: ${cash.toInt()}%",
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _infoCard(
                        "Token Amount",
                        "₹ $tokenAmount",
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _branchDropdown(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _infoCard(
                  "Branch Amount",
                  "₹ $branchTotal",
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(child: _buildPieChart(online, cash)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildDonutChart(branchTotal)),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: _buildBarChart(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _infoCard(String title, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 11)),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _branchDropdown() {
    if (data.isEmpty) {
  return const Center(child: Text("No Branch Data"));
}
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(6),
      ),
      child: DropdownButton<String>(
        isExpanded: true,
        underline: const SizedBox(),
        hint: const Text("Select Branch"),
        value: selectedBranch,
        items: data.map<DropdownMenuItem<String>>((item) {
          return DropdownMenuItem<String>(
            value: item['branch'].toString(),
            child: Text(item['branch'].toString()),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            selectedBranch = value;
          });
        },
      ),
    );
  }

  Widget _buildPieChart(double online, double cash) {
    return _card(
      title: "Payment Method",
      child: SizedBox(
        height: 220,
        child: PieChart(
          PieChartData(
            sections: [
              PieChartSectionData(
                  value: online, color: Colors.orange),
              PieChartSectionData(
                  value: cash, color: Colors.amber),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDonutChart(num total) {
    return _card(
      title: "Branch Total",
      child: SizedBox(
        height: 220,
        child: PieChart(
          PieChartData(
            centerSpaceRadius: 40,
            sections: [
              PieChartSectionData(
                value: total.toDouble(),
                color: Colors.red,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBarChart() {
    if (filteredData.isEmpty) {
      return const Center(child: Text("No Data"));
    }

    return _card(
      title: "Revenue",
      child: SizedBox(
        height: 400,
        child: BarChart(
          BarChartData(
            maxY: _getMaxY(),
            barGroups:
                List.generate(filteredData.length, (index) {
              final item = filteredData[index];
              return BarChartGroupData(
                x: index,
                barRods: [
                  BarChartRodData(
                    toY:
                       (item['total'] as num?)?.toDouble() ?? 0.0,
                    color: Colors.blue,
                    width: 20,
                  ),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _card({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
                  const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  double _getMaxY() {
    double maxVal = 0;
    for (var item in filteredData) {
      final value =
          (item['total'] as num?)?.toDouble() ?? 0.0;
      if (value > maxVal) maxVal = value;
    }
    return maxVal == 0 ? 100 : maxVal * 1.2;
  }
}