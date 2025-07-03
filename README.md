# FitLog - Flutter 健身应用

## 1. 项目概述

FitLog 是一款基于 Flutter 开发的**跨平台健身助手应用**，专注于提供完整的健身数据管理和追踪功能。该应用采用**本地 SQLite 数据库**存储，支持**用户认证系统**和**音视频学习资源**，为用户提供全面的健身体验。

### 核心特性
- 🗄️ **SQLite 本地数据库**：安全可靠的数据持久化
- 👤 **用户认证系统**：完整的注册、登录和个人资料管理
- 🎥 **音视频资源库**：集成视频播放器，提供健身教学视频
- 📊 **数据可视化**：体重趋势图表和训练进度追踪
- 🔄 **数据导入导出**：支持数据备份和恢复
- 📱 **跨平台支持**：Windows、Android、iOS、Linux、macOS

### 当前版本状态
- **ASGM1**: 基础功能完成 ✅
- **ASGM2**: SQLite 集成 + 用户认证 + 音视频功能 ✅(Fitness Assistant) - Flutter 应用

## 1. 项目概述

一款**离线优先 (offline-first)** 的 Android (及潜在多平台) 健身助手应用，使用 Flutter 构建。它聚焦于三大核心场景：**“体重体测”、“训练打卡”和“饮食记录”**。该应用专为已具备基础健身知识的用户设计，为他们提供**快速录入和趋势可视化**功能。

其核心特性是强大的**本地数据持久化**能力，确保用户数据在不同应用会话间得以保存，并且应用能够完全离线运行。此外，它还具备数据**导入/导出功能**。

## 2. 功能特性

### 核心功能模块

#### 🏠 Dashboard (仪表盘)
- 今日数据概览 (体重、训练完成度、热量平衡)
- 快速访问各功能模块
- 用户登录状态显示

#### ⚖️ Body Data (身体数据)
- 体重记录与趋势图表 (7/30天)
- BMI/FFMI 自动计算
- 体脂率追踪 (待完善)
- 身高设置

#### 🏋️ Training (训练管理)
- 训练计划创建与管理
- 训练记录打卡
- 进度追踪与统计
- 模板化训练动作

#### 🍎 Nutrition (营养管理)
- 饮食记录与热量追踪
- 快速录入功能 (+100/+250 kcal)
- 食物数据库搜索
- 每日摄入统计

#### 📚 Resources (学习资源)
- **文章库**: 健身相关的 Markdown 文章
- **视频库**: 健身教学视频播放 🆕
  - 基础训练教程 (10:30)
  - 热身运动 (5:15)
  - 拉伸放松 (8:20)

#### ⚙️ Settings (设置)
- **个人资料**: 用户信息管理 🆕
- **帮助与支持**: 使用指南和常见问题 🆕
- 身高和热量目标设置
- 数据存储说明

### 新增功能 (ASGM2)

#### 👤 用户认证系统
- **用户注册**: 邮箱、密码、姓名注册
- **用户登录**: 安全的身份验证
- **会话管理**: 登录状态持久化
- **测试账户**: demo@fitlog.com / demo123

#### 🗄️ SQLite 数据库
- **数据表设计**: users, weights, workouts, nutrition, media
- **CRUD 操作**: 完整的增删改查功能
- **数据隔离**: 基于 user_id 的用户数据分离
- **性能优化**: 数据缓存和索引优化

#### 🎥 音视频功能
- **视频播放器**: 基于 video_player 和 chewie
- **媒体管理**: 本地视频资源管理
- **播放控制**: 全屏播放、进度控制
- **资源集成**: 无缝整合到学习资源库

## 3. 技术架构

### 架构概览

FitLog 采用分层架构设计，结合现代 Flutter 开发最佳实践，确保代码的可维护性和扩展性。

```
┌─────────────────────────────────────────┐
│              UI Layer                   │
│    (Screens & Widgets)                 │
├─────────────────────────────────────────┤
│            Service Layer                │
│  (DataManager, DatabaseService)        │
├─────────────────────────────────────────┤
│             Data Layer                  │
│      (SQLite Database)                  │
└─────────────────────────────────────────┘
```

