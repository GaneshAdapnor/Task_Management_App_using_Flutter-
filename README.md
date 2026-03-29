# Task Management System

A production-quality Flutter task-management app built for the Flodo AI take-home assignment.

---

## Track & Stretch Goal

| | |
|---|---|
| **Track** | B — Mobile Specialist (Flutter + SQLite, no backend) |
| **Stretch Goal** | Debounced Search (300 ms) with highlighted match text |

---

## Architecture

Feature-first **Clean Architecture** with three explicit layers:

```
lib/
├── core/                          # Shared, feature-agnostic
│   ├── theme/                     # AppColors, AppTheme
│   ├── utils/                     # Debouncer
│   └── widgets/                   # HighlightedText
└── features/tasks/
    ├── domain/                    # Pure Dart — zero Flutter/DB imports
    │   ├── entities/              # TaskEntity, TaskStatus, TaskItem
    │   ├── repositories/          # Abstract TaskRepository interface
    │   └── usecases/              # GetTasks, CreateTask, UpdateTask, DeleteTask
    ├── data/                      # Implements domain contracts
    │   ├── models/                # TaskModel ↔ TaskEntity mapping
    │   ├── datasources/           # SQLite adapter (sqflite)
    │   └── repositories/          # TaskRepositoryImpl
    └── presentation/              # Flutter-aware code only
        ├── providers/             # Riverpod dependency wiring
        ├── controllers/           # TaskListController, TaskFormController
        ├── screens/               # HomeScreen, TaskFormScreen
        └── widgets/               # TaskCard, EmptyStateWidget
```

**Why this matters:** The domain layer has no `import 'package:flutter/...'` and no sqflite dependency. You could swap the entire data layer for a REST API without touching a single domain or presentation file.

---

## State Management

| Provider | Type | Responsibility |
|---|---|---|
| `taskListControllerProvider` | `AsyncNotifier` | Load tasks, CRUD mutations, optimistic delete |
| `taskFilterProvider` | `StateNotifier` | Debounced search query + status filter |
| `filteredTasksProvider` | `Provider` (derived) | Applies filter to the task list |
| `taskFormControllerProvider` | `StateNotifier.family` (autoDispose) | Form field state, draft persistence, save with 2 s delay |

---

## Key Decisions

### sqflite over Isar
Isar requires code generation (`build_runner`). On a fresh clone, this means an extra step before the app compiles. sqflite works immediately after `flutter pub get` — important for a reviewer evaluating a submitted ZIP. The architectural value (domain/data separation, repository pattern) is identical regardless of DB choice.

### Simulated delay in the repository, not the use case
The 2-second delay lives in `TaskRepositoryImpl.createTask/updateTask`. This keeps the use case instant and directly testable, and mirrors what a real API would look like — the repository is the network boundary. Removing the delay to ship to production is a one-line change in one file.

### `TaskItem` view model (pre-computed blocking state)
Rather than having each card widget walk the full task list to check if it's blocked, the controller pre-computes `TaskItem { task, isBlocked, blocker }` once after every mutation. Widgets stay pure and dumb.

### `autoDispose.family` for the form controller
Each form screen gets its own controller keyed by `TaskEntity?`. `autoDispose` ensures the controller (and its in-memory state) is destroyed when the screen pops, preventing stale state if the user opens the form twice. The draft itself survives because it's in `SharedPreferences`, not in the controller's memory.

---

## Features

### Core
- **CRUD** — Create, Read, Update, Delete tasks persisted to SQLite
- **Task fields** — Title, Description, Due Date, Status, Blocked By (optional)
- **Blocking logic** — Task B greyed-out (opacity + lock icon + "Waiting on…" badge) until Task A is Done
- **Drafts** — Title + description auto-saved on every keystroke; restored on next open; cleared on successful save
- **2-second simulated delay** — Save button swaps label for an inline spinner; tapping a second time is a no-op
- **Quick status toggle** — Tap any status chip on a card to cycle it (no delay, optimistic update)
- **Optimistic delete** — Card disappears instantly; DB write happens in background

### Search & Filter
- Debounced text search (300 ms) — list filters only after typing stops
- Matched characters highlighted in indigo inside card titles
- Status filter chips (All / To-Do / In Progress / Done)
- Both filters compose (search within a status filter)

### UX polish
- Staggered card entrance animations (`flutter_animate`)
- Animated opacity transition on blocked/unblocked state change
- `AnimatedContainer` on status chips and filter buttons
- Slide-up page transition into the form screen
- Overdue badge (red) on past-due incomplete tasks
- Progress chip in the AppBar (`X / Y done`)
- Animated empty states for "no tasks" and "no results"
- Bottom sheet save button stays above keyboard / home indicator

---

## Setup

```bash
# 1. Navigate to the project directory
cd flodo_tasks

# 2. Generate platform folders (only needed once if android/ / ios/ are missing)
flutter create . --project-name flodo_tasks

# 3. Install dependencies
flutter pub get

# 4. Run
flutter run
```

> **Flutter SDK requirement:** ≥ 3.3.0

---

## AI Usage

Built with **Claude (claude-sonnet-4-6)** via Claude Code.

### Most valuable prompts
- *"Design a Riverpod AsyncNotifier that pre-computes an isBlocked flag per task so widgets don't need to traverse the full list"* — the `TaskItem` view-model pattern came directly from this.
- *"Put the simulated 2-second delay in the repository, not the use case — explain why"* — the reasoning about the network boundary was immediately usable in the README.
- *"Write a Debouncer utility class that cancels the previous timer on each call, and integrate it with a StateNotifier's setQuery method"* — cleaner than inline `Timer` logic in the widget.

### AI mis-steps I fixed
The initial `copyWith` on `TaskFormState` used a simple `?? this.value` default for nullable fields, making it impossible to explicitly set `blockedById` back to `null` (clearing a blocker). The fix — a private `_kSentinel` object to distinguish "not provided" from "explicitly null" — required a follow-up prompt and manual verification.
