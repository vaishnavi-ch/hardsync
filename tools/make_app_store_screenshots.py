import os
from PIL import Image, ImageDraw, ImageFont, ImageFilter

os.makedirs('app_store_screenshots/showcase', exist_ok=True)

W, H = 1290, 2796
font_title = ImageFont.truetype('C:/Windows/Fonts/segoeuib.ttf', 72)
font_sub = ImageFont.truetype('C:/Windows/Fonts/segoeui.ttf', 44)

cards = [
    {
        'title': 'Practice Tough Conversations',
        'sub': 'Executive AI Rehearsal Flight Simulator',
        'src': 'home_screen.png',
        'out': 'app_store_screenshots/showcase/1_dashboard.png',
        'crop_top': 75,
        'crop_bot': 50
    },
    {
        'title': 'Realistic AI Sparring Partners',
        'sub': '50+ High-Stakes Workplace Scenarios',
        'src': 'practice_all.png',
        'out': 'app_store_screenshots/showcase/2_scenarios.png',
        'crop_top': 75,
        'crop_bot': 50
    },
    {
        'title': 'Real-Time Speech Telemetry',
        'sub': 'Track Vocal Cadence, WPM & Filler Words',
        'src': 'performance1.png',
        'out': 'app_store_screenshots/showcase/3_telemetry.png',
        'crop_top': 75,
        'crop_bot': 50
    },
    {
        'title': 'Forensic Coaching Debrief',
        'sub': 'Actionable Analysis Grounded in C.A.R.E.',
        'src': 'history_detail.png',
        'out': 'app_store_screenshots/showcase/4_debrief.png',
        'crop_top': 75,
        'crop_bot': 50
    }
]

for card in cards:
    # 1. Background (Executive Dark Slate with Violet glow)
    canvas = Image.new('RGB', (W, H), (13, 16, 24))
    draw = ImageDraw.Draw(canvas)
    
    # Header area subtle lighting
    for r in range(400, 0, -20):
        alpha = int((1 - r / 400) * 40)
        draw.ellipse([W//2 - r, 200 - r//3, W//2 + r, 200 + r//3], fill=(30 + alpha, 20 + alpha, 60 + alpha))
    
    # 2. Text layout
    title = card['title']
    sub = card['sub']
    
    # Draw title
    bbox_t = draw.textbbox((0, 0), title, font=font_title)
    w_t = bbox_t[2] - bbox_t[0]
    draw.text(((W - w_t) // 2, 140), title, fill=(255, 255, 255), font=font_title)
    
    # Draw subtitle
    bbox_s = draw.textbbox((0, 0), sub, font=font_sub)
    w_s = bbox_s[2] - bbox_s[0]
    draw.text(((W - w_s) // 2, 235), sub, fill=(160, 168, 190), font=font_sub)
    
    # 3. Process App Screenshot
    raw = Image.open(card['src']).convert('RGB')
    rw, rh = raw.size
    # Crop status bar and bottom nav
    cropped = raw.crop((0, card['crop_top'], rw, rh - card['crop_bot']))
    
    # Scale to fit device mockup width
    target_w = 1040
    target_h = int(cropped.height * (target_w / cropped.width))
    scaled = cropped.resize((target_w, target_h), Image.Resampling.LANCZOS)
    
    # Add rounded corners mask
    radius = 50
    mask = Image.new('L', (target_w, target_h), 0)
    draw_mask = ImageDraw.Draw(mask)
    draw_mask.rounded_rectangle([0, 0, target_w, target_h], radius=radius, fill=255)
    
    # Device frame container (with dark bezel & glowing border)
    bezel_pad = 12
    fw = target_w + bezel_pad * 2
    fh = target_h + bezel_pad * 2
    frame = Image.new('RGBA', (fw, fh), (0, 0, 0, 0))
    draw_frame = ImageDraw.Draw(frame)
    draw_frame.rounded_rectangle([0, 0, fw, fh], radius=radius + bezel_pad, fill=(24, 28, 42, 255), outline=(65, 75, 105, 255), width=3)
    
    # Drop Shadow
    shadow = Image.new('RGBA', (fw + 60, fh + 60), (0, 0, 0, 0))
    draw_shadow = ImageDraw.Draw(shadow)
    draw_shadow.rounded_rectangle([30, 30, fw + 30, fh + 30], radius=radius + bezel_pad, fill=(0, 0, 0, 160))
    shadow = shadow.filter(ImageFilter.GaussianBlur(24))
    
    # Composite
    pos_x = (W - fw) // 2
    pos_y = 350
    canvas.paste(shadow, (pos_x - 30, pos_y - 20), shadow)
    canvas.paste(frame.convert('RGB'), (pos_x, pos_y), frame)
    canvas.paste(scaled, (pos_x + bezel_pad, pos_y + bezel_pad), mask)
    
    # Final Crop/Check to exact 1290 x 2796
    final = canvas.crop((0, 0, W, H))
    final.save(card['out'], 'PNG', optimize=True)
    print(f"Generated: {card['out']} ({final.size})")

print("All App Store showcase screenshots completed successfully!")
