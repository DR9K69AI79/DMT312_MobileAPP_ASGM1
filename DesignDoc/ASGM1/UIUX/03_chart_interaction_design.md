# 图表展示与交互设计

## 图表设计通用原则

### 视觉风格
- **配色方案**：
  - 主数据线/柱：主色调（#1E88E5）
  - 次要数据线/柱：辅助色（#43A047、#FFC107等）
  - 背景：白色（#FFFFFF）
  - 网格线：极浅灰色（#F5F5F5）
  - 轴线：浅灰色（#E0E0E0）
  - 标签文字：深灰色（#616161）
  
- **字体设置**：
  - 轴标签：12sp，Roboto Regular
  - 数值标签：10sp，Roboto Regular
  - 图表标题：16sp，Roboto Medium
  - 图例文字：12sp，Roboto Regular
  
- **线条样式**：
  - 数据线：2dp宽度，圆角连接
  - 网格线：虚线，1dp宽度
  - 轴线：实线，1dp宽度
  
- **数据点样式**：
  - 直径：6dp（默认）
  - 选中状态：8dp，带白色边框
  - 悬停状态：轻微放大动画

### 交互设计
- **触摸反馈**：
  - 点击数据点：显示详细数值气泡
  - 长按图表区域：显示十字准线和详细信息
  - 左右滑动：平移查看更多数据
  - 双指缩放：调整数据范围（时间/数值）
  
- **动画效果**：
  - 初始加载：数据线从左到右/从下到上的绘制动画
  - 数据更新：平滑过渡到新值（300ms动画）
  - 视图切换：数据重组的平滑过渡（500ms动画）
  - 缩放动画：跟随手势的实时响应
  
- **信息展示**：
  - 悬浮提示框（Tooltip）：
    - 背景：深色半透明（#212121，80%不透明度）
    - 文字：白色（#FFFFFF）
    - 内边距：8dp
    - 圆角：4dp
    - 箭头指向当前数据点
  
- **空数据处理**：
  - 显示友好的空状态提示
  - 提供添加数据的快捷入口
  - 可选显示示例数据（虚线表示）

## 具体图表类型设计

### 1. 体重趋势折线图

#### 视觉设计
- **尺寸**：高度180dp，宽度为卡片宽度减去内边距
- **X轴**：日期（最近7天/30天）
  - 标签：简化日期格式（如"周一"或"5/20"）
  - 间隔：均匀分布，根据数据范围自动调整
- **Y轴**：体重数值
  - 范围：根据数据自动调整，但最小跨度为5kg
  - 标签：整数值，带单位（kg）
- **数据线**：
  - 颜色：主色调（#1E88E5）
  - 样式：平滑曲线（非直线连接）
  - 数据点：小圆点，点击时高亮显示
- **填充区域**：
  - 数据线下方轻微渐变填充
  - 从主色调到透明
  - 透明度：20%到0%

#### 交互功能
- **时间范围切换**：
  - 顶部标签切换：7天/30天
  - 切换时的平滑过渡动画
- **数据点交互**：
  - 点击：显示详细信息（具体日期、精确体重值、与前一天对比）
  - 长按：锁定显示，不会自动消失
- **趋势分析**：
  - 显示趋势线（可选功能）
  - 上升/下降趋势用不同颜色标识
- **历史查看**：
  - 左右滑动查看更早/更晚数据
  - 边缘滑动时有轻微阻尼效果
  - 释放时自动对齐到日期点

### 2. 训练完成度环形图

#### 视觉设计
- **尺寸**：直径120dp（大型）或40dp（小型，用于Dashboard收起状态）
- **环形宽度**：12dp（大型）或4dp（小型）
- **颜色**：
  - 已完成部分：主色调（#1E88E5）
  - 未完成部分：浅灰色（#E0E0E0）
  - 超额完成部分：强调色（#FF5722）
- **中心文字**：
  - 完成百分比：48sp（大型）或18sp（小型），主色调，Roboto Bold
  - 百分号：20sp（大型）或10sp（小型），主色调，Roboto Regular
