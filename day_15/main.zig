const std = @import("std");
const Allocator = std.mem.Allocator;
const print = std.debug.print;
const data = @embedFile("input.txt");
const test_data = @embedFile("test_input.txt");
const test2 = @embedFile("test_2.txt");
const testing = std.testing;

var gpa_impl = std.heap.GeneralPurposeAllocator(.{}){};
var gpa = gpa_impl.allocator();

var alloc: Allocator = undefined;

var moves: std.ArrayList(Direction) = undefined;
var grid: std.ArrayList(std.ArrayList(u8)) = undefined;
var robot: Robot = undefined;

const DEBUG = false;

const Range = struct {
    y1: usize,
    y2: usize,
};

const Point = struct {
    x: usize,
    y: usize,

    pub fn init(x: usize, y: usize) Point {
        return Point{
            .x = x,
            .y = y,
        };
    }

    pub fn equals(self: Point, other: Point) bool {
        return self.x == other.x and self.y == other.y;
    }

    pub fn is_before(self: Point, other: Point, direction: Direction) bool {
        switch (direction) {
            .up => return self.x > other.x,
            .down => return self.x < other.x,
            .left => return self.y > other.y,
            .right => return self.y < other.y,
        }
    }
};

const Box = struct {
    x1: usize,
    y1: usize,
    y2: usize,

    pub fn init(x1: usize, y1: usize, y2: usize) Box {
        return Box{
            .x1 = x1,
            .y1 = y1,
            .y2 = y2,
        };
    }
};

const Direction = enum {
    up,
    down,
    left,
    right,

    pub fn get_next(self: Direction, p: Point) Point {
        switch (self) {
            .up => return Point.init(p.x - 1, p.y),
            .down => return Point.init(p.x + 1, p.y),
            .left => return Point.init(p.x, p.y - 1),
            .right => return Point.init(p.x, p.y + 1),
        }
    }

    pub fn opposite(self: Direction) Direction {
        switch (self) {
            .up => return .down,
            .down => return .up,
            .left => return .right,
            .right => return .left,
        }
    }

    pub fn to_string(self: Direction) []const u8 {
        return switch (self) {
            .up => "UP",
            .down => "DOWN",
            .left => "LEFT",
            .right => "RIGHT",
        };
    }
};

