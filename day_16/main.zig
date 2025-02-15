const std = @import("std");
const Allocator = std.mem.Allocator;
const print = std.debug.print;
const data = @embedFile("input.txt");
const test_data = @embedFile("test_input.txt");
const testing = std.testing;

var gpa_impl = std.heap.GeneralPurposeAllocator(.{}){};
var gpa = gpa_impl.allocator();

var alloc: Allocator = undefined;

const direction = enum {
    up,
    down,
    left,
    right,

    pub fn get_next(self: direction, p: Point) Point {
        return switch (self) {
            .up => Point.init(p.x - 1, p.y),
            .down => Point.init(p.x + 1, p.y),
            .left => Point.init(p.x, p.y - 1),
            .right => Point.init(p.x, p.y + 1),
        };
    }

    pub fn get_clockwise(self: direction) direction {
        return switch (self) {
            .up => .right,
            .down => .left,
            .left => .up,
            .right => .down,
        };
    }

    pub fn get_counter_clockwise(self: direction) direction {
        return switch (self) {
            .up => .left,
            .down => .right,
            .left => .down,
            .right => .up,
        };
    }

    pub fn to_string(self: direction) []const u8 {
        return switch (self) {
            .up => "up",
            .down => "down",
            .left => "left",
            .right => "right",
        };
    }
};

const Point = struct {
    x: i32,
    y: i32,

    pub fn init(x: i32, y: i32) Point {
        return Point{
            .x = x,
            .y = y,
        };
    }

    pub fn equals(self: Point, other: Point) bool {
        return self.x == other.x and self.y == other.y;
    }
};

const State = struct {
    p: Point,
    dir: direction,

    pub fn print_self(self: State) void {
        print("({},{}) | dir: {s}", .{ self.p.x, self.p.y, self.dir.to_string() });
    }

    pub fn init(p: Point, dir: direction) State {
        return State{
            .p = p,
            .dir = dir,
        };
    }
};

const CostState = struct {
    s: State,
    cost: i64,

    pub fn less_than(context: void, a: CostState, b: CostState) std.math.Order {
        _ = context;
        return std.math.order(a.cost, b.cost);
    }

    pub fn init(s: State, cost: i64) CostState {
        return CostState{
            .s = s,
            .cost = cost,
        };
    }
};

var grid: std.ArrayList(std.ArrayList(u8)) = undefined;
var start: Point = undefined;
var end: Point = undefined;

pub fn parse(input: []const u8) void {
    var lines = std.mem.tokenizeSequence(u8, input, "\n");
    var i: i32 = 0;
    while (lines.next()) |line| {
        var list = std.ArrayList(u8).init(alloc);
        var j: i32 = 0;
        for (line) |c| {
            list.append(c) catch unreachable;
            if (c == 'S') {
                start = Point.init(i, j);
            }
            if (c == 'E') {
                end = Point.init(i, j);
            }
            j += 1;
        }
        grid.append(list) catch unreachable;
        i += 1;
    }
}

pub fn solve(pq: *std.PriorityQueue(CostState, void, CostState.less_than), visited: *std.AutoHashMap(State, void)) i64 {
    while (pq.items.len > 0) {
        const cost_state = pq.remove();
        const state = cost_state.s;
        const dir = state.dir;
        const cost = cost_state.cost;
        visited.put(state, {}) catch unreachable;
        var travelers = std.ArrayList(CostState).init(alloc);

        if (state.p.equals(end)) {
            return cost;
        }
        const same_state = State.init(dir.get_next(state.p), dir);
        const clockwise_state = State.init(state.p, dir.get_clockwise());
        const counter_clockwise_state = State.init(state.p, dir.get_counter_clockwise());

        const same_dir = CostState.init(same_state, cost + 1);
        const clockwise = CostState.init(clockwise_state, cost + 1000);
        const counter_clockwise = CostState.init(counter_clockwise_state, cost + 1000);

        travelers.append(same_dir) catch unreachable;
        travelers.append(clockwise) catch unreachable;
        travelers.append(counter_clockwise) catch unreachable;

        for (travelers.items) |ts| {
            const r: usize = @intCast(ts.s.p.x);
            const c: usize = @intCast(ts.s.p.y);
            const nd = ts.s.dir;

            if (grid.items[r].items[c] == '#') continue;
            const ns = State.init(ts.s.p, nd);
            if (visited.get(ns)) |_| continue;
            pq.add(ts) catch unreachable;
        }
    }

    return std.math.maxInt(i64);
}

pub fn print_grid() void {
    for (grid.items) |row| {
        for (row.items) |cell| {
            print("{c}", .{cell});
        }
        print("\n", .{});
    }
}

pub fn main() void {
    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();
    alloc = arena.allocator();

    grid = std.ArrayList(std.ArrayList(u8)).init(alloc);
    parse(data);

    var pq = std.PriorityQueue(CostState, void, CostState.less_than).init(alloc, {});
    var visited = std.AutoHashMap(State, void).init(alloc);

    const start_state = State{
        .p = start,
        .dir = .right,
    };
    visited.put(start_state, {}) catch unreachable;
    pq.add(CostState{
        .s = start_state,
        .cost = 0,
    }) catch unreachable;

    const actual = solve(&pq, &visited);
    print("part_1={}\n", .{actual});
}

test "part 1" {
    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();
    alloc = arena.allocator();

    grid = std.ArrayList(std.ArrayList(u8)).init(alloc);
    parse(test_data);

    var pq = std.PriorityQueue(CostState, void, CostState.less_than).init(alloc, {});
    var visited = std.AutoHashMap(State, void).init(alloc);

    const start_state = State{
        .p = start,
        .dir = .right,
    };
    visited.put(start_state, {}) catch unreachable;
    pq.add(CostState{
        .s = start_state,
        .cost = 0,
    }) catch unreachable;

    const actual = solve(&pq, &visited);
    print("part_1={}\n", .{actual});
}
