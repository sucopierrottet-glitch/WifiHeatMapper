import math
import os
from PIL import Image, ImageDraw


def create_app_icon(output_path="assets/icon/app_icon.png"):
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    size = 1024
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # 1. Base Background with Rounded Squircle (Obsidian Dark #0B0F19 -> #161F30)
    bg_margin = 32
    bg_radius = 220

    gradient_img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    grad_draw = ImageDraw.Draw(gradient_img)

    for y in range(size):
        ratio = y / size
        r = int(11 + (22 - 11) * ratio)
        g = int(15 + (31 - 15) * ratio)
        b = int(25 + (48 - 25) * ratio)
        grad_draw.line([(0, y), (size, y)], fill=(r, g, b, 255))

    mask = Image.new("L", (size, size), 0)
    mask_draw = ImageDraw.Draw(mask)
    mask_draw.rounded_rectangle(
        [bg_margin, bg_margin, size - bg_margin, size - bg_margin],
        radius=bg_radius,
        fill=255,
    )
    img.paste(gradient_img, (0, 0), mask)

    # Outer cyan/emerald glow border
    draw.rounded_rectangle(
        [bg_margin, bg_margin, size - bg_margin, size - bg_margin],
        radius=bg_radius,
        outline=(56, 189, 248, 95),
        width=6,
    )

    cx, cy = 512, 512

    # 2. Floorplan Blueprint Grid + Thermal Zones
    grid_rect = [180, 180, 844, 844]
    draw.rounded_rectangle(
        grid_rect,
        radius=48,
        fill=(15, 23, 42, 230),
        outline=(56, 189, 248, 120),
        width=5,
    )

    # Thermal heatmap rooms inside floorplan
    # Top-left: Green Strong zone
    draw.rounded_rectangle(
        [205, 205, 500, 500],
        radius=28,
        fill=(0, 230, 118, 68),
        outline=(0, 230, 118, 160),
        width=4,
    )
    # Top-right: Yellow Fair zone
    draw.rounded_rectangle(
        [524, 205, 819, 500],
        radius=28,
        fill=(255, 214, 0, 62),
        outline=(255, 214, 0, 150),
        width=4,
    )
    # Bottom-left: Cyan Optimal Router zone
    draw.rounded_rectangle(
        [205, 524, 500, 819],
        radius=28,
        fill=(56, 189, 248, 62),
        outline=(56, 189, 248, 150),
        width=4,
    )
    # Bottom-right: Red Dead-zone warning
    draw.rounded_rectangle(
        [524, 524, 819, 819],
        radius=28,
        fill=(255, 82, 82, 62),
        outline=(255, 82, 82, 150),
        width=4,
    )

    # 3. Concentric Wi-Fi Radar Waves from Center
    for r, col in [
        (290, (0, 230, 118, 220)),
        (210, (56, 189, 248, 240)),
        (130, (0, 230, 118, 255)),
    ]:
        bbox = [cx - r, cy - r, cx + r, cy + r]
        draw.arc(bbox, start=215, end=325, fill=col, width=22)
        draw.arc(bbox, start=35, end=145, fill=col, width=14)

    # 4. Center Router Hub Core
    hub_r = 68
    draw.ellipse(
        [cx - hub_r - 8, cy - hub_r - 8, cx + hub_r + 8, cy + hub_r + 8],
        fill=(7, 11, 20, 230),
    )
    draw.ellipse(
        [cx - hub_r, cy - hub_r, cx + hub_r, cy + hub_r],
        fill=(0, 230, 118, 255),
        outline=(255, 255, 255, 240),
        width=6,
    )
    draw.ellipse(
        [cx - 22, cy - 22, cx + 22, cy + 22],
        fill=(11, 15, 25, 255),
    )

    img.save(output_path, "PNG")
    print(f"Generated WiFi HeatMapper Pro icon successfully at {output_path}")


if __name__ == "__main__":
    create_app_icon()