const Robot = struct {
    const Self = @This();
    position: Point,

    pub fn init(p: Point) Self {
        return Self{
            .position = p,
        };
    }

    pub fn move(self: *Self, dir: Direction) void {
        const next = dir.get_next(self.position);
        var next_wall = next;
        var next_empty = next;

        // find next empty space in direction
        while (grid.items[next_empty.x].items[next_empty.y] != '.') {
            if (grid.items[next_empty.x].items[next_empty.y] == '#') {
                return;
            }
            next_empty = dir.get_next(next_empty);
        }

        // no empty space in direction, so do nothing
        if (next_empty.equals(self.position)) {
            return;
        }

        // get position of wall
        while (grid.items[next_wall.x].items[next_wall.y] != '#') {
            next_wall = dir.get_next(next_wall);
        }

        // wall is before empty space, so do nothing
        if (next_wall.is_before(next_empty, dir)) {
            return;
        }

        const opp = dir.opposite();
        while (next_empty.is_before(self.position, opp)) {
            const traveler = opp.get_next(next_empty);
            grid.items[next_empty.x].items[next_empty.y] = grid.items[traveler.x].items[traveler.y];
            next_empty = traveler;
        }
        self.position = next;
        grid.items[next_empty.x].items[next_empty.y] = '.';
    }

    pub fn move2(self: *Self, dir: Direction) void {
        const next = dir.get_next(self.position);
        var next_wall = next;
        var next_empty = next;

        // find next empty space in direction
        while (grid.items[next_empty.x].items[next_empty.y] != '.') {
            if (grid.items[next_empty.x].items[next_empty.y] == '#') {
                return;
            }
            next_empty = dir.get_next(next_empty);
        }

        // no empty space in direction, so do nothing
        if (next_empty.equals(self.position)) {
            return;
        }

        // get position of wall
        while (grid.items[next_wall.x].items[next_wall.y] != '#') {
            next_wall = dir.get_next(next_wall);
        }

        // wall is before empty space, so do nothing
        if (next_wall.is_before(next_empty, dir)) {
            return;
        }

        const ne_i: i64 = @intCast(next_empty.x);
        const s_i: i64 = @intCast(self.position.x);
        const distance: usize = @abs(ne_i - s_i);
        if (distance == 1) {
            grid.items[next_empty.x].items[next_empty.y] = '@';
            grid.items[self.position.x].items[self.position.y] = '.';
            self.position = next;
            return;
        }

        var i: usize = 0;
        var boxes_to_be_pushed = std.AutoHashMap(Box, void).init(alloc);
        defer boxes_to_be_pushed.deinit();
        var boxes_queue = std.ArrayList(Box).init(alloc);
        defer boxes_queue.deinit();

        const x_usize: usize = @intCast(next.x);
        const y_usize: usize = @intCast(next.y);

        var cleanup_points = std.ArrayList(Point).init(alloc);
        var last_count: usize = 0;
        while (i == 0 or boxes_to_be_pushed.count() != last_count) {
            last_count = boxes_to_be_pushed.count();
            if (i == 0) {
                if (grid.items[x_usize].items[y_usize] == '[') {
                    const box = Box.init(x_usize, y_usize, y_usize + 1);
                    cleanup_points.append(Point.init(x_usize, y_usize)) catch unreachable;
                    cleanup_points.append(Point.init(x_usize, y_usize + 1)) catch unreachable;
                    boxes_to_be_pushed.put(box, {}) catch unreachable;
                } else if (grid.items[x_usize].items[y_usize] == ']') {
                    const box = Box.init(x_usize, y_usize - 1, y_usize);
                    cleanup_points.append(Point.init(x_usize, y_usize)) catch unreachable;
                    cleanup_points.append(Point.init(x_usize, y_usize - 1)) catch unreachable;
                    boxes_to_be_pushed.put(box, {}) catch unreachable;
                }
                i += 1;
                continue;
            }
            var final_it = boxes_to_be_pushed.iterator();
            if (i == distance) {
                while (final_it.next()) |box| {
                    const b = box.key_ptr.*;
                    const x1: usize = @intCast(b.x1);
                    const y1: usize = @intCast(b.y1);
                    const y2: usize = @intCast(b.y2);

                    const x1y1_next = dir.get_next(Point.init(x1, y1));
                    const x1y2_next = dir.get_next(Point.init(x1, y2));
                    const x1y1_x_next_usize: usize = @intCast(x1y1_next.x);
                    const x1y2_x_next_usize: usize = @intCast(x1y2_next.x);
                    const x1y1_y_next_usize: usize = @intCast(x1y1_next.y);
                    const x1y2_y_next_usize: usize = @intCast(x1y2_next.y);

                    if (grid.items[x1y1_x_next_usize].items[x1y1_y_next_usize] == '#') {
                        return;
                    }

                    if (grid.items[x1y2_x_next_usize].items[x1y2_y_next_usize] == '#') {
                        return;
                    }
                }
            }
            var it = boxes_to_be_pushed.iterator();
            while (it.next()) |box| {
                const b = box.key_ptr.*;
                const x1: usize = @intCast(b.x1);
                const y1: usize = @intCast(b.y1);
                const y2: usize = @intCast(b.y2);

                const x1y1_next = dir.get_next(Point.init(x1, y1));
                const x1y2_next = dir.get_next(Point.init(x1, y2));
                const x1y1_x_next_usize: usize = @intCast(x1y1_next.x);
                const x1y2_x_next_usize: usize = @intCast(x1y2_next.x);
                const x1y1_y_next_usize: usize = @intCast(x1y1_next.y);
                const x1y2_y_next_usize: usize = @intCast(x1y2_next.y);

                if (grid.items[x1y1_x_next_usize].items[x1y1_y_next_usize] == '#') {
                    return;
                }

                if (grid.items[x1y2_x_next_usize].items[x1y2_y_next_usize] == '#') {
                    return;
                }

                if (grid.items[x1y1_x_next_usize].items[x1y1_y_next_usize] == '[') {
                    const new_b = Box.init(x1y1_next.x, x1y1_next.y, x1y1_next.y + 1);
                    cleanup_points.append(Point.init(x1y1_next.x, x1y1_next.y)) catch unreachable;
                    cleanup_points.append(Point.init(x1y1_next.x, x1y1_next.y + 1)) catch unreachable;
                    boxes_queue.append(new_b) catch unreachable;
                } else if (grid.items[x1y1_x_next_usize].items[x1y1_y_next_usize] == ']') {
                    const new_b = Box.init(x1y1_next.x, x1y1_next.y - 1, x1y1_next.y);
                    cleanup_points.append(Point.init(x1y1_next.x, x1y1_next.y)) catch unreachable;
                    cleanup_points.append(Point.init(x1y1_next.x, x1y1_next.y - 1)) catch unreachable;
                    boxes_queue.append(new_b) catch unreachable;
                }

                if (grid.items[x1y2_x_next_usize].items[x1y2_y_next_usize] == '[') {
                    const new_b = Box.init(x1y2_next.x, x1y2_next.y, x1y2_next.y + 1);
                    cleanup_points.append(Point.init(x1y2_next.x, x1y2_next.y)) catch unreachable;
                    cleanup_points.append(Point.init(x1y2_next.x, x1y2_next.y + 1)) catch unreachable;
                    boxes_queue.append(new_b) catch unreachable;
                } else if (grid.items[x1y2_x_next_usize].items[x1y2_y_next_usize] == ']') {
                    const new_b = Box.init(x1y2_next.x, x1y2_next.y - 1, x1y2_next.y);
                    cleanup_points.append(Point.init(x1y2_next.x, x1y2_next.y)) catch unreachable;
                    cleanup_points.append(Point.init(x1y2_next.x, x1y2_next.y - 1)) catch unreachable;
                    boxes_queue.append(new_b) catch unreachable;
                }
            }
            for (boxes_queue.items) |box| {
                boxes_to_be_pushed.put(box, {}) catch unreachable;
                const after_box = dir.get_next(Point.init(box.x1, box.y1));
                const next_right = dir.get_next(Point.init(box.x1, box.y2));

                const next_x: usize = @intCast(after_box.x);
                const next_y1: usize = @intCast(after_box.y);
                const next_y2: usize = @intCast(next_right.y);

                if (grid.items[next_x].items[next_y1] == '#') {
                    return;
                }

                if (grid.items[next_x].items[next_y2] == '#') {
                    return;
                }
            }

            i += 1;
        }

        for (cleanup_points.items) |point| {
            grid.items[point.x].items[point.y] = '.';
        }

        var it = boxes_to_be_pushed.iterator();
        while (it.next()) |box| {
            const b = box.key_ptr.*;
            var adjustment: i64 = 1;
            if (dir == .up) {
                adjustment = -1;
            }
            const bx_i64: i64 = @intCast(b.x1);
            const bx: i64 = bx_i64 + adjustment;
            const x1: usize = @intCast(bx);
            const y1: usize = @intCast(b.y1);
            const y2: usize = @intCast(b.y2);

            grid.items[x1].items[y1] = '[';
            grid.items[x1].items[y2] = ']';
        }

        const self_x_usize: usize = @intCast(self.position.x);
        const self_y_usize: usize = @intCast(self.position.y);
        grid.items[self_x_usize].items[self_y_usize] = '.';

        self.position = next;
        const x_u: usize = @intCast(next.x);
        const y_u: usize = @intCast(next.y);
        grid.items[x_u].items[y_u] = '@';
    }
};

