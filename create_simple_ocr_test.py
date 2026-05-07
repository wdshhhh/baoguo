#!/usr/bin/env python3
"""
创建简单的OCR测试面单图片
使用ASCII字符避免编码问题
"""

from PIL import Image, ImageDraw, ImageFont
import os

def create_simple_parcel_label():
    """创建简单的快递面单图片"""
    
    # 图片尺寸
    width, height = 800, 600
    
    # 创建白色背景图片
    image = Image.new('RGB', (width, height), 'white')
    draw = ImageDraw.Draw(image)
    
    # 使用默认字体
    try:
        # 尝试加载系统字体
        font_large = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 24)
        font_medium = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", 18)
        font_small = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", 14)
    except:
        # 使用默认字体
        font_large = ImageFont.load_default()
        font_medium = ImageFont.load_default()
        font_small = ImageFont.load_default()
    
    # 快递面单内容（使用ASCII字符）
    parcel_info = {
        "courier": "SF Express",
        "tracking_number": "SF1234567890",
        "sender": "Zhang San 13800138000",
        "sender_address": "Beijing Chaoyang District",
        "recipient": "Li Si 13900139000", 
        "recipient_address": "Shanghai Pudong District",
        "package_type": "Document",
        "weight": "0.5kg",
        "note": "Fragile, handle with care"
    }
    
    # 绘制快递面单边框
    draw.rectangle([20, 20, width-20, height-20], outline='black', width=2)
    
    # 绘制标题栏
    draw.rectangle([20, 20, width-20, 60], fill='#1E90FF', outline='black', width=1)
    draw.text((width//2, 40), "PARCEL LABEL", fill='white', font=font_large, anchor='mm')
    
    # 绘制内容区域
    y_position = 80
    line_height = 35
    
    # 快递公司信息
    draw.text((40, y_position), f"Courier: {parcel_info['courier']}", fill='black', font=font_medium)
    y_position += line_height
    
    # 运单号（突出显示）
    draw.rectangle([40, y_position, 400, y_position+30], fill='#FFE4B5', outline='#FFA500', width=1)
    draw.text((50, y_position+15), f"Tracking: {parcel_info['tracking_number']}", fill='#FF4500', font=font_large)
    y_position += line_height + 10
    
    # 寄件人信息
    draw.text((40, y_position), f"Sender: {parcel_info['sender']}", fill='black', font=font_medium)
    y_position += line_height
    
    draw.text((40, y_position), f"From: {parcel_info['sender_address']}", fill='black', font=font_medium)
    y_position += line_height
    
    # 分隔线
    draw.line([40, y_position, width-40, y_position], fill='gray', width=1)
    y_position += 20
    
    # 收件人信息
    draw.text((40, y_position), f"Recipient: {parcel_info['recipient']}", fill='black', font=font_medium)
    y_position += line_height
    
    draw.text((40, y_position), f"To: {parcel_info['recipient_address']}", fill='black', font=font_medium)
    y_position += line_height
    
    # 包裹信息
    draw.text((40, y_position), f"Type: {parcel_info['package_type']}", fill='black', font=font_medium)
    y_position += line_height
    
    draw.text((40, y_position), f"Weight: {parcel_info['weight']}", fill='black', font=font_medium)
    y_position += line_height
    
    # 备注信息
    draw.text((40, y_position), f"Note: {parcel_info['note']}", fill='red', font=font_medium)
    
    return image

def create_chinese_test_image():
    """创建中文测试图片（使用系统命令）"""
    
    # 使用ImageMagick创建中文测试图片
    test_dir = "/tmp/ocr_test_images"
    os.makedirs(test_dir, exist_ok=True)
    
    # 创建中文测试图片
    chinese_text = [
        "顺丰快递 SF1234567890",
        "收件人: 张三",
        "手机: 13800138000",
        "地址: 北京市朝阳区",
        "包裹类型: 文件",
        "重量: 0.5kg"
    ]
    
    # 使用convert命令创建图片
    for i, text in enumerate(chinese_text):
        cmd = f"convert -size 600x400 xc:white -pointsize 24 -fill black -gravity northwest -annotate +20+{20+i*40} '{text}' {test_dir}/chinese_test_{i+1}.jpg"
        os.system(cmd)
    
    print("✓ 已生成中文测试图片")
    return test_dir

def create_test_images():
    """创建测试图片"""
    
    test_dir = "/tmp/ocr_test_images"
    os.makedirs(test_dir, exist_ok=True)
    
    print("正在生成OCR测试面单图片...")
    
    # 创建简单的英文面单
    image = create_simple_parcel_label()
    image.save(f"{test_dir}/simple_parcel.jpg", 'JPEG', quality=95)
    print("✓ 已生成: simple_parcel.jpg")
    
    # 创建不同快递公司的测试图片
    test_cases = [
        ("顺丰快递 SF1234567890 张三 13800138000", "sf_parcel.jpg"),
        ("圆通快递 YT9876543210 李四 13900139000", "yt_parcel.jpg"),
        ("中通快递 ZTO555666777 王五 13700137000", "zto_parcel.jpg"),
        ("韵达快递 YD333444555 赵六 13600136000", "yd_parcel.jpg")
    ]
    
    for text, filename in test_cases:
        # 使用convert命令创建图片
        cmd = f"convert -size 600x300 xc:white -pointsize 20 -fill black -gravity center -annotate +0+0 '{text}' {test_dir}/{filename}"
        os.system(cmd)
        print(f"✓ 已生成: {filename}")
    
    # 创建中文测试图片
    create_chinese_test_image()
    
    print(f"\n🎉 测试图片生成完成！")
    print(f"📁 保存位置: {test_dir}")
    print(f"📸 生成文件列表:")
    
    for file in os.listdir(test_dir):
        if file.endswith(('.jpg', '.jpeg', '.png')):
            print(f"   - {file}")
    
    return test_dir

if __name__ == "__main__":
    # 检查ImageMagick是否安装
    if os.system("which convert > /dev/null 2>&1") != 0:
        print("⚠ 警告: ImageMagick未安装，将使用PIL创建简单图片")
        print("   建议安装: sudo apt install imagemagick")
    
    # 生成测试图片
    test_dir = create_test_images()
    
    print(f"\n🚀 使用说明:")
    print(f"1. 访问系统: http://localhost:3000/pc/packages")
    print(f"2. 点击'新增包裹'按钮")
    print(f"3. 使用'OCR识别面单'功能上传测试图片")
    print(f"4. 验证自动填充效果")
    
    print(f"\n📋 测试要点:")
    print(f"• 运单号识别准确性 (SF1234567890, YT9876543210等)")
    print(f"• 手机号格式标准化 (13800138000等)")
    print(f"• 收件人姓名识别")
    print(f"• 快递公司自动识别")
    
    print(f"\n💡 提示:")
    print(f"• 测试图片保存在: {test_dir}")
    print(f"• 可以复制图片到桌面方便上传")
    print(f"• 系统支持拖拽上传功能")