### 核心组件

#### 🗄️ 数据持久化层

**SQLite 数据库设计**:
- **users 表**: 用户认证和基本信息 (`id`, `name`, `email`, `password`, `height`)
- **weights 表**: 体重记录历史 (`id`, `user_id`, `date`, `value`)
- **workouts 表**: 训练记录 (`id`, `user_id`, `date`, `name`, `sets`, `is_completed`)
- **nutrition 表**: 营养摄入记录 (`id`, `user_id`, `date`, `meal_type`, `name`, `calories`, `amount`)
- **media 表**: 音视频资源管理 (`id`, `title`, `type`, `path`)

**DatabaseService 特性**:
- 单例模式确保全局统一的数据库实例
- 完整的 CRUD 操作支持
- 用户数据隔离 (基于 user_id)
- 跨平台兼容性

#### 📊 数据管理层

**DataManager (核心服务)**:
- 继承 `ChangeNotifier` 实现响应式状态管理
- 整合 SQLite 数据库操作
- 内存缓存机制提升性能
- 用户会话管理和状态持久化

### 数据流程

1. **应用启动**: 初始化 SQLite 数据库，检查用户登录状态
2. **用户认证**: 通过 DatabaseService 验证用户身份
3. **数据操作**: UI → DataManager → DatabaseService → SQLite
4. **状态更新**: DatabaseService → DataManager → ChangeNotifier → UI 重建
5. **数据持久化**: 所有操作实时同步到 SQLite 数据库

* **UI 层 (`lib/screens/`, `lib/widgets/`)**:
    * 由构成用户界面的 Flutter 小部件组成。
    * 与 `DataManager` 交互以显示和更新数据。
    * 通过 `ChangeNotifier` 监听 `DataManager` 的变化，实现响应式 UI 更新。
    * 详细的 UI/UX 设计在 `DesignDoc/by_Manus/` 目录中指定。

* **数据模型 (`lib/models/`)**:
    * 表示应用的数据结构（例如 `WeightEntry`, `WorkoutEntry`, `NutritionEntry`, `Article`）。
    * 利用 `json_serializable` 方便地与 JSON 格式相互转换以进行存储。

* **服务层 (`lib/services/`)**:
    * **`DataManager`**: 一个单例的 `ChangeNotifier`，作为所有应用数据的中心枢纽。它管理内存中的数据缓存，处理从存储服务加载数据和向存储服务保存数据，并为 UI 提供与数据交互的方法。
    * **`StorageService` (接口)**: 定义了存储操作的契约，允许灵活的存储实现。
    * **`LocalStorageService` (实现)**: 实现了 `StorageService`，结合使用 `shared_preferences` 存储简单数据和本地 JSON 文件（通过 `path_provider`）存储结构化数据集合（例如体重历史、训练日志）。
    * **`ExportService`**: 管理将用户数据导出到 JSON 备份文件以及从这类文件导入数据的逻辑。使用 `permission_handler` 获取必要的文件系统权限。

* **数据持久化流程**:
    1.  应用启动时，初始化 `DataManager`。
    2.  `DataManager` 使用 `LocalStorageService` 从文件加载持久化的 JSON 数据到内存中。
    3.  UI 从 `DataManager` 显示数据。
    4.  用户操作通过 `DataManager` 的方法修改数据。
    5.  `DataManager` 更新其内存缓存，通知监听器（UI 更新），然后指示 `LocalStorageService` 将更改保存回 JSON 文件。

* **导航**:
    * 一个顶部 Dashboard 卡片，在切换页面时会收缩为全局固定头部。
    * 底部导航栏包含“体测”、“训练”、“饮食”、“资源”四个一级页面。
    * 操作（新增/编辑）主要使用弹框或底部抽屉，以尽量避免二级页面跳转。

## 4. 开发状态

