const std = @import("std");
const Allocator = std.mem.Allocator;
const print = std.debug.print;
const data = @embedFile("input.txt");
const test_data = @embedFile("test_input.txt");
const testing = std.testing;

var gpa_impl = std.heap.GeneralPurposeAllocator(.{}){};
var gpa = gpa_impl.allocator();

var alloc: Allocator = undefined;

var grid: std.ArrayList(std.ArrayList(u8)) = undefined;

pub fn parse(input: []const u8) !void {
    grid = std.ArrayList(std.ArrayList(u8)).init(alloc);
    var lines = std.mem.tokenizeScalar(u8, input, '\n');
    while (lines.next()) |line| {
        var line_list = std.ArrayList(u8).init(alloc);
        for (line) |c| {
            const digit = get_digit(c);
            line_list.append(digit) catch {
                return error.LineListAppendError;
            };
        }
        grid.append(line_list) catch {
            return error.GridAppendError;
        };
    }
}

pub fn traverse_hill(level: i32, i: i32, j: i32, visited: *std.AutoHashMap(Point, void)) usize {
    if (i < 0 or j < 0 or i >= grid.items.len or j >= grid.items[0].items.len) return 0;
    const i_usize: usize = @intCast(i);
    const j_usize: usize = @intCast(j);
    if (grid.items[i_usize].items[j_usize] != level) return 0;
    const p = Point{ .i = i, .j = j };
    const has_visited: bool = visited.get(p) != null;
    if (level == 9 and !has_visited) {
        visited.*.put(p, {}) catch unreachable;
        return 1;
    }

    return traverse_hill(level + 1, i - 1, j, visited) +
        traverse_hill(level + 1, i + 1, j, visited) +
        traverse_hill(level + 1, i, j - 1, visited) +
        traverse_hill(level + 1, i, j + 1, visited);
}

const Point = struct {
    i: i32,
    j: i32,
};

pub fn solve() usize {
    var scores: usize = 0;

    for (grid.items, 0..) |row, i| {
        for (row.items, 0..) |digit, j| {
            if (digit == 0) {
                const zero: i32 = 0;
                const i_i32: i32 = @intCast(i);
                const j_i32: i32 = @intCast(j);
                var visited = std.AutoHashMap(Point, void).init(alloc);
                const score_at_trailhill = traverse_hill(zero, i_i32, j_i32, &visited);
                scores += score_at_trailhill;
            }
        }
    }

    return scores;
}

pub fn print_grid() void {
    for (grid.items) |row| {
        for (row.items) |digit| {
            print("{}", .{digit});
        }
        print("\n", .{});
    }
}

pub fn get_digit(c: u8) u8 {
    switch (c) {
        '0' => return 0,
        '1' => return 1,
        '2' => return 2,
        '3' => return 3,
        '4' => return 4,
        '5' => return 5,
        '6' => return 6,
        '7' => return 7,
        '8' => return 8,
        '9' => return 9,
        else => return 0,
    }
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();
    alloc = arena.allocator();

    try parse(data);
    const part_1 = solve();

    print("part_1={}\n", .{part_1});
}

test "part 1" {
    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();
    alloc = arena.allocator();

    try parse(test_data);
    const expected = 36;
    const actual = solve();

    try testing.expectEqual(expected, actual);
}

test "part 2" {}
