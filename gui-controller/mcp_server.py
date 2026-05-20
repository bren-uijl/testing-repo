#!/usr/bin/env python3
"""MCP Server for GUI Controller - exposes GUI operations as MCP tools."""

import os
import subprocess
import time
from pathlib import Path

from mcp.server.fastmcp import FastMCP

mcp = FastMCP("gui-controller")

DISPLAY = os.environ.get("DISPLAY", ":99")
SCREENSHOT_DIR = Path("gui-controller/screenshots")
SCREENSHOT_DIR.mkdir(parents=True, exist_ok=True)


def _run_xdotool(*args):
    env = os.environ.copy()
    env["DISPLAY"] = DISPLAY
    result = subprocess.run(
        ["xdotool"] + list(args),
        capture_output=True,
        text=True,
        env=env,
        timeout=10,
    )
    return result


def _capture_screenshot():
    import mss
    from PIL import Image

    with mss.mss(display=DISPLAY) as sct:
        monitor = sct.monitors[1]
        screenshot = sct.grab(monitor)
        return Image.frombytes("RGB", screenshot.size, screenshot.bgra, "raw", "BGRX")


@mcp.tool()
def screenshot(filename: str = None) -> str:
    """Take a screenshot of the virtual display and save it. Returns the file path."""
    import base64

    img = _capture_screenshot()
    if filename is None:
        timestamp = time.strftime("%Y%m%d_%H%M%S")
        filename = f"screenshot_{timestamp}.png"
    filepath = str(SCREENSHOT_DIR / filename)
    img.save(filepath)
    return filepath


@mcp.tool()
def click(x: int, y: int, button: int = 1) -> str:
    """Click at the specified (x, y) coordinates on the virtual display. Button: 1=left, 3=right."""
    _run_xdotool("mousemove", "--sync", str(x), str(y))
    time.sleep(0.1)
    _run_xdotool("click", str(button))
    return f"Clicked at ({x}, {y}) with button {button}"


@mcp.tool()
def move_mouse(x: int, y: int) -> str:
    """Move the mouse cursor to the specified (x, y) coordinates."""
    _run_xdotool("mousemove", "--sync", str(x), str(y))
    return f"Mouse moved to ({x}, {y})"


@mcp.tool()
def double_click(x: int, y: int) -> str:
    """Double-click at the specified (x, y) coordinates."""
    _run_xdotool("mousemove", "--sync", str(x), str(y))
    time.sleep(0.1)
    _run_xdotool("click", "--repeat", "2", "--delay", "100", "1")
    return f"Double-clicked at ({x}, {y})"


@mcp.tool()
def drag(x1: int, y1: int, x2: int, y2: int) -> str:
    """Drag from (x1, y1) to (x2, y2) on the virtual display."""
    _run_xdotool("mousemove", "--sync", str(x1), str(y1))
    time.sleep(0.2)
    _run_xdotool("mousedown", "1")
    time.sleep(0.1)
    steps = 10
    for i in range(1, steps + 1):
        x = int(x1 + (x2 - x1) * i / steps)
        y = int(y1 + (y2 - y1) * i / steps)
        _run_xdotool("mousemove", "--sync", str(x), str(y))
        time.sleep(0.05)
    _run_xdotool("mouseup", "1")
    return f"Dragged from ({x1}, {y1}) to ({x2}, {y2})"


@mcp.tool()
def type_text(text: str) -> str:
    """Type the given text using the virtual keyboard."""
    _run_xdotool("type", "--clearmodifiers", text)
    return f"Typed: {text}"


@mcp.tool()
def press_key(key: str) -> str:
    """Press a single key (e.g., 'Return', 'Escape', 'space')."""
    _run_xdotool("key", key)
    return f"Pressed key: {key}"


@mcp.tool()
def key_combo(keys: str) -> str:
    """Press a combination of keys joined by '+' (e.g., 'ctrl+c', 'alt+tab')."""
    _run_xdotool("key", keys)
    return f"Pressed key combo: {keys}"


@mcp.tool()
def scroll(clicks: int, x: int = None, y: int = None) -> str:
    """Scroll at the given position. Positive clicks scroll up, negative down."""
    if x is not None and y is not None:
        _run_xdotool("mousemove", "--sync", str(x), str(y))
    button = "4" if clicks > 0 else "5"
    for _ in range(abs(clicks)):
        _run_xdotool("click", button)
        time.sleep(0.05)
    direction = "up" if clicks > 0 else "down"
    return f"Scrolled {abs(clicks)} clicks {direction}"


@mcp.tool()
def launch_app(command: str, wait: float = 2.0) -> str:
    """Launch a GUI application. Returns the process info."""
    env = os.environ.copy()
    env["DISPLAY"] = DISPLAY
    process = subprocess.Popen(
        command.split(),
        env=env,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )
    time.sleep(wait)
    return f"Launched '{command}' with PID {process.pid}"


@mcp.tool()
def wait_for_window(window_name: str, timeout: int = 30) -> str:
    """Wait for a window with the given name to appear. Returns success/failure."""
    env = os.environ.copy()
    env["DISPLAY"] = DISPLAY
    start = time.time()
    while time.time() - start < timeout:
        result = subprocess.run(
            ["xdotool", "search", "--name", window_name],
            capture_output=True,
            text=True,
            env=env,
        )
        if result.stdout.strip():
            return f"Window '{window_name}' found"
        time.sleep(0.5)
    return f"Window '{window_name}' not found within {timeout}s"


@mcp.tool()
def focus_window(window_name: str) -> str:
    """Focus/activate a window by its name."""
    env = os.environ.copy()
    env["DISPLAY"] = DISPLAY
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
        return f"Focused window '{window_name}'"
    return f"Window '{window_name}' not found"


@mcp.tool()
def get_pixel_color(x: int, y: int) -> str:
    """Get the RGB color of the pixel at (x, y). Returns 'R, G, B'."""
    img = _capture_screenshot()
    color = img.getpixel((x, y))
    return f"RGB({color[0]}, {color[1]}, {color[2]})"


@mcp.tool()
def get_mouse_position() -> str:
    """Get the current mouse position. Returns 'X, Y'."""
    result = _run_xdotool("getmouselocation", "--shell")
    x = y = 0
    for line in result.stdout.strip().split("\n"):
        if line.startswith("X="):
            x = int(line.split("=")[1])
        elif line.startswith("Y="):
            y = int(line.split("=")[1])
    return f"Mouse at ({x}, {y})"


@mcp.tool()
def get_display_info() -> str:
    """Get information about the current virtual display."""
    width = os.environ.get("GUI_WIDTH", "1280")
    height = os.environ.get("GUI_HEIGHT", "720")
    return f"Display: {DISPLAY}, Resolution: {width}x{height}"


if __name__ == "__main__":
    mcp.run()
