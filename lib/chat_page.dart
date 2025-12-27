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
    setOnlineStatus(true); // Set online when page opens
  }

  @override
  void dispose() {
    setOnlineStatus(false); // Set offline when page closes
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
      usersRef.child(currentUser!.uid).update({'onlineStatus': isOnline});
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

  Widget buildAvatar(String? photoUrl, bool isOnline) {
    return Stack(
      children: [
        CircleAvatar(
          radius: 30,
          backgroundColor: Colors.grey[300],
          child: const Icon(Icons.person, size: 30),
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
      appBar: AppBar(
        title: const Text("Chat"),
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

          return Column(
            children: [
              // My Profile Section
              Container(
                color: Colors.grey[200],
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Row(
                  children: [
                    buildAvatar(
                        currentUserData['photoUrl'],
                        currentUserData['onlineStatus'] ?? false),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentUser?.displayName ?? "You",
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
                    final isOnline = user['onlineStatus'] ?? false;
                    return ListTile(
                      leading: buildAvatar(user['photoUrl'], isOnline),
                      title: Text(user['username']),
                      subtitle: Text(user['email']),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PrivateChatPage(
                              currentUserId: currentUser!.uid,
                              friendId: user['uid'],
                              friendName: user['username'],
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
