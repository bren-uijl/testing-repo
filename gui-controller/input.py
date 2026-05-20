import os
import subprocess
import time
from display import DisplayManager


class InputController:
    def __init__(self, display_manager: DisplayManager):
        self.display = display_manager.display
        self.display_manager = display_manager
        self._env = os.environ.copy()
        self._env["DISPLAY"] = self.display

    def _run_xdotool(self, *args):
        cmd = ["xdotool"] + list(args)
        result = subprocess.run(cmd, capture_output=True, text=True, env=self._env)
        return result

    def _run_xte(self, *args):
        cmd = ["xte", "-x", self.display] + list(args)
        result = subprocess.run(cmd, capture_output=True, text=True)
        return result

    def move_mouse(self, x: int, y: int):
        self._run_xdotool("mousemove", "--sync", str(x), str(y))

    def click(self, x: int = None, y: int = None, button: int = 1):
        if x is not None and y is not None:
            self.move_mouse(x, y)
        time.sleep(0.1)
        self._run_xdotool("click", str(button))

    def double_click(self, x: int = None, y: int = None):
        if x is not None and y is not None:
            self.move_mouse(x, y)
        time.sleep(0.1)
        self._run_xdotool("click", "--repeat", "2", "--delay", "100", "1")

    def right_click(self, x: int = None, y: int = None):
        if x is not None and y is not None:
            self.move_mouse(x, y)
        time.sleep(0.1)
        self._run_xdotool("click", "3")

    def drag(self, x1: int, y1: int, x2: int, y2: int, duration: float = 0.5):
        self.move_mouse(x1, y1)
        time.sleep(0.2)
        self._run_xdotool("mousedown", "1")
        time.sleep(0.1)
        steps = max(int(duration * 20), 5)
        for i in range(1, steps + 1):
            x = int(x1 + (x2 - x1) * i / steps)
            y = int(y1 + (y2 - y1) * i / steps)
            self.move_mouse(x, y)
            time.sleep(duration / steps)
        self._run_xdotool("mouseup", "1")

    def key_press(self, key: str):
        self._run_xdotool("key", key)

    def type_text(self, text: str):
        self._run_xdotool("type", "--clearmodifiers", text)

    def key_down(self, key: str):
        self._run_xdotool("keydown", key)

    def key_up(self, key: str):
        self._run_xdotool("keyup", key)

    def key_combo(self, *keys: str):
        self._run_xdotool("key", "+".join(keys))

    def get_mouse_position(self) -> tuple:
        result = self._run_xdotool("getmouselocation", "--shell")
        output = result.stdout
        x = y = 0
        for line in output.strip().split("\n"):
            if line.startswith("X="):
                x = int(line.split("=")[1])
            elif line.startswith("Y="):
                y = int(line.split("=")[1])
        return (x, y)

    def scroll(self, clicks: int, x: int = None, y: int = None):
        if x is not None and y is not None:
            self.move_mouse(x, y)
        button = "4" if clicks > 0 else "5"
        for _ in range(abs(clicks)):
            self._run_xdotool("click", button)
            time.sleep(0.05)
