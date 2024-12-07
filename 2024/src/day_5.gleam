import gleam/dict
import gleam/int
import gleam/io
import gleam/order

import gleam/list
import gleam/result
import gleam/string
import simplifile as file

type Page =
  List(Int)

type RulesMap =
  dict.Dict(Int, Page)

type PagesList =
  List(Page)

fn generate_rule_map(rules: String) -> RulesMap {
  let rules =
    rules
    |> string.split("\n")
    |> list.map(fn(rule) {
      let rule =
        rule
        |> string.split("|")
        |> list.map(int.parse)
        |> result.values
      let assert [l, r] = rule
      #(l, r)
    })

  use map, rule <- list.fold(rules, dict.new())
  let list = [rule.1, ..dict.get(map, rule.0) |> result.unwrap([])]
  dict.insert(map, rule.0, list)
}

fn generate_page_list(pages: String) -> PagesList {
  pages
  |> string.split("\n")
  |> list.map(fn(page) {
    page
    |> string.split(",")
    |> list.map(int.parse)
    |> result.values
  })
}

// validates parent to be a parent of the given children based on rules
fn is_parent(child: Int, parents: Page, rule: RulesMap) -> Bool {
  let children = dict.get(rule, child) |> result.unwrap([])
  // None of the parents should be a child of the given page
  !{
    parents
    |> list.any(fn(parent) { list.contains(children, parent) })
  }
}

fn validate_page_loop(page: Page, rules: RulesMap, is_valid: Bool) -> Bool {
  case page {
    [] -> is_valid
    [child, ..rest] ->
      is_valid
      && is_parent(child, rest, rules)
      && validate_page_loop(rest, rules, is_valid)
  }
}

fn validate_page(page: Page, rules: RulesMap) -> Bool {
  // Page has to be reversed to ensure no parent are a child of the current element
  validate_page_loop(list.reverse(page), rules, True)
}

fn filter_pages(pages: PagesList, rules: RulesMap) -> #(PagesList, PagesList) {
  pages
  |> list.partition(validate_page(_, rules))
}

fn find_median(page: Page) -> Result(Int, Nil) {
  let total = list.length(page)
  page
  |> list.drop(total / 2)
  |> list.first
}

fn find_median_sum(pages: PagesList) -> Int {
  pages
  |> list.map(find_median)
  |> result.values
  |> int.sum
}

fn compare_page(page1: Int, page2: Int, rules: RulesMap) -> order.Order {
  case is_parent(page1, [page2], rules) {
    True -> order.Gt
    False ->
      case is_parent(page2, [page1], rules) {
        True -> order.Lt
        False -> order.Eq
      }
  }
}

fn fix_page(page: Page, rules: RulesMap) -> Page {
  page
  |> list.sort(fn(a, b) { compare_page(a, b, rules) })
}

pub fn run() {
  let assert Ok(content) = file.read("input/day_5.txt")

  let content = string.split_once(content, "\n\n")
  let assert Ok(#(rules, pages)) = content

  let pages = generate_page_list(pages)
  let rules = generate_rule_map(rules)

  let #(valid, invalid) =
    pages
    |> filter_pages(rules)

  // Section 1
  valid
  |> find_median_sum
  |> io.debug

  // Section 2
  invalid
  |> list.map(fix_page(_, rules))
  |> find_median_sum
  |> io.debug
}
