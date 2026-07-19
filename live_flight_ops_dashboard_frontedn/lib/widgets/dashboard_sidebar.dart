import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class DashboardSidebar extends StatelessWidget {
  const DashboardSidebar({
    required this.selectedPage,
    required this.onPageSelected,
    required this.onToggleTheme,
    this.flightStatesTime,
  });

  final int selectedPage;
  final ValueChanged<int> onPageSelected;
  final VoidCallback onToggleTheme;
  final int? flightStatesTime;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: 272,
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        border: Border(right: BorderSide(color: colors.outlineVariant)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _BrandHeader(colors: colors),
              const SizedBox(height: 32),
              Text(
                'WORKSPACE',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colors.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 10),
              _NavigationItem(
                page: 0,
                title: 'Flight map',
                subtitle: 'Live airspace',
                icon: Icons.public_rounded,
                isSelected: selectedPage == 0,
                onTap: onPageSelected,
              ),
              const SizedBox(height: 6),
              _NavigationItem(
                page: 1,
                title: 'Flight list',
                subtitle: 'Aircraft activity',
                icon: Icons.format_list_bulleted_rounded,
                isSelected: selectedPage == 1,
                onTap: onPageSelected,
              ),
              const SizedBox(height: 6),
              _NavigationItem(
                page: 2,
                title: 'Settings',
                subtitle: 'Dashboard controls',
                icon: Icons.tune_rounded,
                isSelected: selectedPage == 2,
                onTap: onPageSelected,
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: colors.tertiaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.sensors_rounded,
                      color: colors.tertiary,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Operations online',
                            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: colors.onTertiaryContainer,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Live data connection',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colors.onTertiaryContainer,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _FlightDataTimestamp(time: flightStatesTime),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: onToggleTheme,
                icon: Icon(
                  isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                ),
                label: Text(isDark ? 'Use light theme' : 'Use dark theme'),
                style: OutlinedButton.styleFrom(
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  foregroundColor: colors.onSurface,
                  side: BorderSide(color: colors.outlineVariant),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FlightDataTimestamp extends StatelessWidget {
  const _FlightDataTimestamp({required this.time});

  final int? time;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final localizations = MaterialLocalizations.of(context);
    final timestamp = time == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(time! * 1000).toLocal();
    final timestampLabel = timestamp == null
        ? 'Awaiting flight data'
        : '${localizations.formatMediumDate(timestamp)} at '
            '${localizations.formatTimeOfDay(TimeOfDay.fromDateTime(timestamp))}';

    return Semantics(
      label: 'Flight data timestamp: $timestampLabel',
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.secondaryContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(Icons.schedule_rounded, color: colors.secondary, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Data as of',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: colors.onSecondaryContainer,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    timestampLabel,
                    key: const ValueKey('flight-data-timestamp'),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.onSecondaryContainer,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader({required this.colors});

  final ColorScheme colors;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        height: 46,
        width: 46,
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: colors.primary,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: colors.primary.withValues(alpha: 0.22),
              blurRadius: 16,
            ),
          ],
        ),
        child: SvgPicture.asset('assets/icons/logo-white.svg'),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'LIVE FLIGHT',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
            Text(
              'Operations center',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    ],
  );
}

class _NavigationItem extends StatelessWidget {
  const _NavigationItem({
    required this.page,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final int page;
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final foreground = isSelected ? colors.onPrimaryContainer : colors.onSurface;
    return Semantics(
      selected: isSelected,
      button: true,
      label: title,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onTap(page),
          borderRadius: BorderRadius.circular(14),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              color: isSelected ? colors.primaryContainer : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isSelected ? colors.onPrimaryContainer : colors.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: foreground,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isSelected
                              ? foreground
                              : colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Icon(
                    Icons.arrow_forward_rounded,
                    color: colors.onPrimaryContainer,
                    size: 18,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
