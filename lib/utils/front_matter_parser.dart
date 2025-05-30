import 'package:yaml/yaml.dart';

/// Front Matter 解析器，用于解析 Markdown 文件中的 YAML 前置元数据
class FrontMatterParser {
  /// 解析包含 Front Matter 的 Markdown 内容
  /// 
  /// 输入格式示例:
  /// ```
  /// ---
  /// title: "文章标题"
  /// category: "分类"
  /// tags: ["tag1", "tag2"]
  /// ---
  /// 
  /// # 文章内容
  /// 这里是正文内容...
  /// ```
  static ParsedMarkdown parse(String content) {
    // 检查是否包含 Front Matter
    if (!content.trim().startsWith('---')) {
      return ParsedMarkdown(
        frontMatter: {},
        content: content,
      );
    }

    // 查找第二个 ---
    final lines = content.split('\n');
    int endIndex = -1;
    
    for (int i = 1; i < lines.length; i++) {
      if (lines[i].trim() == '---') {
        endIndex = i;
        break;
      }
    }

    if (endIndex == -1) {
      // 没有找到结束标记，返回原内容
      return ParsedMarkdown(
        frontMatter: {},
        content: content,
      );
    }

    // 提取 YAML 内容
    final yamlLines = lines.sublist(1, endIndex);
    final yamlContent = yamlLines.join('\n');
    
    // 提取 Markdown 内容
    final markdownLines = lines.sublist(endIndex + 1);
    final markdownContent = markdownLines.join('\n').trim();    // 解析 YAML
    Map<String, dynamic> frontMatter = {};
    try {
      final yamlMap = loadYaml(yamlContent);
      if (yamlMap is YamlMap) {
        frontMatter = _convertYamlMap(yamlMap);
      } else if (yamlMap is Map) {
        frontMatter = Map<String, dynamic>.from(yamlMap);
      }
    } catch (e) {
      print('Error parsing YAML front matter: $e');
      // 如果 YAML 解析失败，尝试简单解析
      frontMatter = _parseSimpleYaml(yamlContent);
    }

    return ParsedMarkdown(
      frontMatter: frontMatter,
      content: markdownContent,
    );
  }

  /// 将 YAML Map 转换为 Dart Map
  static Map<String, dynamic> _convertYamlMap(YamlMap yamlMap) {
    final Map<String, dynamic> result = {};
    
    for (final entry in yamlMap.entries) {
      final key = entry.key.toString();
      final value = entry.value;
      
      if (value is YamlList) {
        result[key] = value.map((item) => item.toString()).toList();
      } else if (value is YamlMap) {
        result[key] = _convertYamlMap(value);
      } else {
        result[key] = value;
      }
    }
    
    return result;
  }

  /// 简单的 YAML 解析器（作为后备方案）
  static Map<String, dynamic> _parseSimpleYaml(String yamlContent) {
    final Map<String, dynamic> result = {};
    final lines = yamlContent.split('\n');
    
    for (final line in lines) {
      final trimmedLine = line.trim();
      if (trimmedLine.isEmpty || trimmedLine.startsWith('#')) {
        continue;
      }
      
      final colonIndex = trimmedLine.indexOf(':');
      if (colonIndex == -1) continue;
      
      final key = trimmedLine.substring(0, colonIndex).trim();
      final valueStr = trimmedLine.substring(colonIndex + 1).trim();
      
      result[key] = _parseValue(valueStr);
    }
    
    return result;
  }

  /// 解析值
  static dynamic _parseValue(String value) {
    if (value.isEmpty) return '';
    
    // 移除引号
    if ((value.startsWith('"') && value.endsWith('"')) ||
        (value.startsWith("'") && value.endsWith("'"))) {
      value = value.substring(1, value.length - 1);
    }
    
    // 处理列表
    if (value.startsWith('[') && value.endsWith(']')) {
      final listContent = value.substring(1, value.length - 1);
      return listContent
          .split(',')
          .map((item) => item.trim())
          .map((item) {
            // 移除每个项目的引号
            if ((item.startsWith('"') && item.endsWith('"')) ||
                (item.startsWith("'") && item.endsWith("'"))) {
              return item.substring(1, item.length - 1);
            }
            return item;
          })
          .where((item) => item.isNotEmpty)
          .toList();
    }
    
    // 处理布尔值
    if (value.toLowerCase() == 'true') return true;
    if (value.toLowerCase() == 'false') return false;
    
    // 处理数字
    if (RegExp(r'^\d+$').hasMatch(value)) {
      return int.tryParse(value) ?? value;
    }
    if (RegExp(r'^\d+\.\d+$').hasMatch(value)) {
      return double.tryParse(value) ?? value;
    }
    
    // 默认返回字符串
    return value;
  }
}

/// 解析结果类
class ParsedMarkdown {
  final Map<String, dynamic> frontMatter;
  final String content;
  
  const ParsedMarkdown({
    required this.frontMatter,
    required this.content,
  });
}
