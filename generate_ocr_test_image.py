#!/usr/bin/env python3
"""
生成OCR测试面单图片
用于测试菜鸟驿站包裹管理系统的OCR识别功能
"""

from PIL import Image, ImageDraw, ImageFont
import os

def create_parcel_label():
    """创建快递面单图片"""
    
    # 图片尺寸
    width, height = 800, 600
    
    # 创建白色背景图片
    image = Image.new('RGB', (width, height), 'white')
    draw = ImageDraw.Draw(image)
    
    # 尝试加载字体（如果系统有中文字体）
    try:
        # 尝试使用系统字体
        font_large = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 24)
        font_medium = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", 18)
        font_small = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", 14)
    except:
        # 使用默认字体
        font_large = ImageFont.load_default()
        font_medium = ImageFont.load_default()
        font_small = ImageFont.load_default()
    
    # 快递面单内容
    parcel_info = {
        "快递公司": "顺丰速运",
        "运单号": "SF1234567890",
        "寄件人": "张三 13800138000",
        "寄件地址": "北京市朝阳区建国路88号",
        "收件人": "李四 13900139000",
        "收件地址": "上海市浦东新区陆家嘴金融中心A座1001室",
        "包裹类型": "文件",
        "重量": "0.5kg",
        "备注": "易碎物品，请轻拿轻放"
    }
    
    # 绘制快递面单边框
    draw.rectangle([20, 20, width-20, height-20], outline='black', width=2)
    
    # 绘制标题栏
    draw.rectangle([20, 20, width-20, 60], fill='#1E90FF', outline='black', width=1)
    draw.text((width//2, 40), "快递面单", fill='white', font=font_large, anchor='mm')
    
    # 绘制内容区域
    y_position = 80
    line_height = 35
    
    # 快递公司信息
    draw.text((40, y_position), f"快递公司: {parcel_info['快递公司']}", fill='black', font=font_medium)
    y_position += line_height
    
    # 运单号（突出显示）
    draw.rectangle([40, y_position, 400, y_position+30], fill='#FFE4B5', outline='#FFA500', width=1)
    draw.text((50, y_position+15), f"运单号: {parcel_info['运单号']}", fill='#FF4500', font=font_large)
    y_position += line_height + 10
    
    # 寄件人信息
    draw.text((40, y_position), f"寄件人: {parcel_info['寄件人']}", fill='black', font=font_medium)
    y_position += line_height
    
    draw.text((40, y_position), f"寄件地址: {parcel_info['寄件地址']}", fill='black', font=font_medium)
    y_position += line_height
    
    # 分隔线
    draw.line([40, y_position, width-40, y_position], fill='gray', width=1)
    y_position += 20
    
    # 收件人信息
    draw.text((40, y_position), f"收件人: {parcel_info['收件人']}", fill='black', font=font_medium)
    y_position += line_height
    
    draw.text((40, y_position), f"收件地址: {parcel_info['收件地址']}", fill='black', font=font_medium)
    y_position += line_height
    
    # 包裹信息
    draw.text((40, y_position), f"包裹类型: {parcel_info['包裹类型']}", fill='black', font=font_medium)
    y_position += line_height
    
    draw.text((40, y_position), f"重量: {parcel_info['重量']}", fill='black', font=font_medium)
    y_position += line_height
    
    # 备注信息
    draw.text((40, y_position), f"备注: {parcel_info['备注']}", fill='red', font=font_medium)
    y_position += line_height
    
    # 条形码区域（模拟）
    draw.rectangle([40, y_position, width-40, y_position+80], fill='#F5F5F5', outline='gray', width=1)
    draw.text((width//2, y_position+40), "[条形码区域]", fill='gray', font=font_medium, anchor='mm')
    
    # 二维码区域（模拟）
    qr_size = 80
    qr_x = width - 120
    qr_y = y_position
    draw.rectangle([qr_x, qr_y, qr_x+qr_size, qr_y+qr_size], fill='white', outline='black', width=1)
    draw.text((qr_x+qr_size//2, qr_y+qr_size//2), "QR", fill='black', font=font_medium, anchor='mm')
    
    return image

def create_multiple_test_images():
    """创建多个测试面单图片"""
    
    # 不同快递公司的测试数据
    test_cases = [
        {
            "filename": "顺丰面单.jpg",
            "快递公司": "顺丰速运",
            "运单号": "SF1234567890",
            "收件人": "王五 13800138001",
            "收件地址": "广州市天河区珠江新城华夏路10号",
            "包裹类型": "文件",
            "重量": "0.3kg"
        },
        {
            "filename": "圆通面单.jpg", 
            "快递公司": "圆通速递",
            "运单号": "YT9876543210",
            "收件人": "赵六 13900139002",
            "收件地址": "深圳市南山区科技园南区8栋",
            "包裹类型": "电子产品",
            "重量": "2.5kg"
        },
        {
            "filename": "中通面单.jpg",
            "快递公司": "中通快递", 
            "运单号": "ZTO5556667778",
            "收件人": "钱七 13700137003",
            "收件地址": "杭州市西湖区文三路199号",
            "包裹类型": "服装",
            "重量": "1.2kg"
        },
        {
            "filename": "韵达面单.jpg",
            "快递公司": "韵达快递",
            "运单号": "YD3334445556", 
            "收件人": "孙八 13600136004",
            "收件地址": "成都市武侯区天府软件园B区",
            "包裹类型": "书籍",
            "重量": "3.0kg"
        }
    ]
    
    # 创建测试目录
    test_dir = "/tmp/ocr_test_images"
    os.makedirs(test_dir, exist_ok=True)
    
    print("正在生成OCR测试面单图片...")
    
    for i, test_case in enumerate(test_cases):
        # 创建基础面单
        image = create_parcel_label()
        draw = ImageDraw.Draw(image)
        
        # 使用默认字体
        font_medium = ImageFont.load_default()
        
        # 图片尺寸
        width, height = 800, 600
        
        # 更新特定信息
        y_position = 80
        line_height = 35
        
        # 清除原有内容并重新绘制
        draw.rectangle([40, 80, width-40, 400], fill='white')
        
        # 快递公司信息
        draw.text((40, y_position), f"快递公司: {test_case['快递公司']}", fill='black', font=font_medium)
        y_position += line_height
        
        # 运单号
        draw.rectangle([40, y_position, 400, y_position+30], fill='#FFE4B5', outline='#FFA500', width=1)
        draw.text((50, y_position+15), f"运单号: {test_case['运单号']}", fill='#FF4500', font=font_medium)
        y_position += line_height + 10
        
        # 寄件人信息（固定）
        draw.text((40, y_position), "寄件人: 张三 13800138000", fill='black', font=font_medium)
        y_position += line_height
        draw.text((40, y_position), "寄件地址: 北京市朝阳区建国路88号", fill='black', font=font_medium)
        y_position += line_height
        
        # 分隔线
        draw.line([40, y_position, width-40, y_position], fill='gray', width=1)
        y_position += 20
        
        # 收件人信息
        draw.text((40, y_position), f"收件人: {test_case['收件人']}", fill='black', font=font_medium)
        y_position += line_height
        draw.text((40, y_position), f"收件地址: {test_case['收件地址']}", fill='black', font=font_medium)
        y_position += line_height
        
        # 包裹信息
        draw.text((40, y_position), f"包裹类型: {test_case['包裹类型']}", fill='black', font=font_medium)
        y_position += line_height
        draw.text((40, y_position), f"重量: {test_case['重量']}", fill='black', font=font_medium)
        
        # 保存图片
        filepath = os.path.join(test_dir, test_case['filename'])
        image.save(filepath, 'JPEG', quality=95)
        print(f"✓ 已生成: {test_case['filename']}")
    
    # 生成简单的文本测试图片
    create_simple_test_image(test_dir)
    
    print(f"\n🎉 测试图片生成完成！")
    print(f"📁 保存位置: {test_dir}")
    print(f"📸 生成文件:")
    for test_case in test_cases:
        print(f"   - {test_case['filename']}")
    print(f"   - 简单测试面单.jpg")
    
    return test_dir

def create_simple_test_image(test_dir):
    """创建简单的文本测试图片"""
    
    # 创建更简单的测试图片（适合OCR识别）
    width, height = 600, 400
    image = Image.new('RGB', (width, height), 'white')
    draw = ImageDraw.Draw(image)
    
    # 使用默认字体
    font = ImageFont.load_default()
    
    # 添加清晰的文本内容
    texts = [
        "顺丰快递 SF1234567890",
        "收件人: 张三",
        "手机: 13800138000", 
        "地址: 北京市朝阳区建国门外大街1号",
        "包裹类型: 文件",
        "重量: 0.5kg",
        "备注: 请妥善保管"
    ]
    
    y_position = 50
    for text in texts:
        draw.text((50, y_position), text, fill='black', font=font)
        y_position += 40
    
    # 保存图片
    filepath = os.path.join(test_dir, "简单测试面单.jpg")
    image.save(filepath, 'JPEG', quality=95)
    print(f"✓ 已生成: 简单测试面单.jpg")

if __name__ == "__main__":
    # 生成测试图片
    test_dir = create_multiple_test_images()
    
    print(f"\n🚀 使用说明:")
    print(f"1. 访问系统: http://localhost:3000/pc/packages")
    print(f"2. 点击'新增包裹'按钮")
    print(f"3. 使用'OCR识别面单'功能上传测试图片")
    print(f"4. 验证自动填充效果")
    print(f"\n📋 测试要点:")
    print(f"• 运单号识别准确性")
    print(f"• 手机号格式标准化")
    print(f"• 地址信息提取")
    print(f"• 包裹类型智能识别")
    print(f"• 重量自动估算")