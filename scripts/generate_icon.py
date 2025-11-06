#!/usr/bin/env python3
from PIL import Image, ImageDraw
import os

# 创建一个 1024x1024 的图标（基础尺寸）
size = 1024
icon = Image.new('RGBA', (size, size), (0, 0, 0, 0))  # 透明背景
draw = ImageDraw.Draw(icon)

# GitHub 风格的图标 - 使用圆角矩形
# 主色调：深色系
bg_color = (36, 41, 46, 255)

# 创建圆角矩形（GitHub 风格）
margin = 80  # 留出边距
radius = 200  # 圆角半径

# 绘制圆角矩形
draw.rounded_rectangle(
    [margin, margin, size - margin, size - margin],
    radius=radius,
    fill=bg_color
)

# 在中间添加一个 Git 图标（简化的叉子图标）
# 使用白色
icon_color = (255, 255, 255, 255)

# 绘制中心圆
center = size // 2
circle_radius = 80
draw.ellipse(
    [center - circle_radius, center - circle_radius,
     center + circle_radius, center + circle_radius],
    fill=icon_color
)

# 绘制三个分支
branch_length = 180
branch_width = 40

# 上分支
draw.rectangle(
    [center - branch_width//2, center - circle_radius - branch_length,
     center + branch_width//2, center - circle_radius],
    fill=icon_color
)
# 上分支圆
draw.ellipse(
    [center - circle_radius//2, center - circle_radius - branch_length - circle_radius//2,
     center + circle_radius//2, center - circle_radius - branch_length + circle_radius//2],
    fill=icon_color
)

# 左下分支
import math
angle = -120 * math.pi / 180
x_offset = branch_length * math.cos(angle)
y_offset = branch_length * math.sin(angle)
# 简化：绘制矩形分支
draw.rectangle(
    [center - circle_radius - branch_length, center + circle_radius,
     center - circle_radius, center + circle_radius + branch_width],
    fill=icon_color
)
draw.ellipse(
    [center - circle_radius - branch_length - circle_radius//2, center + circle_radius - circle_radius//2,
     center - circle_radius - branch_length + circle_radius//2, center + circle_radius + circle_radius//2],
    fill=icon_color
)

# 右下分支
draw.rectangle(
    [center + circle_radius, center + circle_radius,
     center + circle_radius + branch_length, center + circle_radius + branch_width],
    fill=icon_color
)
draw.ellipse(
    [center + circle_radius + branch_length - circle_radius//2, center + circle_radius - circle_radius//2,
     center + circle_radius + branch_length + circle_radius//2, center + circle_radius + circle_radius//2],
    fill=icon_color
)

# 保存不同尺寸的图标
icon_dir = 'CommitPop/Assets.xcassets/AppIcon.appiconset'
sizes = [
    ('icon_16x16.png', 16),
    ('icon_16x16@2x.png', 32),
    ('icon_32x32.png', 32),
    ('icon_32x32@2x.png', 64),
    ('icon_128x128.png', 128),
    ('icon_128x128@2x.png', 256),
    ('icon_256x256.png', 256),
    ('icon_256x256@2x.png', 512),
    ('icon_512x512.png', 512),
    ('icon_512x512@2x.png', 1024),
]

for filename, pixel_size in sizes:
    resized = icon.resize((pixel_size, pixel_size), Image.Resampling.LANCZOS)
    resized.save(os.path.join(icon_dir, filename), 'PNG')
    print(f'✅ 生成: {filename} ({pixel_size}x{pixel_size})')

print('\n🎉 所有图标已生成！')
print('请重新编译应用以查看新图标。')
