import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/message_model.dart';

class PrivateChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Generate a unique chat room ID for two users (sorted to ensure consistency)
  String _getChatRoomId(String userId1, String userId2) {
    List<String> ids = [userId1, userId2];
    ids.sort();
    return '${ids[0]}_${ids[1]}';
  }

  // Send message to a specific user - stored under sender's UID
  Future<void> sendMessage(String receiverId, String text) async {
    User? currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception("User not authenticated");

    String chatRoomId = _getChatRoomId(currentUser.uid, receiverId);

    // Fetch sender's name
    DocumentSnapshot userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
    String senderName = (userDoc.data() as Map<String, dynamic>)['name'] ?? 'Unknown';

    MessageModel message = MessageModel(
      senderId: currentUser.uid,
      senderName: senderName,
      text: text,
      timestamp: Timestamp.now(),
    );

    // Store message in the chat room
    await _firestore
        .collection('private_chats')
        .doc(chatRoomId)
        .collection('messages')
        .add(message.toMap());

    // Update chat room metadata for both users
    await _updateChatRoomMetadata(chatRoomId, currentUser.uid, receiverId, text);

    // Also store reference under each user's UID for quick access
    await _storeMessageReference(currentUser.uid, receiverId, chatRoomId, text);
    await _storeMessageReference(receiverId, currentUser.uid, chatRoomId, text);
  }

  // Update chat room metadata
  Future<void> _updateChatRoomMetadata(
    String chatRoomId,
    String senderId,
    String receiverId,
    String lastMessage,
  ) async {
    await _firestore.collection('private_chats').doc(chatRoomId).set({
      'participants': [senderId, receiverId],
      'lastMessage': lastMessage,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'lastSenderId': senderId,
    }, SetOptions(merge: true));
  }

  // Store message reference under user's UID
  Future<void> _storeMessageReference(
    String userId,
    String otherUserId,
    String chatRoomId,
    String lastMessage,
  ) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('chats')
        .doc(otherUserId)
        .set({
      'chatRoomId': chatRoomId,
      'lastMessage': lastMessage,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'otherUserId': otherUserId,
    }, SetOptions(merge: true));
  }

  // Get messages stream for a private chat
  Stream<List<MessageModel>> getMessages(String otherUserId) {
    User? currentUser = _auth.currentUser;
    if (currentUser == null) return Stream.value([]);

    String chatRoomId = _getChatRoomId(currentUser.uid, otherUserId);

    return _firestore
        .collection('private_chats')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return MessageModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  // Edit a message in private chat
  Future<void> editMessage(String otherUserId, String messageId, String newText) async {
    User? currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception("User not authenticated");

    String chatRoomId = _getChatRoomId(currentUser.uid, otherUserId);

    await _firestore
        .collection('private_chats')
        .doc(chatRoomId)
        .collection('messages')
        .doc(messageId)
        .update({
      'text': newText,
      'editedAt': FieldValue.serverTimestamp(),
    });
  }

  // Delete a message from private chat
  Future<void> deleteMessage(String otherUserId, String messageId) async {
    User? currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception("User not authenticated");

    String chatRoomId = _getChatRoomId(currentUser.uid, otherUserId);

    await _firestore
        .collection('private_chats')
        .doc(chatRoomId)
        .collection('messages')
        .doc(messageId)
        .delete();
  }

  // Get user's chat list (recent conversations)
  Stream<List<Map<String, dynamic>>> getUserChats() {
    User? currentUser = _auth.currentUser;
    if (currentUser == null) return Stream.value([]);

    return _firestore
        .collection('users')
        .doc(currentUser.uid)
        .collection('chats')
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => doc.data()).toList();
    });
  }
}
