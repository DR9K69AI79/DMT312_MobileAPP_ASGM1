# 健身助手 Flutter 应用

## 概述

本项目是一个 Flutter 的健身助手应用。该应用设计为一个离线优先的健身追踪工具，允许用户监控他们的身体指标、计划锻炼、记录营养，并访问健身文章库。它利用集中的模拟数据管理系统进行状态处理，并具有一系列自定义 UI 组件。

## 项目结构

Flutter 应用的主要代码库组织如下（不包括原生或构建目录，如 `android`、`ios`、`.dart_tool`）：

```
lib/
├── main.dart           # 应用程序入口和主要导航
├── mock_data.dart      # 模拟数据管理和全局状态
├── theme.dart          # 应用程序主题配置
│
├── models/             # 数据模型类
│   ├── article.dart
│   ├── weight_entry.dart
│   └── workout_entry.dart
│
├── screens/            # 主要应用程序功能/页面的 UI
│   ├── dashboard_screen.dart
│   ├── body_screen.dart
│   ├── workout_screen.dart
│   ├── nutrition_screen.dart
│   └── library_screen.dart
│
└── widgets/            # 可重用的 UI 组件
    ├── glass_card.dart
    ├── weight_line_chart.dart
    ├── ring_progress.dart
    └── primary_button.dart

assets/
└── articles/           # 资源库的 Markdown 文件
    ├── muscle_gain.md
    ├── fat_burn.md
    ├── diet.md
    └── recovery.md
```

## 主要文件和目录功能

### `lib/main.dart`

  * **应用程序入口点**：初始化 `FitnessMiniApp` 根部件 [cite: 1]。
  * **MaterialApp 设置**：配置应用程序标题、主题，并将 `MainScreen`（带有底部导航栏的主界面）定义为主页 [cite: 1]。
  * **命名路由**：定义命名路由（例如 `/body/workout`, `/nutrition`, `/Library`）用于导航到对应的页面部件 [cite: 1]。
  * **MainScreen**：一个 `StatefulWidget`，包含一个 `BottomNavigationBar` 用于在五个主页面（首页、体测、训练、饮食、资源）之间切换 [cite: 1]。它维护一个 `_selectedIndex` 状态，当点击导航项时通过 `setState` 更新该状态，从而使主内容区域显示选定的页面部件 [cite: 1, 3]。五个主页面部件是作为 `const` 创建并保存在一个列表中的，这意味着它们会一直保留在内存中，切换时无需重新初始化 [cite: 8]。

### `lib/theme.dart`

  * **主题配置**：提供 `buildAppTheme()` 函数，该函数返回一个全局 `ThemeData` 对象 [cite: 2]。
  * **Material 3 颜色**：使用预设的种子颜色创建 Material 3 颜色方案（主色调为蓝色系，辅助色为绿色系） [cite: 2, 4]。
  * **组件定制**：
      * `CardTheme`：统一圆角和阴影，提升视觉一致性 [cite: 2, 5]。
      * `ElevatedButton`：统一圆角半径 [cite: 2, 6]。
      * `AppBar`：背景色使用主色并去除阴影 [cite: 2, 7]。
      * `BottomNavigationBar`：配置选中项的颜色等 [cite: 2, 3, 8]。

