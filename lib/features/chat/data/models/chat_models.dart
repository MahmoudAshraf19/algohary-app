import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessageModel {
  final String id;
  final String conversationId;
  final String senderId;
  final String? content;
  final String type; // TEXT, IMAGE, VOICE, CAROUSEL, VIDEO, etc.
  final DateTime createdAt;
  final String status; // SENT, DELIVERED, READ, SENDING, FAILED
  final bool isMe;
  final String? mediaUrl;
  final List<String>? mediaUrls;
  final String? localFilePath;
  final bool isUploading;

  ChatMessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    this.content,
    required this.type,
    required this.createdAt,
    required this.status,
    required this.isMe,
    this.mediaUrl,
    this.mediaUrls,
    this.localFilePath,
    this.isUploading = false,
  });

  factory ChatMessageModel.fromFirestore(DocumentSnapshot doc, String currentUserId) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatMessageModel(
      id: doc.id,
      conversationId: data['conversationId'] ?? '',
      senderId: data['senderId'] ?? '',
      content: data['content'],
      type: data['type'] ?? 'TEXT',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: data['status'] ?? 'SENT',
      isMe: data['senderId'] == currentUserId,
      mediaUrl: data['mediaUrl'],
      mediaUrls: data['mediaUrls'] != null ? List<String>.from(data['mediaUrls']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'conversationId': conversationId,
      'senderId': senderId,
      'content': content,
      'type': type,
      'createdAt': FieldValue.serverTimestamp(),
      'status': status,
      if (mediaUrl != null) 'mediaUrl': mediaUrl,
      if (mediaUrls != null) 'mediaUrls': mediaUrls,
    };
  }
}

class ConversationModel {
  final String id;
  final String title;
  final String? avatar;
  final ChatMessageModel? lastMessage;
  final DateTime? lastMessageAt;
  final int unreadCount;

  ConversationModel({
    required this.id,
    required this.title,
    this.avatar,
    this.lastMessage,
    this.lastMessageAt,
    this.unreadCount = 0,
  });

  factory ConversationModel.fromFirestore(
      DocumentSnapshot doc, 
      String currentUserId, 
      Map<String, dynamic>? otherUserDetails) {
    final data = doc.data() as Map<String, dynamic>;
    
    // Extract last message info
    final lastMessageData = data['lastMessage'] as Map<String, dynamic>?;
    ChatMessageModel? lastMsg;
    if (lastMessageData != null) {
      lastMsg = ChatMessageModel(
        id: lastMessageData['id'] ?? '',
        conversationId: doc.id,
        senderId: lastMessageData['senderId'] ?? '',
        content: lastMessageData['content'],
        type: lastMessageData['type'] ?? 'TEXT',
        createdAt: (lastMessageData['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        status: lastMessageData['status'] ?? 'SENT',
        isMe: lastMessageData['senderId'] == currentUserId,
      );
    }

    // Determine unread count based on current user
    final unreadMap = data['unreadCounts'] as Map<String, dynamic>? ?? {};
    final unreadCount = (unreadMap[currentUserId] as num?)?.toInt() ?? 0;

    // Use other user's details for title and avatar
    String title = 'Unknown';
    String? avatar;
    if (otherUserDetails != null) {
      final firstName = otherUserDetails['first_name'] ?? '';
      final lastName = otherUserDetails['last_name'] ?? '';
      title = '$firstName $lastName'.trim();
      if (title.isEmpty) title = 'User';
      avatar = otherUserDetails['image_url'];
    }

    return ConversationModel(
      id: doc.id,
      title: title,
      avatar: avatar,
      lastMessage: lastMsg,
      lastMessageAt: (data['lastMessageAt'] as Timestamp?)?.toDate(),
      unreadCount: unreadCount,
    );
  }
}
