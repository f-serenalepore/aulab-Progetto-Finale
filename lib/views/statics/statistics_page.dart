import 'package:aullet/viewmodel/statistics_view_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  int _selectedYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StatisticsViewModel>().loadExpenses();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<StatisticsViewModel>();

    // Recupera gli anni presenti nelle spese
    final yearList = vm.allExpenses.map((e) => e.date.year).toSet().toList()
      ..sort();

    // Aggiunge l'anno corrente se non è ancora presente
    if (!yearList.contains(_selectedYear)) {
      yearList.insert(0, _selectedYear);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Statistiche Mensili')),

      body: vm.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // -------------------------
                  // SELETTORE ANNO
                  // -------------------------
                  DropdownButton<int>(
                    value: _selectedYear,
                    isExpanded: true,
                    items: yearList.map((year) {
                      return DropdownMenuItem<int>(
                        value: year,
                        child: Text(year.toString()),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value == null) return;

                      setState(() {
                        _selectedYear = value;
                      });
                    },
                  ),

                  const SizedBox(height: 24),

                  // -------------------------
                  // GRAFICO
                  // -------------------------
                  Expanded(child: _buildChart(vm)),
                ],
              ),
            ),
    );
  }

  Widget _buildChart(StatisticsViewModel vm) {
    final monthlyExpenses = vm.calculateMonthlyExpenses(_selectedYear);

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,

        // Valore massimo dell'asse Y
        maxY: _calculateMaxY(monthlyExpenses),

        // Titoli e impostazioni degli assi
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),

          // Asse X: mesi
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                const months = [
                  'Gen',
                  'Feb',
                  'Mar',
                  'Apr',
                  'Mag',
                  'Giu',
                  'Lug',
                  'Ago',
                  'Set',
                  'Ott',
                  'Nov',
                  'Dic',
                ];

                final index = value.toInt();

                if (index < 0 || index >= months.length) {
                  return const SizedBox();
                }

                return Text(
                  months[index],
                  style: const TextStyle(fontSize: 11),
                );
              },
            ),
          ),

          // Asse Y
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 45),
          ),
        ),

        // Barre
        barGroups: List.generate(12, (index) {
          final month = index + 1;
          final amount = monthlyExpenses[month] ?? 0;

          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: amount,
                width: 18,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          );
        }),
      ),
    );
  }

  double _calculateMaxY(Map<int, double> monthlyExpenses) {
    final maxExpense = monthlyExpenses.values.fold<double>(
      0,
      (max, value) => value > max ? value : max,
    );

    if (maxExpense == 0) {
      return 100;
    }

    return maxExpense * 1.2;
  }
}
