import 'package:flutter/material.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';
import 'package:infano_care_mobile/features/safety/data/safety_repository.dart';
import 'package:infano_care_mobile/core/services/api_service.dart';
import 'package:go_router/go_router.dart';

class TrustedContactsScreen extends StatefulWidget {
  const TrustedContactsScreen({super.key});

  @override
  State<TrustedContactsScreen> createState() => _TrustedContactsScreenState();
}

class _TrustedContactsScreenState extends State<TrustedContactsScreen> {
  final SafetyRepository _repository = SafetyRepository(ApiService.instance.dio);
  List<dynamic> _contacts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    try {
      setState(() => _isLoading = true);
      final contacts = await _repository.getTrustedContacts();
      setState(() {
        _contacts = contacts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load contacts: $e')),
        );
      }
    }
  }

  Future<void> _addContactDialog() async {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final relationController = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Trusted Contact'),
        content: SizedBox(
          width: MediaQuery.of(ctx).size.width * 0.9,
          child: ListView(
            shrinkWrap: true,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Phone Number (e.g. +919876543210)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: relationController,
                decoration: const InputDecoration(labelText: 'Relation (e.g. Mother, Friend)', border: OutlineInputBorder()),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isEmpty || phoneController.text.isEmpty) return;
              Navigator.pop(ctx);
              try {
                await _repository.addTrustedContact(
                  nameController.text,
                  phoneController.text,
                  relationController.text,
                );
                _loadContacts();
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to add contact: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.purple, foregroundColor: Colors.white),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteContact(String id) async {
    try {
      await _repository.deleteTrustedContact(id);
      _loadContacts();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete contact: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Trusted Contacts (${_contacts.length})', style: const TextStyle(color: AppColors.purple)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.purple),
          onPressed: () => context.pop(),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _contacts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.people_outline, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text(
                        'No trusted contacts added yet.',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _addContactDialog,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.purple,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Add Your First Contact'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _contacts.length,
                  itemBuilder: (context, index) {
                    final contact = _contacts[index];
                    return Card(
                      elevation: 0,
                      color: Colors.white,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.purple.withOpacity(0.1),
                          child: Text(
                            contact['name'].substring(0, 1).toUpperCase(),
                            style: const TextStyle(color: AppColors.purple, fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(contact['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${contact['relation'] ?? 'Friend'} • ${contact['phone']}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: AppColors.error),
                          onPressed: () => _deleteContact(contact['id']),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: _contacts.isNotEmpty && _contacts.length < 5
          ? FloatingActionButton(
              onPressed: _addContactDialog,
              backgroundColor: AppColors.purple,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }
}
