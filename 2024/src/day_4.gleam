import gleam/bool
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import simplifile as file

type Update {
  Update(row: Int, col: Int)
}

type Finder =
  fn(List(List(String)), String, Int, Int, Int, Int) -> Int

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

fn runner_int(
  grid: List(List(String)),
  row: Int,
  col: Int,
  max_row: Int,
  max_col: Int,
  target: String,
  acc: Int,
  finder: Finder,
) -> Int {
  case row > max_row - 1 {
    True -> acc
    False -> {
      case col > max_col - 1 {
        False ->
          acc
          + finder(grid, target, row, col, max_row, max_col)
          + runner_int(
            grid,
            row,
            col + 1,
            max_row,
            max_col,
            target,
            acc,
            finder,
          )

        True ->
          runner_int(grid, row + 1, 0, max_row, max_col, target, acc, finder)
      }
    }
  }
}

fn runner(grid: List(List(String)), target: String, finder: Finder) -> Int {
  let rows = list.length(grid)
  let cols = grid |> list.first |> result.unwrap([]) |> list.length

  runner_int(grid, 0, 0, rows, cols, target, 0, finder)
}

// =========== SECTION 1

const updates_x_mas = [
  Update(0, 1),
  Update(0, -1),
  Update(1, 0),
  Update(-1, 0),
  Update(1, 1),
  Update(-1, -1),
  Update(1, -1),
  Update(-1, 1),
]

fn find_x_mas_int(
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
          find_x_mas_int(
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

fn find_x_mas(
  grid: List(List(String)),
  target: String,
  row: Int,
  col: Int,
  max_row: Int,
  max_col: Int,
) -> Int {
  use a, upd <- list.fold(updates_x_mas, 0)
  a + find_x_mas_int(grid, upd, target, row, col, max_row, max_col, "")
}

// =========== SECTION 2

const updates_mas = #(
  #(Update(1, 1), Update(-1, -1)),
  #(Update(1, -1), Update(-1, 1)),
)

// TODO: only matches string of length - 3, can be easily extended to match arbitrary length of string though
fn find_mas_int(
  grid: List(List(String)),
  row: Int,
  col: Int,
  max_row: Int,
  max_col: Int,
  update_pair: #(Update, Update),
) -> String {
  get_char_at(
    grid,
    row + { update_pair.0 }.row,
    col + { update_pair.0 }.col,
    max_row,
    max_col,
  )
  <> get_char_at(grid, row, col, max_row, max_col)
  <> get_char_at(
    grid,
    row + { update_pair.1 }.row,
    col + { update_pair.1 }.col,
    max_row,
    max_col,
  )
}

fn find_mas(
  grid: List(List(String)),
  target: String,
  row: Int,
  col: Int,
  max_row: Int,
  max_col: Int,
) -> Int {
  let left = find_mas_int(grid, row, col, max_row, max_col, updates_mas.0)
  let right = find_mas_int(grid, row, col, max_row, max_col, updates_mas.1)

  let left_match = left == target || string.reverse(left) == target
  let right_match = right == target || string.reverse(right) == target
  bool.to_int(left_match && right_match)
}

pub fn run() {
  let assert Ok(content) = file.read("input/day_4.txt")
  let matrix =
    content
    |> string.split("\n")
    |> list.map(string.split(_, ""))

  runner(matrix, "XMAS", find_x_mas)
  |> io.debug

  runner(matrix, "MAS", find_mas)
  |> io.debug
}
