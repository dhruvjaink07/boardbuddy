# 🧠 BoardBuddy

> Your personal AI-enhanced Kanban and Project Management tool, designed for students, creators, and campus teams.

BoardBuddy helps users quickly create task boards either manually or through AI prompts. It supports file sharing, in-app chat, Kanban task flow, and is optimized for mobile productivity.

---

## 📁 Directory Structure (Feature-First Architecture with Riverpod + GoRouter)

```
lib/
├── core/                   # Global constants, themes, services, and shared widgets
│   ├── constants/
│   ├── services/
│   ├── theme/
│   └── widgets/
│
├── routes/                 # Centralized GoRouter setup
│   ├── app_router.dart
│   └── route_paths.dart
│
├── features/               # Feature-first modular folders
│   ├── auth/
│   │   ├── data/           # FirebaseAuth, models
│   │   ├── presentation/   # Login, signup screens
│   │   └── providers/      # Riverpod providers
│   │
│   ├── home/
│   ├── board/              # Create board, list boards
│   ├── kanban/             # Kanban board UI + logic
│   └── shared/             # Reusable UI, utilities
│
└── main.dart               # Entry point 
```

---

## 🛠️ Tech Stack

| Tech         | Usage                              |
|--------------|-------------------------------------|
| Flutter      | Mobile frontend framework           |
| Firebase     | Auth, Firestore, FCM                |
| Riverpod     | State management                    |
| GoRouter     | Routing and navigation              |
| Cloudinary   | File uploads and sharing            |

---

## 🧑‍💻 Contribution Guidelines

### 👥 Team Roles

| Developer     | Responsibility                          |
|---------------|------------------------------------------|
| **Dhruv**     | Lead dev (UI + Backend + Setup)          |
| **Chirag**    | UI + Backend Contributor                 |
| **Shriram**   | UI Only                                  |
| **Prathmesh** | UI Only                                  |

### 🔧 Getting Started (First Time Setup)

1. **Clone the project to your computer**  
   ```bash
   git clone https://github.com/<your-org>/boardbuddy.git
   cd boardbuddy
   ```

2. **Install Flutter dependencies**  
   ```bash
   flutter pub get
   ```

3. **Run the app to make sure everything works**  
   ```bash
   flutter run
   ```

### 📝 How to Work on Tasks (Simple Version)

**Step 1: Get your task**
- Check the Notion board for your assigned task
- if you're unsure about anything let's discuss

**Step 2: Pull latest changes (VERY IMPORTANT!)**
```bash
git pull origin main
```

**Step 3: Make your changes**
- Write your code
- Test that it works
- Follow the folder structure shown above

**Step 4: Save your work**
```bash
git add .
git commit -m "Add: brief description of what you did"
git push origin main
```

### ⚠️ SUPER IMPORTANT - Avoiding Merge Conflicts

**Before you start working, ALWAYS do:**
```bash
git pull origin main
```

**Why? To avoid merge conflicts that break everything!**

### 🚨 Rules to Prevent Problems

1. **Always pull before starting** - Run `git pull origin main` before coding
2. **Don't edit the same file as someone else** - Check with team first use Notion for it
3. **Work on different features** - Don't touch files others are working on
4. **Ask before big changes** - If unsure, just add comment in the issues created
5. **Test your code** - Make sure it runs before pushing

### 🆘 When You Get Merge Conflicts

**If you see scary error messages:**
- **DON'T PANIC** 
- Ask me immediately - do not --force push it 😭 
- Try to fix conflicts by yourself but also see to it that is doesn't create another issues  

### 🚫 What NOT to Do

- Don't forget to `git pull` before starting
- Don't edit files that others are working on
- Don't push broken code
- Don't ignore error messages - ask for help

### 📋 Quick Checklist Before You Code

- [ ] Did I pull latest changes? (`git pull origin main`)
- [ ] Am I working on my assigned task only?
- [ ] Is anyone else editing the same files?
- [ ] Did I test my code?

---

## 📌 Working Guidelines

- Follow the **feature-first folder structure** strictly
- Each feature should have its own:
  - `data/` folder: models, services, repos
  - `presentation/`: screens and widgets
  - `providers/`: Riverpod logic

### 📚 Naming Conventions

- Screens: `xyz_screen.dart`
- Models: `xyz_model.dart`
- Services: `xyz_service.dart`
- Providers: `xyz_provider.dart`
- Use snake_case for files, camelCase for variables

---

## 🔄 Simple Branch Guide

```
main ← (protected, don't touch)
  ↑
 dev ← (pull from here, merge to here)
  ↑
feature/your-task ← (your work happens here)
```

**Remember:** Always create your branch from `dev`, and merge back to `dev`

---

## ✅ Task Management

All assigned tasks are tracked in the shared Notion board  
👉 [Notion Task Board](https://www.notion.so/23c0a523445d80e48270e31f3b01a4e9?v=23c0a523445d80a99442000c99209ada&source=copy_link) 

- Update status regularly
- Tick completed tasks
- Ask Dhruv or Chirag for logic guidance if stuck

---

## 🙏 Acknowledgement

This project is developed as part of an academic initiative with the aim to explore real-world team collaboration, architecture, and product design using Flutter and Firebase. We futher aim to take this to market so other's can also benefit from it

---

> Built with ❤️ by Team BoardBuddy
