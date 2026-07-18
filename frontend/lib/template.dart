import 'package:flutter/material.dart';
import 'package:animated_bottom_navigation_bar/animated_bottom_navigation_bar.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:plant_it/event/add_new_event.dart';
import 'package:plant_it/commons.dart';
import 'package:plant_it/environment.dart';
import 'package:plant_it/event/events_page.dart';
import 'package:plant_it/homepage/homepage.dart';
import 'package:plant_it/more/more_page.dart';
import 'package:plant_it/search/search_page.dart';
import 'package:plant_it/observation/add_observation_page.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class TemplatePage extends StatefulWidget {
  final Environment env;

  const TemplatePage({
    super.key,
    required this.env,
  });

  @override
  State<TemplatePage> createState() => _TemplatePageState();
}

class _TemplatePageState extends State<TemplatePage> {
  late final Environment _env;
  final _bottombarIconList = [
    Icons.home_outlined,
    Icons.calendar_month_outlined,
    Icons.search_outlined,
    Icons.menu_outlined,
  ];
  late List<Widget> _bottombarPages;
  int _currentIndex = 0;
  final Color _iconActiveColor = const Color.fromARGB(255, 55, 189, 6);
  final Color _iconNotActiveColor = const Color.fromARGB(255, 156, 192, 172);

  @override
  void initState() {
    super.initState();
    _env = widget.env;
  }

  @override
  Widget build(BuildContext context) {
    _bottombarPages = [
      HomePage(
        env: _env,
      ),
      EventsPage(
        env: _env,
      ),
      SeachPage(
        env: _env,
      ),
      MorePage(
        env: _env,
      ),
    ];
    return _buildTemplate();
  }

  Widget _buildTemplate() {
    return Scaffold(
        key: navigatorKey,
        extendBody: true,
        body: Container(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: SafeArea(
            bottom: false,
            child: _bottombarPages[_currentIndex],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _showQuickAdd,
          child: const Icon(Icons.add),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: AnimatedBottomNavigationBar.builder(
          itemCount: _bottombarIconList.length,
          tabBuilder: (int index, bool isActive) {
            return Icon(
              _bottombarIconList[index],
              size: 24,
              color: isActive ? _iconActiveColor : _iconNotActiveColor,
            );
          },
          activeIndex: _currentIndex,
          backgroundColor: const Color.fromRGBO(24, 44, 37, 1),
          gapLocation: GapLocation.center,
          notchSmoothness: NotchSmoothness.softEdge,
          leftCornerRadius: 20,
          rightCornerRadius: 20,
          splashColor: const Color.fromRGBO(24, 44, 37, 1),
          onTap: (index) => setState(() => _currentIndex = index),
        ));
  }

  void _showQuickAdd() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF182C25),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _quickAddAction(
                context: sheetContext,
                icon: Icons.camera_alt_outlined,
                label: AppLocalizations.of(context).recordTrailFind,
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  goToPageSlidingUp(
                    context,
                    AddObservationPage(env: _env),
                  );
                },
              ),
              const SizedBox(height: 12),
              _quickAddAction(
                context: sheetContext,
                icon: Icons.event_available_outlined,
                label: AppLocalizations.of(context).addNewEvent,
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  goToPageSlidingUp(context, AddNewEventPage(env: _env));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _quickAddAction({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: const Color(0xFF315D4E),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 64),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(icon, color: const Color(0xFFC7F9CC), size: 28),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.white),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
