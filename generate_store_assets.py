import os
from PIL import Image, ImageDraw, ImageFont


def generate_store_assets():
    out_dir = "store_assets"
    os.makedirs(out_dir, exist_ok=True)

    font_bold_path = "C:/Windows/Fonts/segoeuib.ttf"
    font_reg_path = "C:/Windows/Fonts/segoeui.ttf"

    # 1. ICON 512x512
    base_icon_path = "assets/icon/app_icon.png"
    if os.path.exists(base_icon_path):
        base_icon = Image.open(base_icon_path).convert("RGBA")
        icon_512 = base_icon.resize((512, 512), Image.Resampling.LANCZOS)
        icon_512.save(os.path.join(out_dir, "icon_512.png"), "PNG")
        print("Generated icon_512.png")

    # 2. FEATURE GRAPHIC 1024x500
    w_feat, h_feat = 1024, 500
    feat_img = Image.new("RGBA", (w_feat, h_feat), (0, 0, 0, 0))
    feat_draw = ImageDraw.Draw(feat_img)

    for x in range(w_feat):
        ratio = x / w_feat
        r = int(11 + (22 - 11) * ratio)
        g = int(15 + (31 - 15) * ratio)
        b = int(25 + (48 - 25) * ratio)
        feat_draw.line([(x, 0), (x, h_feat)], fill=(r, g, b, 255))

    glow_overlay = Image.new("RGBA", (w_feat, h_feat), (0, 0, 0, 0))
    glow_draw = ImageDraw.Draw(glow_overlay)
    glow_draw.ellipse([80, 50, 480, 450], fill=(0, 230, 118, 28))
    glow_draw.ellipse([600, -100, 1100, 400], fill=(56, 189, 248, 24))
    feat_img = Image.alpha_composite(feat_img, glow_overlay)
    feat_draw = ImageDraw.Draw(feat_img)

    if os.path.exists(base_icon_path):
        icon_for_feat = (
            Image.open(base_icon_path)
            .convert("RGBA")
            .resize((320, 320), Image.Resampling.LANCZOS)
        )
        feat_img.paste(icon_for_feat, (90, 90), icon_for_feat)

    f_badge = ImageFont.truetype(font_bold_path, 16)
    f_title = ImageFont.truetype(font_bold_path, 44)
    f_sub = ImageFont.truetype(font_reg_path, 21)
    f_tag = ImageFont.truetype(font_bold_path, 14)

    tx = 450
    badge_text = "MAPA TÉRMICO WI-FI • ESPECTRO & EMF"
    feat_draw.rounded_rectangle(
        [tx, 95, tx + 380, 130],
        radius=18,
        fill=(0, 230, 118, 35),
        outline=(0, 230, 118, 180),
        width=1,
    )
    feat_draw.text((tx + 18, 103), badge_text, font=f_badge, fill=(0, 230, 118, 255))

    feat_draw.text(
        (tx, 145), "WIFI HEATMAPPER PRO", font=f_title, fill=(248, 250, 252, 255)
    )
    feat_draw.text(
        (tx, 210),
        "Cobertura por Habitación • Ubicación Óptima Router",
        font=f_sub,
        fill=(203, 213, 225, 255),
    )
    feat_draw.text(
        (tx, 240),
        "Canales 2.4/5 GHz, Radar EMF (µT) & Reportes PDF",
        font=f_sub,
        fill=(148, 163, 184, 255),
    )

    chips = ["IEEE 802.11", "FSPL MODEL", "EMF RADAR µT", "SIGNED PDF", "100% PRO"]
    chip_x = tx
    chip_y = 300
    for std in chips:
        bbox = f_tag.getbbox(std)
        tw = bbox[2] - bbox[0] + 24
        feat_draw.rounded_rectangle(
            [chip_x, chip_y, chip_x + tw, chip_y + 32],
            radius=8,
            fill=(22, 31, 48, 255),
            outline=(56, 189, 248, 180),
            width=1,
        )
        feat_draw.text(
            (chip_x + 12, chip_y + 7), std, font=f_tag, fill=(248, 250, 252, 255)
        )
        chip_x += tw + 10
        if chip_x > 940:
            chip_x = tx
            chip_y += 42

    feat_img.save(os.path.join(out_dir, "feature_graphic_1024x500.png"), "PNG")
    print("Generated feature_graphic_1024x500.png")

    # 3. HIGH-RES PHONE SCREENSHOTS (1080x1920)
    def create_mockup(filename, banner_tag, main_title, subtitle, card_builder):
        w, h = 1080, 1920
        img = Image.new("RGBA", (w, h), (11, 15, 25, 255))
        draw = ImageDraw.Draw(img)

        for y in range(400):
            ratio = y / 400
            alpha = int(35 * (1 - ratio))
            draw.line([(0, y), (w, y)], fill=(0, 230, 118, alpha))

        f_top_tag = ImageFont.truetype(font_bold_path, 28)
        f_top_title = ImageFont.truetype(font_bold_path, 60)
        f_top_sub = ImageFont.truetype(font_reg_path, 32)

        draw.text((70, 90), banner_tag.upper(), font=f_top_tag, fill=(0, 230, 118, 255))
        draw.text((70, 135), main_title, font=f_top_title, fill=(248, 250, 252, 255))
        draw.text((70, 220), subtitle, font=f_top_sub, fill=(148, 163, 184, 255))

        p_left, p_top, p_right, p_bottom = 80, 310, 1000, 1860
        draw.rounded_rectangle(
            [p_left, p_top, p_right, p_bottom],
            radius=54,
            fill=(16, 23, 37, 255),
            outline=(45, 60, 82, 255),
            width=4,
        )

        s_left, s_top, s_right, s_bottom = (
            p_left + 16,
            p_top + 16,
            p_right - 16,
            p_bottom - 16,
        )
        draw.rounded_rectangle(
            [s_left, s_top, s_right, s_bottom], radius=44, fill=(11, 15, 25, 255)
        )
        draw.rounded_rectangle(
            [(w // 2) - 80, s_top + 14, (w // 2) + 80, s_top + 44],
            radius=15,
            fill=(7, 11, 20, 255),
        )

        card_builder(draw, s_left, s_top + 60, s_right, s_bottom)

        img.save(os.path.join(out_dir, filename), "PNG")
        print(f"Generated {filename}")

    def draw_screen1(draw, sl, st, sr, sb):
        cx = (sl + sr) // 2
        f_b1 = ImageFont.truetype(font_bold_path, 42)
        f_b2 = ImageFont.truetype(font_reg_path, 26)
        f_btn = ImageFont.truetype(font_bold_path, 32)
        draw.ellipse(
            [cx - 110, st + 180, cx + 110, st + 400],
            fill=(22, 31, 48, 255),
            outline=(0, 230, 118, 255),
            width=4,
        )
        draw.text(
            (cx - 210, st + 450),
            "WIFI HEATMAPPER PRO",
            font=f_b1,
            fill=(255, 255, 255, 255),
        )
        draw.text(
            (cx - 260, st + 515),
            "Mapeo Térmico 2D, Espectro & Radar EMF",
            font=f_b2,
            fill=(148, 163, 184, 255),
        )
        by = st + 780
        draw.rounded_rectangle(
            [sl + 60, by, sr - 60, by + 100], radius=24, fill=(0, 230, 118, 255)
        )
        draw.text(
            (cx - 170, by + 28),
            "Entrar al Mapa Térmico",
            font=f_btn,
            fill=(4, 20, 11, 255),
        )

    create_mockup(
        "1_pantalla_bienvenida.png",
        "100% Pro Desbloqueado",
        "Auditoría Wi-Fi & EMF en Campo",
        "Interfaz Obsidian de alto contraste y 100% Offline",
        draw_screen1,
    )

    def draw_screen2(draw, sl, st, sr, sb):
        f_h = ImageFont.truetype(font_bold_path, 32)
        f_sub = ImageFont.truetype(font_reg_path, 24)
        draw.rounded_rectangle(
            [sl + 30, st + 30, sr - 30, st + 620],
            radius=24,
            fill=(16, 23, 37, 255),
            outline=(56, 189, 248, 200),
            width=2,
        )
        draw.text(
            (sl + 60, st + 55),
            "PLANO TÉRMICO INTERACTIVO 2D",
            font=f_h,
            fill=(0, 230, 118, 255),
        )
        # Rooms
        draw.rounded_rectangle(
            [sl + 60, st + 130, sl + 430, st + 340],
            radius=16,
            fill=(0, 230, 118, 65),
            outline=(0, 230, 118, 255),
            width=3,
        )
        draw.text(
            (sl + 90, st + 210),
            "Sala: -48 dBm",
            font=f_h,
            fill=(0, 230, 118, 255),
        )
        draw.rounded_rectangle(
            [sl + 460, st + 130, sr - 60, st + 340],
            radius=16,
            fill=(255, 214, 0, 65),
            outline=(255, 214, 0, 255),
            width=3,
        )
        draw.text(
            (sl + 490, st + 210),
            "Estudio: -66 dBm",
            font=f_h,
            fill=(255, 214, 0, 255),
        )
        draw.rounded_rectangle(
            [sl + 60, st + 370, sr - 60, st + 570],
            radius=16,
            fill=(255, 82, 82, 65),
            outline=(255, 82, 82, 255),
            width=3,
        )
        draw.text(
            (sl + 90, st + 450),
            "Terraza: -79 dBm (Zona Muerta)",
            font=f_sub,
            fill=(255, 82, 82, 255),
        )

    create_mockup(
        "2_mapa_termico_planta.png",
        "Mapeo por Habitación",
        "Calor Wi-Fi & Router Óptimo",
        "Toca cada habitación para pintar dBm y calcular coordenadas óptimas",
        draw_screen2,
    )

    def draw_screen3(draw, sl, st, sr, sb):
        f_h = ImageFont.truetype(font_bold_path, 32)
        f_res = ImageFont.truetype(font_bold_path, 56)
        draw.rounded_rectangle(
            [sl + 30, st + 30, sr - 30, st + 480],
            radius=24,
            fill=(22, 31, 48, 255),
            outline=(45, 60, 82, 255),
            width=2,
        )
        draw.text(
            (sl + 60, st + 60),
            "ESPECTRO 2.4 / 5 GHz & FSPL",
            font=f_h,
            fill=(56, 189, 248, 255),
        )
        draw.text(
            (sl + 60, st + 140),
            "Canales Limpios: 1, 6, 11",
            font=f_res,
            fill=(255, 255, 255, 255),
        )
        draw.rounded_rectangle(
            [sl + 30, st + 520, sr - 30, st + 1020],
            radius=24,
            fill=(22, 31, 48, 255),
            outline=(0, 230, 118, 200),
            width=2,
        )
        draw.text(
            (sl + 60, st + 555),
            "RADAR MAGNETÓMETRO EMF (µT)",
            font=f_h,
            fill=(0, 230, 118, 255),
        )
        draw.text(
            (sl + 60, st + 650),
            "46.5 µT • BAJA INTERFERENCIA",
            font=f_h,
            fill=(255, 255, 255, 255),
        )

    create_mockup(
        "3_espectro_radar_emf.png",
        "Espectro & Magnetómetro",
        "Solapamiento y Radar EMF",
        "Detecta interferencia electromagnética y congestión de canales",
        draw_screen3,
    )

    def draw_screen4(draw, sl, st, sr, sb):
        f_h = ImageFont.truetype(font_bold_path, 30)
        f_sub = ImageFont.truetype(font_reg_path, 22)
        doc_top = st + 40
        doc_bottom = st + 1150
        draw.rounded_rectangle(
            [sl + 40, doc_top, sr - 40, doc_bottom],
            radius=20,
            fill=(255, 255, 255, 255),
        )
        draw.rounded_rectangle(
            [sl + 40, doc_top, sr - 40, doc_top + 120],
            radius=20,
            fill=(11, 15, 25, 255),
        )
        draw.text(
            (sl + 70, doc_top + 35),
            "REPORTE DE AUDITORÍA WI-FI & EMF",
            font=f_h,
            fill=(0, 230, 118, 255),
        )
        draw.text(
            (sl + 70, doc_top + 170),
            "PROYECTO: Oficina Central & Penthouse A1",
            font=f_sub,
            fill=(15, 23, 42, 255),
        )
        draw.text(
            (sl + 70, doc_top + 220),
            "• Cobertura Promedio: -58.5 dBm (82% Calidad)",
            font=f_sub,
            fill=(4, 120, 87, 255),
        )
        draw.text(
            (sl + 70, doc_top + 265),
            "• Coordenadas Óptimas Router: X:48% Y:44%",
            font=f_sub,
            fill=(4, 120, 87, 255),
        )

    create_mockup(
        "4_reporte_pdf_firmado.png",
        "Memorias PDF Firmadas",
        "Reportes Técnicos con Firma",
        "Exporta informes A4 listos para clientes e inspectores",
        draw_screen4,
    )


if __name__ == "__main__":
    generate_store_assets()
