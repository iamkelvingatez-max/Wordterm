#!/usr/bin/env python3
from PIL import Image, ImageDraw, ImageFont
import os
import shutil

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
ICON_DIR = os.path.join(ROOT, 'assets', 'icons')
os.makedirs(ICON_DIR, exist_ok=True)

# Create multiple icon sizes
sizes = [512, 256, 128, 64, 48, 32, 16]

for size in sizes:
    # Create a new image with transparency
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.ImageDraw(img)

    # Calculate dimensions
    margin = size // 8
    doc_width = size - 2 * margin
    doc_height = int(size * 0.85)
    doc_x = margin
    doc_y = (size - doc_height) // 2
    corner_radius = max(4, size // 64)

    # Draw document background (blue)
    draw.rounded_rectangle(
        [(doc_x, doc_y), (doc_x + doc_width, doc_y + doc_height)],
        radius=corner_radius,
        fill=(43, 87, 154, 255)  # Word blue color
    )

    # Draw document fold (top right corner)
    fold_size = size // 8
    fold_points = [
        (doc_x + doc_width - fold_size, doc_y),
        (doc_x + doc_width, doc_y),
        (doc_x + doc_width, doc_y + fold_size),
    ]
    draw.polygon(fold_points, fill=(30, 63, 111, 255))  # Darker blue

    # Draw "W" letter
    try:
        # Try to load a font
        font_size = int(size * 0.55)
        try:
            font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", font_size)
        except:
            try:
                font = ImageFont.truetype("/usr/share/fonts/TTF/DejaVuSans-Bold.ttf", font_size)
            except:
                font = ImageFont.load_default()

        # Draw W centered
        text = "W"
        bbox = draw.textbbox((0, 0), text, font=font)
        text_width = bbox[2] - bbox[0]
        text_height = bbox[3] - bbox[1]

        text_x = doc_x + (doc_width - text_width) // 2
        text_y = doc_y + (doc_height - text_height) // 2 - size // 20

        draw.text((text_x, text_y), text, fill=(255, 255, 255, 255), font=font)
    except Exception as e:
        print(f"Warning: Could not render text for size {size}: {e}")

    # Save the icon
    output_file = os.path.join(ICON_DIR, f'icon-{size}.png')
    img.save(output_file, 'PNG')
    print(f"Created {output_file}")

# Also create the main icon.png (512x512)
shutil.copyfile(
    os.path.join(ICON_DIR, 'icon-512.png'),
    os.path.join(ICON_DIR, 'icon.png')
)
print("Created icon.png")
