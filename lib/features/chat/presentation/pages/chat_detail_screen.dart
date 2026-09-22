import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:algohary_project/features/chat/presentation/widgets/full_screen_image_viewer.dart';
import 'package:algohary_project/l10n/app_localizations.dart';
import 'package:audioplayers/audioplayers.dart';

import '../../data/models/chat_models.dart';
import '../../data/services/chat_service.dart';
import '../../data/services/chat_media_service.dart';
import '../widgets/voice_recorder_widget.dart';
import 'instagram_gallery_picker.dart';

class ChatDetailScreen extends StatefulWidget {
  final String conversationId;
  final String recipientName;
  final String? recipientAvatar;
  final String? recipientId;
  final bool isOnline;

  const ChatDetailScreen({
    super.key,
    required this.conversationId,
    required this.recipientName,
    this.recipientAvatar,
    this.recipientId,
    this.isOnline = true,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final ChatService _chatService = ChatService();
  final ChatMediaService _mediaService = ChatMediaService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _isTyping = false;
  List<dynamic> _uploadingFiles = [];
  bool _isRecordingVoice = false;
  late Stream<List<ChatMessageModel>> _messagesStream;

  // Audio Playback
  String? _playingAudioId;
  final AudioPlayer _audioPlayer = AudioPlayer();
  double _audioProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _messagesStream = _chatService.streamMessages(widget.conversationId);
    _markAsRead();

    _messageController.addListener(() {
      final text = _messageController.text.trim();
      if (text.isNotEmpty != _isTyping) {
        setState(() {
          _isTyping = text.isNotEmpty;
        });
      }
    });

    _audioPlayer.onPositionChanged.listen((p) {
      _audioPlayer.getDuration().then((d) {
        if (d != null && d.inMilliseconds > 0 && mounted) {
          setState(() {
            _audioProgress = p.inMilliseconds / d.inMilliseconds;
          });
        }
      });
    });

    _audioPlayer.onPlayerStateChanged.listen((s) {
      if (s == PlayerState.completed && mounted) {
        setState(() {
          _playingAudioId = null;
          _audioProgress = 0.0;
        });
      }
    });
  }

  void _markAsRead() {
    _chatService.markConversationAsRead(widget.conversationId);
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleSendMessage({
    String type = 'TEXT',
    String? mediaUrl,
    List<String>? mediaUrls,
    String? content,
  }) async {
    final text = content ?? _messageController.text.trim();
    if (type == 'TEXT' && text.isEmpty && mediaUrl == null && mediaUrls == null) return;

    if (type == 'TEXT') {
      _messageController.clear();
      setState(() => _isTyping = false);
    }
    
    await _chatService.sendMessage(
      conversationId: widget.conversationId,
      content: text.isNotEmpty ? text : null,
      type: type,
      mediaUrl: mediaUrl,
      mediaUrls: mediaUrls,
      recipientId: widget.recipientId,
    );
    
    _scrollToBottom();
  }

  Future<void> _handleVoiceRecordingComplete(String path, int durationSeconds) async {
    setState(() => _isRecordingVoice = false);
    
    String? url;
    if (kIsWeb) {
      url = await _mediaService.uploadWebBlob(path, widget.conversationId, 'm4a');
    } else {
      final file = File(path);
      url = await _mediaService.uploadMedia(file, widget.conversationId, 'VOICE');
    }
    
    if (url != null) {
      _handleSendMessage(type: 'VOICE', mediaUrl: url, content: '🎤 Voice Note ($durationSeconds s)');
    }
  }

  Future<void> _openMediaPicker() async {
    if (kIsWeb) {
      // Fallback for Web (Native Picker)
      final xfiles = await _mediaService.pickMultiMedia();
      if (xfiles.isNotEmpty) {
        setState(() => _uploadingFiles.addAll(xfiles));
        List<String> uploadedUrls = [];
        for (var xfile in xfiles) {
          final url = await _mediaService.uploadWebMedia(xfile, widget.conversationId, 'IMAGE');
          if (url != null) uploadedUrls.add(url);
          setState(() => _uploadingFiles.remove(xfile));
        }
        if (uploadedUrls.isNotEmpty) {
          if (uploadedUrls.length == 1) {
            _handleSendMessage(type: 'IMAGE', mediaUrl: uploadedUrls.first);
          } else {
            _handleSendMessage(type: 'CAROUSEL', mediaUrls: uploadedUrls);
          }
        }
      }
      return;
    }

    // Instagram style picker for Mobile
    final List<File>? selectedFiles = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const InstagramGalleryPicker(maxSelection: 10)),
    );

    if (selectedFiles != null && selectedFiles.isNotEmpty) {
      setState(() => _uploadingFiles.addAll(selectedFiles));
      
      List<String> uploadedUrls = [];
      for (var file in selectedFiles) {
        final isVideo = file.path.toLowerCase().endsWith('.mp4');
        final url = await _mediaService.uploadMedia(file, widget.conversationId, isVideo ? 'VIDEO' : 'IMAGE');
        if (url != null) uploadedUrls.add(url);
        setState(() => _uploadingFiles.remove(file));
      }

      if (uploadedUrls.isNotEmpty) {
        if (uploadedUrls.length == 1) {
           _handleSendMessage(type: 'IMAGE', mediaUrl: uploadedUrls.first);
        } else {
           _handleSendMessage(type: 'CAROUSEL', mediaUrls: uploadedUrls);
        }
      }
    }
  }

