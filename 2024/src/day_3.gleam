import gleam/int
import gleam/io
import gleam/list
import gleam/option
import gleam/regexp
import gleam/string
import simplifile as file

fn parse(str: String) -> Int {
  let assert Ok(reg) = regexp.from_string("mul\\((\\d{1,9}),(\\d{1,9})\\)")
  let matches = regexp.scan(reg, str)
  use acc, match <- list.fold(matches, 0)
  case match.submatches {
    [option.Some(a), option.Some(b)] -> {
      case int.base_parse(a, 10), int.base_parse(b, 10) {
        Ok(a), Ok(b) -> acc + { a * b }
        _, _ -> 0
      }
    }
    _ -> 0
  }
}

fn parse_condition(str: String) -> Int {
  let assert Ok(reg) = regexp.from_string("don't\\(\\).*")

  // Only the first mul is enabled, all the other muls in the new lines should be processed based on the state
  // So join all line to form a single input
  str
  |> string.replace("\n", "")
  |> string.split("do()")
  |> list.map(regexp.replace(reg, _, ""))
  |> list.map(parse)
  |> int.sum
}

pub fn compute(input: String) -> Int {
  let assert Ok(donts) = regexp.from_string("don't\\(\\).*$")

  string.replace(input, each: "\n", with: "")
  |> string.split(on: "do()")
  |> list.map(regexp.replace(donts, _, ""))
  |> string.join("do()")
  |> parse
}

pub fn run() {
  let assert Ok(content) = file.read("input/day_3.txt")

  // Section 1
  parse(content)
  |> io.debug

  // Section 2
  parse_condition(content)
  |> io.debug
}
