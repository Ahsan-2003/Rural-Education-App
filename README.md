# 📚 Rural Education App

**Offline-First Mobile Learning Application for Low-Connectivity Areas**

A Flutter-based education app that works fully offline, designed for students in rural areas with limited internet access. Content is downloaded once and available anytime, with progress syncing to the cloud when connectivity is available.

## ✨ Features

| Feature | Description |
|---------|-------------|
| 📱 **Offline First** | All content works without internet |
| 👤 **Multi-Profile** | Multiple students on one device with PIN login |
| 📚 **4 Subjects** | Mathematics, Science, English, History |
| 📝 **12 Lessons** | Markdown-based content with rich formatting |
| 🎯 **Quiz Engine** | MCQ & True/False with instant local grading |
| 🔄 **Cloud Sync** | Progress syncs to Supabase when online |
| 📊 **Progress Tracking** | Per-student progress with visual indicators |
| 🏆 **Gamification** | Streaks, XP points, and 8 achievement badges |
| 🔊 **Audio Narration** | Text-to-Speech for all lessons |
| 📦 **Content Download** | Download lesson packs from cloud |
| 🔄 **Delta Updates** | Only download changed content |
| 📶 **Connectivity Aware** | Visual online/offline indicators |
| 👨‍🏫 **Teacher Dashboard** | In-app dashboard with passcode access |

## 🛠️ Tech Stack

| Layer | Technology |
|-------|-----------|
| **Framework** | Flutter 3.x |
| **Local Database** | Hive |
| **Backend** | Supabase (PostgreSQL + Storage) |
| **Content Format** | Markdown + JSON |
| **TTS** | flutter_tts |
| **Navigation** | Navigator (push/pushReplacement) |
| **Target Platform** | Android (Min SDK 21) |

## 📋 Prerequisites

- Flutter SDK 3.16+
- Android Studio / VS Code
- Android device or emulator (API 21+)
- Supabase account (free tier)

## 🚀 Quick Start

### 1. Clone the Repository

```bash
git clone https://github.com/yourusername/rural-education-app.git
cd rural-education-app
```
### 2. Install Dependencies

```bash
flutter pub get
```
### 3. Set Up Supabase

1. Create a project at [supabase.com](https://supabase.com)
2. Go to **SQL Editor** and run:

```sql
-- Students table
CREATE TABLE students (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  pin_hash TEXT NOT NULL,
  class_code TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  last_synced_at TIMESTAMPTZ
);

-- Progress events table
CREATE TABLE progress_events (
  id UUID PRIMARY KEY,
  student_id UUID REFERENCES students(id),
  event_type TEXT NOT NULL,
  lesson_id TEXT NOT NULL,
  payload JSONB DEFAULT '{}',
  client_created_at TIMESTAMPTZ NOT NULL,
  server_received_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE students ENABLE ROW LEVEL SECURITY;
ALTER TABLE progress_events ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Enable all for students" ON students FOR ALL USING (true);
CREATE POLICY "Enable all for events" ON progress_events FOR ALL USING (true);
```

3. Go to **Storage** → Create bucket named `lesson-packs` (public)
4. Upload lesson pack JSON files to the bucket

### 4. Configure Supabase in the App

Open `lib/main.dart` and replace with your Supabase credentials:

```dart
await Supabase.initialize(
  url: 'https://YOUR_PROJECT.supabase.co',
  anonKey: 'YOUR_ANON_KEY',
);
```

### 5. Run the App

```bash
flutter run
```

---

## 📁 Project Structure

```
lib/
├── main.dart                          # App entry point
├── models/                            # Data models
│   ├── student_profile.dart
│   ├── lesson.dart
│   ├── subject.dart
│   └── badge.dart
├── services/                          # Business logic
│   ├── database_service.dart          # Hive local storage
│   ├── content_service.dart           # Lesson content provider
│   ├── sync_service.dart              # Supabase sync
│   ├── download_service.dart          # Content download
│   ├── content_cache_service.dart     # Local cache management
│   ├── connectivity_service.dart      # Online/offline detection
│   ├── streak_service.dart            # Streaks & badges
│   └── tts_service.dart               # Text-to-speech
├── screens/                           # UI screens
│   ├── existing_screens.dart          # Profile list
│   ├── profile_screen.dart            # Create profile
│   ├── home_screens.dart              # Welcome & progress
│   ├── subject_screen.dart            # Subject selection
│   ├── lesson_list_screen.dart        # Lesson list
│   ├── lesson_viewer_screen.dart      # Lesson content
│   ├── quiz_screen.dart               # Quiz engine
│   ├── download_screen.dart           # Download manager
│   ├── badges_screen.dart             # Achievement badges
│   ├── dashboard_screen.dart          # Student dashboard
│   └── teacher_dashboard_screen.dart   # Teacher view
└── widgets/                           # Reusable widgets
    ├── connectivity_banner.dart
    ├── audio_player_widget.dart
    └── badge_earned_dialog.dart
```

---

## 📦 Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  supabase_flutter: ^2.3.0    # Backend & sync
  hive_flutter: ^1.1.0         # Local database
  uuid: ^4.2.0                 # Unique IDs
  flutter_markdown: ^0.6.0     # Content rendering
  connectivity_plus: ^5.0.0    # Network detection
  path_provider: ^2.1.0        # File paths
  http: ^1.1.0                 # Download content
  flutter_tts: ^3.8.0          # Text-to-speech
```

---

## 🎯 User Flow

```
App Launch → Profile List → PIN Login → Home Screen
                                          ↓
                                    Subject Selection
                                          ↓
                                    Lesson List → Lesson Viewer
                                          ↓           ↓
                                    Quiz Engine    Audio Narration
                                          ↓
                                    Progress Saved → Cloud Sync
```

---

## 📦 Content Packs

Lesson content is stored as JSON files in Supabase Storage. Each pack contains:

```json
{
  "subjectId": "math",
  "subjectName": "Mathematics",
  "icon": "📐",
  "version": 1,
  "lessons": [
    {
      "id": "math_1",
      "title": "Introduction to Fractions",
      "content": "# Markdown content...",
      "quiz": { "questions": [...] }
    }
  ]
}
```

---

## 🧪 Testing

### Test Offline Mode
1. Turn on Airplane Mode ✈️
2. Browse lessons, take quizzes - everything works
3. Complete some lessons
4. Turn off Airplane Mode
5. Cloud icon shows pending sync count
6. Tap to sync - data uploads to Supabase

### Test Delta Updates
1. Download a lesson pack (v1)
2. Upload updated pack (v2) to Supabase Storage
3. Open Download Manager → Tap Refresh
4. Pack shows "Update Available" with orange button
5. Tap Update - only changed pack downloads

---

## 🔑 Default Passcodes

| Role | Passcode |
|------|----------|
| Teacher Dashboard | `123456` |
| Student PIN | Set by user (4 digits) |

---

## 📊 App Statistics

- **Subjects:** 4
- **Lessons:** 12
- **Quiz Questions:** 60
- **Achievement Badges:** 8
- **Supported Android:** API 21+

---

## 🗄️ Data Storage

| Storage | Purpose |
|---------|---------|
| **Hive (Local)** | Profiles, progress, streaks, badges, cached content |
| **Supabase PostgreSQL** | Student profiles, progress events |
| **Supabase Storage** | Lesson pack JSON files |

---

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Open a Pull Request

---

## 📄 License

This project is licensed under the MIT License.

---
