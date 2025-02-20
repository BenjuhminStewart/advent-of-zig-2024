const std = @import("std");
const Allocator = std.mem.Allocator;
const print = std.debug.print;
const data = @embedFile("input.txt");

var gpa_impl = std.heap.GeneralPurposeAllocator(.{}){};
var gpa = gpa_impl.allocator();

var alloc: Allocator = undefined;

var robots: std.ArrayList(Robot) = undefined;

const Velocity = struct {
    dx: i64,
    dy: i64,

    pub fn init(dx: i64, dy: i64) Velocity {
        return Velocity{
            .dx = dx,
            .dy = dy,
        };
    }
};

const Point = struct {
    x: i64,
    y: i64,

    pub fn init(x: i64, y: i64) Point {
        return Point{
            .x = x,
            .y = y,
        };
    }
};

const Robot = struct {
    position: Point,
    velocity: Velocity,
    quadrant: quadrant,

    pub fn init(position: Point, velocity: Velocity, q: quadrant) Robot {
        return Robot{
            .position = position,
            .velocity = velocity,
            .quadrant = q,
        };
    }

    pub fn move(self: *Robot, width: i64, height: i64) void {
        self.position.x = @mod(self.position.x + self.velocity.dx, width);
        self.position.y = @mod(self.position.y + self.velocity.dy, height);
        self.quadrant = get_quadrant(self.position, width, height);
    }
};

const quadrant = enum {
    top_left,
    top_right,
    bottom_left,
    bottom_right,
    none,

    pub fn to_string(self: quadrant) []const u8 {
        return switch (self) {
            quadrant.top_left => "top_left",
            quadrant.top_right => "top_right",
            quadrant.bottom_left => "bottom_left",
            quadrant.bottom_right => "bottom_right",
            quadrant.none => "none",
        };
    }
};

pub fn get_quadrant(p: Point, width: i64, height: i64) quadrant {
    const mid_width = @divFloor(width, 2);
    const mid_height = @divFloor(height, 2);
    if (p.x < mid_width and p.y < mid_height) {
        return quadrant.top_left;
    } else if (p.x < mid_width and p.y > mid_height) {
        return quadrant.bottom_left;
    } else if (p.x > mid_width and p.y < mid_height) {
        return quadrant.top_right;
    } else if (p.x > mid_width and p.y > mid_height) {
        return quadrant.bottom_right;
    } else {
        return quadrant.none;
    }
}

pub fn solve(width: i64, height: i64, seconds: i64) !i64 {
    var i: usize = 0;
    var has_matched: bool = false;
    while (i < seconds) {
        for (robots.items, 0..) |_, j| {
            robots.items[j].move(width, height);
        }
        i += 1;

        const matches = try matches_tree_heuristic();
        if (matches) {
            if (!has_matched) {
                print("{any}", .{i});
            } else {
                print(", {any}", .{i});
            }
            has_matched = true;
        }
    }

    var q1: i64 = 0;
    var q2: i64 = 0;
    var q3: i64 = 0;
    var q4: i64 = 0;

    for (robots.items) |robot| {
        switch (robot.quadrant) {
            quadrant.top_left => q1 += 1,
            quadrant.top_right => q2 += 1,
            quadrant.bottom_left => q3 += 1,
            quadrant.bottom_right => q4 += 1,
            quadrant.none => {},
        }
    }
    return q1 * q2 * q3 * q4;
}

pub fn parse(input: []const u8, width: i64, height: i64) !void {
    var lines = std.mem.tokenizeSequence(u8, input, "\n");
    while (lines.next()) |line| {
        var split = std.mem.tokenizeSequence(u8, line, " ");
        var left = split.next().?;
        var right = split.next().?;

        var pos_it = std.mem.tokenizeSequence(u8, left[2..], ",");
        const p_x = std.fmt.parseInt(i64, pos_it.next().?, 10) catch {
            return error.ParseError;
        };
        const p_y = std.fmt.parseInt(i64, pos_it.next().?, 10) catch {
            return error.ParseError;
        };

        var vel_it = std.mem.tokenizeSequence(u8, right[2..], ",");
        const v_x = std.fmt.parseInt(i64, vel_it.next().?, 10) catch {
            return error.ParseError;
        };
        const v_y = std.fmt.parseInt(i64, vel_it.next().?, 10) catch {
            return error.ParseError;
        };

        const position = Point.init(p_x, p_y);
        const velocity = Velocity.init(v_x, v_y);
        const q = get_quadrant(position, width, height);
        try robots.append(Robot.init(position, velocity, q));
    }
}

pub fn main() !void {
    print("\n[ Day 14 ]\n", .{});
    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();
    alloc = arena.allocator();

    robots = std.ArrayList(Robot).init(gpa);
    try parse(data, 101, 103);
    const part_1 = try solve(101, 103, 100);
    print("part_1={}\n", .{part_1});

    try parse(data, 101, 103);
    print("part_2=", .{});
    _ = try solve(101, 103, 7754);

    print("\n", .{});
}

const MATCHING_HEURISTIC: usize = 13;
pub fn matches_tree_heuristic() !bool {
    var points_of_robots = std.AutoHashMap(Point, void).init(gpa);
    defer points_of_robots.deinit();
    for (robots.items) |robot| {
        _ = points_of_robots.put(robot.position, {}) catch {
            return error.PutError;
        };
    }

    var consecutive_points: usize = 0;
    for (robots.items) |robot| {
        const robot_position = robot.position;
        var robot_position_right = Point.init(robot_position.x + 1, robot_position.y);
        while (points_of_robots.get(robot_position_right)) |_| {
            consecutive_points += 1;
            if (consecutive_points >= MATCHING_HEURISTIC) {
                return true;
            }
            robot_position_right.x += 1;
        }
        consecutive_points = 0;
    }

    return false;
}
