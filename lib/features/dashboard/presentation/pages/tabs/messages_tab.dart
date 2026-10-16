import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../../auth/presentation/bloc/auth_state.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:algohary_project/l10n/app_localizations.dart';
import '../../../../chat/data/models/chat_models.dart';
import '../../../../chat/data/services/chat_service.dart';
import '../../../../chat/presentation/pages/chat_detail_screen.dart';
import 'package:skeletonizer/skeletonizer.dart';

class MessagesTab extends StatefulWidget {
  const MessagesTab({super.key});

  @override
  State<MessagesTab> createState() => _MessagesTabState();
}

class _MessagesTabState extends State<MessagesTab> {
  late ChatService _chatService;
  final TextEditingController _searchController = TextEditingController();
  
  String _searchQuery = '';
  late Stream<List<ConversationModel>> _conversationsStream;

  @override
  void initState() {
    super.initState();
    
    final authState = context.read<AuthBloc>().state;
    final userId = (authState is AuthSuccess) ? authState.user.id : null;
    debugPrint('==================================================');
    debugPrint('DEBUG: MessagesTab initState');
    debugPrint('DEBUG: AuthState is $authState');
    debugPrint('DEBUG: userId is $userId');
    debugPrint('==================================================');
    _chatService = ChatService(injectedUserId: userId);
    
    // Auto-create admin conversation so it is stored in Firestore
    if (userId != null) {
      _chatService.createOrGetConversation('admin');
    }
    
    _conversationsStream = _chatService.streamConversations();
    
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatTimeStr(DateTime? date) {
    if (date == null) return '';
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays >= 2) {
      return '${diff.inDays}d';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else {
      final hour12 = date.hour % 12 == 0 ? 12 : date.hour % 12;
      final minuteStr = date.minute.toString().padLeft(2, '0');
      final period = date.hour >= 12 ? 'PM' : 'AM';
      return '$hour12:$minuteStr $period';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        title: Text(
          l10n.navMessages,
          style: TextStyle(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search chats...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: colorScheme.surface,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: colorScheme.primary.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: colorScheme.primary,
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          
          const SizedBox(height: 8),

          // List of conversations
          Expanded(
            child: StreamBuilder<List<ConversationModel>>(
              stream: _conversationsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  final mockConv = ConversationModel(
                    id: 'mock',
                    title: 'جاري التحميل',
                    lastMessageAt: DateTime.now(),
                    unreadCount: 0,
                    avatar: '',
                  );
                  return Skeletonizer(
                    enabled: true,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: 5,
                      separatorBuilder: (context, index) => Divider(
                        height: 1, 
                        color: colorScheme.outlineVariant.withOpacity(0.5),
                        indent: 72,
                      ),
                      itemBuilder: (context, index) {
                        return _buildChatTile(mockConv, colorScheme);
                      },
                    ),
                  );
                }
                
                if (snapshot.hasError) {
                  return Center(child: Text('Error loading conversations'));
                }

                var conversations = snapshot.data ?? [];
                
                if (_searchQuery.isNotEmpty) {
                  conversations = conversations.where((c) {
                    return c.title.toLowerCase().contains(_searchQuery);
                  }).toList();
                }

                ConversationModel? adminConv;
                final regularConvs = <ConversationModel>[];
                for (var conv in conversations) {
                  if (conv.otherUserId == 'admin') {
                    adminConv = conv;
                  } else {
                    regularConvs.add(conv);
                  }
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: 1 + regularConvs.length, // 1 for Support, then regular list
                  separatorBuilder: (context, index) {
                    return Divider(
                      height: 1, 
                      color: colorScheme.outlineVariant.withOpacity(0.5),
                      indent: 72,
                    );
                  },
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return _buildSupportChatTile(colorScheme, l10n, adminConv);
                    }
                    final conv = regularConvs[index - 1];
                    return _buildChatTile(conv, colorScheme);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportChatTile(ColorScheme colorScheme, AppLocalizations l10n, ConversationModel? adminConv) {
    String subtitle = l10n.chatWithSupport;
    String timeStr = '';
    int unreadCount = 0;
    
    if (adminConv != null) {
      unreadCount = adminConv.unreadCount;
      timeStr = _formatTimeStr(adminConv.lastMessageAt);
      final lastMsg = adminConv.lastMessage;
      if (lastMsg != null) {
        if (lastMsg.type == 'IMAGE') subtitle = '📷 Photo';
        else if (lastMsg.type == 'VOICE') subtitle = '🎤 Voice Message';
        else if (lastMsg.isMe) subtitle = 'You: ${lastMsg.content ?? ''}';
        else subtitle = lastMsg.content ?? '';
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border.all(color: colorScheme.primary.withOpacity(0.4), width: 1.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () async {
            // Generate or get conversation ID with 'admin'
            final convId = adminConv?.id ?? await _chatService.createOrGetConversation('admin');
            if (mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatDetailScreen(
                    conversationId: convId,
                    recipientName: l10n.alGoharySupport,
                    recipientAvatar: 'assets/icons/support_logo.png',
                    recipientId: 'admin',
                  ),
                ),
              );
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Support Avatar
                CircleAvatar(
                  radius: 28,
                  backgroundColor: colorScheme.primary.withOpacity(0.1),
                  backgroundImage: const AssetImage('assets/icons/support_logo.png'),
                ),
                const SizedBox(width: 16),
                
                // Text Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              l10n.alGoharySupport,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (timeStr.isNotEmpty)
                            Text(
                              timeStr,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.w500,
                                color: unreadCount > 0 ? colorScheme.primary : colorScheme.onSurfaceVariant,
                              ),
                            )
                          else
                            Icon(Icons.verified, color: colorScheme.primary, size: 16),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: unreadCount > 0 ? FontWeight.w600 : FontWeight.normal,
                                color: unreadCount > 0 ? colorScheme.onSurface : colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          if (unreadCount > 0) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: colorScheme.primary,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '$unreadCount',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onPrimary,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChatTile(ConversationModel conv, ColorScheme colorScheme) {
    final lastMsg = conv.lastMessage;
    final timeStr = _formatTimeStr(conv.lastMessageAt);
    
    String snippet = 'No messages yet';
    if (lastMsg != null) {
      if (lastMsg.type == 'IMAGE') snippet = '📷 Photo';
      else if (lastMsg.type == 'VOICE') snippet = '🎤 Voice Message';
      else if (lastMsg.isMe) snippet = 'You: ${lastMsg.content ?? ''}';
      else snippet = lastMsg.content ?? '';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border.all(color: colorScheme.primary.withOpacity(0.4), width: 1.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChatDetailScreen(
                  conversationId: conv.id,
                  recipientName: conv.title,
                  recipientAvatar: conv.avatar,
                  recipientId: conv.otherUserId,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 28,
              backgroundColor: colorScheme.surfaceContainerHighest,
              backgroundImage: conv.avatar != null && conv.avatar!.startsWith('http')
                  ? CachedNetworkImageProvider(conv.avatar!)
                  : (conv.otherUserId == 'admin' ? const AssetImage('assets/icons/support_logo.png') as ImageProvider : null),
              child: conv.otherUserId != 'admin' && (conv.avatar == null || !conv.avatar!.startsWith('http'))
                  ? Icon(Icons.person, color: colorScheme.onSurfaceVariant, size: 28)
                  : null,
            ),
            const SizedBox(width: 16),
            
            // Text Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          conv.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        timeStr,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: conv.unreadCount > 0 ? FontWeight.bold : FontWeight.w500,
                          color: conv.unreadCount > 0 ? colorScheme.primary : colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          snippet,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: conv.unreadCount > 0 ? FontWeight.w600 : FontWeight.normal,
                            color: conv.unreadCount > 0 ? colorScheme.onSurface : colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      if (conv.unreadCount > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${conv.unreadCount}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onPrimary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  ),
);
  }
}
