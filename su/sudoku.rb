
def seed
  box0 = [*1..9].shuffle
  box1r1 = ([*1..9] - box0[..2]).shuffle[..2]

  while true
    box1r2 = ([*1..9] - box1r1 - box0[3..5]).shuffle[..2]
    box1r3 = ([*1..9] - box1r1 - box1r2 - box0[6..9]).shuffle[..2]
    break if box1r3.size == 3
  end

  def complete(a)
    a + ([*1..9] - a).shuffle
  end
  row1 = complete(box0[..2] + box1r1)
  row2 = complete(box0[3..5] + box1r2)
  row3 = complete(box0[6..] + box1r3)

  rows = [row1, row2, row3]
  col1 = complete([row1[0], row2[0], row3[0]])
  6.times { |i| rows << [col1[i+3]] + [0]*8 }

  rows
end

def random_filled_cell(s)
  while true
    r, c = [rand(9), rand(9)]
    return [r, c] if s.grid.rows[r][c] != 0
  end
end

def random_empty_cell(s)
  while true
    r, c = [rand(9), rand(9)]
    return [r, c] if s.grid.rows[r][c] == 0
  end
end

def score(s)
  s.bf*100 + s.grid.rows.sum { |row| row.count { |cell| cell == 0 } }
end

def gen(try_goal=9999999)
  solution = solve_first(init_sudoku(seed))
  best = deep_copy_sudoku(solution)
  best.bf = 0
  best_score = score(best)
  catch :done do
    # Would use Timeout::timeout but no thread support in wasm yet
    100.times do
      new = deep_copy_sudoku(best)
      5.times do
        if rand(2) == 1 || done?(new)
          r, c = random_filled_cell(new)
          new.grid.rows[r][c] = 0
        else
          r, c = random_empty_cell(new)
          new.grid.rows[r][c] = solution.grid.rows[r][c]
        end

        one_sol = one_solution?(init_sudoku(new.grid.rows))
        next if !one_sol

        new.bf = one_sol.bf
        next if score(new) <= best_score

        best = deep_copy_sudoku(new)
        best_score = score(best)
        throw :done if best_score >= try_goal
      end
    end
  end
  {puzzle: best.grid.rows, solution: solution.grid.rows, score: best_score}
end

def test
  score = []
  500.times do
    p Benchmark.measure {
      r = gen(48)
      pp r
      score << r[:score]
    }.total
  end
  pp score.group_by { _1/100 }.transform_values { _1.size }.sort_by {_1}
end


def nums(array)
  array.filter { _1 != 0 }
end

def possible_positions(grid)
  grid.rows.map.with_index { |row, r|
    row.map.with_index { |num, c|
      next unless num == 0
      in_row = nums(grid.rows[r])
      in_col = nums(grid.cols[c])
      in_box = nums(grid.boxes[rc2box(r, c).first])
      [*1..9] - in_row - in_col - in_box
    }
  }
end

def best_by_position(moves)
  min, min_r, min_c = 10, nil, nil
  moves.each.with_index { |row, r|
    row.each.with_index { |nums, c|
      next unless nums
      if nums.size < min
        min, min_r, min_c = nums.size, r, c
      end
    }
  }
  moves[min_r][min_c].map { |num|
    Move.new(min_r, min_c, num)
  }
end


def box2rc(box, i)
  r = box / 3 * 3 + i / 3
  c = box % 3 * 3 + i % 3
  [r, c]
end

def possible?(grid, r, c, m)
  return false if grid.rows[r][c] != 0
  return false if grid.rows[r].include?(m)
  return false if grid.cols[c].include?(m)
  return false if grid.boxes[rc2box(r, c)[0]].include?(m)
  true
end

def possible_sets(grid)
  rows = grid.rows.map.with_index { |row, r|
    ([*1..9] - row).map { |m|
      [m, row.map.with_index { |_, c|
        [r, c] if possible?(grid, r, c, m)
      }.compact]
    }
  }
  cols = grid.cols.map.with_index { |col, c|
    ([*1..9] - col).map { |m|
      [m, col.map.with_index { |_, r|
        [r, c] if possible?(grid, r, c, m)
      }.compact]
    }
  }
  boxes = grid.boxes.map.with_index { |box, b|
    ([*1..9] - box).map { |m|
      [m, box.map.with_index { |_, i|
        r, c = box2rc(b, i)
        [r, c] if possible?(grid, r, c, m)
      }.compact]
    }
  }
  rows + cols + boxes