### 🎯 ASGM2 开发完成状态

**✅ 已完成的核心功能**:
- 🗄️ SQLite 数据库完全集成
- 👤 用户认证系统 (注册/登录/个人资料)
- 🎥 音视频播放功能
- 📊 数据可视化图表
- 🔄 数据导入导出
- 📱 跨平台支持 (Windows/Android/iOS/Linux/macOS)
- ⚙️ 完整的设置管理

**⚠️ 部分完成的功能**:
- 体脂率记录 (基础框架，返回空数据)
- 高级数据分析功能

**🔄 待优化项目**:
- 代码质量优化 (修复 41 个 lint 警告)
- 性能优化 (数据库索引)
- 用户体验改进 (错误处理优化)

### 📊 技术指标

- **编译状态**: ✅ 无编译错误
- **测试账户**: demo@fitlog.com / demo123
- **应用性能**: 启动速度正常，页面切换流畅
- **数据库性能**: 响应及时，支持并发操作
- **兼容性**: 新旧代码接口完全兼容

### 🧪 测试状态

**功能测试清单**:
- [x] 应用启动和数据库初始化
- [x] 用户认证系统
- [x] 数据库 CRUD 操作
- [x] 主要界面功能
- [x] 音视频播放
- [x] 数据追踪功能
- [x] 个人资料管理

**已知问题**:
- 41 个非阻塞性编译警告
- 体脂率功能需要完整实现
- 部分硬编码值需要优化

## 5. 项目结构重点

```
FitLog_Project/
├── DesignDoc/                  # 设计文档
│   ├── ASGM2/                  # ASGM2 开发文档
│   │   ├── ASGM2_todo.md       # 开发任务清单
│   │   └── ASGM2具体开发参考.md # 具体开发指南
│   └── Temp/                   # 开发过程文档
│       ├── SQLite系统优化清单.md
│       ├── 功能测试清单.md
│       ├── 开发任务概览.md
│       ├── 开发进度跟踪.md
│       └── 界面导航确认清单.md
├── assets/                     # 资源文件
│   ├── articles/               # Markdown 文章
│   ├── images/                 # 图片资源
│   └── videos/                 # 视频资源 🆕
│       ├── stretching.mp4
│       ├── tutorial.mp4
│       └── warmup.mp4
├── lib/
│   ├── main.dart               # 应用入口，认证包装器
│   ├── models/                 # 数据模型
│   │   ├── user.dart           # 用户模型 🆕
│   │   ├── weight_entry.dart   # 体重记录
│   │   ├── workout_entry.dart  # 训练记录
│   │   ├── nutrition_entry.dart # 营养记录
│   │   └── article.dart        # 文章模型
│   ├── screens/                # UI 界面
│   │   ├── auth/               # 认证相关 🆕
│   │   │   ├── login_screen.dart
│   │   │   └── registration_screen.dart
│   │   ├── main_screen.dart    # 主界面 (底部导航)
│   │   ├── dashboard_screen.dart
│   │   ├── body_screen.dart
│   │   ├── workout_screen.dart
│   │   ├── nutrition_screen.dart
│   │   ├── library_screen.dart
│   │   ├── settings_screen.dart
│   │   ├── profile_screen.dart 🆕
│   │   ├── help_screen.dart    🆕
│   │   └── video/              # 视频相关 🆕
│   │       ├── video_library_screen.dart
│   │       └── video_player_screen.dart
│   ├── services/               # 业务逻辑服务
│   │   ├── data_manager.dart   # 核心数据管理
│   │   ├── database_service.dart # SQLite 服务 🆕
│   │   ├── export_service.dart # 导入导出
│   │   └── article_service.dart # 文章服务
│   ├── widgets/                # UI 组件
│   │   ├── glass_card.dart     # 毛玻璃卡片
│   │   ├── weight_chart.dart   # 体重图表
│   │   └── video_player_widget.dart # 视频播放器 🆕
│   └── utils/                  # 工具类
└── pubspec.yaml                # 依赖配置
```
## 6. 主要依赖项

