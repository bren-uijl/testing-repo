# GUI Controller Instructions

## Overview

The GUI Controller is a Python-based framework for interacting with GUI applications on Ubuntu using a virtual X11 display (Xvfb). It enables AI agents running in headless environments (like GitHub Actions) to launch, control, and interact with graphical applications.

## Architecture

```
gui-controller/
├── app.py              # Main GUIController class
├── display.py          # DisplayManager and Resolution classes
├── input.py            # InputController for mouse/keyboard
├── screenshot.py       # ScreenshotManager for screen capture
├── minesweeper.py      # Minesweeper game player (demo)
├── test_gui.py         # Unit tests
├── test_visual.py      # Visual tests with x11 apps
├── test_minesweeper_grid.py  # Grid interaction test
└── requirements.txt    # Python dependencies
```

## Quick Start

```python
from gui_controller import GUIController, Resolution

with GUIController(Resolution(1280, 720)) as controller:
    # Launch an application
    controller.launch_app("xeyes")

    # Interact with mouse
    controller.click_at(400, 300)
    controller.move_to(600, 400)

    # Type text
    controller.type_text("Hello World")

    # Take screenshot
    path = controller.screenshot("output.png")
```

## Components

### DisplayManager
Manages the Xvfb virtual framebuffer.

```python
from display import DisplayManager, Resolution

dm = DisplayManager(Resolution(1920, 1080))
display = dm.start()  # Returns ":99"
# ... use display ...
dm.stop()
```

Resolution presets:
- `Resolution.low()` - 640x480
- `Resolution.quarter_hd()` - 960x540
- `Resolution.hd()` - 1280x720
- `Resolution.full_hd()` - 1920x1080

### InputController
Controls mouse and keyboard via xdotool.

```python
from input import InputController

ic = InputController(display_manager)

# Mouse
ic.move_mouse(x, y)
ic.click(x, y, button=1)  # 1=left, 3=right
ic.double_click(x, y)
ic.right_click(x, y)
ic.drag(x1, y1, x2, y2)
ic.scroll(clicks, x, y)

# Keyboard
ic.key_press("Return")
ic.type_text("hello")
ic.key_combo("ctrl", "c")
ic.key_down("shift")
ic.key_up("shift")
```

### ScreenshotManager
Captures and analyzes screen content.

```python
from screenshot import ScreenshotManager

sm = ScreenshotManager(display_manager)

# Capture
img = sm.capture()
sm.save(img, "output.png")
sm.capture_and_save("auto.png")

# Analysis
color = sm.get_pixel_color(x, y)
matches = sm.find_color_region((255, 0, 0), tolerance=10)
similarity = sm.compare(img1, img2)
```

## Running Tests

```bash
cd gui-controller
pip install -r requirements.txt

# Unit tests
python3 test_gui.py

# Visual tests (requires x11-apps)
python3 test_visual.py

# Minesweeper grid test
python3 test_minesweeper_grid.py
```

## GitHub Actions Workflow

The workflow file is at `workflows/opencodev3-fixed.txt`. It extends opencodev2 with:

- `enable_gui` input (true/false)
- `gui_resolution` input (e.g., "1280x720")
- Automatic Xvfb setup
- GUI dependency installation
- Screenshot artifact upload

## Common Use Cases

### Launch and interact with an app
```python
with GUIController() as controller:
    controller.launch_app("gnome-calculator", wait=2.0)
    controller.wait_for_window("Calculator", timeout=10)
    controller.focus_window("Calculator")
    controller.click_at(400, 300)
```

### Play minesweeper
```python
from minesweeper import MinesweeperPlayer

with GUIController(Resolution(1024, 768)) as controller:
    controller.launch_app("gnome-mines", wait=3.0)
    player = MinesweeperPlayer(controller)
    player.play(max_iterations=100)
```

### Automated testing
```python
with GUIController() as controller:
    controller.launch_app("my-app")
    controller.click_at(100, 100)
    time.sleep(1)
    screenshot = controller.screenshot("test_result.png")
    # Compare with expected
```

## Troubleshooting

### xdotool not finding display
Ensure DISPLAY environment variable is set:
```bash
export DISPLAY=:99
```

### Mouse position not updating
The InputController now uses env var instead of --display flag. Make sure you're using the latest version.

### Screenshot is black
Xvfb may not have started properly. Check:
```bash
ps aux | grep Xvfb
```

### Application not launching
Increase the wait time or check if the app is installed:
```bash
which gnome-mines
```
