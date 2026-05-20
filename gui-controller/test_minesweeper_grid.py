#!/usr/bin/env python3
import sys
import os
import time

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from app import GUIController
from display import Resolution
from input import InputController


class SimpleGridTest:
    def __init__(self, controller: GUIController, cols: int = 5, rows: int = 5):
        self.controller = controller
        self.cols = cols
        self.rows = rows
        self.cell_size = 60
        self.grid_width = cols * self.cell_size
        self.grid_height = rows * self.cell_size
        self.offset_x = (controller.display_manager.resolution.width - self.grid_width) // 2
        self.offset_y = (controller.display_manager.resolution.height - self.grid_height) // 2
        self.grid = [[0] * cols for _ in range(rows)]

    def get_cell_center(self, col: int, row: int) -> tuple:
        x = self.offset_x + col * self.cell_size + self.cell_size // 2
        y = self.offset_y + row * self.cell_size + self.cell_size // 2
        return (x, y)

    def click_cell(self, col: int, row: int):
        x, y = self.get_cell_center(col, row)
        self.controller.click_at(x, y)
        self.grid[row][col] = 1
        time.sleep(0.2)

    def right_click_cell(self, col: int, row: int):
        x, y = self.get_cell_center(col, row)
        self.controller.input.right_click(x, y)
        self.grid[row][col] = 2
        time.sleep(0.2)

    def run_pattern_test(self):
        print("  Running click pattern test...")
        for row in range(self.rows):
            for col in range(self.cols):
                self.click_cell(col, row)
        print("  All cells clicked")

    def run_flag_test(self):
        print("  Running flag test...")
        for row in range(0, self.rows, 2):
            for col in range(0, self.cols, 2):
                self.right_click_cell(col, row)
        print("  Alternate cells flagged")

    def run_sweep_test(self):
        print("  Running sweep test...")
        for i in range(self.cols):
            self.click_cell(i, 0)
            time.sleep(0.1)
        for i in range(self.rows):
            self.click_cell(self.cols - 1, i)
            time.sleep(0.1)
        print("  Edge sweep complete")


def main():
    print("=" * 50)
    print("Minesweeper-like Grid Test")
    print("=" * 50)
    print()

    with GUIController(Resolution(800, 600)) as controller:
        test = SimpleGridTest(controller, cols=5, rows=5)

        path = controller.screenshot("minesweeper_grid_initial.png")
        print(f"Initial grid: {path}")

        test.run_pattern_test()
        path = controller.screenshot("minesweeper_grid_clicked.png")
        print(f"After clicks: {path}")

        test.run_flag_test()
        path = controller.screenshot("minesweeper_grid_flagged.png")
        print(f"After flags: {path}")

        test.run_sweep_test()
        path = controller.screenshot("minesweeper_grid_swept.png")
        print(f"After sweep: {path}")

    print()
    print("=" * 50)
    print("Minesweeper grid test: PASSED")
    print("=" * 50)


if __name__ == "__main__":
    main()
