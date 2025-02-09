const std = @import("std");
const Allocator = std.mem.Allocator;
const print = std.debug.print;
const data = @embedFile("input.txt");
const test_data = @embedFile("test_input.txt");
const testing = std.testing;

var gpa_impl = std.heap.GeneralPurposeAllocator(.{}){};
var gpa = gpa_impl.allocator();

var stones: std.ArrayList(u64) = undefined;
var stone_map: std.AutoHashMap(u64, SplitStone) = undefined;

var alloc: Allocator = undefined;

const SplitStone = struct {
    left: u64,
    right: u64,
};

pub fn parse(input: []const u8) void {
    stones = std.ArrayList(u64).init(alloc);
    var lines = std.mem.tokenizeSequence(u8, input, "\n");
    while (lines.next()) |line| {
        var nums = std.mem.tokenizeSequence(u8, line, " ");
        while (nums.next()) |num| {
            const stone = std.fmt.parseInt(u64, num, 10) catch unreachable;
            stones.append(stone) catch unreachable;
        }
    }
}

pub fn solve(blinks: usize) u64 {
    var curr_blinks: usize = 0;
    while (curr_blinks < blinks) {
        var i: usize = 0;
        while (i < stones.items.len) : (i += 1) {
            const stone = stones.items[i];
            if (stone == 0) {
                stones.items[i] = 1;
                continue;
            }

            const length = length_of_stone(stone);
            if (length % 2 == 0) {
                const split_stone = split(stone, length);
                stones.items[i] = split_stone.left;
                stones.insert(i + 1, split_stone.right) catch unreachable;
                i += 1;
                continue;
            } else {
                stones.items[i] = stone * 2024;
            }
        }
        curr_blinks += 1;
        print("blinks={}\n", .{curr_blinks});
    }

    return stones.items.len;
}

pub fn split(stone: u64, length: u64) SplitStone {
    var divisor: u32 = 1;
    const half_digits: u64 = length / 2;
    var i: u32 = 0;
    while (i < half_digits) : (i += 1) {
        divisor *= 10;
    }

    const first_part = stone / divisor;
    const second_part = stone % divisor;

    return SplitStone{
        .left = first_part,
        .right = second_part,
    };
}

pub fn length_of_stone(stone: u64) u64 {
    return std.math.log10(stone) + 1;
}

pub fn main() void {
    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();
    alloc = arena.allocator();

    parse(data);
    const part_1 = solve(25);
    print("part_1={}\n", .{part_1});

    // parse(data);
    // const part_2 = solve(75);
    // print("part_2={}\n", .{part_2});
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
