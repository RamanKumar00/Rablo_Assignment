import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import '../models/user_model.dart';

class ContactService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Request contacts permission
  Future<bool> requestContactsPermission() async {
    final status = await Permission.contacts.request();
    return status.isGranted;
  }

  // Check if contacts permission is granted
  Future<bool> hasContactsPermission() async {
    return await Permission.contacts.isGranted;
  }

  // Get all device contacts
  Future<List<Contact>> getDeviceContacts() async {
    if (!await hasContactsPermission()) {
      final granted = await requestContactsPermission();
      if (!granted) return [];
    }

    try {
      return await FlutterContacts.getContacts(
        withProperties: true,
        withPhoto: false,
      );
    } catch (e) {
      return [];
    }
  }

  // Normalize phone number for comparison (remove spaces, dashes, country codes)
  String _normalizePhone(String phone) {
    // Remove all non-digit characters
    String normalized = phone.replaceAll(RegExp(r'[^\d]'), '');
    
    // If starts with country code (91 for India), remove it
    if (normalized.length > 10 && normalized.startsWith('91')) {
      normalized = normalized.substring(2);
    }
    // If starts with 0, remove it
    if (normalized.startsWith('0')) {
      normalized = normalized.substring(1);
    }
    
    // Return last 10 digits
    if (normalized.length >= 10) {
      return normalized.substring(normalized.length - 10);
    }
    return normalized;
  }

  // Get all registered users from Firestore
  Future<List<UserModel>> getAllRegisteredUsers() async {
    QuerySnapshot snapshot = await _firestore.collection('users').get();
    return snapshot.docs
        .map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>))
        .toList();
  }

  // Get contacts who are on the app (registered users)
  Future<List<ContactMatch>> getContactsOnApp() async {
    final deviceContacts = await getDeviceContacts();
    final registeredUsers = await getAllRegisteredUsers();
    
    List<ContactMatch> matches = [];
    
    // Create a map of normalized phone numbers to users for quick lookup
    Map<String, UserModel> userPhoneMap = {};
    for (var user in registeredUsers) {
      String normalizedPhone = _normalizePhone(user.mobile);
      if (normalizedPhone.isNotEmpty) {
        userPhoneMap[normalizedPhone] = user;
      }
    }
    
    // Check each device contact
    for (var contact in deviceContacts) {
      for (var phone in contact.phones) {
        String normalizedPhone = _normalizePhone(phone.number);
        if (userPhoneMap.containsKey(normalizedPhone)) {
          matches.add(ContactMatch(
            contact: contact,
            user: userPhoneMap[normalizedPhone]!,
            isOnApp: true,
          ));
          break; // Found a match, move to next contact
        }
      }
    }
    
    return matches;
  }

  // Get contacts who are NOT on the app
  Future<List<Contact>> getContactsNotOnApp() async {
    final deviceContacts = await getDeviceContacts();
    final registeredUsers = await getAllRegisteredUsers();
    
    // Create a set of normalized phone numbers for registered users
    Set<String> registeredPhones = {};
    for (var user in registeredUsers) {
      String normalizedPhone = _normalizePhone(user.mobile);
      if (normalizedPhone.isNotEmpty) {
        registeredPhones.add(normalizedPhone);
      }
    }
    
    // Filter contacts not on app
    List<Contact> notOnApp = [];
    for (var contact in deviceContacts) {
      bool isOnApp = false;
      for (var phone in contact.phones) {
        String normalizedPhone = _normalizePhone(phone.number);
        if (registeredPhones.contains(normalizedPhone)) {
          isOnApp = true;
          break;
        }
      }
      if (!isOnApp && contact.phones.isNotEmpty) {
        notOnApp.add(contact);
      }
    }
    
    return notOnApp;
  }

  // Search users by name or email
  Future<List<UserModel>> searchUsers(String query) async {
    if (query.isEmpty) return [];
    
    String queryLower = query.toLowerCase();
    
    // Get all users and filter locally (Firestore doesn't support case-insensitive search easily)
    QuerySnapshot snapshot = await _firestore.collection('users').get();
    
    return snapshot.docs
        .map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>))
        .where((user) =>
            user.name.toLowerCase().contains(queryLower) ||
            user.email.toLowerCase().contains(queryLower) ||
            user.mobile.contains(query))
        .toList();
  }

  // Send invite via Share
  Future<void> inviteContact(Contact contact) async {
    String contactName = contact.displayName;
    String message = '''
Hey $contactName! 👋

I'm using Rablo Chat App to stay connected. It's a great way to chat!

Download it now and join me:
https://play.google.com/store/apps/details?id=com.rablo.chat

See you there! 🚀
''';

    await Share.share(
      message,
      subject: 'Join me on Rablo Chat!',
    );
  }

  // Bulk invite multiple contacts
  Future<void> inviteMultipleContacts() async {
    String message = '''
Hey! 👋

I'm using Rablo Chat App to stay connected with friends. 

Download it now and join the conversation:
https://play.google.com/store/apps/details?id=com.rablo.chat

See you there! 🚀
''';

    await Share.share(
      message,
      subject: 'Join me on Rablo Chat!',
    );
  }
}

// Model to represent a matched contact
class ContactMatch {
  final Contact contact;
  final UserModel user;
  final bool isOnApp;

  ContactMatch({
    required this.contact,
    required this.user,
    required this.isOnApp,
  });
}
