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

var bytes: std.AutoHashMap(Position, void) = undefined;
pub fn parse(input: []const u8, rows: usize, cols: usize, bytes_fallen: usize) !void {
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
        if (bytes_corrupted >= bytes_fallen) {
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
        try bytes.put(pos, {});
        bytes_corrupted += 1;
    }
    grid.items[start.y].items[start.x] = 'S';
    grid.items[end.y].items[end.x] = 'E';
}

var min_steps: usize = std.math.maxInt(usize);
var directions = [4]direction{ .up, .down, .left, .right };
pub fn bfs() !usize {
    var q = std.ArrayList(Node).init(alloc);
    defer q.deinit();
    try q.insert(0, Node.init(start, 0));
    var visited = std.AutoHashMap(Position, void).init(alloc);
    defer visited.deinit();

    while (q.popOrNull()) |node| {
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

    bytes = std.AutoHashMap(Position, void).init(alloc);
    try parse(input, rows, cols, bytes_fallen);

    const part_1 = try bfs();
    print("part_1={}\n", .{part_1});
}

pub fn main() !void {
    try part1(data, 71, 71, 1024);
}

test "part 1" {
    try part1(test_data, 7, 7, 12);
    print("expected: {}\n", .{22});
}

// test "part 2" {}
