#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
检查Swift语法错误
"""
import re
import sys

def check_swift_file(filepath):
    """检查Swift文件的常见语法问题"""
    print(f"检查文件: {filepath}")

    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
        lines = content.split('\n')

    errors = []
    warnings = []

    # 检查大括号匹配
    stack = []
    for i, line in enumerate(lines, 1):
        for j, char in enumerate(line):
            if char == '{':
                stack.append((i, j + 1))
            elif char == '}':
                if not stack:
                    errors.append(f"第{i}行第{j+1}列: 不匹配的 '}}'")
                else:
                    stack.pop()

    if stack:
        for i, j in stack:
            errors.append(f"第{i}行第{j+1}列: 未闭合的 '{{'")

    # 检查常见问题
    for i, line in enumerate(lines, 1):
        # 检查let id = UUID()在Codable结构体中
        if 'Codable' in line and i < len(lines):
            next_line = lines[i]
            if 'let id = UUID()' in next_line:
                warnings.append(f"第{i+1}行: Codable结构体中使用 'let id = UUID()' 可能导致解码失败")

        # 检查enum的case是否都包含
        if 'if selectedMode == .' in line and 'else if selectedMode == .' not in line:
            # 检查是否遗漏了新增的conversations case
            if i > 100 and i < 1000:  # 只检查主要部分
                context = '\n'.join(lines[max(0,i-5):min(len(lines),i+5)])
                if 'conversations' not in context:
                    warnings.append(f"第{i}行: 可能遗漏了 .conversations case")

    # 输出结果
    if errors:
        print(f"\n❌ 发现 {len(errors)} 个错误:")
        for error in errors[:10]:
            print(f"  {error}")
        if len(errors) > 10:
            print(f"  ... 还有 {len(errors) - 10} 个错误")
    else:
        print("\n✓ 没有发现语法错误")

    if warnings:
        print(f"\n⚠️  发现 {len(warnings)} 个警告:")
        for warning in warnings[:10]:
            print(f"  {warning}")
        if len(warnings) > 10:
            print(f"  ... 还有 {len(warnings) - 10} 个警告")
    else:
        print("✓ 没有发现警告")

    return len(errors) == 0

if __name__ == "__main__":
    filepath = "/Users/fushuai/Documents/1test/app/travel/travel/ContentView.swift"
    success = check_swift_file(filepath)
    sys.exit(0 if success else 1)
