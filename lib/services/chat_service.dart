
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/message_model.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Send Message
  Future<void> sendMessage(String text) async {
    User? currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception("User not authenticated");

    // Fetch user name for the message (optional, could store just ID and fetch name on display, but storing name is easier for simple apps)
    DocumentSnapshot userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
    String userName = (userDoc.data() as Map<String, dynamic>)['name'] ?? 'Unknown';

    MessageModel message = MessageModel(
      senderId: currentUser.uid,
      senderName: userName,
      text: text,
      timestamp: Timestamp.now(),
    );

    await _firestore.collection('chat_room').add(message.toMap());
  }

  // Get Messages Stream
  Stream<List<MessageModel>> getMessages() {
    return _firestore
        .collection('chat_room')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return MessageModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  // Edit Message
  Future<void> editMessage(String messageId, String newText) async {
    await _firestore
        .collection('chat_room')
        .doc(messageId)
        .update({'text': newText});
  }

  // Delete Message
  Future<void> deleteMessage(String messageId) async {
    await _firestore
        .collection('chat_room')
        .doc(messageId)
        .delete();
  }
}
