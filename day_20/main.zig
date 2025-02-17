const std = @import("std");
const Allocator = std.mem.Allocator;
const print = std.debug.print;
const data = @embedFile("input.txt");
const test_data = @embedFile("test_input.txt");
const testing = std.testing;

var gpa_impl = std.heap.GeneralPurposeAllocator(.{}){};
var gpa = gpa_impl.allocator();

const START = 'S';
const END = 'E';
const WALL = '#';
const TRACK = '.';

var start: Point = undefined;
var end: Point = undefined;

const Point = struct {
    x: usize,
    y: usize,

    pub fn init(x: usize, y: usize) Point {
        return Point{ .x = x, .y = y };
    }

    pub fn equals(self: Point, other: Point) bool {
        return self.x == other.x and self.y == other.y;
    }

    pub fn manhattan_distance(self: Point, other: Point) usize {
        const p1_x: i64 = @intCast(self.x);
        const p1_y: i64 = @intCast(self.y);
        const p2_x: i64 = @intCast(other.x);
        const p2_y: i64 = @intCast(other.y);

        return @abs(p2_x - p1_x) + @abs(p2_y - p1_y);
    }
};

const Cheat = struct {
    start: Point,
    end: Point,
    picoseconds_saved: usize,

    pub fn init(from: Point, to: Point, picoseconds_saved: usize) Cheat {
        return Cheat{ .start = from, .end = to, .picoseconds_saved = picoseconds_saved };
    }
};

const State = struct {
    position: Point,
    steps: usize,

    pub fn init(position: Point, steps: usize) State {
        return State{ .position = position, .steps = steps };
    }
};

const directions = [_]direction{
    .up,
    .down,
    .left,
    .right,
};
const direction = enum {
    up,
    down,
    left,
    right,

    pub fn next(self: direction, point: Point, rows: usize, cols: usize) !Point {
        switch (self) {
            .up => {
                if (point.y == 0) return error.OutOfBounds;
                return Point{ .x = point.x, .y = point.y - 1 };
            },
            .down => {
                if (point.y == rows - 1) return error.OutOfBounds;
                return Point{ .x = point.x, .y = point.y + 1 };
            },
            .left => {
                if (point.x == 0) return error.OutOfBounds;
                return Point{ .x = point.x - 1, .y = point.y };
            },
            .right => {
                if (point.x == cols - 1) return error.OutOfBounds;
                return Point{ .x = point.x + 1, .y = point.y };
            },
        }
    }
};

var alloc: Allocator = undefined;

var grid: std.ArrayList(std.ArrayList(u8)) = undefined;
var walls: std.AutoArrayHashMap(Point, void) = undefined;

pub fn parse(input: []const u8) void {
    var lines = std.mem.tokenizeScalar(u8, input, '\n');
    var i: usize = 0;
    while (lines.next()) |line| {
        var row = std.ArrayList(u8).init(alloc);
        for (line, 0..) |c, j| {
            row.append(c) catch unreachable;
            if (c == WALL) walls.put(Point.init(j, i), void{}) catch unreachable;
            if (c == START) start = Point.init(j, i);
            if (c == END) end = Point.init(j, i);
        }
        grid.append(row) catch unreachable;
        i += 1;
    }
}

pub fn print_grid() void {
    for (grid.items) |row| {
        for (row.items) |c| {
            print("{c}", .{c});
        }
        print("\n", .{});
    }
}

pub fn find_path(from: Point, to: Point) !std.ArrayList(State) {
    var q = std.ArrayList(State).init(alloc);
    defer q.deinit();

    var visited = std.AutoArrayHashMap(Point, void).init(alloc);
    defer visited.deinit();

    var path = std.ArrayList(State).init(alloc);
    try q.insert(0, State.init(from, 0));

    while (q.popOrNull()) |state| {
        if (walls.contains(state.position)) continue;
        if (visited.contains(state.position)) continue;

        if (state.position.equals(to)) {
            try path.append(state);
            return path;
        }

        for (directions) |dir| {
            const next = dir.next(state.position, grid.items.len, grid.items[0].items.len) catch unreachable;
            const next_state = State.init(next, state.steps + 1);
            try q.insert(0, next_state);
        }

        try visited.put(state.position, {});
        try path.append(state);
    }

    return error.NoPathFound;
}

pub fn find_cheats(path: std.ArrayList(State), cheat_duration: usize) !std.ArrayList(Cheat) {
    var cheats = std.ArrayList(Cheat).init(alloc);
    for (path.items, 0..) |state, i| {
        for (path.items[i + 1 ..]) |next_state| {
            const md = state.position.manhattan_distance(next_state.position);
            if (md <= cheat_duration) {
                try cheats.append(Cheat.init(state.position, next_state.position, next_state.steps - state.steps - md));
            }
        }
    }
    return cheats;
}

pub fn part1(input: []const u8, min_saved: usize) !void {
    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();
    alloc = arena.allocator();

    grid = std.ArrayList(std.ArrayList(u8)).init(alloc);
    walls = std.AutoArrayHashMap(Point, void).init(alloc);

    parse(input);

    const path = try find_path(start, end);
    defer path.deinit();

    const cheats = try find_cheats(path, 2);
    defer cheats.deinit();

    var count: usize = 0;
    for (cheats.items) |cheat| {
        if (cheat.picoseconds_saved >= min_saved) {
            count += 1;
        }
    }
    print("\npart_1={}\n", .{count});
}

pub fn part2(input: []const u8, min_saved: usize) !void {
    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();
    alloc = arena.allocator();

    grid = std.ArrayList(std.ArrayList(u8)).init(alloc);
    walls = std.AutoArrayHashMap(Point, void).init(alloc);

    parse(input);

    const path = try find_path(start, end);
    defer path.deinit();

    const cheats = try find_cheats(path, 20);
    defer cheats.deinit();

    var count: usize = 0;
    for (cheats.items) |cheat| {
        if (cheat.picoseconds_saved >= min_saved) {
            count += 1;
        }
    }
    print("part_2={}\n", .{count});
}

pub fn main() !void {
    try part1(data, 100);
    try part2(data, 100);
}

test "part 1" {
    try part1(test_data, 2);
    print("   (E)=44\n\n", .{});
}

test "part 2" {
    try part2(test_data, 50);
    print("   (E)=285\n\n", .{});
}
