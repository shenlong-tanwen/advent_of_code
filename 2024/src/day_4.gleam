import gleam/io
import gleam/list
import gleam/result
import gleam/string
import simplifile as file

type Update {
  Update(row: Int, col: Int)
}

const updates = [
  Update(0, 1),
  Update(0, -1),
  Update(1, 0),
  Update(-1, 0),
  Update(1, 1),
  Update(-1, -1),
  Update(1, -1),
  Update(-1, 1),
]

fn get_char_at(
  grid: List(List(String)),
  row: Int,
  col: Int,
  max_row: Int,
  max_col: Int,
) -> String {
  case row < 0 || row > max_row {
    True -> "."
    False -> {
      let curr_row = grid |> list.drop(row) |> list.first |> result.unwrap([])
      case col < 0 || col > max_col {
        True -> "."
        False -> curr_row |> list.drop(col) |> list.first |> result.unwrap(".")
      }
    }
  }
}

fn move_int(
  grid: List(List(String)),
  update: Update,
  target: String,
  row: Int,
  col: Int,
  max_row: Int,
  max_col: Int,
  acc: String,
) -> Int {
  case acc == target {
    True -> 1

    False ->
      case string.starts_with(target, acc) {
        False -> 0
        True ->
          move_int(
            grid,
            update,
            target,
            row + update.row,
            col + update.col,
            max_row,
            max_col,
            acc <> get_char_at(grid, row, col, max_row, max_col),
          )
      }
  }
}

fn move(
  grid: List(List(String)),
  update: Update,
  target: String,
  row: Int,
  col: Int,
  max_row: Int,
  max_col: Int,
) -> Int {
  move_int(grid, update, target, row, col, max_row, max_col, "")
}

fn runner_int(
  grid: List(List(String)),
  row: Int,
  col: Int,
  max_row: Int,
  max_col: Int,
  target: String,
  acc: Int,
) -> Int {
  case row > max_row - 1 {
    True -> acc
    False -> {
      case col > max_col - 1 {
        False ->
          acc
          + {
            use a, upd <- list.fold(updates, 0)
            a + move(grid, upd, target, row, col, max_row, max_col)
          }
          + runner_int(grid, row, col + 1, max_row, max_col, target, acc)

        True -> runner_int(grid, row + 1, 0, max_row, max_col, target, acc)
      }
    }
  }
}

fn runner(grid: List(List(String)), target: String) -> Int {
  let rows = list.length(grid)
  let cols = grid |> list.first |> result.unwrap([]) |> list.length

  runner_int(grid, 0, 0, rows, cols, target, 0)
}

pub fn run() {
  let assert Ok(content) = file.read("input/day_4.txt")
  let matrix =
    content
    |> string.split("\n")
    |> list.map(string.split(_, ""))

  runner(matrix, "XMAS")
  |> io.debug
}
