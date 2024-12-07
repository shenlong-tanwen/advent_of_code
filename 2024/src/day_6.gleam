import gleam/bool
import gleam/dict as d
import gleam/option
import gleam/set

import gleam/io
import gleam/list
import gleam/string
import simplifile as file

type Position {
  Position(x: Int, y: Int)
}

type Element {
  Empty
  Obstacle
  Visited
}

type Guard {
  Guard(pos: Position, dir: Direction)
}

type Direction {
  Up
  Down
  Left
  Right
}

type Map =
  d.Dict(Position, Element)

fn rotate_guard(guard: Guard) -> Guard {
  case guard.dir {
    Up -> Guard(..guard, dir: Right)
    Right -> Guard(..guard, dir: Down)
    Down -> Guard(..guard, dir: Left)
    Left -> Guard(..guard, dir: Up)
  }
}

fn next_move(guard: Guard) -> Position {
  let Guard(pos, dir) = guard
  case dir {
    Up -> Position(pos.x - 1, pos.y)
    Right -> Position(pos.x, pos.y + 1)
    Down -> Position(pos.x + 1, pos.y)
    Left -> Position(pos.x, pos.y - 1)
  }
}

fn get_visited(map: Map) -> set.Set(Position) {
  d.keys(map)
  |> list.filter(fn(x) { d.get(map, x) == Ok(Visited) })
  |> set.from_list
}

fn generate_map(input: String) -> #(Map, Guard) {
  input
  |> string.split("\n")
  |> list.map(string.split(_, ""))
  |> list.index_fold(
    #(d.new(), Guard(dir: Up, pos: Position(-1, -1))),
    fn(acc, row, i) {
      list.index_fold(row, acc, fn(acc, element, j) {
        let #(map, guard) = acc
        let pos = Position(i, j)
        case element {
          "^" -> #(d.insert(map, pos, Visited), Guard(dir: Up, pos: pos))
          "#" -> #(d.insert(map, pos, Obstacle), guard)
          _ -> #(d.insert(map, pos, Empty), guard)
        }
      })
    },
  )
}

fn move(map: Map, guard: Guard) -> Map {
  let curr_pos = guard.pos
  let next_pos = next_move(guard)
  let map = d.insert(map, curr_pos, Visited)
  case d.get(map, next_pos) {
    Ok(element) -> {
      case element {
        Empty | Visited -> move(map, Guard(..guard, pos: next_pos))
        Obstacle -> move(map, rotate_guard(guard))
      }
    }
    // Guard exited the map
    Error(_) -> map
  }
}

// We are in a loop only if the already visited element and direction match
type DirectedElement =
  #(Element, set.Set(Direction))

type DirectedMap =
  d.Dict(Position, DirectedElement)

fn check_cycle(dmap: DirectedMap, guard: Guard) -> Bool {
  let curr_pos = guard.pos
  let next_pos = next_move(guard)
  let dmap =
    d.upsert(dmap, curr_pos, fn(option) {
      case option {
        option.Some(s) -> #(Visited, set.insert(s.1, guard.dir))
        option.None -> #(Visited, set.insert(set.new(), guard.dir))
      }
    })

  case d.get(dmap, next_pos) {
    Ok(val) -> {
      let #(element, direction_list) = val
      case element {
        Visited -> {
          case set.contains(direction_list, guard.dir) {
            True -> True
            False -> check_cycle(dmap, Guard(..guard, pos: next_pos))
          }
        }
        Empty -> check_cycle(dmap, Guard(..guard, pos: next_pos))
        Obstacle -> check_cycle(dmap, rotate_guard(guard))
      }
    }

    Error(_) -> False
  }
}

pub fn run() {
  let assert Ok(content) = file.read("input/day_6.txt")
  let #(map, guard) = generate_map(content)
  let move_map = move(map, guard)

  // Section 1
  move_map
  |> get_visited
  |> set.size
  |> io.debug

  let directed_map =
    map
    |> d.map_values(fn(_, val) { #(val, set.new()) })
  // Section 2
  move_map
  |> get_visited
  // Remove initial position
  |> set.delete(guard.pos)
  |> set.fold(0, fn(count, position) {
    count
    + bool.to_int(check_cycle(
      d.insert(directed_map, position, #(Obstacle, set.new())),
      guard,
    ))
  })
  |> io.debug
}
