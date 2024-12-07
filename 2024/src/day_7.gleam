import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import simplifile as file

type Equations =
  List(Int)

type Calibration {
  Calibration(total: Int, equations: Equations)
}

type Calibrations =
  List(Calibration)

type Operation =
  fn(Int, Int) -> Int

fn validate_calibration(
  calibration: Calibration,
  operations: List(Operation),
) -> Bool {
  case calibration.equations {
    [x] -> x == calibration.total
    [x, y, ..rest] -> {
      operations
      |> list.any(fn(o) {
        validate_calibration(
          Calibration(calibration.total, [o(x, y), ..rest]),
          operations,
        )
      })
    }
    _ -> False
  }
}

fn parse_input(input: String) -> Calibrations {
  input
  |> string.split("\n")
  |> list.map(fn(line) {
    let assert [total_str, equation] = string.split(line, ": ")
    let assert Ok(total) = int.parse(total_str)
    let equation =
      equation
      |> string.split(" ")
      |> list.filter_map(int.parse)
    Calibration(total, equation)
  })
}

fn concat(a: Int, b: Int) -> Int {
  let a = int.to_string(a)
  let b = int.to_string(b)

  int.parse(a <> b) |> result.unwrap(0)
}

pub fn run() {
  let assert Ok(content) = file.read("input/day_7.txt")
  let calibrations = parse_input(content)

  // Section 1
  calibrations
  |> list.filter(fn(c) { validate_calibration(c, [int.add, int.multiply]) })
  |> list.map(fn(x) { x.total })
  |> list.fold(0, int.add)
  |> io.debug

  // Section 2
  calibrations
  |> list.filter(fn(c) {
    validate_calibration(c, [int.add, int.multiply, concat])
  })
  |> list.map(fn(x) { x.total })
  |> list.fold(0, int.add)
  |> io.debug
}