pub fn get_direction(c: u8) !Direction {
    switch (c) {
        '^' => return .up,
        'v' => return .down,
        '>' => return .right,
        '<' => return .left,
        else => return error.InvalidDirection,
    }
}

pub fn parse(input: []const u8) !void {
    var lines = std.mem.tokenizeSequence(u8, input, "\n");
    var i: usize = 0;
    while (lines.next()) |line| {
        if (std.mem.startsWith(u8, line, "#")) {
            var list = std.ArrayList(u8).init(alloc);
            var j: usize = 0;
            for (line) |c| {
                list.append(c) catch unreachable;
                if (c == '@') {
                    robot = Robot.init(Point.init(i, j));
                }
                j += 1;
            }
            grid.append(list) catch unreachable;
        } else {
            for (line) |c| {
                const dir = try get_direction(c);
                moves.append(dir) catch unreachable;
            }
        }
        i += 1;
    }
}

pub fn parse_2(input: []const u8) !void {
    var lines = std.mem.tokenizeSequence(u8, input, "\n");
    var i: usize = 0;
    while (lines.next()) |line| {
        if (std.mem.startsWith(u8, line, "#")) {
            var list = std.ArrayList(u8).init(alloc);
            var j: usize = 0;
            for (line) |c| {
                if (c == '@') {
                    robot = Robot.init(Point.init(i, j));
                    list.append(c) catch unreachable;
                    list.append('.') catch unreachable;
                } else if (c == 'O') {
                    list.append('[') catch unreachable;
                    list.append(']') catch unreachable;
                } else {
                    list.append(c) catch unreachable;
                    list.append(c) catch unreachable;
                }
                j += 2;
            }
            grid.append(list) catch unreachable;
        } else {
            for (line) |c| {
                const dir = try get_direction(c);
                moves.append(dir) catch unreachable;
            }
        }
        i += 1;
    }
}

