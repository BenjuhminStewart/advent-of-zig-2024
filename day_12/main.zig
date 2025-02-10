const std = @import("std");
const Allocator = std.mem.Allocator;
const print = std.debug.print;
const data = @embedFile("input.txt");
const test_data = @embedFile("test_input.txt");
const testing = std.testing;

var gpa_impl = std.heap.GeneralPurposeAllocator(.{}){};
var gpa = gpa_impl.allocator();

var grid: std.ArrayList(std.ArrayList(u8)) = undefined;
var visited: std.AutoHashMap(Point, void) = undefined;

const Point = struct {
    const Self = @This();
    x: i64,
    y: i64,

    pub fn print_self(self: Point) void {
        print("({}, {})", .{ self.x, self.y });
    }

    pub fn equals(self: Point, other: Point) bool {
        return self.x == other.x and self.y == other.y;
    }
};

var alloc: Allocator = undefined;

pub fn main() void {
    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();
    alloc = arena.allocator();

    parse(data);
    const part_1 = solve(false);
    print("part_1={}\n", .{part_1});

    parse(data);
    const part_2 = solve(true);
    print("part_2={}\n", .{part_2});
}

pub fn parse(input: []const u8) void {
    grid = std.ArrayList(std.ArrayList(u8)).init(gpa);
    var lines = std.mem.tokenizeSequence(u8, input, "\n");
    while (lines.next()) |line| {
        var list = std.ArrayList(u8).init(gpa);
        for (line) |c| {
            list.append(c) catch unreachable;
        }
        grid.append(list) catch unreachable;
    }
}

pub fn solve(is_budget: bool) u64 {
    visited = std.AutoHashMap(Point, void).init(gpa);
    var total_price: u64 = 0;
    for (grid.items, 0..) |row, i| {
        for (row.items, 0..) |value, j| {
            var region = std.ArrayList(Point).init(gpa);
            const i_i64: i64 = @intCast(i);
            const j_i64: i64 = @intCast(j);
            build_region(value, i_i64, j_i64, &region);
            total_price += build_fence(region.items, value, is_budget);
        }
    }
    return total_price;
}

pub fn build_region(value: u8, x: i64, y: i64, region: *std.ArrayList(Point)) void {
    if (x < 0 or x >= grid.items.len or y < 0 or y >= grid.items[0].items.len) {
        return;
    }

    if (visited.get(Point{ .x = x, .y = y })) |_| {
        return;
    }

    const x_usize: usize = @intCast(x);
    const y_usize: usize = @intCast(y);

    if (grid.items[x_usize].items[y_usize] != value) {
        return;
    }

    region.append(Point{ .x = x, .y = y }) catch unreachable;
    visited.put(Point{ .x = x, .y = y }, void{}) catch unreachable;

    build_region(value, x + 1, y, region);
    build_region(value, x - 1, y, region);
    build_region(value, x, y + 1, region);
    build_region(value, x, y - 1, region);
}

pub fn build_fence(region: []Point, value: u8, is_budget: bool) u64 {
    if (region.len == 0) {
        return 0;
    }
    var price: u64 = 0;
    var perimeter: u64 = undefined;
    if (is_budget) {
        perimeter = get_num_sides(region) catch unreachable;
    } else {
        perimeter = get_perimiter(region, value);
    }
    const area = region.len;
    price += area * perimeter;
    return price;
}

const directions = [_]Point{
    Point{ .x = 0, .y = 1 },
    Point{ .x = 1, .y = 0 },
    Point{ .x = 0, .y = -1 },
    Point{ .x = -1, .y = 0 },
};

pub fn get_perimiter(region: []Point, target: u8) u64 {
    var perimeter: u64 = 0;

    const rows = grid.items.len;
    const cols = grid.items[0].items.len;

    for (region) |point| {
        for (directions) |dir| {
            const ni: i64 = point.x + dir.x;
            const nj: i64 = point.y + dir.y;
            const rows_i64: i64 = @intCast(rows);
            const cols_i64: i64 = @intCast(cols);
            if (ni < 0 or nj < 0 or ni >= rows_i64 or nj >= cols_i64) {
                perimeter += 1;
                continue;
            }

            const ni_usize: usize = @intCast(ni);
            const nj_usize: usize = @intCast(nj);
            if (grid.items[ni_usize].items[nj_usize] != target) {
                perimeter += 1;
            }
        }
    }

    return perimeter;
}

pub fn get_num_sides(region: []Point) !u64 {
    _ = region;
    return 0;
}

pub fn print_grid() void {
    for (grid.items) |row| {
        print("{s}\n", .{row.items});
    }
    print("\n", .{});
}

test "part 1" {
    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();
    alloc = arena.allocator();

    const expected = 1930;
    parse(test_data);
    const result = solve(false);
    try testing.expectEqual(expected, result);
}

test "part 2" {
    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();
    alloc = arena.allocator();

    const expected = 1206;
    parse(test_data);
    const result = solve(true);
    try testing.expectEqual(expected, result);
}
