const std = @import("std");
const Allocator = std.mem.Allocator;
const data = @embedFile("input.txt");
const print = std.debug.print;

var gpa_impl = std.heap.GeneralPurposeAllocator(.{}){};
var gpa = gpa_impl.allocator();

var secrets: std.ArrayList(usize) = undefined;

var sequence_map: std.AutoArrayHashMap([4]i8, usize) = undefined;
var visited: std.AutoArrayHashMap([4]i8, void) = undefined;

var alloc: Allocator = undefined;

pub fn parse(input: []const u8) void {
    secrets = std.ArrayList(usize).init(alloc);
    sequence_map = std.AutoArrayHashMap([4]i8, usize).init(alloc);
    visited = std.AutoArrayHashMap([4]i8, void).init(alloc);

    var lines = std.mem.tokenizeScalar(u8, input, '\n');
    while (lines.next()) |line| {
        const secret = std.fmt.parseInt(usize, line, 10) catch unreachable;
        secrets.append(secret) catch unreachable;
    }
}

pub fn next_secret(secret: usize) usize {
    const step1 = prune(mix(secret, secret * 64));
    const step2 = prune(mix(step1, step1 / 32));
    const step3 = prune(mix(step2, step2 * 2048));

    return step3;
}

pub fn mix(secret: usize, other: usize) usize {
    return secret ^ other;
}

pub fn prune(secret: usize) usize {
    return @mod(secret, 16777216);
}

pub fn solve(input: []const u8) !void {
    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();
    alloc = arena.allocator();

    parse(input);

    var sum: usize = 0;

    for (secrets.items) |secret| {
        var curr = secret;
        var history = [4]i8{ 0, 0, 0, 0 };
        visited.clearRetainingCapacity();
        for (0..2000) |secret_i| {
            const next = next_secret(curr);
            const curr_mod: i8 = @intCast(curr % 10);
            const next_mod: i8 = @intCast(next % 10);

            const change: i8 = next_mod - curr_mod;
            curr = next;

            std.mem.copyForwards(i8, history[0..3], history[1..4]);
            history[3] = change;

            if (secret_i < 3) continue;

            if (visited.contains(history)) continue;
            try visited.putNoClobber(history, {});

            const gOP = try sequence_map.getOrPut(history);
            if (!gOP.found_existing) {
                gOP.value_ptr.* = 0;
            }
            gOP.value_ptr.* += @intCast(next_mod);
        }
        sum += curr;
    }

    var best_sequence: [4]i8 = undefined;
    var biggest_gain: usize = 0;

    var iter = sequence_map.iterator();
    while (iter.next()) |map_entry| {
        const history: *[4]i8 = map_entry.key_ptr;
        const banana_count: usize = map_entry.value_ptr.*;
        if (banana_count > biggest_gain) {
            best_sequence = history.*;
            biggest_gain = banana_count;
        }
    }

    print("part_1={}\n", .{sum});
    print("part_2={}\n", .{biggest_gain});
}

pub fn main() !void {
    print("\n[ Day 22 ]\n", .{});
    try solve(data);
}
