import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/chat_models.dart';
import 'package:algohary_project/core/network/firebase_config.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseConfig.firestore;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  /// Ensure a conversation exists between the current user and another user
  Future<String> createOrGetConversation(String otherUserId) async {
    final uid = currentUserId;
    if (uid == null) throw Exception('User not logged in');

    // To ensure unique conversation ID regardless of who started it,
    // we can sort the UIDs and join them.
    final ids = [uid, otherUserId];
    ids.sort();
    final conversationId = ids.join('_');

    final docRef = _firestore.collection('conversations').doc(conversationId);
    final docSnap = await docRef.get();

    if (!docSnap.exists) {
      await docRef.set({
        'participants': [uid, otherUserId],
        'createdAt': FieldValue.serverTimestamp(),
        'lastMessageAt': FieldValue.serverTimestamp(),
        'unreadCounts': {
          uid: 0,
          otherUserId: 0,
        },
      });
    }

    return conversationId;
  }

  /// Fetch conversations for the current user
  Stream<List<ConversationModel>> streamConversations() {
    final uid = currentUserId;
    if (uid == null) return Stream.value([]);

    return _firestore
        .collection('conversations')
        .where('participants', arrayContains: uid)
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      
      List<ConversationModel> conversations = [];
      
      for (var doc in snapshot.docs) {
        final data = doc.data();
        
        dynamic rawParticipants = data['participants'];
        List<String> participants = [];
        if (rawParticipants is List) {
          participants = rawParticipants.map((e) => e.toString()).toList();
        } else if (rawParticipants is Map) {
          participants = rawParticipants.keys.map((e) => e.toString()).toList();
        }
        
        // Find the other user's ID
        final otherUserId = participants.firstWhere((id) => id != uid, orElse: () => '');
        
        Map<String, dynamic>? otherUserDetails;
        if (otherUserId.isNotEmpty) {
          try {
            final userDoc = await _firestore.collection('users').doc(otherUserId).get();
            if (userDoc.exists) {
              otherUserDetails = userDoc.data();
            }
          } catch (e) {
            print('Error fetching user details for chat: $e');
          }
        }
        
        conversations.add(ConversationModel.fromFirestore(doc, uid, otherUserDetails));
      }
      
      return conversations;
    }).handleError((error) {
      _handleFirebaseError('streamConversations', error);
      throw error;
    });
  }

  /// Stream messages for a specific conversation
  Stream<List<ChatMessageModel>> streamMessages(String conversationId) {
    final uid = currentUserId;
    if (uid == null) return Stream.value([]);

    return _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ChatMessageModel.fromFirestore(doc, uid))
          .toList();
    }).handleError((error) {
      _handleFirebaseError('streamMessages', error);
      throw error;
    });
  }

  /// Send a message
  Future<ChatMessageModel?> sendMessage({
    required String conversationId,
    String? content,
    String type = 'TEXT',
    String? mediaUrl,
    List<String>? mediaUrls,
    String? recipientId, // Important for Cloud Functions
    String? senderName,  // Important for Cloud Functions
    String? senderAvatar, // Important for Cloud Functions
  }) async {
    final uid = currentUserId;
    if (uid == null) throw Exception('User not logged in');

    final conversationRef = _firestore.collection('conversations').doc(conversationId);
    final messagesRef = conversationRef.collection('messages');

    final newMessageRef = messagesRef.doc();
    
    final messageData = {
      'conversationId': conversationId,
      'senderId': uid,
      'content': content,
      'type': type,
      'createdAt': FieldValue.serverTimestamp(),
      'status': 'SENT',
      if (mediaUrl != null) 'mediaUrl': mediaUrl,
      if (mediaUrls != null) 'mediaUrls': mediaUrls,
      if (recipientId != null) 'recipientId': recipientId,
      if (senderName != null) 'senderName': senderName,
      if (senderAvatar != null) 'senderAvatar': senderAvatar,
    };

    // We need to update the conversation's last message and unread counts
    // using a transaction or batch to ensure atomic updates.
    final batch = _firestore.batch();
    
    batch.set(newMessageRef, messageData);
    
    // Get the other participant to increment their unread count
    final convDoc = await conversationRef.get();
    if (convDoc.exists) {
      final participants = List<String>.from(convDoc.data()?['participants'] ?? []);
      final otherUserId = participants.firstWhere((id) => id != uid, orElse: () => '');
      
      if (otherUserId.isNotEmpty) {
        batch.update(conversationRef, {
          'lastMessage': {
            'id': newMessageRef.id,
            'senderId': uid,
            'content': content,
            'type': type,
            'status': 'SENT',
            if (mediaUrl != null) 'mediaUrl': mediaUrl,
            if (mediaUrls != null) 'mediaUrls': mediaUrls,
            if (recipientId != null) 'recipientId': recipientId,
            if (senderName != null) 'senderName': senderName,
            if (senderAvatar != null) 'senderAvatar': senderAvatar,
          },
          'lastMessageAt': FieldValue.serverTimestamp(),
          'unreadCounts.$otherUserId': FieldValue.increment(1),
        });
      }
    }

    await batch.commit();
    
    // Return the optimistically created model
    return ChatMessageModel(
      id: newMessageRef.id,
      conversationId: conversationId,
      senderId: uid,
      content: content,
      type: type,
      createdAt: DateTime.now(),
      status: 'SENT',
      isMe: true,
      mediaUrl: mediaUrl,
      mediaUrls: mediaUrls,
    );
  }

  /// Mark conversation as read
  Future<void> markConversationAsRead(String conversationId) async {
    final uid = currentUserId;
    if (uid == null) return;

    try {
      await _firestore.collection('conversations').doc(conversationId).update({
        'unreadCounts.$uid': 0,
      });
    } catch (e) {
      _handleFirebaseError('markConversationAsRead', e);
    }
  }

  void _handleFirebaseError(String methodName, dynamic error) {
    print('\n=============================================');
    print('🚨 [ChatService] ERROR in $methodName');
    
    if (error is FirebaseException) {
      print('Firebase Code: ${error.code}');
      print('Message: ${error.message}');
      
      // Look for the missing index link which is often in the message
      if (error.message != null && error.message!.contains('https://console.firebase.google.com')) {
        final RegExp urlRegExp = RegExp(r'(https://console\.firebase\.google\.com[^\s]+)');
        final match = urlRegExp.firstMatch(error.message!);
        if (match != null) {
          print('\n🔥 MISSING INDEX DETECTED 🔥');
          print('Please create the index by clicking the link below:');
          print('👉 ${match.group(0)}');
        }
      }
    } else {
      print('Error details: $error');
    }
    print('=============================================\n');
  }
}
