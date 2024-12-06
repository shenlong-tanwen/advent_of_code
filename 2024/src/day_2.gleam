import gleam/bool
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import simplifile as file

fn parse_level(line: String) -> List(Int) {
  line
  |> string.split(" ")
  |> list.map(string.trim)
  |> list.map(int.base_parse(_, 10))
  |> list.map(result.unwrap(_, 0))
}

fn parse_levels(content: String) -> List(List(Int)) {
  content
  |> string.split("\n")
  |> list.map(parse_level)
}

fn is_valid(a: Int, b: Int) -> Bool {
  let diff = int.absolute_value(a - b)
  diff >= 1 && diff <= 3
}

fn check_strict_increasing(levels: List(Int), is_increasing: Bool) -> Bool {
  case levels {
    [] -> is_increasing
    [_] -> is_increasing
    [first, second, ..rest] ->
      is_increasing
      && check_strict_increasing(
        [second, ..rest],
        first > second && is_valid(first, second),
      )
  }
}

fn check_strict_decreasing(levels: List(Int), is_decreasing: Bool) -> Bool {
  case levels {
    [] -> is_decreasing
    [_] -> is_decreasing
    [first, second, ..rest] ->
      is_decreasing
      && check_strict_decreasing(
        [second, ..rest],
        first < second && is_valid(first, second),
      )
  }
}

fn check_strict_level(level: List(Int)) -> Bool {
  check_strict_increasing(level, True) || check_strict_decreasing(level, True)
}

fn check_strict_levels(levels: List(List(Int))) -> List(Bool) {
  levels
  |> list.map(check_strict_level)
}

fn calculate_valid_level(levels: List(Bool)) -> Int {
  levels
  |> list.map(bool.to_int)
  |> int.sum
}

pub fn run() {
  let assert Ok(content) = file.read("input/day_2.txt")
  let levels = parse_levels(content)

  // Section 1
  levels
  |> check_strict_levels
  |> calculate_valid_level
  |> io.debug

  // Section 2
  levels
  |> list.map(fn(x) { list.combinations(x, list.length(x) - 1) })
  |> list.map(check_strict_levels)
  |> list.map(list.any(_, fn(x) { x }))
  |> calculate_valid_level
  |> io.debug
}
