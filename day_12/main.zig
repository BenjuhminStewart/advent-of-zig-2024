const std = @import("std");
const Allocator = std.mem.Allocator;
const print = std.debug.print;
const data = @embedFile("input.txt");

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
    print("\n[ Day 12 ]\n", .{});
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

const diagonal = enum {
    northwest,
    northeast,
    southeast,
    southwest,

    pub fn get_points(self: diagonal, p: Point) [2]Point {
        switch (self) {
            .northwest => return [2]Point{
                Point{ .x = p.x - 1, .y = p.y },
                Point{ .x = p.x, .y = p.y - 1 },
            },
            .northeast => return [2]Point{
                Point{ .x = p.x - 1, .y = p.y },
                Point{ .x = p.x, .y = p.y + 1 },
            },
            .southeast => return [2]Point{
                Point{ .x = p.x + 1, .y = p.y },
                Point{ .x = p.x, .y = p.y + 1 },
            },
            .southwest => return [2]Point{
                Point{ .x = p.x + 1, .y = p.y },
                Point{ .x = p.x, .y = p.y - 1 },
            },
        }
    }

    pub fn get_diagonal_point(self: diagonal, p: Point) Point {
        switch (self) {
            .northwest => return Point{ .x = p.x - 1, .y = p.y - 1 },
            .northeast => return Point{ .x = p.x - 1, .y = p.y + 1 },
            .southeast => return Point{ .x = p.x + 1, .y = p.y + 1 },
            .southwest => return Point{ .x = p.x + 1, .y = p.y - 1 },
        }
    }
};

const corner = struct {
    x: i64,
    x_dec: i4,
    y: i64,
    y_dec: i4,
    direction: diagonal,
};

const diagonals = [_]diagonal{
    .northwest,
    .northeast,
    .southeast,
    .southwest,
};

pub fn get_sides(region: []Point) !u64 {
    var corners: u64 = 0;
    var points = std.AutoHashMap(Point, void).init(alloc);
    for (region) |point| {
        points.put(point, {}) catch unreachable;
    }

    var visited_corners = std.AutoHashMap(corner, void).init(alloc);

    for (region) |point| {
        const divisor: i64 = 2;
        // basic corner checking
        for (diagonals) |direction| {
            const ps: [2]Point = direction.get_points(point);
            const p1 = ps[0];
            const p2 = ps[1];
            if (!points.contains(p1) and !points.contains(p2)) {
                const c: corner = corner{
                    .x = @divFloor(p1.x + p2.x, divisor),
                    .x_dec = 5,
                    .y = @divFloor(p1.y + p2.y, divisor),
                    .y_dec = 5,
                    .direction = direction,
                };
                if (!visited_corners.contains(c)) {
                    visited_corners.put(c, {}) catch unreachable;
                    corners += 1;
                }
            }
            const diag = direction.get_diagonal_point(point);
            if (points.contains(p1) and points.contains(p2) and !points.contains(diag)) {
                const c: corner = corner{
                    .x = @divFloor((p1.x + p2.x), divisor),
                    .x_dec = 5,
                    .y = @divFloor((p1.y + p2.y), divisor),
                    .y_dec = 5,
                    .direction = direction,
                };
                if (!visited_corners.contains(c)) {
                    visited_corners.put(c, {}) catch unreachable;
                    corners += 1;
                }
            }
        }
    }
    return corners;
}