- **起始位置**：顶部中央（12点位置）
- **进度方向**：顺时针

#### 交互功能
- **动画效果**：
  - 初始加载：从0%平滑增加到当前完成度
  - 完成新训练项目时：环形进度平滑增加
  - 动画持续时间：600ms，带轻微弹性效果
- **点击交互**：
  - 点击环形图：显示训练项目完成详情
  - 长按：显示历史完成率对比
- **状态变化**：
  - 达到100%：显示完成动画（环形波纹扩散）
  - 接近截止时间未完成：环形颜色变为警告色（#FFC107）

### 3. 热量摄入/消耗条形图

#### 视觉设计
- **尺寸**：高度60dp，宽度为卡片宽度减去内边距
- **布局**：
  - 上部：数值显示区域
  - 中部：水平条形图
  - 下部：标签区域
- **条形图**：
  - 摄入量条：蓝色（#1E88E5）
  - 消耗量条：绿色（#43A047）
  - 目标线：垂直虚线，黑色（#212121，50%透明度）
  - 条形高度：16dp
  - 条形圆角：8dp
- **标签**：
  - 左侧："摄入"文字
  - 右侧："消耗"文字
  - 中间：目标值

#### 交互功能
- **动画效果**：
  - 初始加载：条形从左侧/右侧延伸至当前值
  - 数据更新：条形长度平滑调整
- **点击交互**：
  - 点击摄入条：显示今日摄入详情
  - 点击消耗条：显示今日消耗详情
  - 点击目标线：调整目标值
- **状态显示**：
  - 摄入>消耗：盈余值显示为红色
  - 摄入<消耗：赤字值显示为绿色
  - 接近平衡（±50kcal）：显示"平衡"标识

### 4. BMI/FFMI指数条形图

#### 视觉设计
- **尺寸**：高度40dp，宽度为卡片宽度减去内边距
- **布局**：水平条形进度条，分区显示
- **分区颜色**：
  - 过低区：黄色（#FFC107）
  - 正常区：绿色（#43A047）
  - 过高区：橙色（#FF9800）
  - 极高区：红色（#E53935）
- **指示器**：
  - 样式：小三角形，指向当前值位置
  - 颜色：深灰色（#424242）
- **标签**：
  - 区间范围值显示在条形图下方
  - 当前值显示在指示器上方

#### 交互功能
- **动画效果**：
  - 初始加载：指示器从左侧滑动到当前位置
  - 数值变化：指示器平滑移动到新位置
- **点击交互**：
  - 点击不同区域：显示该区间的健康建议
  - 点击当前值：显示详细计算方法
- **信息展示**：
  - 悬停在区间上：显示该区间的详细说明
  - 长按指示器：显示历史变化趋势

### 5. 训练历史日历热图

#### 视觉设计
- **尺寸**：高度自适应（根据显示月数），宽度为卡片宽度减去内边距
- **布局**：月历格式，每个日期单元格为正方形
- **颜色编码**：
  - 无训练：浅灰色（#F5F5F5）
  - 部分完成：浅蓝色（#BBDEFB）
  - 完全完成：中蓝色（#64B5F6）
  - 超额完成：深蓝色（#1E88E5）
- **单元格**：
  - 尺寸：36dp x 36dp
  - 日期文字：12sp，黑色，Roboto Regular
  - 完成度指示：底部小圆点或填充背景

#### 交互功能
- **导航**：
  - 左右滑动：切换月份
  - 上下滑动：查看更多月份
- **点击交互**：
  - 点击日期单元格：显示该日训练详情
  - 长按：比较与当前训练计划的差异
- **视图切换**：
  - 支持月视图/周视图切换
  - 切换时的平滑过渡动画
- **数据筛选**：
  - 可按训练类型筛选显示
  - 筛选时热图颜色动态更新

### 6. 饮食营养素分布饼图

#### 视觉设计
- **尺寸**：直径140dp
- **布局**：
  - 中心：总热量数值
  - 扇区：不同营养素占比
