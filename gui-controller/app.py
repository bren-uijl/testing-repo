#!/usr/bin/env python3
import os
import signal
import subprocess
import sys
import time
from pathlib import Path

from display import DisplayManager, Resolution
from input import InputController
from screenshot import ScreenshotManager


class GUIController:
    def __init__(self, resolution: Resolution = None):
        self.display_manager = DisplayManager(resolution or Resolution.full_hd())
        self.input = None
        self.screenshot_manager = None
        self._started = False

    def start(self):
        display = self.display_manager.start()
        os.environ["DISPLAY"] = display
        self.input = InputController(self.display_manager)
        self.screenshot_manager = ScreenshotManager(self.display_manager)
        self._started = True
        return self

    def stop(self):
        self.display_manager.stop()
        self._started = False

    def launch_app(self, command: str, wait: float = 2.0) -> subprocess.Popen:
        env = os.environ.copy()
        env["DISPLAY"] = self.display_manager.display
        process = subprocess.Popen(
            command.split(),
            env=env,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
        time.sleep(wait)
        return process

    def wait_for_window(self, window_name: str, timeout: int = 30) -> bool:
        env = os.environ.copy()
        env["DISPLAY"] = self.display_manager.display
        start = time.time()
        while time.time() - start < timeout:
            result = subprocess.run(
                ["xdotool", "search", "--name", window_name],
                capture_output=True,
                text=True,
                env=env,
            )
            if result.stdout.strip():
                return True
            time.sleep(0.5)
        return False

    def focus_window(self, window_name: str) -> bool:
        env = os.environ.copy()
        env["DISPLAY"] = self.display_manager.display
        result = subprocess.run(
            ["xdotool", "search", "--name", window_name],
            capture_output=True,
            text=True,
            env=env,
        )
        window_id = result.stdout.strip().split("\n")[0]
        if window_id:
            subprocess.run(
                ["xdotool", "windowactivate", "--sync", window_id],
                capture_output=True,
                env=env,
            )
            return True
        return False

    def click_at(self, x: int, y: int, button: int = 1):
        self.input.click(x, y, button)

    def move_to(self, x: int, y: int):
        self.input.move_mouse(x, y)

    def type_text(self, text: str):
        self.input.type_text(text)

    def press_key(self, key: str):
        self.input.key_press(key)

    def key_combo(self, *keys: str):
        self.input.key_combo(*keys)

    def screenshot(self, filename: str = None) -> str:
        return self.screenshot_manager.capture_and_save(filename)

    def get_pixel(self, x: int, y: int) -> tuple:
        return self.screenshot_manager.get_pixel_color(x, y)

    def __enter__(self):
        self.start()
        return self

    def __exit__(self, exc_type, exc_val, exc_tb):
        self.stop()


def main():
    import argparse

    parser = argparse.ArgumentParser(description="GUI Controller for Ubuntu")
    parser.add_argument("--resolution", choices=["low", "qhd", "hd", "fhd"], default="fhd")
    parser.add_argument("--app", help="Application to launch")
    parser.add_argument("--wait", type=float, default=2.0, help="Wait time after launch")
    parser.add_argument("--screenshot", action="store_true", help="Take a screenshot")
    parser.add_argument("--click", nargs=2, type=int, metavar=("X", "Y"), help="Click at position")
    parser.add_argument("--type", dest="type_text", help="Type text")
    parser.add_argument("--key", help="Press a key")
    parser.add_argument("--keep-alive", action="store_true", help="Keep display running")

    args = parser.parse_args()

    resolution_map = {
        "low": Resolution.low(),
        "qhd": Resolution.quarter_hd(),
        "hd": Resolution.hd(),
        "fhd": Resolution.full_hd(),
    }
    resolution = resolution_map[args.resolution]

    with GUIController(resolution) as controller:
        if args.app:
            print(f"Launching: {args.app}")
            controller.launch_app(args.app, args.wait)

        if args.click:
            x, y = args.click
            print(f"Clicking at ({x}, {y})")
            controller.click_at(x, y)

        if args.type_text:
            print(f"Typing: {args.type_text}")
            controller.type_text(args.type_text)

        if args.key:
            print(f"Pressing key: {args.key}")
            controller.press_key(args.key)

        if args.screenshot:
            path = controller.screenshot()
            print(f"Screenshot saved: {path}")

        if args.keep_alive:
            print(f"Display running at {controller.display_manager.display}")
            print("Press Ctrl+C to stop")
            try:
                while True:
                    time.sleep(1)
            except KeyboardInterrupt:
                print("\nStopping...")


if __name__ == "__main__":
    main()
