#!/usr/bin/env python3
"""Render Garmin vívoactive 5 screenshots from the actual UI source code logic."""

from PIL import Image, ImageDraw, ImageFont
import os

SCREEN_SIZE = 260  # vívoactive 5 resolution
OUTPUT_DIR = "garmin-ai-chat/screenshots"
os.makedirs(OUTPUT_DIR, exist_ok=True)

# Garmin Connect IQ color constants (RGB)
COLORS = {
    "BLACK": (0, 0, 0),
    "WHITE": (255, 255, 255),
    "BLUE": (0, 0, 255),
    "RED": (255, 0, 0),
    "YELLOW": (255, 255, 0),
    "LT_GRAY": (192, 192, 192),
    "DK_GRAY": (64, 64, 64),
    "TRANSPARENT": None,
}

def get_font(size, bold=False):
    """Get a font approximating Connect IQ watch fonts."""
    try:
        if bold:
            return ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", size)
        return ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", size)
    except:
        return ImageFont.load_default()

def create_round_mask(size):
    """Create a circular mask for the round watch face."""
    mask = Image.new("L", (size, size), 0)
    draw = ImageDraw.Draw(mask)
    draw.ellipse((0, 0, size-1, size-1), fill=255)
    return mask

def render_conversation_list():
    """Render the ConversationListView from source/ConversationListView.mc"""
    img = Image.new("RGB", (SCREEN_SIZE, SCREEN_SIZE), COLORS["BLACK"])
    draw = ImageDraw.Draw(img)

    width = SCREEN_SIZE
    height = SCREEN_SIZE

    # Font sizes matching Connect IQ FONT_TINY and FONT_SMALL
    font_tiny = get_font(11)
    font_small = get_font(14)

    # Black background (line 92-93)
    draw.rectangle([0, 0, width, height], fill=COLORS["BLACK"])

    # App title (line 96)
    draw.text((width // 2, 18), "AI Chat", fill=COLORS["WHITE"], font=font_tiny, anchor="mt")

    # Help/settings icon (line 108)
    draw.text((width - 35, 18), "?", fill=COLORS["LT_GRAY"], font=font_tiny, anchor="mt")

    # Separator line (line 112)
    draw.line([(0, 38), (width, 38)], fill=COLORS["DK_GRAY"])

    # "+ New" button (lines 114-123)
    btn_width = 70
    btn_height = 24
    btn_x = (width - btn_width) // 2
    btn_y = 42
    draw.rectangle([btn_x, btn_y, btn_x + btn_width, btn_y + btn_height], fill=COLORS["BLUE"])
    draw.text((width // 2, btn_y + 12), "+ New", fill=COLORS["WHITE"], font=font_tiny, anchor="mm")

    # Quick prompts (lines 125-143)
    quick_prompts = ["Translate", "Summarize", "Explain", "Weather", "Joke", "Timer"]
    prompt_y = btn_y + btn_height + 8
    prompt_btn_width = (width - 30) // 2
    prompt_btn_height = 22

    for p, label in enumerate(quick_prompts):
        col = p % 2
        row = p // 2
        px = 10 + col * (prompt_btn_width + 10)
        py = prompt_y + row * (prompt_btn_height + 6)
        draw.rounded_rectangle([px, py, px + prompt_btn_width, py + prompt_btn_height], radius=6, fill=COLORS["DK_GRAY"])
        draw.text((px + prompt_btn_width // 2, py + 11), label, fill=COLORS["WHITE"], font=font_tiny, anchor="mm")

    # Conversation list (lines 156-204)
    list_top = btn_y + btn_height + 8 + 3 * (22 + 6) + 10
    item_height = 50

    conversations = [
        {"title": "Recipe Ideas", "time": "2m ago", "preview": "What can I make with chicken?"},
        {"title": "Travel Tips", "time": "1h ago", "preview": "Best spots in Amsterdam?"},
        {"title": "Workout Plan", "time": "3h ago", "preview": "5K training schedule"},
        {"title": "Translation", "time": "Yesterday", "preview": "Translate to Spanish: Hello"},
    ]

    available_height = height - list_top - 20

    # Clip area
    for i, conv in enumerate(conversations):
        y = list_top + i * item_height
        if y + item_height > list_top + available_height:
            break

        # Selected item highlight
        if i == 0:
            draw.rectangle([5, y, width - 10, y + item_height - 4], fill=COLORS["DK_GRAY"])

        # Title
        draw.text((15, y + 8), conv["title"], fill=COLORS["WHITE"], font=font_small, anchor="lt")

        # Time
        draw.text((width - 15, y + 8), conv["time"], fill=COLORS["LT_GRAY"], font=font_tiny, anchor="rt")

        # Preview
        draw.text((15, y + 26), conv["preview"], fill=COLORS["LT_GRAY"], font=font_tiny, anchor="lt")

        # Separator
        if i < len(conversations) - 1:
            draw.line([(10, y + item_height - 4), (width - 10, y + item_height - 4)], fill=COLORS["DK_GRAY"])

    # Apply round mask
    mask = create_round_mask(SCREEN_SIZE)
    result = Image.new("RGBA", (SCREEN_SIZE, SCREEN_SIZE), (0, 0, 0, 0))
    result.paste(img, (0, 0), mask)
    result.save(os.path.join(OUTPUT_DIR, "garmin-conversation-list.png"))
    print("Saved: garmin-conversation-list.png")

def render_conversation_view():
    """Render the ConversationView from source/ConversationView.mc"""
    img = Image.new("RGB", (SCREEN_SIZE, SCREEN_SIZE), COLORS["BLACK"])
    draw = ImageDraw.Draw(img)

    width = SCREEN_SIZE
    height = SCREEN_SIZE
    font_tiny = get_font(11)
    font_small = get_font(14)

    # Black background
    draw.rectangle([0, 0, width, height], fill=COLORS["BLACK"])

    # Title (line 76-80)
    draw.text((width // 2, 18), "Recipe Ideas", fill=COLORS["WHITE"], font=font_tiny, anchor="mt")

    # Message count (line 83-84)
    draw.text((width // 2, 28), "4 msgs", fill=COLORS["LT_GRAY"], font=font_tiny, anchor="mt")

    # Separator (line 87)
    draw.line([(0, 30), (width, 30)], fill=COLORS["DK_GRAY"])

    # Messages (lines 100-147)
    header_height = 35
    footer_height = 45

    messages = [
        {"role": "user", "text": "What can I make with chicken and rice?"},
        {"role": "assistant", "text": "Try chicken stir-fry with vegetables, or a classic chicken and rice soup!"},
        {"role": "user", "text": "How long does stir-fry take?"},
        {"role": "assistant", "text": "About 20 minutes total. Prep 10 min, cook 10 min."},
    ]

    y = height - footer_height - 10
    for msg in reversed(messages):
        text = msg["text"]
        # Estimate bubble size
        text_width = font_small.getlength(text)
        bubble_width = min(text_width + 20, width - 40)
        bubble_height = 36

        if msg["role"] == "user":
            # User message - right aligned blue bubble (lines 119-129)
            bubble_x = width - bubble_width - 10
            draw.rounded_rectangle([bubble_x, y - bubble_height, width - 10, y], radius=8, fill=COLORS["BLUE"])
            draw.text((width - 15, y - bubble_height + 12), text, fill=COLORS["WHITE"], font=font_small, anchor="rt")
        else:
            # Assistant message - left aligned gray bubble (lines 131-140)
            draw.rounded_rectangle([10, y - bubble_height, 10 + bubble_width, y], radius=8, fill=COLORS["DK_GRAY"])
            draw.text((15, y - bubble_height + 12), text, fill=COLORS["WHITE"], font=font_small, anchor="lt")

        y = y - bubble_height - 8

    # Footer separator (line 149-150)
    draw.line([(0, height - footer_height), (width, height - footer_height)], fill=COLORS["DK_GRAY"])

    # Reply button (lines 152-162)
    reply_btn_width = 100
    reply_btn_height = 28
    reply_btn_x = (width - reply_btn_width) // 2
    reply_btn_y = height - footer_height + 10
    draw.rounded_rectangle([reply_btn_x, reply_btn_y, reply_btn_x + reply_btn_width, reply_btn_y + reply_btn_height], radius=8, fill=COLORS["BLUE"])
    draw.text((width // 2, reply_btn_y + 14), "Reply", fill=COLORS["WHITE"], font=font_small, anchor="mm")

    # Apply round mask
    mask = create_round_mask(SCREEN_SIZE)
    result = Image.new("RGBA", (SCREEN_SIZE, SCREEN_SIZE), (0, 0, 0, 0))
    result.paste(img, (0, 0), mask)
    result.save(os.path.join(OUTPUT_DIR, "garmin-conversation-view.png"))
    print("Saved: garmin-conversation-view.png")

def render_settings_view():
    """Render the SettingsView from source/SettingsView.mc"""
    img = Image.new("RGB", (SCREEN_SIZE, SCREEN_SIZE), COLORS["BLACK"])
    draw = ImageDraw.Draw(img)

    width = SCREEN_SIZE
    height = SCREEN_SIZE
    font_tiny = get_font(11)
    font_small = get_font(14)

    # Black background (line 84-85)
    draw.rectangle([0, 0, width, height], fill=COLORS["BLACK"])

    # Title (line 88)
    draw.text((width // 2, 18), "Settings", fill=COLORS["WHITE"], font=font_tiny, anchor="mt")

    # Separator (line 91)
    draw.line([(0, 35), (width, 35)], fill=COLORS["DK_GRAY"])

    # Settings items (lines 99-129)
    header_height = 45
    item_height = 50
    list_top = header_height

    settings_items = [
        {"label": "API Key", "value": "nvapi-...x7kQ"},
        {"label": "Model", "value": "Nemotron Nano 9B"},
        {"label": "System Prompt", "value": "You are a helpful..."},
        {"label": "Clear All Chats", "value": ""},
        {"label": "About", "value": "v1.2.0"},
    ]

    available_height = height - list_top - 20

    for i, item in enumerate(settings_items):
        y = list_top + i * item_height
        if y + item_height > list_top + available_height:
            break

        # Selected highlight
        if i == 1:
            draw.rectangle([5, y, width - 10, y + item_height - 4], fill=COLORS["DK_GRAY"])

        # Label
        draw.text((15, y + 12), item["label"], fill=COLORS["WHITE"], font=font_small, anchor="lt")

        # Value
        if item["value"]:
            display_value = item["value"] if len(item["value"]) <= 20 else item["value"][:17] + "..."
            draw.text((width - 15, y + 12), display_value, fill=COLORS["LT_GRAY"], font=font_tiny, anchor="rt")

        # Separator
        if i < len(settings_items) - 1:
            draw.line([(10, y + item_height - 4), (width - 10, y + item_height - 4)], fill=COLORS["DK_GRAY"])

    # Apply round mask
    mask = create_round_mask(SCREEN_SIZE)
    result = Image.new("RGBA", (SCREEN_SIZE, SCREEN_SIZE), (0, 0, 0, 0))
    result.paste(img, (0, 0), mask)
    result.save(os.path.join(OUTPUT_DIR, "garmin-settings.png"))
    print("Saved: garmin-settings.png")

if __name__ == "__main__":
    render_conversation_list()
    render_conversation_view()
    render_settings_view()
    print("All screenshots generated.")
