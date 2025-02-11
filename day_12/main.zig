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
            total_price += build_fence(region.items, is_budget);
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

pub fn build_fence(region: []Point, is_budget: bool) u64 {
    if (region.len == 0) {
        return 0;
    }

    var perimeter: u64 = undefined;
    if (is_budget) {
        perimeter = get_sides(region) catch unreachable;
    } else {
        perimeter = get_perimiter(region);
    }
    const area = region.len;
    return area * perimeter;
}

const directions = [_]Point{
    Point{ .x = 0, .y = 1 },
    Point{ .x = 1, .y = 0 },
    Point{ .x = 0, .y = -1 },
    Point{ .x = -1, .y = 0 },
};

pub fn print_region(region: []Point) void {
    var set = std.AutoHashMap(Point, void).init(alloc);
    defer set.deinit();
    for (region) |point| {
        set.put(point, {}) catch unreachable;
    }

    for (grid.items, 0..) |row, i| {
        for (row.items, 0..) |_, j| {
            const x: i64 = @intCast(i);
            const y: i64 = @intCast(j);
            const p = Point{ .x = x, .y = y };
            const value = grid.items[i].items[j];
            if (set.contains(p)) {
                std.debug.print("{c}", .{value});
            } else {
                std.debug.print(" ", .{});
            }
        }
        print("\n", .{});
    }
}

pub fn get_perimiter(region: []Point) u64 {
    var points = std.AutoHashMap(Point, void).init(alloc);
    for (region) |point| {
        points.put(point, {}) catch unreachable;
    }
    var perimeter: u64 = 0;
    for (region) |point| {
        for (directions) |dir| {
            const np = Point{ .x = point.x + dir.x, .y = point.y + dir.y };
            if (!points.contains(np)) {
                perimeter += 1;
            }
        }
    }

    return perimeter;
}

const diagonals = enum {
    northwest,
    northeast,
    southeast,
    southwest,
};

const corner = struct {
    x: i64,
    x_dec: i4,
    y: i64,
    y_dec: i4,
    diagonal: diagonals,
};

pub fn get_sides(region: []Point) !u64 {
    var corners: u64 = 0;
    var points = std.AutoHashMap(Point, void).init(alloc);
    for (region) |point| {
        points.put(point, {}) catch unreachable;
    }

    var visited_corners = std.AutoHashMap(corner, void).init(alloc);

    for (region) |point| {
        const up = Point{ .x = point.x - 1, .y = point.y };
        const down = Point{ .x = point.x + 1, .y = point.y };
        const left = Point{ .x = point.x, .y = point.y - 1 };
        const right = Point{ .x = point.x, .y = point.y + 1 };

        const divisor: i64 = 2;
        if (!points.contains(left) and !points.contains(down)) {
            const c: corner = corner{
                .x = @divFloor(left.x + down.x, divisor),
                .x_dec = 5,
                .y = @divFloor(left.y + down.y, divisor),
                .y_dec = 5,
                .diagonal = .southwest,
            };
            if (!visited_corners.contains(c)) {
                visited_corners.put(c, {}) catch unreachable;
                corners += 1;
            }
        }

        if (!points.contains(right) and !points.contains(down)) {
            const c: corner = corner{
                .x = @divFloor(right.x + down.x, divisor),
                .x_dec = 5,
                .y = @divFloor(right.y + down.y, divisor),
                .y_dec = 5,
                .diagonal = .southeast,
            };
            if (!visited_corners.contains(c)) {
                visited_corners.put(c, {}) catch unreachable;
                corners += 1;
            }
        }

        if (!points.contains(left) and !points.contains(up)) {
            const c: corner = corner{
                .x = @divFloor(left.x + up.x, divisor),
                .x_dec = 5,
                .y = @divFloor(left.y + up.y, divisor),
                .y_dec = 5,
                .diagonal = .northwest,
            };
            if (!visited_corners.contains(c)) {
                visited_corners.put(c, {}) catch unreachable;
                corners += 1;
            }
        }

        if (!points.contains(right) and !points.contains(up)) {
            const c: corner = corner{
                .x = @divFloor(right.x + up.x, divisor),
                .x_dec = 5,
                .y = @divFloor(right.y + up.y, divisor),
                .y_dec = 5,
                .diagonal = .northeast,
            };
            if (!visited_corners.contains(c)) {
                visited_corners.put(c, {}) catch unreachable;
                corners += 1;
            }
        }
        const up_and_left = Point{ .x = point.x - 1, .y = point.y - 1 };
        if (points.contains(left) and points.contains(up) and !points.contains(up_and_left)) {
            const c: corner = corner{
                .x = @divFloor((left.x + up.x), divisor),
                .x_dec = 5,
                .y = @divFloor((left.y + up.y), divisor),
                .y_dec = 5,
                .diagonal = .northwest,
            };
            if (!visited_corners.contains(c)) {
                visited_corners.put(c, {}) catch unreachable;
                corners += 1;
            }
        }

        const up_and_right = Point{ .x = point.x - 1, .y = point.y + 1 };
        if (points.contains(right) and points.contains(up) and !points.contains(up_and_right)) {
            const c: corner = corner{
                .x = @divFloor((right.x + up.x), divisor),
                .x_dec = 5,
                .y = @divFloor((right.y + up.y), divisor),
                .y_dec = 5,
                .diagonal = .northeast,
            };
            if (!visited_corners.contains(c)) {
                visited_corners.put(c, {}) catch unreachable;
                corners += 1;
            }
        }

        const down_and_left = Point{ .x = point.x + 1, .y = point.y - 1 };
        if (points.contains(left) and points.contains(down) and !points.contains(down_and_left)) {
            const c: corner = corner{
                .x = @divFloor((left.x + down.x), divisor),
                .x_dec = 5,
                .y = @divFloor((left.y + down.y), divisor),
                .y_dec = 5,
                .diagonal = .southwest,
            };
            if (!visited_corners.contains(c)) {
                visited_corners.put(c, {}) catch unreachable;
                corners += 1;
            }
        }

        const down_and_right = Point{ .x = point.x + 1, .y = point.y + 1 };
        if (points.contains(right) and points.contains(down) and !points.contains(down_and_right)) {
            const c: corner = corner{
                .x = @divFloor((right.x + down.x), divisor),
                .x_dec = 5,
                .y = @divFloor((right.y + down.y), divisor),
                .y_dec = 5,
                .diagonal = .southeast,
            };
            if (!visited_corners.contains(c)) {
                visited_corners.put(c, {}) catch unreachable;
                corners += 1;
            }
        }
    }
    return corners;
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

test "part 2 main" {
    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();
    alloc = arena.allocator();

    const expected = 953738;
    parse(data);
    const result = solve(true);
    try testing.expectEqual(expected, result);
}

const tester1 = @embedFile("testers/test1.txt");
const tester2 = @embedFile("testers/test2.txt");
const tester3 = @embedFile("testers/test3.txt");

test "part 2 tester 1" {
    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();
    alloc = arena.allocator();

    const expected = 80;
    parse(tester1);
    const result = solve(true);
    try testing.expectEqual(expected, result);
}

test "part 2 tester 2" {
    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();
    alloc = arena.allocator();

    const expected = 236;
    parse(tester2);
    const result = solve(true);
    try testing.expectEqual(expected, result);
}

test "part 2 tester 3" {
    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();
    alloc = arena.allocator();

    const expected = 368;
    parse(tester3);
    const result = solve(true);
    try testing.expectEqual(expected, result);
}
