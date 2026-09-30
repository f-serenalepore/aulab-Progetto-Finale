import 'package:aullet/viewmodel/statistics_view_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({Key? key}) : super(key: key);

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  // Filtro principale della pagina
  int _selectedYear = DateTime.now().year;

  // Periodo 1
  int _year1 = DateTime.now().year;
  int? _month1;

  // Periodo 2
  int _year2 = DateTime.now().year;
  int? _month2;

  // Risultato del confronto
  Map<String, dynamic>? _comparison;

  // ==========================================
  // CONFRONTO
  // ==========================================

  Future<void> _doCompare() async {
    final vm = context.read<StatisticsViewModel>();

    final result = await vm.comparePeriods(
      _year1,
      _month1,
      _year2,
      _month2,
    );

    setState(() {
      _comparison = result;
    });
  }

  // ==========================================
  // DROPDOWN ANNO
  // ==========================================

  Widget _buildYearDropdown({required bool isFirst}) {
    final vm = context.watch<StatisticsViewModel>();

    final years = vm.allExpenses
        .map((e) => e.date.year)
        .toSet()
        .toList()
      ..sort();

    final value = isFirst ? _year1 : _year2;

    // Evita problemi se l'anno selezionato
    // non è ancora presente nelle spese
    if (!years.contains(value)) {
      years.add(value);
      years.sort();
    }

    return DropdownButton<int>(
      value: value,
      isExpanded: true,
      items: years.map((y) {
        return DropdownMenuItem<int>(
          value: y,
          child: Text(y.toString()),
        );
      }).toList(),
      onChanged: (y) {
        if (y == null) return;

        setState(() {
          if (isFirst) {
            _year1 = y;
          } else {
            _year2 = y;
          }
        });
      },
    );
  }

  // ==========================================
  // DROPDOWN MESE
  // ==========================================

  Widget _buildMonthDropdown({required bool isFirst}) {
    final value = isFirst ? _month1 : _month2;

    return DropdownButton<int?>(
      value: value,
      isExpanded: true,
      items: [
        const DropdownMenuItem<int?>(
          value: null,
          child: Text('Tutti i mesi'),
        ),
        ...List.generate(12, (i) => i + 1).map((m) {
          return DropdownMenuItem<int?>(
            value: m,
            child: Text(_monthName(m)),
          );
        }),
      ],
      onChanged: (month) {
        setState(() {
          if (isFirst) {
            _month1 = month;
          } else {
            _month2 = month;
          }
        });
      },
    );
  }

  // ==========================================
  // INIT STATE
  // ==========================================

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StatisticsViewModel>().loadExpenses();
    });
  }

  // ==========================================
  // BUILD
  // ==========================================

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<StatisticsViewModel>();

    final years = vm.allExpenses
        .map((e) => e.date.year)
        .toSet()
        .toList()
      ..sort();

    if (!years.contains(_selectedYear)) {
      years.insert(0, _selectedYear);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistiche'),
      ),

      body: vm.isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [

                  // ==========================================
                  // FILTRI ANNO E MESE
                  // ==========================================

                  Row(
                    children: [
                      Expanded(
                        child: DropdownButton<int>(
                          value: _selectedYear,
                          isExpanded: true,
                          items: years.map((y) {
                            return DropdownMenuItem<int>(
                              value: y,
                              child: Text(y.toString()),
                            );
                          }).toList(),
                          onChanged: (y) {
                            if (y == null) return;

                            setState(() {
                              _selectedYear = y;
                            });
                          },
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: DropdownButton<int?>(
                          value: vm.monthFilter,
                          isExpanded: true,
                          items: [
                            const DropdownMenuItem<int?>(
                              value: null,
                              child: Text('Tutti i mesi'),
                            ),
                            ...List.generate(12, (i) => i + 1).map((m) {
                              return DropdownMenuItem<int?>(
                                value: m,
                                child: Text(_monthName(m)),
                              );
                            }),
                          ],
                          onChanged: (m) {
                            vm.setMonthFilter(m);
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ==========================================
                  // TOTALE PERIODO
                  // ==========================================

                  FutureBuilder<double>(
                    future: vm.calculateTotalForPeriod(
                      _selectedYear,
                      vm.monthFilter,
                    ),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const SizedBox(
                          height: 60,
                          child: Center(
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              const Text(
                                'Totale spese',
                                style: TextStyle(
                                  fontSize: 16,
                                ),
                              ),

                              const SizedBox(height: 8),

                              Text(
                                '€ ${snapshot.data!.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  // ==========================================
                  // GRAFICO MENSILE
                  // ==========================================

                  const Text(
                    'Spese per mese',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 16),

                  SizedBox(
                    height: 300,
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,

                        maxY: _computeMaxY(
                          vm,
                          _selectedYear,
                        ),

                        gridData: const FlGridData(
                          show: false,
                        ),

                        borderData: FlBorderData(
                          show: false,
                        ),

                        titlesData: FlTitlesData(

                          // Valori sopra le barre
                          topTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 30,
                              getTitlesWidget: (v, meta) {
                                final totals =
                                    vm.calculateMonthlyExpenses(
                                  _selectedYear,
                                );

                                final value =
                                    totals[v.toInt()] ?? 0;

                                if (value == 0) {
                                  return const SizedBox();
                                }

                                return Text(
                                  value.toStringAsFixed(0),
                                  style: const TextStyle(
                                    fontSize: 10,
                                  ),
                                );
                              },
                            ),
                          ),

                          // Mesi sull'asse X
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 28,
                              getTitlesWidget: (v, meta) {
                                return Text(
                                  _monthName(v.toInt() + 1),
                                  style: const TextStyle(
                                    fontSize: 11,
                                  ),
                                );
                              },
                            ),
                          ),

                          // Asse Y nascosto
                          leftTitles: const AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: false,
                            ),
                          ),

                          // Asse destro nascosto
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: false,
                            ),
                          ),
                        ),

                        // Barre
                        barGroups: List.generate(
                          12,
                          (index) {
                            final month = index + 1;

                            final totals =
                                vm.calculateMonthlyExpenses(
                              _selectedYear,
                            );

                            final value =
                                totals[month] ?? 0;

                            return BarChartGroupData(
                              x: index,
                              barRods: [
                                BarChartRodData(
                                  toY: value,
                                  width: 18,
                                  borderRadius:
                                      BorderRadius.circular(4),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ==========================================
                  // GRAFICO PER CATEGORIA
                  // ==========================================

                  const Text(
                    'Spese per categoria',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 16),

                  _buildCategoryChart(vm),

                  const SizedBox(height: 32),

                  // ==========================================
                  // CONFRONTO TRA DUE PERIODI
                  // ==========================================

                  const Text(
                    'Confronto tra periodi',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ------------------------------------------
                  // PERIODO 1
                  // ------------------------------------------

                  const Text(
                    'Seleziona periodo 1',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Expanded(
                        child: _buildYearDropdown(
                          isFirst: true,
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: _buildMonthDropdown(
                          isFirst: true,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // ------------------------------------------
                  // PERIODO 2
                  // ------------------------------------------

                  const Text(
                    'Seleziona periodo 2',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Expanded(
                        child: _buildYearDropdown(
                          isFirst: false,
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: _buildMonthDropdown(
                          isFirst: false,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // ------------------------------------------
                  // PULSANTE CONFRONTA
                  // ------------------------------------------

                  ElevatedButton(
                    onPressed: _doCompare,
                    child: const Text('Confronta'),
                  ),

                  const SizedBox(height: 24),

                  // ------------------------------------------
                  // GRAFICO COMPARATIVO
                  // ------------------------------------------

                  _buildComparisonChart(),

                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  // ==========================================
  // GRAFICO CATEGORIE
  // ==========================================

  Widget _buildCategoryChart(
    StatisticsViewModel vm,
  ) {
    final expensesByCategory =
        vm.calculateExpensesByCategory(
      _selectedYear,
    );

    if (expensesByCategory.isEmpty) {
      return const Center(
        child: Text(
          'Nessuna spesa disponibile per questo periodo.',
        ),
      );
    }

    final sections =
        expensesByCategory.entries.map((entry) {
      return PieChartSectionData(
        value: entry.value,
        title: entry.key.name,
        radius: 80,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      );
    }).toList();

    return SizedBox(
      height: 300,
      child: PieChart(
        PieChartData(
          sections: sections,
          centerSpaceRadius: 40,
          sectionsSpace: 2,
        ),
      ),
    );
  }

  // ==========================================
  // GRAFICO COMPARATIVO
  // ==========================================

  Widget _buildComparisonChart() {
    // Se non abbiamo ancora premuto "Confronta",
    // non mostriamo nulla.
    if (_comparison == null) {
      return const SizedBox.shrink();
    }

    final period1 =
        (_comparison!['period1'] as num).toDouble();

    final period2 =
        (_comparison!['period2'] as num).toDouble();

    final difference =
        (_comparison!['difference'] as num).toDouble();

    final percent =
        (_comparison!['percentChange'] as num).toDouble();

    return Column(
      children: [

        // ==========================================
        // BAR CHART COMPARATIVO
        // ==========================================

        SizedBox(
          height: 300,
          child: BarChart(
            BarChartData(

              // Mostra la griglia
              gridData: const FlGridData(
                show: true,
              ),

              // Nasconde il bordo
              borderData: FlBorderData(
                show: false,
              ),

              // Barre
              barGroups: [
                BarChartGroupData(
                  x: 0,
                  barRods: [
                    BarChartRodData(
                      toY: period1,
                      width: 40,
                      borderRadius:
                          BorderRadius.circular(4),
                    ),
                  ],
                ),

                BarChartGroupData(
                  x: 1,
                  barRods: [
                    BarChartRodData(
                      toY: period2,
                      width: 40,
                      borderRadius:
                          BorderRadius.circular(4),
                    ),
                  ],
                ),
              ],

              // Titoli assi
              titlesData: FlTitlesData(

                // Etichette sotto le colonne
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (
                      value,
                      meta,
                    ) {
                      String text;

                      switch (value.toInt()) {
                        case 0:
                          text = 'Periodo 1';
                          break;

                        case 1:
                          text = 'Periodo 2';
                          break;

                        default:
                          text = '';
                      }

                      return Text(
                        text,
                        style: const TextStyle(
                          fontSize: 12,
                        ),
                      );
                    },
                  ),
                ),

                // Asse Y
                leftTitles: const AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                  ),
                ),

                // Nascondiamo asse destro
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: false,
                  ),
                ),

                // Nascondiamo asse superiore
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: false,
                  ),
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // ==========================================
        // RISULTATI DEL CONFRONTO
        // ==========================================

        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [

                Text(
                  'Periodo 1: € ${period1.toStringAsFixed(2)}',
                ),

                const SizedBox(height: 8),

                Text(
                  'Periodo 2: € ${period2.toStringAsFixed(2)}',
                ),

                const SizedBox(height: 12),

                Text(
                  'Differenza: € ${difference.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  'Variazione: ${percent.toStringAsFixed(1)}%',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // CALCOLO MASSIMO ASSE Y
  // ==========================================

  double _computeMaxY(
    StatisticsViewModel vm,
    int year,
  ) {
    final totals =
        vm.calculateMonthlyExpenses(year);

    final maxValue =
        totals.values.fold<double>(
      0,
      (max, value) {
        return value > max ? value : max;
      },
    );

    if (maxValue == 0) {
      return 100;
    }

    return maxValue * 1.2;
  }

  // ==========================================
  // NOME DEL MESE
  // ==========================================

  String _monthName(int month) {
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

    if (month < 1 || month > 12) {
      return '';
    }

    return months[month - 1];
  }
}