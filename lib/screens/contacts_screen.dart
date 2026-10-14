
import 'package:flutter/material.dart';

import '../../model/contact.dart';
import '../service/contact_service.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  final ContactService _service = ContactService();

  late Future<List<Contact>> _contactsFuture;

  List<Contact> _contacts = [];

  @override
  void initState() {
    super.initState();
    _contactsFuture = _service.getContacts();
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }

  void _reloadContacts() {
    setState(() {
      _contactsFuture = _service.getContacts();
    });
  }

  Future<void> _showContactForm({Contact? contact}) async {
    final formKey = GlobalKey<FormState>();

    final nameController =
    TextEditingController(text: contact?.name ?? '');
    final emailController =
    TextEditingController(text: contact?.email ?? '');
    final phoneController =
    TextEditingController(text: contact?.phone ?? '');

    final isEditing = contact != null;

    try {
      final result = await showDialog<Contact>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: Text(
              isEditing
                  ? 'تعديل جهة الاتصال'
                  : 'إضافة جهة اتصال',
            ),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameController,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'الاسم',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (value) {
                        if (value == null ||
                            value.trim().isEmpty) {
                          return 'الاسم مطلوب';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'البريد الإلكتروني',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      validator: (value) {
                        final email = value?.trim() ?? '';

                        if (!RegExp(
                          r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                        ).hasMatch(email)) {
                          return 'أدخلي بريدًا إلكترونيًا صحيحًا';
                        }

                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'رقم الجوال',
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                      validator: (value) {
                        if (value == null ||
                            value.trim().isEmpty) {
                          return 'رقم الجوال مطلوب';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () =>
                    Navigator.pop(dialogContext),
                child: const Text('إلغاء'),
              ),
              FilledButton(
                onPressed: () {
                  if (!formKey.currentState!.validate()) {
                    return;
                  }

                  Navigator.pop(
                    dialogContext,
                    Contact(
                      id: contact?.id,
                      name: nameController.text.trim(),
                      email: emailController.text.trim(),
                      phone: phoneController.text.trim(),
                    ),
                  );
                },
                child: Text(isEditing ? 'حفظ التعديلات' : 'إضافة'),
              ),
            ],
          );
        },
      );

      if (result == null || !mounted) return;

      await _saveContact(result, isEditing: isEditing);
    } finally {
      nameController.dispose();
      emailController.dispose();
      phoneController.dispose();
    }
  }

  Future<void> _saveContact(
      Contact contact, {
        required bool isEditing,
      }) async {
    try {
      final savedContact = isEditing
          ? await _service.updateContact(contact)
          : await _service.addContact(contact);

      if (!mounted) return;

      setState(() {
        if (isEditing) {
          final index = _contacts.indexWhere(
                (item) => item.id == contact.id,
          );

          if (index != -1) {
            _contacts[index] = savedContact;
          }
        } else {
          _contacts.removeWhere(
                (item) => item.id == savedContact.id,
          );
          _contacts.insert(0, savedContact);
        }
      });

      _showMessage(
        isEditing
            ? 'تم تعديل جهة الاتصال بنجاح'
            : 'تمت إضافة جهة الاتصال بنجاح',
      );
    } catch (e) {
      if (!mounted) return;
      _showMessage('تعذر حفظ جهة الاتصال: $e');
    }
  }

  Future<bool> _confirmDelete(Contact contact) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          icon: const Icon(
            Icons.delete_outline,
            color: Colors.red,
            size: 36,
          ),
          title: const Text('تأكيد الحذف'),
          content: Text(
            'هل أنتِ متأكدة من حذف "${contact.name}"؟',
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, false),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              onPressed: () =>
                  Navigator.pop(dialogContext, true),
              child: const Text('حذف'),
            ),
          ],
        );
      },
    );

    return confirmed == true;
  }

  Future<void> _deleteContact(Contact contact) async {
    if (contact.id == null) {
      _showMessage('لا يمكن حذف جهة اتصال دون معرّف');
      return;
    }

    final confirmed = await _confirmDelete(contact);

    if (!confirmed || !mounted) return;

    try {
      await _service.deleteContact(contact.id!);

      if (!mounted) return;

      setState(() {
        _contacts.removeWhere(
              (item) => item.id == contact.id,
        );
      });

      _showMessage('تم حذف جهة الاتصال');
    } catch (e) {
      if (!mounted) return;
      _showMessage('تعذر حذف جهة الاتصال: $e');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message)),
      );
  }

  Widget _buildContactCard(Contact contact) {
    final initial = contact.name.trim().isNotEmpty
        ? contact.name.trim()[0].toUpperCase()
        : '?';

    return Dismissible(
      key: ValueKey(contact.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        await _deleteContact(contact);

        // الحذف من القائمة يتم بعد نجاح طلب DELETE.
        // نرجع false حتى لا يحذف Dismissible العنصر تلقائيًا.
        return false;
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(
          Icons.delete_outline,
          color: Colors.white,
          size: 30,
        ),
      ),
      child: Card(
        elevation: 2,
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.all(14),
          leading: CircleAvatar(
            radius: 26,
            child: Text(
              initial,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          title: Text(
            contact.name,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('الإيميل: ${contact.email}'),
                const SizedBox(height: 5),
                Text('الجوال: ${contact.phone}'),
              ],
            ),
          ),
          onLongPress: () => _showContactForm(
            contact: contact,
          ),
          trailing: const Icon(Icons.edit_outlined),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'دفتر جهات الاتصال',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'تحديث البيانات',
            onPressed: _reloadContacts,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<List<Contact>>(
        future: _contactsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.cloud_off_outlined,
                      size: 56,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'تعذر تحميل جهات الاتصال',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: _reloadContacts,
                      icon: const Icon(Icons.refresh),
                      label: const Text('إعادة المحاولة'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (snapshot.hasData) {
            _contacts = List<Contact>.from(snapshot.data!);
          }

          if (_contacts.isEmpty) {
            return const Center(
              child: Text('لا توجد جهات اتصال'),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              final future = _service.getContacts();

              setState(() {
                _contactsFuture = future;
              });

              try {
                final data = await future;

                if (!mounted) return;

                setState(() {
                  _contacts = data;
                });
              } catch (_) {
                if (!mounted) return;
                _showMessage('تعذر تحديث جهات الاتصال');
              }
            },
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(12),
              itemCount: _contacts.length,
              itemBuilder: (context, index) {
                return _buildContactCard(_contacts[index]);
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showContactForm(),
        icon: const Icon(Icons.add),
        label: const Text('إضافة جهة اتصال'),
      ),
    );
  }
}
