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
* **饮食记录 (饮食记录)**: 快速录入热量（+100/+250 kcal 按钮）。通过离线 JSON 数据库（超过50项）搜索食物。每日摄入列表，支持滑动删除/编辑。
* **学习资源库 (学习资源库)**: 访问5-8篇离线 Markdown 文章（训练技巧/营养科普）。支持收藏/取消收藏文章，收藏列表本地保存。
* **离线数据存储**: 所有用户数据（体重、训练、营养、文章、用户配置）均通过 JSON 文件本地持久化，确保应用在没有网络连接的情况下也能完全正常工作。
* **数据备份与恢复**: 用户可以将其数据导出为 JSON 文件进行备份，并能从备份文件中将数据导入回应用。

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
│   ├── screens/                # UI 屏幕 (Dashboard, Body, Workout 等)
│   ├── services/               # 业务逻辑和数据服务
│   │   ├── data_manager.dart   # 中央数据管理
│   │   ├── storage_service.dart # 存储接口
│   │   ├── local_storage_service.dart # 文件/SharedPreferences 存储实现
│   │   └── export_service.dart # 数据导入/导出逻辑
│   ├── theme.dart              # 应用主题配置
│   └── widgets/                # 可复用 UI 组件 (GlassCard, 图表等)
├── pubspec.yaml                # 项目依赖和元数据
└── README.md                   # 本文件
```

## 6. 主要依赖项

* `flutter`
* `fl_chart`: 用于图表和可视化。
* `shared_preferences`: 用于简单的键值存储。
* `path_provider`: 用于访问文件系统路径。
* `permission_handler`: 用于请求运行时权限（例如存储权限）。
* `json_annotation`: 用于 JSON 序列化的注解。
* `json_serializable` (开发依赖): JSON 序列化的代码生成器。
* `build_runner` (开发依赖): 运行代码生成器的工具。
* `flutter_lints`: Linting 规则。

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

## 9. 待办事项 / 未来增强 (来自 `DesignDoc/by_Manus/todo.md`)
* 最终交付：向用户汇报并发送设计方案文档。

(`todo.md` 表明大部分与界面和基础逻辑相关的设计和实现任务在数据持久化重构之前已经完成。)