### `lib/mock_data.dart`

  * **模拟数据管理**：定义 `MockData` 类，该类继承自 `ChangeNotifier` 并实现单例模式（使用工厂构造函数返回一个 `_instance` 实例），以确保全局只有一个数据源 [cite: 9]。
  * **数据类别**：
      * **体重数据**：
          * `weights7d`：一个 `WeightEntry` 对象列表，存储最近7天的体重记录 [cite: 9, 10]。
          * `currentWeight`：当前体重 [cite: 9, 10]。
          * 初始化时会生成模拟的近7天体重数据 [cite: 9, 11]。
          * `addWeight(double)`：添加新的体重记录（保持列表长度不超过7，并更新当前体重），然后调用 `notifyListeners()` [cite: 9, 12]。
      * **热量数据**：
          * `calorieIntake`：当日摄入卡路里 [cite: 9, 13]。
          * `caloriesBurned`：当日消耗卡路里 [cite: 9, 13]。
          * `calorieGoal`：目标卡路里 [cite: 9]。
          * `updateCalorieIntake(int)` 和 `updateCaloriesBurned(int)`：更新摄入/消耗值的方法，并调用 `notifyListeners()` [cite: 9, 13]。
          * `calorieBalance`：一个 getter，用于计算当前摄入与消耗的差值 [cite: 9]。
      * **训练计划数据**：
          * `workoutToday`：一个 `WorkoutEntry` 对象列表，保存当天的训练项目（包括名称、组数、是否完成等） [cite: 9]。
          * 初始化时模拟添加了几项训练 [cite: 9]。
          * `addWorkout(String, int)`：增加新训练项 [cite: 9]。
          * `toggleWorkoutCompleted(int)`：切换某项训练的完成状态（修改对应项的 `isCompleted` 并通知刷新） [cite: 9]。
          * `workoutCompletionPercent`：一个 getter，计算当天训练完成百分比 [cite: 9]。
      * **文章资源数据**：
          * `articles`：一个 `Article` 对象列表，保存若干文章信息（包括标题、封面图片URL、Markdown文件路径、分类等） [cite: 9]。
          * 初始化时添加了模拟的训练、饮食、康复类别的文章各若干篇 [cite: 9]。
  * **状态通知**：`MockData` 中所有修改数据的方法最后都会调用 `notifyListeners()`，这使得已注册监听该数据的界面能够自动收到通知并刷新UI [cite: 9]。

### `lib/models/`

该目录包含数据模型类的定义：

  * **`article.dart`**：定义 `Article` 类，包含 `title`（标题）、`coverUrl`（封面图片链接）、`mdPath`（Markdown文件路径）、`category`（分类）等属性 [cite: 12]。主要供资源库页面使用 [cite: 12]。
  * **`weight_entry.dart`**：定义 `WeightEntry` 类，表示一条体重记录，包含日期 `date` 和体重值 `value`。提供 `copyWith()` 方法创建修改了某些字段的新实例。
  * **`workout_entry.dart`**：定义 `WorkoutEntry` 类，表示一次训练记录，包含日期 `date`、动作名称 `name`、组数 `sets`、是否已完成 `isCompleted` 等属性。同样提供 `copyWith()` 方法方便状态切换。

### `lib/screens/`

