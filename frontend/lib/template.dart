import 'package:flutter/material.dart';
import 'package:plant_it/environment.dart';
import 'package:plant_it/deployment_status_banner.dart';
import 'package:plant_it/event/events_page.dart';
import 'package:plant_it/homepage/homepage.dart';
import 'package:plant_it/more/more_page.dart';
import 'package:plant_it/observation/observation_journal_page.dart';
import 'package:plant_it/primary_navigation_bar.dart';
import 'package:plant_it/search/search_page.dart';

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
  late final List<Widget?> _pages;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _env = widget.env;
    _pages = List<Widget?>.filled(5, null);
    _pages[0] = HomePage(env: _env);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool useNavigationRail = constraints.maxWidth >= 1000;
        final Widget content = Container(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                DeploymentStatusBanner(env: _env),
                Expanded(
                  child: IndexedStack(
                    index: _currentIndex,
                    children: List<Widget>.generate(
                      _pages.length,
                      (index) => _pages[index] ?? const SizedBox.shrink(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
        return Scaffold(
          key: navigatorKey,
          body: useNavigationRail
              ? Row(
                  children: [
                    SafeArea(
                      right: false,
                      child: PrimaryNavigationRail(
                        selectedIndex: _currentIndex,
                        onDestinationSelected: _selectPage,
                      ),
                    ),
                    const VerticalDivider(width: 1),
                    Expanded(child: content),
                  ],
                )
              : content,
          bottomNavigationBar: useNavigationRail
              ? null
              : PrimaryNavigationBar(
                  selectedIndex: _currentIndex,
                  onDestinationSelected: _selectPage,
                ),
        );
      },
    );
  }

  void _selectPage(int index) {
    if (_pages[index] == null) {
      _pages[index] = _createPage(index);
    }
    setState(() => _currentIndex = index);
  }

  Widget _createPage(int index) {
    return switch (index) {
      0 => HomePage(env: _env),
      1 => EventsPage(env: _env),
      2 => SearchPage(env: _env),
      3 => ObservationJournalPage(env: _env),
      4 => MorePage(env: _env),
      _ => throw RangeError.index(index, _pages),
    };
  }
}
