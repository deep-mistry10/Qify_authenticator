import 'package:flutter/material.dart';

import '../../models/totp_account.dart';
import '../../models/vault.dart';
import '../../repositories/vault_repository.dart';
import '../../services/vault_sync_service.dart';
import '../../widgets/account_tile.dart';
import '../../widgets/empty_state.dart';
import '../account_details/account_details_screen.dart';
import '../add_account/add_account_screen.dart';
import '../settings/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final VaultRepository _repo = VaultRepository.instance;
  final TextEditingController _search = TextEditingController();

  Vault _vault = const Vault();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final vault = await _repo.load();
      if (!mounted) return;
      setState(() {
        _vault = vault;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _message(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _openAdd() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AddAccountScreen(),
      ),
    );
    await _load();
  }

  Future<void> _openAccount(TotpAccount account) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AccountDetailsScreen(account: account),
      ),
    );
    await _load();
  }

  Future<void> _delete(TotpAccount account) async {
    final controller = TextEditingController();

    try {
      final confirmed = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return AlertDialog(
            title: Text('Delete ${account.issuer}?'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'This permanently removes the security key from this device. You may lose access to the account if you do not have another recovery method.',
                ),
                const SizedBox(height: 16),
                const Text(
                  'Type DELETE to confirm.',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: controller,
                  autofocus: true,
                  autocorrect: false,
                  enableSuggestions: false,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    hintText: 'DELETE',
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: controller,
                builder: (_, value, __) {
                  final ready = value.text.trim() == 'DELETE';
                  return FilledButton(
                    onPressed: ready
                        ? () => Navigator.pop(dialogContext, true)
                        : null,
                    child: const Text('Delete'),
                  );
                },
              ),
            ],
          );
        },
      );

      if (confirmed != true) return;

      await _repo.deleteAccount(account.id);

      if (await _repo.isBackupEnabled()) {
        final result = await VaultSyncService.instance.syncIfEnabled();
        if (!result.success && mounted) {
          _message(result.message);
          return;
        }
      }

      await _load();
    } finally {
      controller.dispose();
    }
  }

  void _message(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final query = _search.text.trim().toLowerCase();
    final accounts = _vault.accounts.where((account) {
      if (query.isEmpty) return true;
      return account.issuer.toLowerCase().contains(query) ||
          account.accountName.toLowerCase().contains(query);
    }).toList()
      ..sort(
        (a, b) => a.sortOrder.compareTo(b.sortOrder),
      );

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Qify Authenticator',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SettingsScreen(),
                ),
              );
              await _load();
            },
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
              sliver: SliverToBoxAdapter(
                child: TextField(
                  controller: _search,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search_rounded),
                    hintText: 'Search accounts',
                  ),
                ),
              ),
            ),
            if (_vault.accounts.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyState(onAdd: _openAdd),
              )
            else if (accounts.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Text('No matching accounts.'),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 100),
                sliver: SliverList.builder(
                  itemCount: accounts.length,
                  itemBuilder: (context, index) {
                    final account = accounts[index];
                    return AccountTile(
                      account: account,
                      onTap: () => _openAccount(account),
                      onDelete: () => _delete(account),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAdd,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add account'),
      ),
    );
  }
}