该目录存放应用主要功能界面（页面）的文件，每个 Dart 文件通常定义一个与页面对应的 `StatefulWidget`：

  * **`dashboard_screen.dart` (首页)**：

      * 展示汇总的今日健身概览数据，包括今日体重、训练完成度（使用 `RingProgress`）、热量盈亏，通常展示在 `GlassCard` 容器中 [cite: 4]。
      * 使用 `WeightLineChart` 绘制最近7天体重折线图。
      * AppBar 标题为“健身助手”，并有一个设置按钮（目前未实现功能）。
      * 包含一个“+”号浮动操作按钮菜单（FAB menu）：点击主按钮展开3个子按钮，用于快速导航/录入：跳转到训练页面、跳转到饮食页面，以及添加今日体重记录。
      * 通过 FAB 添加体重会弹出一个对话框让用户输入新体重，并调用 `_mockData.addWeight()` 更新数据。
      * 在 `initState` 中对 `MockData` 添加监听器以实现数据刷新，在 `dispose` 中移除监听器 [cite: 5]。

  * **`body_screen.dart` (体测页面)**：

      * 用于展示和编辑用户的基本身体指标。
      * 包括：
          * 个人资料卡片（显示身高和当前体重，可点击编辑并通过对话框修改）。保存时更新 `_mockData.height` 和调用 `_mockData.addWeight()`。
          * BMI指数卡片（显示根据身高体重计算的BMI值，并用颜色区分范围）。
          * 体重趋势卡片（折线图显示7日体重变化及统计）。
          * 历史体重记录列表。
      * 一个浮动按钮用于通过对话框添加新的体重记录。
      * 通过监听全局 `MockData` 数据变化来实时更新UI。

  * **`workout_screen.dart` (训练计划页面)**：

      * 用于展示当天的训练任务清单，并提供管理功能。
      * “今日训练状态”卡片：显示当天训练完成百分比的环形图和完成/总次数。
      * “训练计划”卡片：使用 `ListView.builder` 动态生成列表项，每项显示训练名称和组数，右侧有完成勾选按钮，可切换完成状态，底层通过调用 `_mockData.toggleWorkoutCompleted(index)` 更新数据。列表项支持向左滑动删除功能（使用 `Dismissible`）。该卡片右上有一个“编辑”按钮，但目前仅作为占位，`onPressed` 尚未实现任何逻辑。
      * “快速添加训练”卡片：提供几个常见训练的快捷按钮，横向滚动列表显示预设的动作（俯卧撑、深蹲等），点击某个图标立即将一项默认3组的新训练添加到计划中。
      * 一个浮动添加按钮“+”，点按弹出底部抽屉对话框让用户自定义添加训练项目（输入名称和组数后保存）。
      * 在 `initState` 添加对 `MockData` 的监听，当训练列表或完成情况变化时刷新UI。

  * **`nutrition_screen.dart` (饮食记录页面)**：

      * 用于记录当天饮食摄入并追踪卡路里。
      * “今日热量摘要”卡片：显示摄入、消耗和剩余热量三项数据，并用不同颜色标识。卡片下方有一个进度条表示摄入量相对于每日目标的进度。
      * “快速录入”卡片：包括三个快捷按钮（例如+100 kcal, +500 kcal）用于快速增加摄入热量；下方列出若干常见食物（鸡蛋、香蕉等）的按钮列表，横向滚动显示，每个食物按钮点击时会直接把对应热量加入总摄入。
      * “食物搜索”卡片：里面是一个带搜索和扫码图标的输入框；目前这只是界面元素，没有实现实际搜索或扫码功能。
      * 按照早餐、午餐、晚餐分段的饮食记录列表：通过 `_buildMealSections()` 动态生成三个餐次卡片。每个餐次卡片列出所属的食物条目（名称、分量、热量），底部有“添加到X餐”按钮，点击可弹出底部对话框，在相应餐次下新增一条记录。对话框允许填写食物名称、分量和热量，并选择所属餐次。列表中的食物项也支持滑动删除。
      * 同样在初始化时监听 `MockData`，主要是为了当消耗量（`caloriesBurned`）等数据更新时可以刷新剩余热量等显示。此外初始时调用 `_updateCaloriesFromMeals()` 根据当前餐食列表计算总摄入热量并同步到 `MockData`。
      * 浮动按钮“+”用于快速添加食物（默认选择早餐，可在对话框中切换餐次）。

  * **`library_screen.dart` (学习资源库页面)**：

      * 用于浏览健身相关文章的离线资源。
      * 界面顶部有两部分筛选控件：一个横向滚动的分类筛选栏（“全部/训练/饮食/康复”），使用 `ChoiceChip` 列出类别标签，支持点击选择某分类来过滤文章列表 [cite: 6]；其下是一个搜索框，用户在此输入关键字可以实时过滤文章标题（通过 `onChanged` 动态更新 `_searchQuery` 状态并触发界面刷新） [cite: 6]。
      * 主内容分为两块：当未输入搜索词且选择分类为“全部”时，会显示一个“推荐文章”板块，横向滚动列出所有文章的精选卡片 [cite: 6]；每个卡片包括文章封面图和标题、分类标签，点击卡片将打开文章详情对话框 [cite: 6]。
      * 推荐区下方（或在有搜索条件/筛选时直接）显示文章列表：使用网格布局（`GridView`）两列排列文章卡片 [cite: 6]。普通文章卡片较简洁，包含封面缩略图和标题、分类等简要信息 [cite: 6]。点击也会打开详情对话框 [cite: 6]。
      * 详情对话框（`_showArticleDialog`）中，显示文章的标题、封面大图和正文内容 [cite: 6]。目前正文内容使用的是示例文本占位，实际并未从Markdown 文件加载 [cite: 6]。对话框底部提供“收藏”和“分享”两个按钮，但目前 `onPressed` 无具体实现 [cite: 6]。
      * 没有使用全局监听器；筛选和搜索通过本地状态 `_selectedCategory` 和 `_searchQuery` 即可完成，对 `_mockData.articles` 列表使用 `where` 方法过滤出 `filteredArticles` 后渲染 [cite: 7]。如果过滤结果为空则显示提示文本 [cite: 7]。

