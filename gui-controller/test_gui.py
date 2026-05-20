#!/usr/bin/env python3
import sys
import os

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from display import DisplayManager, Resolution
from input import InputController
from screenshot import ScreenshotManager
from app import GUIController


def test_display_manager():
    print("Testing DisplayManager...")
    dm = DisplayManager(Resolution(800, 600))
    display = dm.start()
    assert display == ":99", f"Expected :99, got {display}"
    assert os.environ.get("DISPLAY") is None  # Not set yet
    os.environ["DISPLAY"] = display
    print(f"  Display started: {display}")
    print(f"  Resolution: {dm.resolution.geometry}")
    print(f"  Center: {dm.center}")
    dm.stop()
    print("  DisplayManager: PASSED")


def test_screenshot():
    print("Testing ScreenshotManager...")
    dm = DisplayManager(Resolution(800, 600))
    display = dm.start()
    os.environ["DISPLAY"] = display

    sm = ScreenshotManager(dm)
    img = sm.capture()
    assert img.size == (800, 600), f"Expected (800, 600), got {img.size}"
    print(f"  Screenshot size: {img.size}")

    filepath = sm.save(img, "test_screenshot.png")
    assert os.path.exists(filepath), f"File not created: {filepath}"
    print(f"  Screenshot saved: {filepath}")

    dm.stop()
    print("  ScreenshotManager: PASSED")


def test_input_controller():
    print("Testing InputController...")
    dm = DisplayManager(Resolution(800, 600))
    display = dm.start()
    os.environ["DISPLAY"] = display

    ic = InputController(dm)
    ic.move_mouse(400, 300)
    pos = ic.get_mouse_position()
    print(f"  Mouse position after move: {pos}")
    assert pos == (400, 300), f"Expected (400, 300), got {pos}"

    ic.click(100, 100)
    print("  Click executed")

    dm.stop()
    print("  InputController: PASSED")


def test_gui_controller():
    print("Testing GUIController...")
    with GUIController(Resolution(800, 600)) as controller:
        assert controller._started, "Controller not started"
        assert os.environ["DISPLAY"] == ":99", f"DISPLAY not set correctly"

        path = controller.screenshot()
        assert os.path.exists(path), f"Screenshot not created: {path}"
        print(f"  Screenshot via controller: {path}")

        controller.move_to(200, 200)
        pos = controller.input.get_mouse_position()
        assert pos == (200, 200), f"Expected (200, 200), got {pos}"
        print(f"  Mouse position: {pos}")

    assert not controller._started, "Controller not stopped"
    print("  GUIController: PASSED")


def test_resolution_presets():
    print("Testing Resolution presets...")
    assert Resolution.low() == Resolution(640, 480)
    assert Resolution.quarter_hd() == Resolution(960, 540)
    assert Resolution.hd() == Resolution(1280, 720)
    assert Resolution.full_hd() == Resolution(1920, 1080)
    print("  All presets correct")
    print("  Resolution presets: PASSED")


def main():
    print("=" * 50)
    print("GUI Controller Test Suite")
    print("=" * 50)

    test_resolution_presets()
    print()

    test_display_manager()
    print()

    test_screenshot()
    print()

    test_input_controller()
    print()

    test_gui_controller()
    print()

    print("=" * 50)
    print("All tests PASSED!")
    print("=" * 50)


if __name__ == "__main__":
    main()
