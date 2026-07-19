import 'package:flutter/material.dart';

import '../services/refresh_interval_service.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({
    required this.refreshInterval,
    required this.refreshIntervalService,
    required this.onRefreshIntervalUpdated,
    super.key,
  });

  final Duration? refreshInterval;
  final RefreshIntervalService refreshIntervalService;
  final ValueChanged<Duration> onRefreshIntervalUpdated;

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _refreshIntervalController;
  bool _isSaving = false;
  bool _isLoadingInterval = false;
  String? _loadError;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    _refreshIntervalController = TextEditingController(
      text: widget.refreshInterval?.inSeconds.toString() ?? '',
    );
    if (widget.refreshInterval == null) {
      _loadRefreshInterval();
    }
  }

  @override
  void didUpdateWidget(covariant SettingsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshInterval != widget.refreshInterval &&
        widget.refreshInterval != null &&
        !_isSaving) {
      _refreshIntervalController.text = widget.refreshInterval!.inSeconds
          .toString();
    }
  }

  Future<void> _loadRefreshInterval() async {
    setState(() => _isLoadingInterval = true);
    try {
      final refreshInterval = await widget.refreshIntervalService
          .getRefreshInterval();
      if (!mounted || _refreshIntervalController.text.isNotEmpty) return;
      setState(
        () => _refreshIntervalController.text = refreshInterval.inSeconds
            .toString(),
      );
    } on RefreshIntervalException catch (error) {
      if (!mounted) return;
      setState(() => _loadError = error.message);
    } finally {
      if (mounted) setState(() => _isLoadingInterval = false);
    }
  }

  @override
  void dispose() {
    _refreshIntervalController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final interval = Duration(
      seconds: int.parse(_refreshIntervalController.text.trim()),
    );
    setState(() {
      _isSaving = true;
      _successMessage = null;
    });

    try {
      await widget.refreshIntervalService.updateRefreshInterval(interval);
      if (!mounted) return;
      widget.onRefreshIntervalUpdated(interval);
      setState(() => _successMessage = 'Refresh interval updated.');
    } on RefreshIntervalException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Settings', style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 8),
                  const Text('Choose how often the dashboard refreshes flight data.'),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _refreshIntervalController,
                    enabled: !_isSaving && !_isLoadingInterval,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Refresh interval',
                      suffixText: 'seconds',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      final seconds = int.tryParse(value?.trim() ?? '');
                      if (seconds == null || seconds <= 0) {
                        return 'Enter a positive whole number of seconds.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _isSaving || _isLoadingInterval ? null : _save,
                    icon: _isSaving
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save),
                    label: Text(_isSaving ? 'Saving...' : 'Save changes'),
                  ),
                  if (_loadError != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Unable to load the current interval. Enter a new value to continue.',
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                  ],
                  if (_successMessage != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      _successMessage!,
                      style: TextStyle(color: Theme.of(context).colorScheme.primary),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
