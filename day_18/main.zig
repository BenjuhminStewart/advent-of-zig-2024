const std = @import("std");
const Allocator = std.mem.Allocator;
const print = std.debug.print;
const data = @embedFile("input.txt");

var gpa_impl = std.heap.GeneralPurposeAllocator(.{}){};
var gpa = gpa_impl.allocator();

var alloc: Allocator = undefined;

var grid: std.ArrayList(std.ArrayList(u8)) = undefined;
var start: Position = Position.init(0, 0);
var end: Position = undefined;

const Position = struct {
    x: usize,
    y: usize,

    pub fn init(x: usize, y: usize) Position {
        return Position{
            .x = x,
            .y = y,
        };
    }

    pub fn equals(self: Position, other: Position) bool {
        return self.x == other.x and self.y == other.y;
    }
};

const Node = struct {
    position: Position,
    steps: usize,

    pub fn init(position: Position, steps: usize) Node {
        return Node{ .position = position, .steps = steps };
    }
};

const direction = enum {
    up,
    down,
    left,
    right,

    pub fn next(self: direction, pos: Position, rows: usize, cols: usize) !Position {
        switch (self) {
            .up => {
                if (pos.y == 0) {
                    return error.OutOfBounds;
                }
                return Position.init(pos.x, pos.y - 1);
            },
            .down => {
                if (pos.y == rows - 1) {
                    return error.OutOfBounds;
                }
                return Position.init(pos.x, pos.y + 1);
            },
            .left => {
                if (pos.x == 0) {
                    return error.OutOfBounds;
                }
                return Position.init(pos.x - 1, pos.y);
            },
            .right => {
                if (pos.x == cols - 1) {
                    return error.OutOfBounds;
                }
                return Position.init(pos.x + 1, pos.y);
            },
        }
    }
};

pub fn print_grid() void {
    for (grid.items) |row| {
        for (row.items) |cell| {
            print("{c}", .{cell});
        }
        print("\n", .{});
    }
}

var bytes_map: std.AutoArrayHashMap(Position, void) = undefined;
var bytes_array: std.ArrayList(Position) = undefined;
pub fn parse(input: []const u8, rows: usize, cols: usize, bytes_fallen: usize, is_part_two: bool) !void {
    end = Position.init(rows - 1, cols - 1);
    grid = std.ArrayList(std.ArrayList(u8)).init(alloc);
    for (0..rows) |_| {
        var grid_row = std.ArrayList(u8).init(alloc);
        for (0..cols) |_| {
            grid_row.append('.') catch unreachable;
        }
        grid.append(grid_row) catch unreachable;
    }

    var bytes_corrupted: usize = 0;
    var lines = std.mem.tokenizeSequence(u8, input, "\n");
    while (lines.next()) |line| {
        if (!is_part_two and bytes_corrupted >= bytes_fallen) {
            break;
        }
        var nums = std.mem.tokenizeSequence(u8, line, ",");
        const x = std.fmt.parseInt(usize, nums.next().?, 10) catch {
            return error.ParseError;
        };
        const y = std.fmt.parseInt(usize, nums.next().?, 10) catch {
            return error.ParseError;
        };
        const pos = Position.init(x, y);
        grid.items[pos.y].items[pos.x] = '#';
        try bytes_map.put(pos, {});
        try bytes_array.append(pos);
        bytes_corrupted += 1;
    }
    grid.items[start.y].items[start.x] = 'S';
    grid.items[end.y].items[end.x] = 'E';
}

var min_steps: usize = std.math.maxInt(usize);
var directions = [4]direction{ .up, .down, .left, .right };
pub fn bfs(bytes: std.AutoArrayHashMap(Position, void)) !usize {
    var q = std.ArrayList(Node).init(alloc);
    defer q.deinit();
    try q.insert(0, Node.init(start, 0));
    var visited = std.AutoHashMap(Position, void).init(alloc);
    defer visited.deinit();

    while (q.pop()) |node| {
        if (bytes.contains(node.position)) continue;
        if (visited.contains(node.position)) continue;
        if (node.position.equals(end)) return node.steps;
        for (directions) |d| {
            const next = d.next(node.position, grid.items.len, grid.items[0].items.len) catch continue;
            const next_node = Node.init(next, node.steps + 1);
            try q.insert(0, next_node);
        }
        try visited.put(node.position, {});
    }

    return 0;
}

pub fn part1(input: []const u8, rows: usize, cols: usize, bytes_fallen: usize) !void {
    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();
    alloc = arena.allocator();

    bytes_map = std.AutoArrayHashMap(Position, void).init(alloc);
    defer bytes_map.deinit();
    bytes_array = std.ArrayList(Position).init(alloc);
    defer bytes_array.deinit();
    try parse(input, rows, cols, bytes_fallen, false);

    const part_1 = try bfs(bytes_map);
    print("part_1={}\n", .{part_1});
}

pub fn part2(input: []const u8, rows: usize, cols: usize, bytes_fallen: usize) !void {
    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();
    alloc = arena.allocator();

    bytes_map = std.AutoArrayHashMap(Position, void).init(alloc);
    defer bytes_map.deinit();
    bytes_array = std.ArrayList(Position).init(alloc);
    defer bytes_array.deinit();
    try parse(input, rows, cols, bytes_fallen, true);

    var left: usize = 0;
    var right: usize = bytes_array.items.len;
    var cutoff = (right - left) / 2;
    var prev: usize = 0;
    var path_found: bool = undefined;

    while (prev != cutoff) {
        var fallen_bytes = std.AutoArrayHashMap(Position, void).init(alloc);
        defer fallen_bytes.deinit();
        for (bytes_array.items[0..cutoff]) |byte| {
            try fallen_bytes.put(byte, {});
        }

        const result = try bfs(fallen_bytes);
        prev = cutoff;
        if (result == 0) {
            right = cutoff;
            cutoff -= (right - left) / 2;
            path_found = false;
        } else {
            left = cutoff;
            cutoff += (right - left) / 2;
            path_found = true;
        }
    }
    if (path_found) {
        const first_position = bytes_array.items[cutoff];
        print("part_2={},{}\n", .{ first_position.x, first_position.y });
        return;
    }
    const first_position = bytes_array.items[cutoff - 1];
    print("part_2={},{}\n", .{ first_position.x, first_position.y });
}

pub fn main() !void {
    print("\n[ Day 18 ]\n", .{});
    try part1(data, 71, 71, 1024);
    try part2(data, 71, 71, 1024);
}