pub fn print_grid() void {
    var break_program = false;
    var last_printed: u8 = undefined;
    for (grid.items) |row| {
        for (row.items) |cell| {
            if (last_printed == '[' and cell != ']') {
                break_program = true;
            }
            print("{c}", .{cell});
            last_printed = cell;
        }
        print("\n", .{});
    }

    if (break_program) {
        std.process.exit(1);
    }
}

pub fn do_robots_moves() void {
    for (moves.items) |move| {
        robot.move(move);
    }
}

pub fn count_walls() usize {
    var walls: usize = 0;
    for (grid.items) |row| {
        for (row.items) |cell| {
            if (cell == '[' or cell == ']') {
                walls += 1;
            }
        }
    }

    return walls;
}

pub fn do_robots_moves_2() void {
    if (DEBUG) {
        var last_execution: i128 = std.time.nanoTimestamp();
        var i: usize = 0;
        while (true) {
            // check if 3 seconds have passed since last execution
            const current_time: i128 = std.time.nanoTimestamp();
            if (current_time - last_execution >= 0.1 * 1_000_000_000) {
                if (i >= moves.items.len) {
                    break;
                }
                const move = moves.items[i];
                print("MOVING {s} | {}/{}\n", .{ move.to_string(), i, moves.items.len });
                if (move == .up or move == .down) {
                    robot.move2(move);
                } else {
                    robot.move(move);
                }
                print_grid();
                i += 1;
                last_execution = current_time;
            }
        }
        return;
    }
    for (moves.items) |move| {
        if (move == .up or move == .down) {
            robot.move2(move);
        } else {
            robot.move(move);
        }
    }
}

pub fn solve() usize {
    var gps_coordinates_sum: usize = 0;
    for (0..grid.items.len) |i| {
        for (0..grid.items[i].items.len) |j| {
            if (grid.items[i].items[j] == 'O') {
                gps_coordinates_sum += 100 * i + j;
            }
        }
    }

    return gps_coordinates_sum;
}

pub fn solve2() usize {
    var gps_coordinates_sum: usize = 0;
    for (0..grid.items.len) |i| {
        for (0..grid.items[i].items.len) |j| {
            if (grid.items[i].items[j] == '[') {
                gps_coordinates_sum += 100 * i + j;
            }
        }
    }

    return gps_coordinates_sum;
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();
    alloc = arena.allocator();

    moves = std.ArrayList(Direction).init(alloc);
    grid = std.ArrayList(std.ArrayList(u8)).init(alloc);

    try parse(data);
    do_robots_moves();
    const part_1 = solve();
    print("part_1={}\n", .{part_1});

    moves = std.ArrayList(Direction).init(alloc);
    grid = std.ArrayList(std.ArrayList(u8)).init(alloc);

    try parse_2(data);
    do_robots_moves_2();
    const part_2 = solve2();

    print("part_2={}\n", .{part_2});
}

test "part 1" {
    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();
    alloc = arena.allocator();

    moves = std.ArrayList(Direction).init(alloc);
    grid = std.ArrayList(std.ArrayList(u8)).init(alloc);

    try parse(test_data);
    do_robots_moves();
    const actual = solve();

    const expected = 10092;
    try testing.expectEqual(expected, actual);
}

test "part 2" {
    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();
    alloc = arena.allocator();

    moves = std.ArrayList(Direction).init(alloc);
    grid = std.ArrayList(std.ArrayList(u8)).init(alloc);

    try parse_2(test_data);
    do_robots_moves_2();

    const actual = solve2();

    const expected = 9021;
    try testing.expectEqual(expected, actual);
}
