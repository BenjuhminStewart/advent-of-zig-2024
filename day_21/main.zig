const std = @import("std");
const Allocator = std.mem.Allocator;
const print = std.debug.print;
const data = @embedFile("input.txt");
const test_data = @embedFile("test_input.txt");
const testing = std.testing;

var gpa_impl = std.heap.GeneralPurposeAllocator(.{}){};
var gpa = gpa_impl.allocator();

var alloc: Allocator = undefined;

var codes: std.ArrayList([]const u8) = undefined;
var sequence_map: std.AutoHashMap(u8, std.AutoHashMap(u8, []const u8)) = undefined;

pub fn parse(input: []const u8) void {
    sequence_map = std.AutoHashMap(u8, std.AutoHashMap(u8, []const u8)).init(alloc);

    var inner_map_left = std.AutoHashMap(u8, []const u8).init(alloc);
    inner_map_left.put('>', ">>A") catch unreachable;
    inner_map_left.put('A', ">>^A") catch unreachable;
    inner_map_left.put('^', ">^A") catch unreachable;
    inner_map_left.put('v', ">A") catch unreachable;

    var inner_map_right = std.AutoHashMap(u8, []const u8).init(alloc);
    inner_map_right.put('<', "<<A") catch unreachable;
    inner_map_right.put('A', "^A") catch unreachable;
    inner_map_right.put('v', "<A") catch unreachable;
    inner_map_right.put('^', "<^A") catch unreachable;

    var inner_map_up = std.AutoHashMap(u8, []const u8).init(alloc);
    inner_map_up.put('v', "vA") catch unreachable;
    inner_map_up.put('A', ">A") catch unreachable;
    inner_map_up.put('>', "v>A") catch unreachable;
    inner_map_up.put('<', "v<A") catch unreachable;

    var inner_map_down = std.AutoHashMap(u8, []const u8).init(alloc);
    inner_map_down.put('^', "^A") catch unreachable;
    inner_map_down.put('A', "^>A") catch unreachable;
    inner_map_down.put('<', "<A") catch unreachable;
    inner_map_down.put('>', ">A") catch unreachable;

    var inner_map_A = std.AutoHashMap(u8, []const u8).init(alloc);
    inner_map_A.put('<', "v<<A") catch unreachable;
    inner_map_A.put('>', "vA") catch unreachable;
    inner_map_A.put('^', "<A") catch unreachable;
    inner_map_A.put('v', "<vA") catch unreachable;

    sequence_map.put('<', inner_map_left) catch unreachable;
    sequence_map.put('>', inner_map_right) catch unreachable;
    sequence_map.put('^', inner_map_up) catch unreachable;
    sequence_map.put('v', inner_map_down) catch unreachable;
    sequence_map.put('A', inner_map_A) catch unreachable;

    codes = std.ArrayList([]const u8).init(alloc);
    var lines = std.mem.tokenizeSequence(u8, input, "\n");
    while (lines.next()) |line| {
        codes.append(line) catch unreachable;
    }
}

pub fn get_y(num: u8) i64 {
    return switch (num) {
        '0', 'A' => 3,
        '1', '2', '3' => 2,
        '4', '5', '6' => 1,
        '7', '8', '9' => 0,
        else => -1,
    };
}

pub fn get_x(num: u8) i64 {
    return switch (num) {
        '1', '4', '7' => 0,
        '0', '2', '5', '8' => 1,
        'A', '3', '6', '9' => 2,
        else => -1,
    };
}

pub fn get_numeric_sequence(start: u8, end: u8) ![]const u8 {
    var sequence = std.ArrayList(u8).init(alloc);
    var order: [4]u8 = undefined;
    order = [4]u8{ '<', 'v', '^', '>' };

    if (start == end) {
        return "A";
    }

    if ((std.mem.containsAtLeastScalar(u8, "0A", 1, start) and std.mem.containsAtLeastScalar(u8, "147", 1, end)) or (std.mem.containsAtLeastScalar(u8, "147", 1, start) and std.mem.containsAtLeastScalar(u8, "0A", 1, end))) {
        order = [4]u8{ '^', '>', 'v', '<' };
    }

    const stepsUpDown = get_y(end) - get_y(start);
    const stepsLeftRight = get_x(end) - get_x(start);

    for (order) |c| {
        switch (c) {
            '<' => {
                if (stepsLeftRight < 0) {
                    const steps = @abs(stepsLeftRight);
                    for (0..steps) |_| {
                        try sequence.append('<');
                    }
                }
            },
            '>' => {
                if (stepsLeftRight > 0) {
                    const steps = @abs(stepsLeftRight);
                    for (0..steps) |_| {
                        try sequence.append('>');
                    }
                }
            },
            '^' => {
                if (stepsUpDown < 0) {
                    const steps = @abs(stepsUpDown);
                    for (0..steps) |_| {
                        try sequence.append('^');
                    }
                }
            },
            'v' => {
                if (stepsUpDown > 0) {
                    const steps = @abs(stepsUpDown);
                    for (0..steps) |_| {
                        try sequence.append('v');
                    }
                }
            },
            else => unreachable,
        }
    }
    try sequence.append('A');
    return sequence.toOwnedSlice();
}