### `lib/widgets/`

该目录存放可以重复使用的UI组件，提升代码复用性：

  * **`glass_card.dart`**：自定义卡片组件 `GlassCard`。其实质是对 `Card` 小部件的封装，统一应用了内容内边距（16像素）。
  * **`weight_line_chart.dart`**：体重折线图组件 `WeightLineChart`，继承自 `StatelessWidget`，使用第三方库 `fl_chart` 绘制折线图。
      * 构造需要传入最近若干天的体重数据列表 `data` (List\<WeightEntry\>)。
      * 组件在 `build` 中先判断数据是否为空，如为空则显示简短提示文字。
      * 如果有数据，则计算y轴最小/最大值范围用于图表刻度，并将体重数据转换为 `FlSpot` 点序列。随后构造 `LineChart` 组件：配置曲线平滑、线条颜色为主题色、节点圆点显示，以及在折线下方填充淡色区域。
      * 图表坐标轴定制为：下方x轴不显示具体值而显示对应日期（仅在整数索引处标注月/日）；左侧y轴显示数值刻度（保留一位小数）；隐藏顶部和右侧的刻度标题。
  * **`ring_progress.dart`**：环形进度组件 `RingProgress`，用于显示完成率等百分比数据的圆环图。同样使用 `fl_chart` 库的 `PieChart` 实现。
      * 传入参数 `percent` (0\~1的完成率)和 `label` (中心文字标签)。
      * `build` 方法返回一个固定150x150大小的堆叠组件，底层是 `PieChart` 绘制两个扇形（已完成部分使用主题主色，未完成部分灰色），通过调整 `sections` 数据使其形成环形。
      * 上层居中叠放一个列组件，显示白色居中的百分比数值和标签文字。
  * **`primary_button.dart`**：主要按钮组件 `PrimaryButton`。对 `ElevatedButton` 的简单封装，统一应用了主题主色背景、白色文字、圆角矩形边框（24dp圆角）等样式。
      * 接受一个子组件 `child` 作为按钮内容（通常是文字），以及 `onPressed` 回调。
      * 用于替代常规的 `ElevatedButton` 以提供一致的主按钮样式，比如在各个对话框的“保存/添加”按钮中都使用了 `PrimaryButton`。

### `assets/articles/`

包含用于健身文章库的 Markdown 文件。例如 `muscle_gain.md`、`fat_burn.md` 等。

## 页面导航逻辑

  * **主导航**：本应用采用了主页 + 底部导航栏的框架，将主要功能划分为五个 Screen 页面，并通过一个底部导航栏（`BottomNavigationBar`）切换显示 [cite: 3]。这五个页面（首页、体测、训练、饮食、资源）在应用启动时由 `MainScreen` 创建一个列表保存，通过索引控制展示 [cite: 3]。用户点击底部导航的不同标签，会调用 `onTap` 回调将 `_selectedIndex` 更新为对应索引，从而触发界面刷新显示新的子页面 [cite: 3]。
  * **命名路由**：在 `MaterialApp.routes` 中定义了一些命名路由（例如 `/workout`, `/nutrition`） [cite: 1]。这些路由主要用于从首页（Dashboard）的浮动按钮菜单进行页面跳转。例如，Dashboard 页展开的 FAB 子菜单中，“记录训练”按钮的点击事件通过 `Navigator.pushNamed(context, '/workout')` 打开训练页面。这种方式可能导致页面堆栈中出现重复的页面实例 [cite: 4]。
  * **页内交互**：所有新增/编辑操作都没有通过 Navigator 跳转到新页面，而是使用了对话框（`showDialog`）或底部抽屉（`showModalBottomSheet`）在当前页面弹出表单 [cite: 9]。这符合项目的“所有新增/编辑均使用弹框或底部抽屉，尽可能避免二级页面跳转”的设计目标 [cite: 9]。

