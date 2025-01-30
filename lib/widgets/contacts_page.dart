import 'package:flutter/material.dart';
import '../models/contact.dart';

class ContactsPage extends StatelessWidget {
  final List<Contact> contacts;
  final Function(Contact) onContactSelected;

  const ContactsPage({super.key, required this.contacts, required this.onContactSelected});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Contact'),
      ),
      body: ListView.builder(
        itemCount: contacts.length,
        itemBuilder: (context, index) {
          final contact = contacts[index];
          return ListTile(
            title: Text('${contact.firstName} ${contact.lastName}'),
            onTap: () {
              onContactSelected(contact);
              Navigator.pop(context);
            },
          );
        },
      ),
    );
  }
}