### 核心依赖
- `flutter`: Flutter 框架
- `sqflite`: SQLite 数据库支持 🆕
- `path_provider`: 文件系统路径访问
- `path`: 路径操作工具

### UI 和可视化
- `fl_chart`: 图表和数据可视化
- `shared_preferences`: 简单键值存储

### 音视频功能 🆕
- `video_player`: 视频播放核心功能
- `chewie`: 视频播放器 UI 组件

### 数据处理
- `json_annotation`: JSON 序列化注解
- `json_serializable` (dev): JSON 序列化代码生成
- `permission_handler`: 运行时权限管理

### 开发工具
- `build_runner` (dev): 代码生成工具
- `flutter_lints` (dev): 代码规范检查

## 7. 安装和运行

### 环境要求
- Flutter SDK 3.0+
- Dart 3.0+
- Android Studio / VS Code
- 支持的平台：Windows, Android, iOS, Linux, macOS

### 快速开始

1. **克隆项目**
   ```bash
   git clone <repository-url>
   cd FitLog_Project
   ```

2. **安装依赖**
   ```bash
   flutter pub get
   ```

3. **生成代码** (如果需要)
   ```bash
   flutter packages pub run build_runner build
   ```

4. **运行应用**
   ```bash
   flutter run
   ```

5. **使用测试账户登录**
   - 📧 邮箱: `demo@fitlog.com`
   - 🔑 密码: `demo123`

### 开发说明

- 首次运行时会自动创建 SQLite 数据库
- 示例用户会自动创建用于测试
- 所有数据本地存储，无需网络连接
- 支持热重载进行快速开发

## 8. 功能导航

### 🔐 认证系统
- **登录**: 邮箱 + 密码验证
- **注册**: 新用户账户创建
- **个人资料**: 用户信息管理 (设置 → 个人资料)

### 📊 数据管理
- **仪表盘**: 应用主界面，数据概览
- **身体数据**: 体重追踪，BMI 计算
- **训练记录**: 训练计划和进度追踪
- **营养管理**: 饮食记录和热量统计

### 📚 学习资源
- **文章库**: 健身相关 Markdown 文章 (资源 → Articles)
- **视频库**: 健身教学视频播放 (资源 → Videos)

### ⚙️ 设置管理
- **帮助与支持**: 使用指南 (设置 → 帮助与支持)
- **数据导出**: 备份功能
- **用户设置**: 身高、热量目标等

## 9. 开发路线图

### 🎯 下一阶段优化
- [ ] 体脂率功能完整实现
- [ ] 高级数据分析和报告
- [ ] 代码质量优化 (消除 lint 警告)
- [ ] 性能优化 (数据库索引)

### 🚀 未来功能
- [ ] 云端数据同步
- [ ] 社交功能 (好友系统)
- [ ] 智能推荐算法
- [ ] 可穿戴设备集成

---

**项目状态**: ASGM2 主要开发完成 ✅  
**最后更新**: 2025年7月1日  
**版本**: v2.0 (ASGM2)
3.  **获取依赖项：**
    ```bash
    flutter pub get
    ```
4.  **运行代码生成器** (如果修改了模型，则需要此步骤)：
    ```bash
    flutter pub run build_runner build --delete-conflicting-outputs
    ```
5.  **运行应用：**
    ```bash
    flutter run
    ```

## 8. 构建配置说明
* **Android**:
    * 应用 ID: `com.example.flutter_asgm1`
    * Release 构建当前使用 debug 签名密钥。对于生产发布，需要正确配置。
* **多平台**: 项目包含了 iOS、Linux、Windows 和 Web 的样板文件，表明了跨平台部署的潜力。

## 9. 待办事项 / 未来增强 (来自 `DesignDoc/by_Manus/todo.md`)
* 最终交付：向用户汇报并发送设计方案文档。

(`todo.md` 表明大部分与界面和基础逻辑相关的设计和实现任务在数据持久化重构之前已经完成。)