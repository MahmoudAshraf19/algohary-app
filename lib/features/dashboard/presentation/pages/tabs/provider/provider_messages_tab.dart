import 'package:flutter/material.dart';
import '../messages_tab.dart'; // Import the user's MessagesTab

class ProviderMessagesTab extends StatelessWidget {
  const ProviderMessagesTab({super.key});

  @override
  Widget build(BuildContext context) {
    // Provider uses the exact same chat system as the user.
    return const MessagesTab();
  }
}
