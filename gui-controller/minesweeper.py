#!/usr/bin/env python3
import time
from typing import Optional

from PIL import Image

from app import GUIController
from display import Resolution
from screenshot import ScreenshotManager


class CellState:
    EMPTY = 0
    MINE = 1
    FLAGGED = 2
    REVEALED = 3
    UNKNOWN = 4


class MinesweeperPlayer:
    GRID_OFFSET_X = 0
    GRID_OFFSET_Y = 0
    CELL_SIZE = 0
    COLS = 9
    ROWS = 9
    MINES = 10

    COLOR_UNREVEALED = (192, 192, 192)
    COLOR_REVEALED = (210, 210, 210)
    COLOR_FLAG = (255, 0, 0)
    COLOR_MINE = (0, 0, 0)

    def __init__(self, controller: GUIController):
        self.controller = controller
        self.grid = [[CellState.UNKNOWN] * self.COLS for _ in range(self.ROWS)]
        self._calibrated = False

    def calibrate(self):
        screenshot = self.controller.screenshot.screenshot_manager.capture()
        width, height = screenshot.size

        self.CELL_SIZE = min(width // (self.COLS + 4), height // (self.ROWS + 6))
        self.GRID_OFFSET_X = (width - self.CELL_SIZE * self.COLS) // 2
        self.GRID_OFFSET_Y = height // 6

        self._calibrated = True
        print(f"Calibrated: cell_size={self.CELL_SIZE}, offset=({self.GRID_OFFSET_X}, {self.GRID_OFFSET_Y})")

    def get_cell_center(self, col: int, row: int) -> tuple:
        x = self.GRID_OFFSET_X + col * self.CELL_SIZE + self.CELL_SIZE // 2
        y = self.GRID_OFFSET_Y + row * self.CELL_SIZE + self.CELL_SIZE // 2
        return (x, y)

    def reveal_cell(self, col: int, row: int):
        if not (0 <= col < self.COLS and 0 <= row < self.ROWS):
            return
        x, y = self.get_cell_center(col, row)
        self.controller.click_at(x, y)
        time.sleep(0.1)

    def flag_cell(self, col: int, row: int):
        if not (0 <= col < self.COLS and 0 <= row < self.ROWS):
            return
        x, y = self.get_cell_center(col, row)
        self.controller.input.right_click(x, y)
        time.sleep(0.1)

    def analyze_grid(self) -> list:
        screenshot = self.controller.screenshot.capture()
        result = []
        for row in range(self.ROWS):
            row_data = []
            for col in range(self.COLS):
                x, y = self.get_cell_center(col, row)
                color = screenshot.getpixel((x, y))
                state = self._classify_cell(color)
                row_data.append(state)
            result.append(row_data)
        return result

    def _classify_cell(self, color: tuple) -> int:
        r, g, b = color[:3]
        brightness = (r + g + b) / 3

        if brightness < 50:
            return CellState.MINE
        elif r > 200 and g < 100 and b < 100:
            return CellState.FLAGGED
        elif brightness > 180:
            return CellState.UNREVEALED
        else:
            return CellState.REVEALED

    def read_number(self, col: int, row: int) -> Optional[int]:
        x, y = self.get_cell_center(col, row)
        screenshot = self.controller.screenshot.capture()
        color = screenshot.getpixel((x, y))

        number_colors = {
            (0, 0, 255): 1,
            (0, 128, 0): 2,
            (255, 0, 0): 3,
            (0, 0, 128): 4,
            (128, 0, 0): 5,
            (0, 128, 128): 6,
            (0, 0, 0): 7,
            (128, 128, 128): 8,
        }

        for num_color, num in number_colors.items():
            if (
                abs(color[0] - num_color[0]) < 50
                and abs(color[1] - num_color[1]) < 50
                and abs(color[2] - num_color[2]) < 50
            ):
                return num
        return None

    def solve_step(self) -> bool:
        grid = self.analyze_grid()
        made_move = False

        for row in range(self.ROWS):
            for col in range(self.COLS):
                number = self.read_number(col, row)
                if number is None:
                    continue

                adjacent = self._get_adjacent(col, row)
                unrevealed = [(c, r) for c, r in adjacent if grid[r][c] == CellState.UNREVEALED]
                flagged = [(c, r) for c, r in adjacent if grid[r][c] == CellState.FLAGGED]

                if len(flagged) == number and unrevealed:
                    for c, r in unrevealed:
                        self.reveal_cell(c, r)
                        made_move = True
                        time.sleep(0.2)

                if len(unrevealed) + len(flagged) == number and unrevealed:
                    for c, r in unrevealed:
                        self.flag_cell(c, r)
                        made_move = True
                        time.sleep(0.2)

        return made_move

    def _get_adjacent(self, col: int, row: int) -> list:
        adjacent = []
        for dr in range(-1, 2):
            for dc in range(-1, 2):
                if dr == 0 and dc == 0:
                    continue
                nc, nr = col + dc, row + dr
                if 0 <= nc < self.COLS and 0 <= nr < self.ROWS:
                    adjacent.append((nc, nr))
        return adjacent

    def play(self, max_iterations: int = 100):
        print("Starting minesweeper...")
        self.calibrate()

        time.sleep(1)
        self.reveal_cell(self.COLS // 2, self.ROWS // 2)
        time.sleep(1)

        for i in range(max_iterations):
            print(f"Iteration {i + 1}/{max_iterations}")
            made_move = self.solve_step()

            if not made_move:
                print("No logical moves found, trying random safe cell...")
                grid = self.analyze_grid()
                for row in range(self.ROWS):
                    for col in range(self.COLS):
                        if grid[row][col] == CellState.UNREVEALED:
                            self.reveal_cell(col, row)
                            time.sleep(0.5)
                            made_move = True
                            break
                    if made_move:
                        break

            if not made_move:
                print("No more moves possible")
                break

            screenshot_path = self.controller.screenshot.capture_and_save(f"minesweeper_step_{i+1}.png")
            print(f"Screenshot: {screenshot_path}")

        print("Game complete!")


def main():
    resolution = Resolution(1024, 768)

    with GUIController(resolution) as controller:
        print("Launching gnome-mines...")
        controller.launch_app("gnome-mines", wait=3.0)

        player = MinesweeperPlayer(controller)
        player.COLS = 9
        player.ROWS = 9
        player.MINES = 10
        player.play(max_iterations=50)


if __name__ == "__main__":
    main()