## 状态管理与数据通信

  * **集中式状态管理**：本项目采用了集中式的简单状态管理模式：即由 `MockData` 单例类充当全局的数据仓库，所有页面共享这一个数据源 [cite: 5]。
  * **ChangeNotifier**：`MockData` 通过继承 `ChangeNotifier` 提供通知机制 [cite: 5, 9]。各界面在初始化时通过 `MockData()` 获取同一实例，并调用 `addListener()` 订阅数据变化 [cite: 5]。
  * **数据流**：
    1.  用户在某个页面执行操作导致数据修改时（例如添加体重、完成训练、删除食物等），对应的 `MockData` 方法会更新数据并调用 `notifyListeners()` [cite: 5]。
    2.  所有监听了该 `MockData` 实例的页面都会收到通知，触发各自定义的监听回调。在本项目中，各页面的监听回调通常很简单，即调用 `setState()` 重建UI [cite: 5]，从而使界面上的数据和全局状态保持同步。
  * **示例**：用户在体测页修改了当前体重并点击保存，`BodyScreen` 会调用 `_mockData.addWeight()` 更新体重。`addWeight` 内部修改了数据并通知监听者 [cite: 9, 12]。`DashboardScreen` 和 `BodyScreen` 本身都监听了 `MockData`，因此它们的 UI 会自动刷新 [cite: 5]。
  * **数据持久化**：目前 `MockData` 数据仅存在于内存，应用关闭后不会持久保存 [cite: 5]。

## 组件之间的协作

  * **父子级数据流**：UI组件之间主要通过父子关系和回调进行协作。各页面（Screen）主要承担将全局数据按需传递给子组件和处理用户交互的职责。比如 `DashboardScreen` 在构建时，将 `_mockData.weights7d` 列表传给 `WeightLineChart` 来绘制折线图，将 `_mockData.workoutCompletionPercent` 传给 `RingProgress` 绘制完成环。子组件本身不维护状态，只根据父组件给的数据渲染。
  * **事件处理**：
      * 用户与界面交互时，通常由页面部件的回调来更新全局数据，再依靠监听机制分发更新。例如：用户点击 `WorkoutScreen` 页某项训练的复选图标，触发 `onPressed` 回调调用 `_mockData.toggleWorkoutCompleted(index)` 切换完成状态。
      * 自定义组件（如 `PrimaryButton`）执行保存操作时，通常在其 `onPressed` 中由页面逻辑去调用相应的 `_mockData` 方法更新数据，然后关闭对话框。
      * 页面内的组件通信通过闭包或参数完成。例如 `LibraryScreen` 页的搜索框，在 `onChanged` 中调用 `setState` 修改了父组件的 `_searchQuery` 状态 [cite: 6]。`LibraryScreen` 页的文章卡片通过 `GestureDetector` 包裹，点击时调用父状态的 `_showArticleDialog(article)` 方法 [cite: 10]。

## 界面中仅供展示的模块和功能

最后，需要指出本项目中哪些界面元素目前仅作为静态演示，未连接实际逻辑或数据：

  * **首页 (Dashboard)**：顶部 AppBar 的“设置”按钮（齿轮图标）目前没有实现点击功能。
  * **训练计划页 (Workout)**：在“训练计划”卡片右上角，有一个“编辑”按钮（带铅笔图标）。当前此按钮的 `onPressed` 回调为空。
  * **饮食记录页 (Nutrition)**：其中“食物搜索”卡片内的搜索输入框和旁边的二维码扫描图标目前只是界面展示，没有实现实际搜索或扫码功能。
  * **资源库页 (Library)**：
      * **文章正文**：文章详情对话框中的正文目前使用写死的示例文本显示，并没有真正根据所点文章去加载其 Markdown 文件内容 [cite: 6]。
      * **操作按钮**：对话框底部的“收藏”和“分享”按钮当前没有任何逻辑，`onPressed` 方法为空实现 [cite: 7]。

以上模块的存在说明该应用有些功能还处于原型阶段。