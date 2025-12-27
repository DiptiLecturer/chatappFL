import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'private_chat_page.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> with WidgetsBindingObserver {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  final DatabaseReference usersRef = FirebaseDatabase.instance.ref("users");

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    setOnlineStatus(true);
  }

  @override
  void dispose() {
    setOnlineStatus(false);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (currentUser != null) {
      if (state == AppLifecycleState.resumed) {
        setOnlineStatus(true);
      } else if (state == AppLifecycleState.paused) {
        setOnlineStatus(false);
      }
    }
  }

  void setOnlineStatus(bool isOnline) {
    if (currentUser != null) {
      usersRef.child(currentUser!.uid).update({
        'onlineStatus': isOnline,
        'username': currentUser?.displayName ?? currentUser!.email
      });
    }
  }

  void logout() async {
    final confirm = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Logout"),
          content: const Text("Are you sure you want to logout?"),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Cancel")),
            TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text("Logout")),
          ],
        ));
    if (confirm == true) {
      setOnlineStatus(false);
      await FirebaseAuth.instance.signOut();
      Navigator.pushReplacementNamed(context, '/signin');
    }
  }

  String getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return "";
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  Color getAvatarColor(String name) {
    final hash = name.codeUnits.fold(0, (prev, elem) => prev + elem);
    final colors = [
      Colors.green[700]!,
      Colors.green[500]!,
      Colors.teal,
      Colors.blue,
      Colors.orange,
      Colors.purple,
      Colors.indigo,
      Colors.brown,
    ];
    return colors[hash % colors.length];
  }

  Widget buildAvatar(String name, bool isOnline) {
    final initials = getInitials(name);
    final bgColor = getAvatarColor(name);

    return Stack(
      children: [
        CircleAvatar(
          radius: 30,
          backgroundColor: bgColor,
          child: Text(
            initials,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
          ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: isOnline ? Colors.green : Colors.grey,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
          ),
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green[50], // soft green background
      appBar: AppBar(
        title: const Text("Chat"),
        backgroundColor: Colors.green[700],
        actions: [
          IconButton(onPressed: logout, icon: const Icon(Icons.logout)),
        ],
      ),
      body: StreamBuilder<DatabaseEvent>(
        stream: usersRef.onValue,
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return const Center(child: Text("No users found"));
          }

          final data =
          Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map);
          final users = data.entries
              .where((e) => e.key != currentUser!.uid)
              .map((e) => Map<String, dynamic>.from(e.value))
              .toList();

          final currentUserData = data[currentUser!.uid] ?? {};
          final myName = currentUserData['username'] != null &&
              currentUserData['username'].toString().trim() != ''
              ? currentUserData['username']
              : (currentUser?.displayName ?? currentUser?.email ?? "User");

          return Column(
            children: [
              // My Profile Section
              Container(
                color: Colors.green[100],
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Row(
                  children: [
                    buildAvatar(myName,
                        currentUserData['onlineStatus'] ?? true),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          myName,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          currentUser?.email ?? "",
                          style: const TextStyle(
                              fontSize: 14, color: Colors.black54),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Friends List
              Expanded(
                child: users.isEmpty
                    ? const Center(child: Text("No friends found"))
                    : ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    final userName = user['username'] ?? "Unknown";
                    final isOnline = user['onlineStatus'] ?? false;
                    return ListTile(
                      leading: buildAvatar(userName, isOnline),
                      title: Text(userName),
                      subtitle: Text(user['email']),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PrivateChatPage(
                              currentUserId: currentUser!.uid,
                              friendId: user['uid'],
                              friendName: userName,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
