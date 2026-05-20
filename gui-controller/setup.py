from setuptools import setup, find_packages

setup(
    name="gui-controller",
    version="1.0.0",
    description="GUI interaction controller for Ubuntu with virtual display support",
    packages=find_packages(),
    install_requires=[
        "Pillow>=10.0.0",
        "mss>=9.0.0",
        "pyautogui>=0.9.54",
        "python-xlib>=0.33",
    ],
    python_requires=">=3.8",
    entry_points={
        "console_scripts": [
            "gui-controller=app:main",
            "minesweeper-player=minesweeper:main",
        ],
    },
)
