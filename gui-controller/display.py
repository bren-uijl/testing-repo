import subprocess
from dataclasses import dataclass


@dataclass
class Resolution:
    width: int
    height: int
    depth: int = 24

    @property
    def geometry(self) -> str:
        return f"{self.width}x{self.height}x{self.depth}"

    @classmethod
    def hd(cls) -> "Resolution":
        return cls(1280, 720)

    @classmethod
    def full_hd(cls) -> "Resolution":
        return cls(1920, 1080)

    @classmethod
    def quarter_hd(cls) -> "Resolution":
        return cls(960, 540)

    @classmethod
    def low(cls) -> "Resolution":
        return cls(640, 480)


class DisplayManager:
    def __init__(self, resolution: Resolution = None):
        self.resolution = resolution or Resolution.full_hd()
        self.display_num = 99
        self.display = f":{self.display_num}"
        self._xvfb_process = None

    def start(self):
        cmd = [
            "Xvfb",
            self.display,
            "-screen", "0",
            self.resolution.geometry,
            "-ac",
            "+extension", "GLX",
            "+render",
            "-noreset",
        ]
        self._xvfb_process = subprocess.Popen(
            cmd,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
        import time
        time.sleep(1)
        return self.display

    def stop(self):
        if self._xvfb_process:
            self._xvfb_process.terminate()
            self._xvfb_process.wait()
            self._xvfb_process = None

    def set_resolution(self, resolution: Resolution):
        self.resolution = resolution
        if self._xvfb_process:
            self.stop()
            self.start()

    @property
    def center(self) -> tuple:
        return (self.resolution.width // 2, self.resolution.height // 2)
