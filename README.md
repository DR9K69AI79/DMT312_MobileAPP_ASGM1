# 健身助手 (Fitness Assistant) - Flutter 应用

## 1. 项目概述

一款**离线优先 (offline-first)** 的 Android (及潜在多平台) 健身助手应用，使用 Flutter 构建。它聚焦于三大核心场景：**“体重体测”、“训练打卡”和“饮食记录”**。该应用专为已具备基础健身知识的用户设计，为他们提供**快速录入和趋势可视化**功能。

其核心特性是强大的**本地数据持久化**能力，确保用户数据在不同应用会话间得以保存，并且应用能够完全离线运行。此外，它还具备数据**导入/导出功能**。

## 2. 目标用户与价值主张

| 维度         | 内容                                                                 |
| ---------------- | ----------------------------------------------------------------------- |
| **目标用户** | 已具备基础训练与饮食知识，需要一款一体化记录工具的用户。 |
| **核心痛点** | 1. 手动记录效率低下。<br/>2. 数据分散在多个应用中。<br/>3. 难以直观地查看趋势。 |
| **价值主张** | 1. 基于模板的点击 + 自动计算，实现 < 5 秒的快速录入。<br/>2. 完全离线存储，无广告，无隐私泄露风险。<br/>3. 体重与热量趋势图表单屏展示。 |

## 3. 核心功能

* **Dashboard (首页)**: 今日体重、训练完成度及热量平衡概览。
* **身体与体重测量 (体测 & 个人资料)**: 追踪姓名、身高、最新体重。查看体重趋势（7/30 天图表）并自动计算 BMI/FFMI 指数。
* **训练打卡 (训练打卡)**: 从动作模板（俯卧撑、深蹲、跑步等）中选择。计时/计次功能，带震动提醒。将训练标记为完成或逾期。
* **饮食记录 (饮食记录)**: 快速录入热量（+100/+250 kcal 按钮）。通过离线食物数据库搜索食物，列表项支持滑动删除或编辑。
* **学习资源库 (学习资源库)**: 浏览离线 Markdown 文章和内置视频教程，支持收藏与本地缓存。
* **用户注册与登录**: 内置认证系统，可创建账号、登录并管理个人资料。
* **离线数据存储**: 现统一使用本地 **SQLite** 数据库保存体重、训练、营养等所有数据，完全离线可用。
* **数据备份与恢复**: 仍支持导入/导出 JSON 备份文件。

## 4. 技术架构

该应用采用 Flutter 构建，并运用了面向服务的架构来管理数据。

* **UI 层 (`lib/screens/`, `lib/widgets/`)**:
    * 由构成用户界面的 Flutter 小部件组成。
    * 与 `DataManager` 交互以显示和更新数据。
    * 通过 `ChangeNotifier` 监听 `DataManager` 的变化，实现响应式 UI 更新。
    * 详细的 UI/UX 设计在 `DesignDoc/by_Manus/` 目录中指定。

* **数据模型 (`lib/models/`)**:
    * 表示应用的数据结构（例如 `WeightEntry`, `WorkoutEntry`, `NutritionEntry`, `Article`）。
    * 利用 `json_serializable` 方便地与 JSON 格式相互转换以进行存储。

* **服务层 (`lib/services/`)**:
    * **`DataManager`**: 单例 `ChangeNotifier`，负责在内存中缓存数据并调用数据库服务读写。
    * **`StorageService` (接口)**: 定义存储操作契约，可按需扩展实现。
    * **`DatabaseService` (实现)**: 基于 `sqflite` 的 SQLite 封装，管理用户、体重、训练、营养等表的 CRUD 操作。
    * **`LocalStorageService`**: 旧版 JSON 存储实现，保留用于导入历史数据。
    * **`ExportService`**: 管理导入/导出 JSON 备份文件，使用 `permission_handler` 处理文件权限。

* **数据持久化流程**:
    1.  应用启动时初始化 `DataManager` 并连接 `DatabaseService`。
    2.  `DataManager` 从 SQLite 数据库加载用户及其记录。
    3.  UI 通过 `DataManager` 获取和修改数据。
    4.  `DataManager` 更新内存缓存，并同步更改到数据库。

* **导航**:
    * 一个顶部 Dashboard 卡片，在切换页面时会收缩为全局固定头部。
    * 底部导航栏包含“体测”、“训练”、“饮食”、“资源”四个一级页面。
    * 操作（新增/编辑）主要使用弹框或底部抽屉，以尽量避免二级页面跳转。

## 5. 项目结构重点

```
flutter_asgm1/
├── DesignDoc/                  # UI/UX 设计文档
│   ├── by_Manus/               # 详细界面设计
│   └── data_persistence_architecture.md # 数据持久化方案
├── android/                    # Android 特定文件
├── ios/                        # iOS 特定文件
├── lib/
│   ├── main.dart               # 应用入口点，初始化 DataManager
│   ├── mock_data.dart          # (旧版) 内存数据，已被 DataManager 取代
│   ├── models/                 # 数据模型类 (Article, WeightEntry 等)
│   │   └── *.g.dart            # 自动生成的序列化代码
│   ├── screens/                # UI 屏幕 (Login、Registration、Dashboard 等)
│   ├── services/               # 业务逻辑和数据服务
│   │   ├── data_manager.dart   # 中央数据管理
│   │   ├── storage_service.dart       # 存储接口
│   │   ├── database_service.dart      # SQLite 数据库实现
│   │   ├── local_storage_service.dart # 旧版 JSON 存储实现
│   │   └── export_service.dart        # 数据导入/导出逻辑
│   ├── theme.dart              # 应用主题配置
│   └── widgets/                # 可复用 UI 组件 (GlassCard, 图表等)
├── pubspec.yaml                # 项目依赖和元数据
└── README.md                   # 本文件
```

## 6. 主要依赖项

* `flutter`
* `fl_chart`: 用于图表和可视化。
* `sqflite` / `sqflite_common_ffi`: 跨平台 SQLite 数据库。
* `path_provider` / `path`: 获取应用文档路径。
* `shared_preferences`: 简单键值存储（兼容旧版）。
* `video_player` + `chewie`: 视频播放组件。
* `permission_handler`: 请求文件读写权限。
* `json_annotation` 与 `json_serializable`: 数据模型序列化。
* `build_runner`: 运行代码生成器。
* `flutter_lints`: Lint 规则。

## 7. 设置与运行

1.  **克隆代码仓库。**
2.  **确保已安装 Flutter SDK。**
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

## 9. 开发进度与后续计划
根据 `DesignDoc/Temp/` 中的文档，ASGM2 阶段已完成数据库集成、用户认证和视频库等主要功能，整体完成度约 **90%**。
后续工作侧重于：
* 完善体脂率和热量计算逻辑；
* 优化数据分析与图表展示；
* 持续改进代码风格与性能。
