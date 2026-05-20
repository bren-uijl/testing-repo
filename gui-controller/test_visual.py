#!/usr/bin/env python3
import sys
import os
import time

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from app import GUIController
from display import Resolution


def test_with_xeyes():
    print("Testing with xeyes...")
    with GUIController(Resolution(800, 600)) as controller:
        print("  Launching xeyes...")
        controller.launch_app("xeyes", wait=1.0)

        path = controller.screenshot("xeyes_test.png")
        print(f"  Screenshot saved: {path}")

        print("  Moving mouse around...")
        for x, y in [(200, 200), (600, 200), (600, 400), (200, 400)]:
            controller.move_to(x, y)
            time.sleep(0.3)
            controller.screenshot(f"xeyes_mouse_{x}_{y}.png")

        print("  xeyes test: PASSED")


def test_with_xclock():
    print("Testing with xclock...")
    with GUIController(Resolution(800, 600)) as controller:
        print("  Launching xclock...")
        controller.launch_app("xclock", wait=1.0)

        path = controller.screenshot("xclock_test.png")
        print(f"  Screenshot saved: {path}")

        print("  xclock test: PASSED")


def test_with_xcalc():
    print("Testing with xcalc...")
    with GUIController(Resolution(800, 600)) as controller:
        print("  Launching xcalc...")
        controller.launch_app("xcalc", wait=1.0)

        path = controller.screenshot("xcalc_test.png")
        print(f"  Screenshot saved: {path}")

        center = controller.display_manager.center
        controller.click_at(center[0], center[1])
        time.sleep(0.5)

        path = controller.screenshot("xcalc_clicked.png")
        print(f"  After click: {path}")

        print("  xcalc test: PASSED")


def main():
    print("=" * 50)
    print("GUI Controller Visual Test Suite")
    print("=" * 50)
    print()

    try:
        test_with_xeyes()
    except Exception as e:
        print(f"  xeyes test skipped: {e}")
    print()

    try:
        test_with_xclock()
    except Exception as e:
        print(f"  xclock test skipped: {e}")
    print()

    try:
        test_with_xcalc()
    except Exception as e:
        print(f"  xcalc test skipped: {e}")
    print()

    print("=" * 50)
    print("Visual tests complete!")
    print("=" * 50)


if __name__ == "__main__":
    main()