end

def best_by_sets(grid)
  best_set = possible_sets(grid)
    .flatten(1)
    .sort_by { |_, positions| positions.length }
    .first
  best_set[1].map { |r, c|
    Move.new(r, c, best_set[0])
  }
end

require 'benchmark'

Grid = Struct.new(:rows, :cols, :boxes)
Sudoku = Struct.new(:grid, :bf, :pos)
Move = Struct.new(:row, :col, :num)

def init_sudoku(rows)
  cols = (0...9).map { |c| rows.map { |row| row[c] } }
  boxes = Array.new(9) { Array.new(9) }
  rows.each.with_index { |row, r|
    row.each.with_index { |content, c|
      box, i = rc2box(r, c)
      boxes[box][i] = content;
    }
  }
  grid = Grid.new(rows, cols, boxes)

  if (d = grid.rows.find_index { |r| r = r.filter { _1 != 0 }; r.uniq.size != r.size })
    raise "duplicate in row #{d+1}"
  end
  if (d = grid.cols.find_index { |c| c = c.filter { _1 != 0 }; c.uniq.size != c.size })
    raise "duplicate in column #{d+1}"
  end
  if (d = grid.boxes.find_index { |b| b = b.filter { _1 != 0 }; b.uniq.size != b.size })
    raise "duplicate in box #{d+1}"
  end

  Sudoku.new(grid, 0, possible_positions(grid))
end

def rc2box(r, c)
  box = r / 3 * 3 + c / 3
  i = r % 3 * 3 + c % 3;
  [box, i]
end

def deep_copy_sudoku(s)
  new_grid = Grid.new(
    s.grid.rows.map { |row| row.map(&:clone) },
    s.grid.cols.map { |col| col.map(&:clone) },
    s.grid.boxes.map { |box| box.map(&:clone) }
  )
  new_pos = s.pos.map { |row| row.map { |nums| nums&.map(&:clone) } }
  Sudoku.new(new_grid, s.bf, new_pos)
end

def rc4box(box)
  start_row = (box / 3) * 3
  start_col = (box % 3) * 3
  (start_row...start_row+3).to_a.product((start_col...start_col+3).to_a)
end

def move(s, m)
  new = deep_copy_sudoku(s)
  box, i = rc2box(m.row, m.col)

  new.grid.rows[m.row][m.col] = m.num
  new.grid.cols[m.col][m.row] = m.num
  new.grid.boxes[box][i] = m.num

  new.pos[m.row][m.col] = nil
  new.pos[m.row].each.with_index { |_, i|
    next unless new.pos[m.row][i]
    new.pos[m.row][i] -= [m.num]
  }
  new.pos.each.with_index { |_, i|
    next unless new.pos[i][m.col]
    new.pos[i][m.col] -= [m.num]
  }
  rc4box(rc2box(m.row, m.col).first).each { |r, c|
    next unless new.pos[r][c]
    new.pos[r][c] -= [m.num]
  }

  new
end

def done?(s)
  s.grid.rows.all? { |row| row.all? { |num| num != 0 } }
end

def no_moves?(s)
  s.pos.flatten.compact.empty?
end

def best_moves(s)
  by_pos = best_by_position(s.pos)
  return by_pos if by_pos.size == 1
  [by_pos, best_by_sets(s.grid)].min_by { _1.size }
end

# Return rows matrix if solved, false otherwise
def solve_first(s)
  return s if done?(s)
  return nil if no_moves?(s)

  moves = best_moves(s)
  s.bf += (moves.size - 1)**2
  moves.each do |move|
    new = move(s, move)
    solved = solve_first(new)
    return solved if solved
  end
  nil
end

def solve_all(s)
  return [s] if done?(s)
  return [] if no_moves?(s)

  moves = best_moves(s)
  s.bf += (moves.size - 1)**2
  sols = []
  moves.each do |move|
    new = move(s, move)
    sols += solve_all(new)
  end
  sols
end

def one_solution?(s)
  def search(s, sols)
    return if sols.size > 1
    return sols << s if done?(s)
    return if no_moves?(s)

    moves = best_moves(s)
    s.bf += (moves.size - 1)**2
    moves.each do |move|
      new = move(s, move)
      search(new, sols)
      return if sols.size > 1
    end
  end

  sols = []
  search(s, sols)
  return nil if sols.size != 1
  sols.first
end

