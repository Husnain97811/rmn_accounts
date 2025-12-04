import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rmn_accounts/utils/views.dart';
import 'package:sidebarx/sidebarx.dart';

// 1. Make Sidebar a StatefulWidget
class Sidebar extends StatefulWidget {
  const Sidebar({super.key});

  @override
  State<Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<Sidebar> {
  // List of screens to preserve state
  final List<Widget> _screens = const [
    DashboardScreen(),
    CustomersScreen(),
    EmployeesScreen(),
    CashFlowScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final sidebarProvider = Provider.of<SidebarProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final loadingProvider = Provider.of<LoadingProvider>(context);

    return Scaffold(
      body: LoadingOverlay(
        child: Row(
          children: [
            SidebarX(
              headerBuilder: (context, extended) {
                return Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          height: 31.sp,
                          padding: EdgeInsets.only(left: 8.sp, top: 0),
                          child: Image(
                            height: 35.sp,
                            width: 35.sp,
                            image: AssetImage('assets/images/logo.png'),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 15.sp),
                  ],
                );
              },

              showToggleButton: false,
              // extendIcon: ,
              controller: sidebarProvider.controller,
              theme: SidebarXTheme(
                width: 43.sp,
                padding: EdgeInsets.only(bottom: 10.sp, left: 18.sp),
                itemMargin: EdgeInsets.symmetric(vertical: 5.sp),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(15),
                    // bottomRight: Radius.circular(15),
                  ),
                ),

                hoverColor: Colors.white,
                hoverIconTheme: IconThemeData(color: Colors.black),
                textStyle: TextStyle(color: Colors.white, fontSize: 11.sp),
                selectedTextStyle: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  fontSize: 12.sp,
                ),

                itemTextPadding: EdgeInsets.only(left: 8.sp),
                selectedItemTextPadding: EdgeInsets.only(left: 8.sp),
                itemDecoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                ),

                selectedItemDecoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),

                  color: AppColors.primary,
                ),
                iconTheme: IconThemeData(
                  color: Colors.blueGrey[800],
                  size: 13.sp,
                ),
                selectedIconTheme: IconThemeData(
                  color: Colors.white,

                  size: 15.sp,
                ),
              ),
              items: [
                SidebarXItem(
                  icon: Icons.dashboard,
                  label: 'Dashboard',
                  onTap: () => sidebarProvider.setSelectedIndex(0),
                ),
                SidebarXItem(
                  icon: Icons.people,
                  label: 'Investors',
                  onTap: () => sidebarProvider.setSelectedIndex(1),
                ),
                SidebarXItem(
                  icon: Icons.people_alt_outlined,
                  label: 'Employee',
                  onTap: () => sidebarProvider.setSelectedIndex(2),
                ),
                SidebarXItem(
                  icon: Icons.attach_money,
                  label: 'Cashflow',
                  onTap: () => sidebarProvider.setSelectedIndex(3),
                ),
                SidebarXItem(
                  icon: Icons.settings,
                  label: 'Settings',
                  onTap: () => sidebarProvider.setSelectedIndex(4),
                ),
              ],
              footerDivider: Divider(color: Colors.white),
              footerItems: [
                SidebarXItem(
                  selectable: false,
                  icon: Icons.logout,
                  label: 'Sign Out',
                  onTap: () async {
                    loadingProvider.startLoading();
                    await Future.delayed(const Duration(seconds: 3));

                    try {
                      authProvider.signOut().then((_) {
                        loadingProvider.stopLoading();
                        // Navigate to the sign-in screen after logout
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          RouteNames.signin,
                          (route) => false,
                        );
                      });
                    } catch (e) {
                      loadingProvider.stopLoading();

                      SupabaseExceptionHandler.showErrorSnackbar(
                        context,
                        e.toString(),
                      );
                    } finally {
                      loadingProvider.stopLoading();
                    }

                    sidebarProvider.setSelectedIndex(
                      0,
                    ); // Reset index on logout
                  },
                ),
              ],
            ),

            Expanded(
              child: IndexedStack(
                index: sidebarProvider.controller.selectedIndex,
                children: _screens,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
