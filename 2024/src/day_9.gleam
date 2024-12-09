import gleam/int
import gleam/io
import gleam/list
import gleam/option
import gleam/string
import simplifile as file

type DiskElement {
  Space
  File(id: Int)
}

type Memory =
  List(DiskElement)

fn generate_layout_1(input: String) -> Memory {
  let out =
    input
    |> string.split("")
    |> list.index_fold(#(list.new(), 0), fn(acc, val, index) {
      let #(layout, id) = acc
      let assert Ok(count) = int.parse(val)
      case index % 2 == 0 {
        True -> #(list.append(layout, list.repeat(File(id), count)), id + 1)
        False -> #(list.append(layout, list.repeat(Space, count)), id)
      }
    })

  out.0
}

fn compress_layout_loop_1(
  compressed: Memory,
  actual: Memory,
  reversed: Memory,
  ai: Int,
  ri: Int,
) -> Memory {
  case ai <= ri {
    False -> compressed
    True -> {
      let assert [af, ..arest] = actual
      let assert [rf, ..rrest] = reversed

      case af, rf {
        File(id), File(_) ->
          compress_layout_loop_1(
            [File(id), ..compressed],
            arest,
            reversed,
            ai + 1,
            ri,
          )

        File(id), Space ->
          compress_layout_loop_1(
            [File(id), ..compressed],
            arest,
            rrest,
            ai + 1,
            ri - 1,
          )
        Space, File(id) ->
          compress_layout_loop_1(
            [File(id), ..compressed],
            arest,
            rrest,
            ai + 1,
            ri - 1,
          )
        Space, Space ->
          compress_layout_loop_1(compressed, actual, rrest, ai, ri - 1)
      }
    }
  }
}

fn compress_layout_1(memory: Memory) -> Memory {
  compress_layout_loop_1(
    list.new(),
    memory,
    list.reverse(memory),
    0,
    list.length(memory) - 1,
  )
  |> list.reverse
}

fn generate_layout_2(input: String) -> MemoryCount {
  let out =
    input
    |> string.split("")
    |> list.index_fold(#(list.new(), 0), fn(acc, val, index) {
      let #(layout, id) = acc
      let assert Ok(count) = int.parse(val)
      case index % 2 == 0 {
        True -> #(list.append(layout, [FileCount(count, id)]), id + 1)
        False -> {
          case count == 0 {
            True -> #(layout, id)
            False -> #(list.append(layout, [SpaceCount(count)]), id)
          }
        }
      }
    })

  out.0
}

type DiskElementCount {
  SpaceCount(count: Int)
  FileCount(count: Int, id: Int)
}

type MemoryCount =
  List(DiskElementCount)

fn calculate_checksum(memory: Memory) -> Int {
  memory
  |> list.index_fold(0, fn(sum, element, index) {
    case element {
      Space -> sum
      File(id) -> sum + id * index
    }
  })
}

fn find_first_space_for_count_loop(
  index: Int,
  memory: MemoryCount,
  count: Int,
) -> option.Option(#(DiskElementCount, Int)) {
  case memory {
    [] -> option.None
    [first, ..rest] ->
      case first {
        SpaceCount(avail) if avail >= count ->
          option.Some(#(SpaceCount(avail), index))
        _ -> find_first_space_for_count_loop(index + 1, rest, count)
      }
  }
}

fn find_first_space_for_count(
  memory: MemoryCount,
  count: Int,
) -> option.Option(#(DiskElementCount, Int)) {
  find_first_space_for_count_loop(0, memory, count)
}

fn find_first_index_for_element_rev_loop(
  rev_index: Int,
  memory: MemoryCount,
  id: Int,
) -> Int {
  case memory {
    [] -> -1
    [first, ..rest] ->
      case first {
        FileCount(_, fid) if fid == id -> rev_index
        _ -> find_first_index_for_element_rev_loop(rev_index - 1, rest, id)
      }
  }
}

fn find_first_index_for_element_rev(memory: MemoryCount, id: Int) -> Int {
  find_first_index_for_element_rev_loop(
    list.length(memory),
    list.reverse(memory),
    id,
  )
}

fn compress_layout_2_loop(
  actual: MemoryCount,
  reversed: MemoryCount,
) -> MemoryCount {
  case reversed {
    [] -> actual
    [SpaceCount(_), ..rest] -> compress_layout_2_loop(actual, rest)
    [FileCount(count, id), ..rest] -> {
      let element = find_first_space_for_count(actual, count)
      case element {
        option.None -> compress_layout_2_loop(actual, rest)
        option.Some(#(element, index)) -> {
          compress_layout_2_loop(
            swap_memory(actual, index, element, FileCount(count, id)),
            rest,
          )
        }
      }
    }
  }
}

fn compress_layout_2(memory: MemoryCount) -> MemoryCount {
  compress_layout_2_loop(memory, list.reverse(memory))
}

fn swap_memory(
  memory: MemoryCount,
  first_index: Int,
  first: DiskElementCount,
  second: DiskElementCount,
) -> MemoryCount {
  case first.count >= second.count {
    False -> memory
    True -> {
      let first_prev = list.take(memory, first_index)
      let first_rest = list.drop(memory, first_index + 1)
      // update first element
      let memory =
        first_prev
        |> list.append(case first.count - second.count == 0 {
          True -> [second]
          False -> [second, SpaceCount(first.count - second.count)]
        })
        |> list.append(first_rest)

      let assert FileCount(_, id) = second
      let index = find_first_index_for_element_rev(memory, id) - 1
      // update last element
      let second_prev = list.take(memory, index)
      let second_rest = list.drop(memory, index + 1)

      second_prev
      |> list.append([SpaceCount(second.count)])
      |> list.append(second_rest)
    }
  }
}

fn map_to_memory(memory: MemoryCount) -> Memory {
  memory
  |> list.flat_map(fn(element) {
    case element {
      SpaceCount(count) -> list.repeat(Space, count)
      FileCount(count, id) -> list.repeat(File(id), count)
    }
  })
}

pub fn run() {
  let assert Ok(content) = file.read("input/day_9.txt")

  // Section 1
  generate_layout_1(content)
  |> compress_layout_1
  |> calculate_checksum
  |> io.debug

  // Section 2
  generate_layout_2(content)
  |> compress_layout_2
  |> map_to_memory
  |> calculate_checksum
  |> io.debug
}
