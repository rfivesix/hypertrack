// lib/screens/ai_settings_screen.dart

import 'package:flutter/material.dart';
import '../generated/app_localizations.dart';
import '../services/ai_service.dart';
import '../util/design_constants.dart';
import '../widgets/global_app_bar.dart';
import '../widgets/summary_card.dart';

/// Settings page for configuring the AI Meal Capture feature.
///
/// Allows users to select an AI provider + model, enter their API key
/// (stored securely in native Keychain/Keystore), test the connection, and read
/// a privacy disclosure.
class AiSettingsScreen extends StatefulWidget {
  const AiSettingsScreen({super.key});

  @override
  State<AiSettingsScreen> createState() => _AiSettingsScreenState();
}

class _AiSettingsScreenState extends State<AiSettingsScreen> {
  final _keyController = TextEditingController();
  AiProvider _selectedProvider = AiProvider.openai;
  String _selectedModel = '';
  List<AiModelOption> _modelOptions = const [];
  bool _isLoading = true;
  bool _isLoadingModels = false;
  bool _isTesting = false;
  bool _obscureKey = true;
  bool _hasKey = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final provider = await AiService.instance.getSelectedProvider();
    final model = await AiService.instance.getSelectedModel(provider);
    final key = await AiService.instance.getApiKey(provider);
    final models = await AiService.instance.getModelOptions(provider);
    final resolvedModel = _resolveModelSelection(model, models, provider);
    if (mounted) {
      setState(() {
        _selectedProvider = provider;
        _selectedModel = resolvedModel;
        _modelOptions = _buildModelOptionsWithSelection(models, resolvedModel);
        _hasKey = key != null && key.isNotEmpty;
        if (_hasKey) {
          // Show masked placeholder — never display the real key
          _keyController.text = '••••••••••••••••••••';
        }
        _isLoading = false;
      });
    }
  }

  Future<void> _onProviderChanged(AiProvider? provider) async {
    if (provider == null) return;
    setState(() => _isLoading = true);
    await AiService.instance.setSelectedProvider(provider);
    final selectedModel = await AiService.instance.getSelectedModel(provider);
    final models = await AiService.instance.getModelOptions(provider);
    final resolvedModel = _resolveModelSelection(selectedModel, models, provider);
    await AiService.instance.setSelectedModel(provider, resolvedModel);
    final key = await AiService.instance.getApiKey(provider);
    if (mounted) {
      setState(() {
        _selectedProvider = provider;
        _selectedModel = resolvedModel;
        _modelOptions = _buildModelOptionsWithSelection(models, resolvedModel);
        _hasKey = key != null && key.isNotEmpty;
        _keyController.text = _hasKey ? '••••••••••••••••••••' : '';
        _isLoading = false;
      });
    }
  }

  Future<void> _onModelChanged(String? model) async {
    if (model == null || model.isEmpty) return;
    await AiService.instance.setSelectedModel(_selectedProvider, model);
    if (mounted) {
      setState(() => _selectedModel = model);
    }
  }

  Future<void> _saveApiKey() async {
    final key = _keyController.text.trim();
    // Don't save the masked placeholder
    if (key.isEmpty || key.startsWith('••')) return;

    await AiService.instance.setApiKey(_selectedProvider, key);
    await _refreshModels();
    if (mounted) {
      setState(() {
        _hasKey = true;
        _keyController.text = '••••••••••••••••••••';
        _obscureKey = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.aiKeySaved),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _deleteApiKey() async {
    await AiService.instance.deleteApiKey(_selectedProvider);
    await _refreshModels();
    if (mounted) {
      setState(() {
        _hasKey = false;
        _keyController.clear();
      });
    }
  }

  Future<void> _refreshModels() async {
    if (!mounted) return;
    setState(() => _isLoadingModels = true);
    final models = await AiService.instance.getModelOptions(_selectedProvider);
    final resolvedModel = _resolveModelSelection(
      _selectedModel,
      models,
      _selectedProvider,
    );
    await AiService.instance.setSelectedModel(_selectedProvider, resolvedModel);
    if (!mounted) return;
    setState(() {
      _selectedModel = resolvedModel;
      _modelOptions = _buildModelOptionsWithSelection(models, resolvedModel);
      _isLoadingModels = false;
    });
  }

  String _resolveModelSelection(
    String currentSelection,
    List<AiModelOption> models,
    AiProvider provider,
  ) {
    if (models.any((m) => m.id == currentSelection)) return currentSelection;
    return AiService.instance.getProviderMetadata(provider).defaultModel;
  }

  List<AiModelOption> _buildModelOptionsWithSelection(
    List<AiModelOption> models,
    String selectedModel,
  ) {
    if (models.isEmpty) {
      return [AiModelOption(id: selectedModel, label: selectedModel, isFallback: true)];
    }
    if (models.any((m) => m.id == selectedModel)) return models;
    return [
      AiModelOption(id: selectedModel, label: selectedModel, isFallback: true),
      ...models,
    ];
  }

  Future<void> _testConnection() async {
    setState(() => _isTesting = true);
    final l10n = AppLocalizations.of(context)!;
    try {
      await AiService.instance.testConnection();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.aiTestSuccess),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green,
          ),
        );
      }
    } on AiServiceException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isTesting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final topPadding = MediaQuery.of(context).padding.top + kToolbarHeight;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlobalAppBar(title: l10n.aiSettingsTitle),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: DesignConstants.cardPadding.copyWith(
                top: DesignConstants.cardPadding.top + topPadding,
              ),
              children: [
                // --- Provider Selection ---
                _buildSectionTitle(context, l10n.aiProviderSection),
                SummaryCard(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.cloud_outlined,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonFormField<AiProvider>(
                            initialValue: _selectedProvider,
                            decoration: InputDecoration(
                              labelText: l10n.aiProviderLabel,
                              border: const OutlineInputBorder(),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                            items: AiService.instance
                                .getSupportedProviders()
                                .map(
                                  (providerMeta) => DropdownMenuItem(
                                    value: providerMeta.provider,
                                    child: Text(providerMeta.displayName),
                                  ),
                                )
                                .toList(),
                            onChanged: _onProviderChanged,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: DesignConstants.spacingXL),

                // --- Model Selection ---
                _buildSectionTitle(context, 'Model'),
                SummaryCard(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: _isLoadingModels
                        ? const Center(child: CircularProgressIndicator())
                        : DropdownButtonFormField<String>(
                            initialValue: _selectedModel,
                            decoration: const InputDecoration(
                              labelText: 'Model',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                            items: _modelOptions
                                .map(
                                  (model) => DropdownMenuItem(
                                    value: model.id,
                                    child: Text(model.label),
                                  ),
                                )
                                .toList(),
                            onChanged: _onModelChanged,
                          ),
                  ),
                ),

                const SizedBox(height: DesignConstants.spacingXL),

                // --- API Key ---
                _buildSectionTitle(context, l10n.aiApiKeySection),
                SummaryCard(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: _keyController,
                          obscureText: _obscureKey,
                          onTap: () {
                            // Clear masked placeholder when user taps to edit
                            if (_keyController.text.startsWith('••')) {
                              _keyController.clear();
                              setState(() => _obscureKey = false);
                            }
                          },
                          decoration: InputDecoration(
                            labelText: l10n.aiApiKeyLabel,
                            hintText: AiService.instance
                                .getProviderMetadata(_selectedProvider)
                                .keyHint,
                            border: const OutlineInputBorder(),
                            suffixIcon: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(
                                    _obscureKey
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                  ),
                                  onPressed: () {
                                    setState(() => _obscureKey = !_obscureKey);
                                  },
                                ),
                                if (_hasKey)
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: Colors.red,
                                    ),
                                    onPressed: _deleteApiKey,
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: _saveApiKey,
                                icon: const Icon(Icons.save_outlined),
                                label: Text(l10n.aiSaveKey),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: (_hasKey && !_isTesting)
                                    ? _testConnection
                                    : null,
                                icon: _isTesting
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.wifi_tethering),
                                label: Text(l10n.aiTestConnection),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: DesignConstants.spacingXL),

                // --- Privacy Disclosure ---
                _buildSectionTitle(context, l10n.aiPrivacySection),
                SummaryCard(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.shield_outlined,
                          color: theme.colorScheme.primary,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            l10n.aiPrivacyDisclosure,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}
