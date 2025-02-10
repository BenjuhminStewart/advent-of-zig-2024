const std = @import("std");
const Allocator = std.mem.Allocator;
const print = std.debug.print;
const data = @embedFile("input.txt");
const test_data = @embedFile("test_input.txt");
const testing = std.testing;

var gpa_impl = std.heap.GeneralPurposeAllocator(.{}){};
var gpa = gpa_impl.allocator();

var stones: std.AutoHashMap(u64, u64) = undefined;

var alloc: Allocator = undefined;

const SplitStone = struct {
    left: u64,
    right: u64,
};

pub fn parse(input: []const u8) void {
    stones = std.AutoHashMap(u64, u64).init(alloc);
    var lines = std.mem.tokenizeSequence(u8, input, "\n");
    while (lines.next()) |line| {
        var nums = std.mem.tokenizeSequence(u8, line, " ");
        while (nums.next()) |num| {
            const stone = std.fmt.parseInt(u64, num, 10) catch unreachable;
            if (!stones.contains(stone)) {
                stones.put(stone, 0) catch unreachable;
            }
            stones.put(stone, stones.get(stone).? + 1) catch unreachable;
        }
    }
}

pub fn solve(blinks: usize) !u64 {
    for (0..blinks) |_| {
        var stones_dest = std.AutoHashMap(u64, u64).init(alloc);
        defer stones_dest.deinit();
        var it = stones.iterator();
        while (it.next()) |entry| {
            const k = entry.key_ptr.*;
            const v = entry.value_ptr.*;

            if (k == 0) {
                const t = try stones_dest.getOrPut(1);
                if (!t.found_existing) {
                    t.value_ptr.* = 0;
                }
                t.value_ptr.* += v;
                continue;
            }
            const digits = length_of_stone(k);
            if (digits % 2 == 0) {
                const split_stone = split(k, digits) catch {
                    return error.SplitError;
                };
                var t = try stones_dest.getOrPut(split_stone.left);
                if (!t.found_existing) {
                    t.value_ptr.* = 0;
                }
                t.value_ptr.* += v;
                t = try stones_dest.getOrPut(split_stone.right);
                if (!t.found_existing) {
                    t.value_ptr.* = 0;
                }
                t.value_ptr.* += v;
                continue;
            }
            const t = try stones_dest.getOrPut(k * 2024);
            if (!t.found_existing) {
                t.value_ptr.* = 0;
            }
            t.value_ptr.* += v;
            continue;
        }
        stones = stones_dest.clone() catch {
            return error.CloneError;
        };
    }
    var num_stones: u64 = 0;
    var it = stones.iterator();
    while (it.next()) |entry| {
        const v = entry.value_ptr.*;
        num_stones += v;
    }
    return num_stones;
}

pub fn split(stone: u64, length: u64) !SplitStone {
    const half_digits = length / 2;

    const splitter: usize = try std.math.powi(usize, 10, half_digits);

    const first_num = stone / splitter;
    const second_num = stone % splitter;

    return SplitStone{
        .left = first_num,
        .right = second_num,
    };
}

pub fn length_of_stone(stone: u64) u64 {
    return std.math.log10(stone) + 1;
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();
    alloc = arena.allocator();

    parse(data);
    const part_1 = solve(25) catch {
        return error.Part1;
    };
    print("part_1={any}\n", .{part_1});

    parse(data);
    const part_2 = solve(75);
    print("part_2={any}\n", .{part_2});
}

test "small" {
    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();
    alloc = arena.allocator();

    parse(test_data);
    const expected = 22;
    const actual = solve(6);
    try testing.expectEqual(expected, actual);
}

test "part 1" {
    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();
    alloc = arena.allocator();

    parse(test_data);
    const expected = 55312;
    const actual = solve(25);
    try testing.expectEqual(expected, actual);
}