pub fn keypad_cost(start: u8, end: u8, robots: usize) usize {
    var sequence = std.ArrayList(u8).init(alloc);
    var ok: bool = false;

    if (start == end) {
        sequence.append('A') catch unreachable;
        ok = true;
    } else {
        if (sequence_map.contains(start)) {
            const inner_map = sequence_map.get(start).?;
            if (inner_map.contains(end)) {
                const str = inner_map.get(end).?;
                sequence.appendSlice(str) catch unreachable;
                ok = true;
            }
        }
    }

    if (ok) {
        if (robots == 1) {
            return sequence.items.len;
        } else {
            return try cost(sequence.items, robots - 1);
        }
    }
    print("Unknown start: {c} or end: {c}\n", .{ start, end });
    return 0;
}

// SOURCE: https://github.com/p88h/aoc2024/blob/main/src/day21.zig
pub fn cache_key(code: []const u8, depth: usize) u64 {
    var ck: u64 = 0;
    for (code) |ch| ck = (ck << 8) | @as(u64, ch);
    // store depth in lowest bits
    return (ck << 8) + @as(u64, @intCast(depth));
}

var cache: std.AutoHashMap(u64, usize) = undefined;
pub fn cost(code: []const u8, robots: usize) !usize {
    const key = cache_key(code, robots);
    if (cache.get(key)) |cached| {
        return cached;
    }
    var result: usize = 0;
    var codes_with_A = std.ArrayList(u8).init(alloc);
    codes_with_A.append('A') catch unreachable;
    for (code) |c| {
        codes_with_A.append(c) catch unreachable;
    }
    var i: usize = 0;
    while (i < codes_with_A.items.len - 1) {
        result += keypad_cost(codes_with_A.items[i], codes_with_A.items[i + 1], robots);
        i += 1;
    }
    cache.put(key, result) catch unreachable;
    return result;
}

pub fn get_complexity(code: []const u8, robots: usize) !usize {
    var sequence = std.ArrayList(u8).init(alloc);
    var new_code = std.ArrayList(u8).init(alloc);
    new_code.append('A') catch unreachable;
    for (code) |c| {
        new_code.append(c) catch unreachable;
    }
    var i: usize = 0;
    while (i < new_code.items.len - 1) {
        const numeric_sequence = try get_numeric_sequence(new_code.items[i], new_code.items[i + 1]);
        try sequence.appendSlice(numeric_sequence);
        i += 1;
    }

    const len = try cost(sequence.items, robots);
    const num = get_usable_code(code);
    return len * num;
}

pub fn get_usable_code(code: []const u8) usize {
    var sequence = std.ArrayList(u8).init(alloc);
    var is_leading_zero = true;
    for (code) |c| {
        if (is_leading_zero and c == '0') continue;
        if (c == 'A') continue;
        is_leading_zero = false;
        sequence.append(c) catch unreachable;
    }
    const sequence_str: []const u8 = sequence.items;
    const num = std.fmt.parseInt(usize, sequence_str, 10) catch unreachable;
    return num;
}

pub fn solve(input: []const u8, robots: usize) !usize {
    cache = std.AutoHashMap(u64, usize).init(alloc);
    parse(input);
    var complexity: usize = 0;
    for (codes.items) |code| {
        const result = try get_complexity(code, robots);
        complexity += result;
    }
    return complexity;
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();
    alloc = arena.allocator();

    const complexity_1 = try solve(data, 2);
    print("part_1={}\n", .{complexity_1});

    const complexity_2 = try solve(data, 25);
    print("part_2={}\n", .{complexity_2});
}
