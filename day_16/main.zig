const std = @import("std");
const Allocator = std.mem.Allocator;
const print = std.debug.print;
const data = @embedFile("input.txt");

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

pub fn print_grid() void {
    for (grid.items) |row| {
        for (row.items) |cell| {
            print("{c}", .{cell});
        }
        print("\n", .{});
    }
}

var part_1: i64 = std.math.maxInt(i64);
pub fn solve() !void {
    const start_state = State.init(start, .right);

    var pq: std.PriorityQueue(CostState, void, CostState.less_than) = undefined;
    defer pq.deinit();
    pq = std.PriorityQueue(CostState, void, CostState.less_than).init(alloc, {});
    pq.add(CostState.init(start_state, 0)) catch unreachable;

    // Data Structures
    var lowest_cost: std.AutoHashMap(State, i64) = undefined;
    defer lowest_cost.deinit();
    lowest_cost = std.AutoHashMap(State, i64).init(alloc);
    lowest_cost.put(start_state, 0) catch unreachable;

    var backtrack: std.AutoHashMap(State, *std.AutoHashMap(State, void)) = undefined;
    defer backtrack.deinit();
    backtrack = std.AutoHashMap(State, *std.AutoHashMap(State, void)).init(alloc);

    var end_states: std.AutoHashMap(State, void) = undefined;
    end_states = std.AutoHashMap(State, void).init(alloc);
    var best_cost: i64 = std.math.maxInt(i64);

    // Djikstra Loop
    while (pq.items.len > 0) {
        const cost_state = pq.remove();
        const cost = cost_state.cost;
        const r: usize = @intCast(cost_state.s.p.x);
        const c: usize = @intCast(cost_state.s.p.y);
        const dir: direction = cost_state.s.dir;
        const old_state = cost_state.s;

        if (cost > lowest_cost.get(cost_state.s).?) {
            continue;
        }

        if (grid.items[r].items[c] == 'E') {
            if (cost > best_cost) break;
            if (cost < part_1) {
                part_1 = cost;
            }
            best_cost = cost;
            end_states.put(cost_state.s, {}) catch unreachable;
        }

        const current_dir = CostState.init(State.init(dir.get_next(cost_state.s.p), dir), cost + 1);
        const cw = CostState.init(State.init(cost_state.s.p, dir.get_clockwise()), cost + 1000);
        const ccw = CostState.init(State.init(cost_state.s.p, dir.get_counter_clockwise()), cost + 1000);

        const travelers = [3]CostState{ current_dir, cw, ccw };
        for (travelers) |traveler| {
            const nr: usize = @intCast(traveler.s.p.x);
            const nc: usize = @intCast(traveler.s.p.y);
            if (grid.items[nr].items[nc] == '#') continue;

            const new_key = State.init(traveler.s.p, traveler.s.dir);
            const lowest = lowest_cost.get(new_key) orelse std.math.maxInt(i64);
            if (traveler.cost > lowest) continue;

            if (traveler.cost < lowest) {
                const set = alloc.create(std.AutoHashMap(State, void)) catch unreachable;
                set.* = std.AutoHashMap(State, void).init(alloc);
                backtrack.put(new_key, set) catch unreachable;
                lowest_cost.put(new_key, traveler.cost) catch unreachable;
            }
            backtrack.get(new_key).?.put(old_state, {}) catch unreachable;
            try pq.add(traveler);
        }
    }

    var states: std.ArrayList(State) = undefined;
    states = std.ArrayList(State).init(alloc);

    var seen: std.AutoHashMap(State, void) = undefined;
    seen = std.AutoHashMap(State, void).init(alloc);

    var it_end_states = end_states.iterator();
    while (it_end_states.next()) |end_state| {
        const state = end_state.key_ptr.*;
        states.insert(0, state) catch unreachable;
        seen.put(state, {}) catch unreachable;
    }

    while (states.items.len > 0) {
        const key = states.pop().?;
        if (!backtrack.contains(key)) continue;
        var it_backtrack = backtrack.get(key).?.iterator();
        while (it_backtrack.next()) |kv| {
            const last = kv.key_ptr.*;
            if (!seen.contains(last)) {
                seen.put(last, {}) catch unreachable;
                states.insert(0, last) catch unreachable;
            }
        }
    }

    var unique_states = std.AutoHashMap(Point, void).init(alloc);
    var it_seen = seen.iterator();
    while (it_seen.next()) |kv| {
        const state = kv.key_ptr.*;
        unique_states.put(state.p, {}) catch unreachable;
    }

    print("part_1={any}\n", .{part_1});
    print("part_2={any}\n", .{unique_states.count()});
}

pub fn main() !void {
    print("\n[ Day 16 ]\n", .{});
    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();
    alloc = arena.allocator();

    grid = std.ArrayList(std.ArrayList(u8)).init(alloc);
    parse(data);
    try solve();
}