- **颜色**：
  - 蛋白质：紫色（#7B1FA2）
  - 脂肪：橙色（#FF9800）
  - 碳水：蓝色（#1E88E5）
- **标签**：
  - 内部：百分比值
  - 外部：营养素名称和具体克数
- **图例**：饼图下方，水平排列

#### 交互功能
- **动画效果**：
  - 初始加载：扇区从中心向外扩展
  - 数据更新：扇区大小平滑调整
- **点击交互**：
  - 点击扇区：该营养素轻微分离并高亮
  - 双击：显示该营养素的食物来源明细
- **旋转交互**：
  - 支持手指旋转饼图
  - 旋转时标签保持可读方向
- **对比功能**：
  - 可叠加显示目标营养素比例（半透明外环）
  - 点击切换显示/隐藏目标比例

## 图表交互通用模式

### 数据探索交互
- **缩放操作**：
  - 双指捏合/张开：放大/缩小数据范围
  - 双击：自动缩放至适合视图
  - 缩放限制：设置最大/最小缩放级别
  
- **平移操作**：
  - 单指拖动：在已缩放的视图中平移
  - 快速滑动：带惯性的平移效果
  - 边界限制：防止平移超出数据范围
  
- **数据选择**：
  - 单击数据点：选中并显示详情
  - 框选（长按后拖动）：选择多个数据点
  - 多选模式：显示选中数据的汇总信息

### 图表切换动画
- **数据范围切换**：
  - 7天/30天切换：数据点平滑重新分布
  - 动画持续时间：500ms
  - 缓动函数：先加速后减速
  
- **图表类型切换**：
  - 折线图/柱状图切换：形状变形动画
  - 动画持续时间：800ms
  - 过渡效果：数据点位置保持，仅改变表现形式
  
- **数据更新**：
  - 新数据添加：从右侧滑入
  - 数据删除：平滑收缩并重新分布
  - 数据修改：旧值到新值的平滑过渡

### 图表交互反馈
- **触摸反馈**：
  - 触摸数据点：轻微放大效果
  - 选中状态：高亮显示（颜色加深+轮廓）
  - 拖动操作：跟随手指的实时更新
  
- **信息提示**：
  - 悬浮提示框跟随触摸位置
  - 多指触摸时提示框智能定位（避免遮挡）
  - 提示框显示/隐藏的淡入/淡出动画
  
- **操作引导**：
  - 首次使用时显示简短操作提示
  - 新功能引导覆盖层
  - 复杂操作的手势提示动画

### 图表辅助功能
- **数据标注**：
  - 支持在图表上添加文字标注
  - 标注可拖动定位
  - 标注样式：半透明背景，文字简洁
  
- **趋势线**：
  - 可选显示趋势线（线性/曲线拟合）
  - 趋势线样式：虚线，与数据线区分
  - 趋势预测：可延伸显示预测趋势
  
- **对比功能**：
  - 支持历史数据对比（如上周/上月）
  - 对比数据使用半透明或虚线表示
  - 差异突出显示（填充区域或标记）

## 响应式调整
- **小屏幕设备**（<5英寸）：
  - 减小图表高度约10%
  - 简化标签，减少显示的刻度数量
  - 增大触摸目标区域
  
- **大屏幕设备**（>6英寸）：
  - 增加图表细节和数据密度
  - 显示更多辅助信息和标签
  - 支持更复杂的多指交互

## 性能优化
- **渲染优化**：
  - 使用硬件加速
  - 大数据集采用抽样显示
  - 视图外数据延迟加载
  
- **交互优化**：
  - 触摸事件节流处理
  - 复杂动画仅在高性能设备启用
  - 平滑降级策略

## 无障碍支持
- **色盲友好**：
  - 不仅依靠颜色区分数据
  - 提供高对比度模式
  - 支持自定义配色方案
  
- **屏幕阅读**：
  - 图表提供结构化的数据描述
  - 关键数据点和趋势有语音描述
  - 支持键盘导航和探索
