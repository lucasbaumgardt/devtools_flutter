import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'theme.dart';
import 'tools/tool_catalog.dart';

class DevToolsApp extends StatefulWidget {
  const DevToolsApp({super.key});

  @override
  State<DevToolsApp> createState() => _DevToolsAppState();
}

class _DevToolsAppState extends State<DevToolsApp> {
  // Follows the system theme until the user picks one.
  ThemeMode _themeMode = ThemeMode.system;

  void _toggleTheme(Brightness current) {
    setState(() {
      _themeMode = current == Brightness.dark
          ? ThemeMode.light
          : ThemeMode.dark;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DevTools',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      themeMode: _themeMode,
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [Locale('pt', 'BR')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: HomeShell(onToggleTheme: _toggleTheme),
    );
  }
}

/// Sidebar with the tools on wide screens; a drawer menu on narrow ones.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.onToggleTheme});

  final ValueChanged<Brightness> onToggleTheme;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  final _search = SearchController();
  int _selected = 0;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _select(int index) => setState(() => _selected = index);

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 840;
    final brightness = Theme.of(context).brightness;
    final content = _ToolContent(selected: _selected);

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyK, control: true):
            _search.openView,
        const SingleActivator(LogicalKeyboardKey.keyK, meta: true):
            _search.openView,
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          appBar: AppBar(
            title: const _Brand(),
            actions: [
              _ToolSearch(
                controller: _search,
                onSelected: (tool) => _select(devTools.indexOf(tool)),
              ),
              IconButton(
                tooltip: brightness == Brightness.dark
                    ? 'Usar tema claro'
                    : 'Usar tema escuro',
                icon: Icon(
                  brightness == Brightness.dark
                      ? Icons.light_mode_outlined
                      : Icons.dark_mode_outlined,
                ),
                onPressed: () => widget.onToggleTheme(brightness),
              ),
              const SizedBox(width: 8),
            ],
          ),
          drawer: wide
              ? null
              : _ToolDrawer(selected: _selected, onSelected: _select),
          body: wide
              ? Row(
                  children: [
                    _ToolRail(selected: _selected, onSelected: _select),
                    const VerticalDivider(width: 1),
                    Expanded(child: content),
                  ],
                )
              : content,
        ),
      ),
    );
  }
}

class _ToolContent extends StatelessWidget {
  const _ToolContent({required this.selected});

  final int selected;

  @override
  Widget build(BuildContext context) {
    final tool = devTools[selected];
    final text = Theme.of(context).textTheme;
    final side = MediaQuery.sizeOf(context).width < 600 ? 16.0 : 32.0;
    return Padding(
      padding: EdgeInsets.fromLTRB(side, 20, side, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(tool.name, style: text.headlineSmall),
          ),
          const SizedBox(height: 4),
          Text(
            tool.description,
            style: text.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          // IndexedStack keeps what was typed in each tool when switching.
          Expanded(
            child: IndexedStack(
              index: selected,
              children: [for (final tool in devTools) tool.page],
            ),
          ),
        ],
      ),
    );
  }
}

class _ToolRail extends StatelessWidget {
  const _ToolRail({required this.selected, required this.onSelected});

  final int selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return NavigationRail(
      extended: true,
      minExtendedWidth: 220,
      selectedIndex: selected,
      onDestinationSelected: onSelected,
      destinations: [
        for (final tool in devTools)
          NavigationRailDestination(
            icon: Icon(tool.icon),
            label: Text(tool.shortName),
          ),
      ],
      trailingAtBottom: true,
      trailing: const Padding(
        padding: EdgeInsets.all(16),
        child: SizedBox(width: 188, child: _PrivacyNote()),
      ),
    );
  }
}

class _ToolDrawer extends StatelessWidget {
  const _ToolDrawer({required this.selected, required this.onSelected});

  final int selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return NavigationDrawer(
      selectedIndex: selected,
      onDestinationSelected: (index) {
        onSelected(index);
        Navigator.pop(context); // closes the drawer
      },
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 20, 16, 12),
          child: Text(
            'Ferramentas',
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        for (final tool in devTools)
          NavigationDrawerDestination(
            icon: Icon(tool.icon),
            label: Text(tool.shortName),
          ),
        const Padding(
          padding: EdgeInsets.fromLTRB(28, 16, 28, 16),
          child: Divider(),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 28),
          child: _PrivacyNote(),
        ),
      ],
    );
  }
}

class _ToolSearch extends StatelessWidget {
  const _ToolSearch({required this.controller, required this.onSelected});

  final SearchController controller;
  final ValueChanged<DevTool> onSelected;

  @override
  Widget build(BuildContext context) {
    return SearchAnchor(
      searchController: controller,
      viewHintText: 'Buscar ferramenta…',
      builder: (context, controller) => IconButton(
        tooltip: 'Buscar ferramenta (Ctrl+K)',
        icon: const Icon(Icons.search),
        onPressed: controller.openView,
      ),
      suggestionsBuilder: (context, controller) {
        final results = searchTools(controller.text);
        if (results.isEmpty) {
          return const [
            ListTile(title: Text('Nenhuma ferramenta encontrada.')),
          ];
        }
        return [
          for (final tool in results)
            ListTile(
              leading: Icon(tool.icon),
              title: Text(tool.name),
              subtitle: Text(
                tool.description,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () {
                controller.closeView('');
                onSelected(tool);
              },
            ),
        ];
      },
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: scheme.primary,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.terminal, size: 18, color: scheme.onPrimary),
        ),
        const SizedBox(width: 10),
        const Flexible(
          child: Text(
            'DevTools',
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

class _PrivacyNote extends StatelessWidget {
  const _PrivacyNote();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.lock_outline, size: 16, color: scheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Tudo roda no seu dispositivo. Nada é enviado.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ),
      ],
    );
  }
}
