import 'package:flutter/material.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('帮助与支持'),
        centerTitle: true,
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 应用介绍
          _buildSectionHeader(context, '关于 FitLog'),
          _buildInfoCard(
            icon: Icons.fitness_center,
            title: 'FitLog 健身助手',
            content: 'FitLog 是一款专业的健身记录应用，帮助您追踪体重、记录训练计划、管理饮食，并提供丰富的健身知识内容。',
          ),
          
          const SizedBox(height: 24),
          
          // 功能介绍
          _buildSectionHeader(context, '主要功能'),
          _buildFeatureList(context),
          
          const SizedBox(height: 24),
          
          // 常见问题
          _buildSectionHeader(context, '常见问题'),
          _buildFAQSection(),
          
          const SizedBox(height: 24),
          
          // 使用技巧
          _buildSectionHeader(context, '使用技巧'),
          _buildTipsSection(),
          
          const SizedBox(height: 24),
          
          // 联系方式
          _buildSectionHeader(context, '联系我们'),
          _buildContactCard(),
          
          const SizedBox(height: 24),
          
          // 版本信息
          _buildSectionHeader(context, '版本信息'),
          _buildVersionCard(),
          
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 32, color: Colors.blue),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    content,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureList(BuildContext context) {
    final features = [
      {'icon': Icons.monitor_weight, 'title': '体重追踪', 'desc': '记录和查看体重变化趋势'},
      {'icon': Icons.fitness_center, 'title': '训练计划', 'desc': '创建和管理个人训练计划'},
      {'icon': Icons.restaurant, 'title': '饮食记录', 'desc': '记录每日饮食和卡路里摄入'},
      {'icon': Icons.library_books, 'title': '知识库', 'desc': '丰富的健身知识和指导文章'},
      {'icon': Icons.analytics, 'title': '数据分析', 'desc': '可视化图表展示健身进度'},
      {'icon': Icons.cloud_upload, 'title': '数据导出', 'desc': '支持导出数据进行备份'},
    ];

    return Card(
      child: Column(
        children: features.map((feature) => ListTile(
          leading: Icon(
            feature['icon'] as IconData,
            color: Theme.of(context).primaryColor,
          ),
          title: Text(
            feature['title'] as String,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(feature['desc'] as String),
        )).toList(),
      ),
    );
  }

  Widget _buildFAQSection() {
    return Column(
      children: [
        _buildFAQItem(
          '如何开始使用 FitLog？',
          '首先注册一个账户，然后可以开始记录您的体重、创建训练计划和记录饮食。建议先设置您的个人信息，如身高等，以获得更准确的 BMI 计算。',
        ),
        _buildFAQItem(
          '如何记录体重数据？',
          '在主页面点击"添加体重"按钮，输入当前体重即可。应用会自动记录日期并生成趋势图表。',
        ),
        _buildFAQItem(
          '能否修改或删除已记录的数据？',
          '是的，您可以在相应的数据列表中长按或点击编辑按钮来修改或删除数据。',
        ),
        _buildFAQItem(
          '数据会同步到云端吗？',
          '目前数据存储在本地设备上。我们建议定期使用导出功能备份您的数据。',
        ),
        _buildFAQItem(
          '忘记密码怎么办？',
          '在登录页面点击"忘记密码"链接，按照提示操作即可重置密码。如遇问题请联系客服。',
        ),
      ],
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        title: Text(
          question,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              answer,
              style: TextStyle(
                color: Colors.grey[700],
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipsSection() {
    final tips = [
      {'icon': Icons.schedule, 'text': '建议每天同一时间测量体重，获得更准确的数据'},
      {'icon': Icons.trending_up, 'text': '查看趋势图表比单日数据更有意义'},
      {'icon': Icons.note_add, 'text': '及时记录训练完成情况，养成良好习惯'},
      {'icon': Icons.backup, 'text': '定期导出数据，避免数据丢失'},
      {'icon': Icons.flag, 'text': '设定合理的目标，循序渐进地进行健身'},
    ];

    return Card(
      child: Column(
        children: tips.map((tip) => ListTile(
          leading: Icon(
            tip['icon'] as IconData,
            color: Colors.orange,
            size: 20,
          ),
          title: Text(
            tip['text'] as String,
            style: const TextStyle(fontSize: 14),
          ),
          dense: true,
        )).toList(),
      ),
    );
  }

  Widget _buildContactCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.support_agent, color: Colors.green),
                SizedBox(width: 8),
                Text(
                  '联系客服',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildContactItem(Icons.email, '邮箱', 'support@fitlog.com'),
            _buildContactItem(Icons.phone, '电话', '+86 400-123-4567'),
            _buildContactItem(Icons.access_time, '服务时间', '周一至周五 9:00-18:00'),
            const SizedBox(height: 12),
            Text(
              '如果您在使用过程中遇到任何问题或有改进建议，欢迎随时联系我们。我们致力于为您提供最好的健身记录体验。',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Text(value),
        ],
      ),
    );
  }

  Widget _buildVersionCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'FitLog',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('版本: 2.0.0', style: TextStyle(color: Colors.grey[600])),
            Text('构建: 2025.06.30', style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 8),
            Text(
              '© 2025 FitLog Team. All rights reserved.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