  Future<void> _toggleAudioPlayback(String messageId, String? mediaUrl) async {
    if (mediaUrl == null) return;
    if (_playingAudioId == messageId) {
      await _audioPlayer.pause();
      setState(() => _playingAudioId = null);
    } else {
      if (_playingAudioId != null) {
        await _audioPlayer.stop();
      }
      setState(() {
        _playingAudioId = messageId;
        _audioProgress = 0.0;
      });
      await _audioPlayer.play(UrlSource(mediaUrl));
    }
  }

  String _formatTime(DateTime date) {
    final hour12 = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minuteStr = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '$hour12:$minuteStr $period';
  }

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final msgDate = DateTime(date.year, date.month, date.day);
    final diffDays = today.difference(msgDate).inDays;

    if (diffDays == 0) return 'Today';
    if (diffDays == 1) return 'Yesterday';

    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final scaffoldBg = theme.brightness == Brightness.light ? const Color(0xFFF9F6F0) : colorScheme.surface;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0.5,
        shadowColor: Colors.black.withOpacity(0.08),
        leadingWidth: 44,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(1.5),
                  decoration: BoxDecoration(color: colorScheme.primary, shape: BoxShape.circle),
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: colorScheme.surfaceContainerHighest,
                    backgroundImage: widget.recipientAvatar != null && widget.recipientAvatar!.startsWith('http')
                        ? CachedNetworkImageProvider(widget.recipientAvatar!)
                        : null,
                    child: widget.recipientAvatar == null || !widget.recipientAvatar!.startsWith('http')
                        ? Icon(Icons.person, color: colorScheme.onSurfaceVariant, size: 22)
                        : null,
                  ),
                ),
                if (widget.isOnline)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 12, height: 12,
                      decoration: BoxDecoration(color: const Color(0xFF10B981), shape: BoxShape.circle, border: Border.all(color: colorScheme.surface, width: 2)),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.recipientName,
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colorScheme.onSurface, letterSpacing: -0.2),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Service Provider',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: const [SizedBox(width: 16)],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<ChatMessageModel>>(
              stream: _messagesStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  final mockMessageMe = ChatMessageModel(
                    id: 'mock1',
                    conversationId: 'mock',
                    senderId: 'currentUserId',
                    content: 'رسالة قصيرة',
                    type: 'TEXT',
                    createdAt: DateTime.now(),
                    isMe: true,
                    status: 'sent',
                  );
                  final mockMessageOther = ChatMessageModel(
                    id: 'mock2',
                    conversationId: 'mock',
                    senderId: 'other',
                    content: 'هذه رسالة تجريبية أطول قليلاً للتحميل',
                    type: 'TEXT',
                    createdAt: DateTime.now(),
                    isMe: false,
                    status: 'sent',
                  );
                  return Skeletonizer(
                    enabled: true,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      itemCount: 4,
                      itemBuilder: (context, index) {
                        final isMe = index % 2 == 0;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildMessageBubble(isMe ? mockMessageMe : mockMessageOther, colorScheme),
                          ],
                        );
                      },
                    ),
                  );
                }
                if (snapshot.hasError) {
                  return const Center(child: Text('Error loading messages'));
                }
                final messages = snapshot.data ?? [];
                if (messages.isNotEmpty) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (_scrollController.hasClients) {
                      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
                    }
                  });
                }
                if (messages.isEmpty) return const SizedBox();

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final showDateHeader = index == 0 || _formatDateHeader(msg.createdAt) != _formatDateHeader(messages[index - 1].createdAt);

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (showDateHeader)
                          Padding(
                            padding: const EdgeInsets.only(top: 14, bottom: 8),
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                decoration: BoxDecoration(
                                  color: colorScheme.surface,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2))],
                                ),
                                child: Text(_formatDateHeader(msg.createdAt), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colorScheme.onSurfaceVariant)),
                              ),
                            ),
                          ),
                        _buildMessageBubble(msg, colorScheme),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          
          if (_uploadingFiles.isNotEmpty)
            _buildUploadingIndicator(colorScheme),

          if (_isRecordingVoice)
            VoiceRecorderWidget(
              onRecordingComplete: _handleVoiceRecordingComplete,
              onCancel: () => setState(() => _isRecordingVoice = false),
            )
          else
            _buildBottomInputBar(colorScheme, l10n),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessageModel msg, ColorScheme colorScheme) {
    final isMe = msg.isMe;
    final bubbleColor = isMe ? colorScheme.primary.withOpacity(0.12) : colorScheme.surface;
    final textColor = colorScheme.onSurface;
    final timeColor = colorScheme.onSurfaceVariant;

    Widget contentWidget;

    if (msg.type == 'IMAGE' && msg.mediaUrl != null) {
      contentWidget = GestureDetector(
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => FullScreenImageViewer(imageUrls: [msg.mediaUrl!])));
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: CachedNetworkImage(
            imageUrl: msg.mediaUrl!, 
            width: 200, 
            height: 200, 
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              width: 200, height: 200, 
              color: colorScheme.surfaceContainerHighest,
              child: const Center(child: CircularProgressIndicator()),
            ),
            errorWidget: (context, url, error) => Container(
              width: 200, height: 200, 
              color: colorScheme.errorContainer,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.broken_image_rounded, color: colorScheme.error, size: 40),
                  const SizedBox(height: 8),
                  Text('Error loading image', style: TextStyle(color: colorScheme.error, fontSize: 12)),
                ],
              ),
            ),
          ),
        ),
      );
    } else if (msg.type == 'CAROUSEL' && msg.mediaUrls != null) {
      contentWidget = SizedBox(
        width: 220,
        height: 220,
        child: CarouselSlider(
          options: CarouselOptions(enableInfiniteScroll: false, viewportFraction: 0.9, padEnds: false),
          items: msg.mediaUrls!.asMap().entries.map((entry) {
            int index = entry.key;
            String url = entry.value;
            return GestureDetector(
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => FullScreenImageViewer(imageUrls: msg.mediaUrls!, initialIndex: index)));
              },
              child: Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12), 
                      child: CachedNetworkImage(
                        imageUrl: url, 
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: colorScheme.surfaceContainerHighest,
                          child: const Center(child: CircularProgressIndicator()),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: colorScheme.errorContainer,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.broken_image_rounded, color: colorScheme.error, size: 40),
                              const SizedBox(height: 8),
                              Text('Error', style: TextStyle(color: colorScheme.error, fontSize: 12)),
                            ],
                          ),
                        ),
                      )
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${index + 1}/${msg.mediaUrls!.length}',
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      );
    } else if (msg.type == 'VOICE') {
      contentWidget = GestureDetector(
        onTap: () => _toggleAudioPlayback(msg.id, msg.mediaUrl),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_playingAudioId == msg.id ? Icons.pause_circle_filled : Icons.play_circle_fill, color: colorScheme.primary, size: 38),
            const SizedBox(width: 8),
            SizedBox(
              width: 120,
              child: LinearProgressIndicator(
                value: _playingAudioId == msg.id ? _audioProgress : 0.0,
                backgroundColor: colorScheme.outlineVariant,
                valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
              ),
            ),
          ],
        ),
      );
    } else {
      contentWidget = Text(
        msg.content ?? '',
        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: textColor, height: 1.35),
      );
    }

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: isMe ? const Radius.circular(18) : const Radius.circular(4),
            bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(18),
          ),
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            contentWidget,
            const SizedBox(height: 6),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_formatTime(msg.createdAt), style: TextStyle(fontSize: 11, color: timeColor)),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  Icon(msg.status == 'READ' ? Icons.done_all_rounded : Icons.done_rounded, size: 14, color: msg.status == 'READ' ? colorScheme.primary : timeColor),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomInputBar(ColorScheme colorScheme, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.5)),
                ),
                child: Row(
                  children: [
                    // Attachment Button
                    IconButton(
                      icon: Icon(Icons.attach_file_rounded, color: colorScheme.onSurfaceVariant),
                      onPressed: _openMediaPicker,
                    ),
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        maxLines: 5,
                        minLines: 1,
                        textInputAction: TextInputAction.newline,
                        decoration: InputDecoration(
                          hintText: l10n.chatWithProvider ?? 'Type a message...',
                          hintStyle: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 14),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        textAlignVertical: TextAlignVertical.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            
            // Send / Mic Button
            GestureDetector(
              onTap: _isTyping ? _handleSendMessage : () => setState(() => _isRecordingVoice = true),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 46, height: 46,
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _isTyping ? Icons.send_rounded : Icons.mic_rounded,
                  color: colorScheme.onPrimary,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadingIndicator(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      alignment: Alignment.centerRight,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.end,
        children: _uploadingFiles.map((file) {
          // file is either XFile or File
          Widget imageWidget;
          if (kIsWeb) {
             imageWidget = Image.network(file.path, width: 80, height: 80, fit: BoxFit.cover);
          } else {
             imageWidget = Image.file(File(file.path), width: 80, height: 80, fit: BoxFit.cover);
          }

          return ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              children: [
                imageWidget,
                Container(
                  width: 80, height: 80,
                  color: Colors.black.withOpacity(0.4),
                  child: const Center(
                    child: SizedBox(
                      width: 24, height: 24,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
