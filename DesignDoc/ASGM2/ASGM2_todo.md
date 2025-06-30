# **Assignment 2 开发任务清单 (TODO List)**

本文档旨在详细列出为完成 DMT321 Assignment 2 所需的所有核心开发任务。

## **一、 数据库层：集成 SQLite**

-   [ ] **1. 添加依赖**:
    -   在 `pubspec.yaml` 文件中添加 `sqflite` 和 `path` 依赖。

-   [ ] **2. 创建数据库服务 (`database_service.dart`)**:
    -   创建一个新的 Service 文件，例如 `lib/services/database_service.dart`。
    -   在该文件中创建一个 `DatabaseService` 类。
    -   实现数据库的初始化方法 `initDB()`，该方法应：
        -   使用 `path_provider` 的 `getApplicationDocumentsDirectory()` 找到数据库存储路径。
        -   使用 `sqflite` 的 `openDatabase()` 打开或创建一个名为 `fitness_app.db` 的数据库文件。
    -   在 `onCreate` 回调中，创建所有需要的表。

-   [ ] **3. 设计并创建数据表**:
    -   **用户表 (users)**:
        -   `id` (INTEGER, PRIMARY KEY, AUTOINCREMENT)
        -   `name` (TEXT, NOT NULL)
        -   `email` (TEXT, NOT NULL, UNIQUE)
        -   `password` (TEXT, NOT NULL)
        -   `height` (REAL)
    -   **体重记录表 (weights)**:
        -   `id` (INTEGER, PRIMARY KEY, AUTOINCREMENT)
        -   `user_id` (INTEGER, FOREIGN KEY to users.id)
        -   `date` (TEXT, NOT NULL)
        -   `value` (REAL, NOT NULL)
    -   **训练记录表 (workouts)**:
        -   `id` (INTEGER, PRIMARY KEY, AUTOINCREMENT)
        -   `user_id` (INTEGER, FOREIGN KEY to users.id)
        -   `date` (TEXT, NOT NULL)
        -   `name` (TEXT, NOT NULL)
        -   `sets` (INTEGER, NOT NULL)
        -   `is_completed` (INTEGER, NOT NULL, 0 or 1)
    -   **饮食记录表 (nutrition)**:
        -   `id` (INTEGER, PRIMARY KEY, AUTOINCREMENT)
        -   `user_id` (INTEGER, FOREIGN KEY to users.id)
        -   `date` (TEXT, NOT NULL)
        -   `meal_type` (TEXT, NOT NULL)
        -   `name` (TEXT, NOT NULL)
        -   `calories` (INTEGER, NOT NULL)
        -   `amount` (TEXT)
    -   **音视频记录表 (media)**:
        -   `id` (INTEGER, PRIMARY KEY, AUTOINCREMENT)
        -   `title` (TEXT, NOT NULL)
        -   `type` (TEXT, 'audio' or 'video')
        -   `path` (TEXT, NOT NULL)

-   [ ] **4. 实现 CRUD 操作**:
    -   在 `DatabaseService` 中为每个表创建完整的 `Create`, `Read`, `Update`, `Delete` 方法。
    -   **Users**:
        -   `createUser(User user)`
        -   `getUser(String email, String password)`
        -   `updateUser(User user)`
    -   **Weights**:
        -   `addWeight(WeightEntry entry)`
        -   `getWeights(int userId)`
        -   `deleteWeight(int id)`
    -   **Workouts**:
        -   `addWorkout(WorkoutEntry entry)`
        -   `getWorkoutsByDate(int userId, String date)`
        -   `updateWorkout(WorkoutEntry entry)`
        -   `deleteWorkout(int id)`
    -   **Nutrition**:
        -   `addMeal(MealEntry entry)`
        -   `getMealsByDate(int userId, String date)`
        -   `deleteMeal(int id)`
    -   **Media**:
        -   `addMedia(MediaEntry entry)`
        -   `getMedia()`

-   [ ] **5. 重构 `DataManager`**:
    -   移除 `DataManager` 中的本地 JSON 文件存储逻辑 (`local_storage_service.dart` 的相关调用可以被替换)。
    -   将 `DataManager` 的所有数据操作方法（如 `addWeight`, `addWorkout` 等）的实现，改为调用 `DatabaseService` 中对应的 CRUD 方法。

## **二、 用户认证与页面实现**

-   [ ] **1. 创建用户模型 (`user.dart`)**:
    -   在 `lib/models/`下创建 `user.dart`，包含 `id`, `name`, `email`, `password`, `height` 等字段。

-   [ ] **2. 实现注册屏幕 (`registration_screen.dart`)**:
    -   创建一个新的 `StatefulWidget` 页面。
    -   UI 包含输入 "姓名"、"邮箱"、"密码" 的 `TextField` 和一个 "注册" 按钮。
    -   点击 "注册" 按钮时，调用 `DatabaseService` 的 `createUser` 方法将新用户信息存入数据库。
    -   注册成功后，自动跳转到登录页面。

-   [ ] **3. 实现登录屏幕 (`login_screen.dart`)**:
    -   创建一个新的 `StatefulWidget` 页面。
    -   UI 包含输入 "邮箱"、"密码" 的 `TextField` 和一个 "登录" 按钮。
    -   [cite_start]点击 "登录" 按钮时，调用 `DatabaseService` 的 `getUser` 方法进行验证 [cite: 90]。
    -   验证成功后，将用户信息保存在一个全局状态中（如 `DataManager`），并导航到 `MainScreen`。

-   [ ] **4. 修改应用入口 (`main.dart`)**:
    -   将 `home` 的默认页面从 `MainScreen` 改为 `LoginScreen`。
    -   在 `routes` 中添加 `/register` 和 `/login` 的路由。
    -   实现启动时检查登录状态的逻辑，如果已登录则直接进入 `MainScreen`。

-   [ ] **5. 实现个人资料页面 (`profile_screen.dart`)**:
    -   [cite_start]创建一个新的 `StatefulWidget` 页面来满足 Asg2 的要求，或者改造现有的 `BodyScreen` [cite: 83]。
    -   此页面应能显示当前登录用户的姓名、邮箱、身高等信息。
    -   提供一个 "编辑" 功能，允许用户修改个人信息，并调用 `DatabaseService` 的 `updateUser` 方法更新数据库。

-   [ ] **6. 实现帮助/支持页面 (`help_support_screen.dart`)**:
    -   [cite_start]创建一个新的 `StatelessWidget` 页面 [cite: 87]。
    -   页面内容可以包含静态文本，如应用的常见问题解答 (FAQ) 或联系方式。
    -   在 `SettingsScreen` 或其他合适的位置添加入口导航到此页面。

## **三、 音视频功能集成**

-   [ ] **1. 添加依赖**:
    -   在 `pubspec.yaml` 中添加 `video_player` 和 `chewie` (或 `audioplayers`) 包。

-   [ ] **2. 创建音视频播放页面/组件**:
    -   [cite_start]选择一个合适的屏幕（例如 `LibraryScreen` 或一个新的 `MediaScreen`）来集成播放功能 [cite: 93]。
    -   实现视频播放器组件，能够加载并播放一个（或多个）本地或网络视频。
    -   为播放器添加播放、暂停、进度条等基本控制功能。
    -   如果选择音频，实现类似的音频播放功能。

-   [ ] **3. 准备媒体资源**:
    -   将至少一个音频或视频文件放置在 `assets` 目录下。
    -   在 `pubspec.yaml` 中声明 `assets` 路径。

---