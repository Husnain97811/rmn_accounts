import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:rmn_accounts/core/providers/profile_provider.dart';
import 'package:rmn_accounts/utils/views.dart';

class ChartVisibilityProvider with ChangeNotifier {
  bool _showIncome = true;
  bool _showExpense = true;
  bool _showCashFlow = true;

  bool get showIncome => _showIncome;
  bool get showExpense => _showExpense;
  bool get showCashFlow => _showCashFlow;

  void toggleIncome() {
    _showIncome = !_showIncome;
    notifyListeners();
  }

  void toggleExpense() {
    _showExpense = !_showExpense;
    notifyListeners();
  }

  void toggleCashFlow() {
    _showCashFlow = !_showCashFlow;
    notifyListeners();
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with AutomaticKeepAliveClientMixin {
  final user = Supabase.instance.client;
  //here fetch data from profiles tables and match current user and from profiles if it matches then fetch that email and store in userEmail;

  final List<FlSpot> _incomeData = const [
    FlSpot(0, 3),
    FlSpot(1, 5),
    FlSpot(2, 4),
    FlSpot(3, 7),
    FlSpot(4, 6),
    FlSpot(5, 8),
  ];

  final List<FlSpot> _expenseData = const [
    FlSpot(0, 2),
    FlSpot(1, 4),
    FlSpot(2, 3),
    FlSpot(3, 5),
    FlSpot(4, 4),
    FlSpot(5, 6),
  ];

  Widget _buildLineChart(List<FlSpot> spots) {
    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: 5,
        minY: 0,
        maxY: 10,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Colors.blue,
            barWidth: 2,
            belowBarData: BarAreaData(show: false),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart(final Color basecolor) {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 30,
        barTouchData: BarTouchData(enabled: false),
        titlesData: const FlTitlesData(show: false),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: [
          BarChartGroupData(
            x: 0,
            barRods: [BarChartRodData(fromY: 8, color: basecolor, toY: 1)],
          ),
          BarChartGroupData(
            x: 1,
            barRods: [BarChartRodData(toY: 12, color: basecolor)],
          ),
          BarChartGroupData(
            x: 2,
            barRods: [BarChartRodData(toY: 6, color: basecolor)],
          ),
          BarChartGroupData(
            x: 3,
            barRods: [BarChartRodData(toY: 14, color: basecolor)],
          ),
          BarChartGroupData(
            x: 4,
            barRods: [BarChartRodData(toY: 10, color: basecolor)],
          ),
          BarChartGroupData(
            x: 5,
            barRods: [BarChartRodData(toY: 16, color: basecolor)],
          ),
          BarChartGroupData(
            x: 6,
            barRods: [BarChartRodData(toY: 8, color: basecolor)],
          ),
          BarChartGroupData(
            x: 7,
            barRods: [BarChartRodData(toY: 12, color: basecolor)],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    // required IconData icon,
    required Widget chart, // Changed to non-nullable
    required VoidCallback onToggle,
    required bool showValue, // New parameter
  }) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.sp * 0.7),
      ),
      child: Container(
        padding: EdgeInsets.all(12.sp * 0.7),
        width: 24.w,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 13.sp * 0.7,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Visibility(
                      visible: showValue,
                      child: Text(
                        value,
                        style: TextStyle(
                          fontSize: 16.sp * 0.7,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        showValue ? Icons.visibility : Icons.visibility_off,
                        size: 18.sp * 0.7,
                      ),
                      onPressed: onToggle,
                    ),
                    // Icon(icon, size: 20.sp * 0.7),
                  ],
                ),
              ],
            ),
            SizedBox(height: 8.sp * 0.7),
            SizedBox(height: 42.sp * 0.7, child: chart),
          ],
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true; // Preserve state

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAlive

    final authProvider = Provider.of<AuthProvider>(context);

    return Consumer2<ProfileProvider, ChartVisibilityProvider>(
      builder: (context, profileProvider, chartProvider, _) {
        return Scaffold(
          appBar: AppBar(
            toolbarHeight: 33.sp * 0.7,
            title: Padding(
              padding: EdgeInsets.only(left: 30.sp),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    children: [
                      Text(
                        'Dashboard',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'Welcome RMN',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  if (authProvider.currentUser?.email ==
                      "software.rmn@gmail.com")
                    IconButton(
                      tooltip: 'Sign Up for new user',
                      onPressed: () {
                        Navigator.pushNamed(context, '/signup');
                      },
                      icon: Icon(Icons.account_box_outlined, size: 20.sp * 0.7),
                    ),
                ],
              ),
            ),
            backgroundColor: Colors.white,
          ),
          body: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                'assets/images/background_image.png',
                fit: BoxFit.cover,
                color: Colors.black.withOpacity(0.3),
                colorBlendMode: BlendMode.darken,
                // opacity: const AlwaysStoppedAnimation(0.1),
              ),
              SingleChildScrollView(
                child: Column(
                  children: [
                    SizedBox(height: 16.sp * 0.7),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12.sp * 0.7),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Consumer<CashFlowProvider>(
                            builder: (context, value, _) {
                              return _buildMetricCard(
                                title: 'Income',
                                value: value.totalIncome.toString(),
                                // icon: Icons.attach_money,
                                chart: _buildBarChart(Colors.green),
                                onToggle: chartProvider.toggleIncome,
                                showValue: chartProvider.showIncome,
                              );
                            },
                          ),
                          Consumer<CashFlowProvider>(
                            builder: (context, value, _) {
                              return _buildMetricCard(
                                title: 'Expense',
                                value: value.totalExpense.toString(),
                                // icon: Icons.money_off,
                                chart: _buildBarChart(Colors.red),
                                onToggle: chartProvider.toggleExpense,
                                showValue: chartProvider.showExpense,
                              );
                            },
                          ),
                          Consumer<CashFlowProvider>(
                            builder: (context, value, _) {
                              return _buildMetricCard(
                                title: 'CashFlow',
                                value:
                                    (value.totalIncome - value.totalExpense)
                                        .toString(),
                                // icon: Icons.show_chart,
                                chart: _buildLineChart(_expenseData),
                                onToggle: chartProvider.toggleCashFlow,
                                showValue: chartProvider.showCashFlow,
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 6.sp * 0.7),
                    Text(
                      'We Build Your Future',
                      style: GoogleFonts.roadRage(
                        fontSize: 40.sp,
                        // fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 6.sp * 0.7),
                    Container(
                      width: 93.w,
                      // padding: EdgeInsets.symmetric(horizontal: 12.sp * 0.7),
                      child: Card(
                        elevation: 6,
                        child: Padding(
                          padding: EdgeInsets.all(0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: List.generate(
                              6,
                              (index) => Image.asset(
                                fit: BoxFit.fill,
                                'assets/images/s${index + 1}.png',
                                height: 41.sp,
                                // height: 191,
                                width: 41.sp,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
