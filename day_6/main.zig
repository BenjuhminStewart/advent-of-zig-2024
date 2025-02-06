const std = @import("std");
const testing = std.testing;
const mem = std.mem;
const print = std.debug.print;
const data = @embedFile("input.txt");
const test_data = @embedFile("test_input.txt");
const Allocator = std.mem.Allocator;
const OBSTACLE = '#';
const NEW_OBSTACLE = 'O';
const GUARD = '^';
const VISITED = 'X';
const DEFAULT = '.';

const Point = struct {
    i: usize,
    j: usize,
};

const Guard = struct {
    direction: TravelingDirection = TravelingDirection.Up,
    position: Point,
    visited: std.AutoHashMap(Point, void),
    is_outside: bool = false,
    steps: usize = 1,

    fn turn(self: *Guard) !void {
        switch (self.direction) {
            .Up => self.direction = .Right,
            .Down => self.direction = .Left,
            .Left => self.direction = .Up,
            .Right => self.direction = .Down,
        }
    }

    fn move(self: *Guard, grid: [][]u8) !void {
        if (self.direction == .Up and self.position.i == 0) {
            self.is_outside = true;
            return error.OutOfBounds;
        }
        if (self.direction == .Down and self.position.i == grid.len - 1) {
            self.is_outside = true;
            return error.OutOfBounds;
        }
        if (self.direction == .Left and self.position.j == 0) {
            self.is_outside = true;
            return error.OutOfBounds;
        }
        if (self.direction == .Right and self.position.j == grid[0].len - 1) {
            self.is_outside = true;
            return error.OutOfBounds;
        }
        var p: Point = undefined;
        switch (self.direction) {
            .Up => {
                p = Point{ .i = self.position.i - 1, .j = self.position.j };
            },
            .Down => {
                p = Point{ .i = self.position.i + 1, .j = self.position.j };
            },
            .Left => {
                p = Point{ .i = self.position.i, .j = self.position.j - 1 };
            },
            .Right => {
                p = Point{ .i = self.position.i, .j = self.position.j + 1 };
            },
        }
        if (grid[p.i][p.j] == OBSTACLE or grid[p.i][p.j] == NEW_OBSTACLE) {
            self.turn() catch unreachable;
        } else {
            if (self.visited.get(p)) |_| {} else {
                self.visited.put(p, {}) catch unreachable;
                self.steps += 1;
            }
            self.position = p;
        }
    }
};

const TravelingDirection = enum {
    Up,
    Down,
    Left,
    Right,
};

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const input = try parse_input(data, allocator, 130);
    defer free_input(input, allocator);

    const start_point = get_starting_position(input) catch {
        return error.NoGuardFound;
    };

    var visited = std.AutoHashMap(Point, void).init(allocator);
    defer visited.deinit();

    var guard = Guard{ .position = start_point, .visited = visited };
    guard.visited.put(start_point, {}) catch unreachable;

    const part_1 = distinct_positions(input, &guard);
    print("part 1: {}\n", .{part_1});

    const part_2 = get_perfect_obstacles(input, start_point);
    print("part 2: {}\n", .{part_2});
}

fn get_starting_position(grid: [][]u8) !Point {
    for (grid, 0..) |row, i| {
        for (row, 0..) |cell, j| {
            if (cell == GUARD) {
                return Point{ .i = i, .j = j };
            }
        }
    }

    return error.NoGuardFound;
}

fn distinct_positions(grid: [][]u8, guard: *Guard) usize {
    while (!guard.is_outside) {
        guard.move(grid) catch {
            break;
        };
    }

    return guard.steps;
}

fn get_perfect_obstacles(grid: [][]u8, start_point: Point) usize {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var visited = std.AutoHashMap(Point, void).init(allocator);
    defer visited.deinit();

    var perfect_obstacles: usize = 0;
    for (grid, 0..) |row, i| {
        for (row, 0..) |cell, j| {
            if (cell == OBSTACLE or cell == NEW_OBSTACLE or cell == GUARD) {
                continue;
            }
            var guard = Guard{ .position = start_point, .visited = visited };
            guard.visited.put(start_point, {}) catch unreachable;
            const contents = grid[i][j];
            grid[i][j] = NEW_OBSTACLE;
            if (is_guard_in_loop(grid, &guard)) {
                perfect_obstacles += 1;
            }
            grid[i][j] = contents;
        }
    }

    return perfect_obstacles;
}

fn is_guard_in_loop(grid: [][]u8, guard: *Guard) bool {
    var is_in_loop = false;
    var moves: usize = 0;

    while (!guard.is_outside) {
        guard.move(grid) catch {
            break;
        };
        moves += 1;
        if (moves > grid.len * grid[0].len) {
            is_in_loop = true;
            break;
        }
    }
    return is_in_loop;
}

fn print_grid(grid: [][]u8) void {
    print("\n", .{});
    for (grid) |row| {
        print("{s}\n", .{row});
    }
    print("\n", .{});
}

fn parse_input(input: []const u8, allocator: Allocator, rows: usize) ![][]u8 {
    const cols = rows;

    if (cols != rows) {
        return error.InvalidInput;
    }

    var grid: [][]u8 = try allocator.alloc([]u8, rows);
    for (grid) |*row| {
        row.* = try allocator.alloc(u8, cols);
    }
    var i: usize = 0;
    var lines = mem.tokenizeScalar(u8, input, '\n');
    while (lines.next()) |line| {
        var j: usize = 0;
        for (line) |c| {
            grid[i][j] = c;
            j += 1;
        }
        i += 1;
    }
    return grid;
}

fn free_input(grid: [][]u8, allocator: Allocator) void {
    for (grid) |row| {
        allocator.free(row);
    }
    allocator.free(grid);
}

test "part 1" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const input = try parse_input(test_data, allocator, 10);
    defer allocator.free(input);

    var visited = std.AutoHashMap(Point, void).init(allocator);
    defer visited.deinit();

    const start_point = get_starting_position(input) catch {
        return error.NoGuardFound;
    };
    var guard = Guard{ .position = start_point, .visited = visited };

    const expected = 41;
    const actual = distinct_positions(input, &guard);
    try testing.expectEqual(expected, actual);
}

test "part 2" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const input = try parse_input(test_data, allocator, 10);
    defer allocator.free(input);

    var visited = std.AutoHashMap(Point, void).init(allocator);
    defer visited.deinit();

    const start_point = get_starting_position(input) catch {
        return error.NoGuardFound;
    };

    const expected = 6;
    const actual = get_perfect_obstacles(input, start_point);
    try testing.expectEqual(expected, actual);
}
