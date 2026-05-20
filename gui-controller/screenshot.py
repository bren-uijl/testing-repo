import io
import os
from datetime import datetime
from typing import Optional

import mss
from PIL import Image

from display import DisplayManager


class ScreenshotManager:
    def __init__(self, display_manager: DisplayManager):
        self.display = display_manager.display
        self.resolution = display_manager.resolution
        self._screenshot_dir = "screenshots"
        os.makedirs(self._screenshot_dir, exist_ok=True)

    def capture(self) -> Image.Image:
        with mss.mss(display=self.display) as sct:
            monitor = sct.monitors[1]
            screenshot = sct.grab(monitor)
            img = Image.frombytes("RGB", screenshot.size, screenshot.bgra, "raw", "BGRX")
        return img

    def save(self, image: Image.Image = None, filename: str = None) -> str:
        if image is None:
            image = self.capture()
        if filename is None:
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S_%f")
            filename = f"screenshot_{timestamp}.png"
        filepath = os.path.join(self._screenshot_dir, filename)
        image.save(filepath)
        return filepath

    def capture_and_save(self, filename: str = None) -> str:
        image = self.capture()
        return self.save(image, filename)

    def find_region(self, x: int, y: int, width: int, height: int) -> Image.Image:
        with mss.mss(display=self.display) as sct:
            monitor = {
                "top": y,
                "left": x,
                "width": width,
                "height": height,
            }
            screenshot = sct.grab(monitor)
            img = Image.frombytes("RGB", screenshot.size, screenshot.bgra, "raw", "BGRX")
        return img

    def get_pixel_color(self, x: int, y: int) -> tuple:
        image = self.capture()
        return image.getpixel((x, y))

    def find_color_region(self, target_color: tuple, tolerance: int = 10) -> list:
        image = self.capture()
        pixels = image.load()
        matches = []
        for y in range(image.height):
            for x in range(image.width):
                pixel = pixels[x, y]
                if (
                    abs(pixel[0] - target_color[0]) <= tolerance
                    and abs(pixel[1] - target_color[1]) <= tolerance
                    and abs(pixel[2] - target_color[2]) <= tolerance
                ):
                    matches.append((x, y))
        return matches

    def compare(self, img1: Image.Image, img2: Image.Image) -> float:
        if img1.size != img2.size:
            img2 = img2.resize(img1.size)
        pixels1 = list(img1.getdata())
        pixels2 = list(img2.getdata())
        total = len(pixels1)
        different = sum(
            1 for p1, p2 in zip(pixels1, pixels2)
            if any(abs(a - b) > 10 for a, b in zip(p1, p2))
        )
        return 1.0 - (different / total)
