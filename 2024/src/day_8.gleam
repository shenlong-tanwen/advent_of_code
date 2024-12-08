import gleam/dict as d
import gleam/io
import gleam/list
import gleam/option
import gleam/set
import gleam/string
import simplifile as file

type Position {
  Position(x: Int, y: Int)
}

type MapConstraints {
  MapConstraints(rows: Int, cols: Int)
}

type AntennaLoc =
  d.Dict(String, List(Position))

fn generate_map(input: String) -> #(AntennaLoc, MapConstraints) {
  let map =
    input
    |> string.split("\n")
    |> list.map(string.split(_, ""))
  use acc, row, i <- list.index_fold(map, #(d.new(), MapConstraints(0, 0)))
  use acc, element, j <- list.index_fold(row, acc)
  let #(amap, _) = acc
  let constraints = MapConstraints(i + 1, j + 1)
  case element {
    "." -> #(amap, constraints)
    freq -> {
      let pos = Position(i + 1, j + 1)
      #(
        d.upsert(amap, freq, fn(o) {
          case o {
            option.Some(l) -> [pos, ..l]
            option.None -> [pos]
          }
        }),
        constraints,
      )
    }
  }
}

fn is_valid_antinode(pos: Position, max: MapConstraints) -> Bool {
  pos.x > 0 && pos.x <= max.rows && pos.y > 0 && pos.y <= max.cols
}

fn find_antinodes(
  antinodes: set.Set(Position),
  antenna_pair: #(Position, Position),
) -> set.Set(Position) {
  let #(a, b) = antenna_pair

  let row_diff = a.x - b.x
  let col_diff = a.y - b.y
  let l = Position(a.x + row_diff, a.y + col_diff)
  let r = Position(b.x - row_diff, b.y - col_diff)

  antinodes
  |> set.insert(l)
  |> set.insert(r)
}

fn find_antinodes_resonance_loop(
  antinodes: set.Set(Position),
  antenna: Position,
  diff: Position,
  max: MapConstraints,
) -> set.Set(Position) {
  let antinode = Position(antenna.x - diff.x, antenna.y - diff.y)
  case is_valid_antinode(antinode, max) {
    False -> antinodes
    True -> {
      antinodes
      |> set.insert(antinode)
      |> find_antinodes_resonance_loop(antinode, diff, max)
    }
  }
}

fn find_antinodes_resonance(
  antinodes: set.Set(Position),
  antenna_pair: #(Position, Position),
  max: MapConstraints,
) -> set.Set(Position) {
  let #(a, b) = antenna_pair

  let row_diff = a.x - b.x
  let col_diff = a.y - b.y

  let rdiff = Position(row_diff, col_diff)
  let ldiff = Position(-row_diff, -col_diff)

  // Looping over both antennas to get overlapping antinodes
  antinodes
  |> find_antinodes_resonance_loop(a, rdiff, max)
  |> find_antinodes_resonance_loop(b, rdiff, max)
  |> find_antinodes_resonance_loop(a, ldiff, max)
  |> find_antinodes_resonance_loop(b, ldiff, max)
}

pub fn run() {
  let assert Ok(content) = file.read("input/day_8.txt")
  let #(map, max) = generate_map(content)
  let antennas =
    map
    |> d.map_values(fn(_, values) { list.combination_pairs(values) })
    |> d.values
    |> list.flatten

  // Section 1
  antennas
  |> list.fold(set.new(), find_antinodes)
  |> set.filter(is_valid_antinode(_, max))
  |> set.size
  |> io.debug

  // Section 2
  antennas
  |> list.fold(set.new(), fn(acc, x) { find_antinodes_resonance(acc, x, max) })
  |> set.size
  |> io.debug
}
