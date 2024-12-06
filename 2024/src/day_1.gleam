import gleam/int
import gleam/io
import gleam/list
import gleam/string
import simplifile as file

// =========== COMMON

fn parse_line(line: String) -> #(Int, Int) {
  let pairs =
    line
    |> string.split("  ")
    |> list.map(string.trim)
    |> list.map(int.base_parse(_, 10))

  case pairs {
    [Ok(a), Ok(b)] -> #(a, b)
    _ -> #(0, 0)
  }
}

fn get_lists(content: String) -> #(List(Int), List(Int)) {
  let lines =
    content
    |> string.split("\n")
    |> list.map(parse_line)

  let first =
    lines
    |> list.map(fn(x) { x.0 })
  let second =
    lines
    |> list.map(fn(x) { x.1 })

  #(first, second)
}

// =========== SECTION 1

fn sort_and_collect_lists(lists: #(List(Int), List(Int))) -> List(#(Int, Int)) {
  let first = list.sort(lists.0, int.compare)
  let second = list.sort(lists.1, int.compare)

  list.zip(first, second)
}

fn calculate_diff(pair: #(Int, Int)) -> Int {
  int.absolute_value(pair.0 - pair.1)
}

fn calculate_total_diff(pairs: List(#(Int, Int))) -> Int {
  pairs
  |> list.map(calculate_diff)
  |> int.sum
}

// =========== SECTION 2

fn calculate_similarity(num: Int, other_list: List(Int)) -> Int {
  let count =
    other_list
    |> list.count(fn(x) { x == num })
  num * count
}

fn calculate_total_similarity(lists: #(List(Int), List(Int))) -> Int {
  lists.0
  |> list.map(calculate_similarity(_, lists.1))
  |> int.sum
}

pub fn run() {
  let assert Ok(content) = file.read("input/day_1.txt")
  let lists = get_lists(content)

  // Section 1
  lists
  |> sort_and_collect_lists
  |> calculate_total_diff
  |> io.debug

  // Section 2
  lists
  |> calculate_total_similarity
  |> io.debug
}
