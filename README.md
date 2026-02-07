# Rablo Chat App - Assignment Task 2

A real-time chat application built with **Flutter** and **Firebase** that allows users to chat with each other, sync contacts, and invite friends.

## 📱 Screenshots

The app features a modern, premium UI with:
- Gradient backgrounds and glassmorphism effects
- Smooth animations and micro-interactions
- Dark mode support

## ✅ Features Implemented

### Task 2 Requirements:

| Requirement | Status | Implementation |
|-------------|--------|----------------|
| Frontend to show all users to chat with | ✅ | Home Screen with Users tab |
| Store messages by user UID in Firebase | ✅ | Private chat with UID-based storage |
| CRUD operations for messages | ✅ | Create, Read, Update, Delete |
| Firebase Firestore integration | ✅ | Real-time sync |
| Real-time synchronization | ✅ | Firestore snapshots |

### Additional Features:
- 🔍 **Search Users** - Find users by name, email, or phone
- 📱 **Contact Sync** - Sync device contacts to find friends on the app
- 📨 **Invite Friends** - Share invite links to non-users
- 💬 **Global Chat** - Chat room for all users
- 🔒 **Authentication** - Email/password login with Firebase Auth

## 🛠️ Tech Stack

- **Frontend**: Flutter 3.x
- **Backend**: Firebase
  - Firebase Authentication
  - Cloud Firestore
- **State Management**: Provider
- **UI Libraries**: 
  - Google Fonts
  - Flutter Animate

## 📂 Project Structure

```
lib/
├── main.dart                    # App entry point
├── models/
│   ├── message_model.dart       # Message data model
│   └── user_model.dart          # User data model
├── screens/
│   ├── auth/
│   │   ├── login_screen.dart    # Login screen
│   │   └── signup_screen.dart   # Registration screen
│   ├── chat/
│   │   └── chat_screen.dart     # Global chat screen
│   └── home/
│       ├── home_screen.dart     # Main home with tabs
│       └── private_chat_screen.dart  # Private 1-on-1 chat
├── services/
│   ├── auth_service.dart        # Authentication logic
│   ├── chat_service.dart        # Global chat CRUD
│   ├── private_chat_service.dart # Private chat CRUD
│   ├── contact_service.dart     # Contact sync & invite
│   └── user_service.dart        # User management
└── utils/
    ├── theme.dart               # App theming
    └── common_widgets.dart      # Reusable widgets
```

## 🔥 Firebase Structure

### Firestore Collections:

```
/users/{uid}
  ├── name: string
  ├── email: string
  ├── mobile: string
  └── /chats/{otherUserId}
        ├── lastMessage: string
        └── lastMessageTime: timestamp

/chat_room/{messageId}
  ├── senderId: string
  ├── senderName: string
  ├── text: string
  └── timestamp: timestamp

/private_chats/{chatRoomId}
  └── /messages/{messageId}
        ├── senderId: string
        ├── senderName: string
        ├── text: string
        └── timestamp: timestamp
```

## 🔐 Firestore Security Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
      
      match /chats/{chatId} {
        allow read, write: if request.auth != null;
      }
    }
    
    match /chat_room/{messageId} {
      allow read, write: if request.auth != null;
    }
    
    match /private_chats/{chatRoomId} {
      allow read, write: if request.auth != null;
      
      match /messages/{messageId} {
        allow read, write: if request.auth != null;
      }
    }
  }
}
```

## 🚀 Getting Started

### Prerequisites:
- Flutter SDK 3.2.0 or higher
- Android Studio / VS Code
- Firebase project with Firestore enabled

### Installation:

1. Clone the repository:
```bash
git clone https://github.com/RamanKumar00/Rablo_Assignment.git
cd Rablo_Assignment
```

2. Install dependencies:
```bash
flutter pub get
```

3. Configure Firebase:
   - Add your `google-services.json` to `android/app/`
   - Add your `GoogleService-Info.plist` to `ios/Runner/`

4. Run the app:
```bash
flutter run
```

### Build APK:
```bash
flutter build apk --release
```

The APK will be generated at: `build/app/outputs/flutter-apk/app-release.apk`

## 📱 CRUD Operations

| Operation | Method | Description |
|-----------|--------|-------------|
| **Create** | `sendMessage()` | Add new message to Firestore |
| **Read** | `getMessages()` | Stream messages in real-time |
| **Update** | `editMessage()` | Modify existing message text |
| **Delete** | `deleteMessage()` | Remove message from Firestore |

### Example Usage:

```dart
// Create
await chatService.sendMessage("Hello!");

// Read (real-time stream)
StreamBuilder<List<MessageModel>>(
  stream: chatService.getMessages(),
  builder: (context, snapshot) { ... }
);

// Update
await chatService.editMessage(messageId, "Updated text");

// Delete
await chatService.deleteMessage(messageId);
```

## 📧 Contact

- **Developer**: Raman Kumar
- **GitHub**: [@RamanKumar00](https://github.com/RamanKumar00)

## 📝 License

This project is created for the Rablo Assignment.
