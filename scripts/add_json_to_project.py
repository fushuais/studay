#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
将 minna_conversation_lessons.json 添加到 Xcode 项目
"""
import subprocess
import os

# Xcode项目路径
project_file = "/Users/fushuai/Documents/1test/app/travel/travel.xcodeproj/project.pbxproj"

# 检查文件是否已经添加
def is_file_in_project(filename):
    try:
        with open(project_file, 'r', encoding='utf-8') as f:
            content = f.read()
            return filename in content
    except Exception as e:
        print(f"Error reading project file: {e}")
        return False

if __name__ == "__main__":
    json_file = "minna_conversation_lessons.json"
    
    if is_file_in_project(json_file):
        print(f"✓ {json_file} 已在项目中")
    else:
        print(f"⚠️  {json_file} 未在项目中，请手动添加")
        print(f"\n手动添加步骤:")
        print(f"1. 打开 Xcode 项目")
        print(f"2. 在 Project Navigator 中找到 'travel' 文件夹")
        print(f"3. 右键点击 'travel' 文件夹，选择 'Add Files to travel...'")
        print(f"4. 选择 {json_file}")
        print(f"5. 确保 'Copy items if needed' 未勾选（文件已在正确位置）")
        print(f"6. 确保 'Add to targets' 勾选了 'travel'")
