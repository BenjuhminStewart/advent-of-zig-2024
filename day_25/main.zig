const std = @import("std");
const Allocator = std.mem.Allocator;
const data = @embedFile("input.txt");

const verbose = false;
fn log(comptime s: []const u8, args: anytype) void {
    if (verbose) print(s, args);
}
fn print(comptime s: []const u8, args: anytype) void {
    std.debug.print(s, args);
    printNewLine();
}
fn printNewLine() void {
    std.debug.print("\n", .{});
}

const Vec256 = @Vector(8, u64);
pub const Vec8 = @Vector(8, u8);

var gpa_impl = std.heap.GeneralPurposeAllocator(.{}){};
var gpa = gpa_impl.allocator();

var alloc: Allocator = undefined;

var keys: []Vec8 = undefined;
var locks: []Vec8 = undefined;
pub fn parse(input: []const u8) void {
    var keylist = std.ArrayList(Vec8).init(alloc);
    var locklist = std.ArrayList(Vec8).init(alloc);
    var key: bool = false;
    var curr: Vec8 = @splat(0);

    const lines = get_lines(input);
    for (lines) |line| {
        if (line.len == 0) {
            if (key) {
                keylist.append(curr) catch unreachable;
            } else {
                locklist.append(curr) catch unreachable;
            }

            curr = @splat(0);
            key = false;
        } else {
            key = line[0] == '#';
            for (line, 0..) |c, i| {
                if (c == '#') curr[i] += 1;
            }
        }
    }
    if (key) {
        keylist.append(curr) catch unreachable;
    } else {
        locklist.append(curr) catch unreachable;
    }
    keys = keylist.items;
    locks = locklist.items;
}

pub fn get_lines(input: []const u8) [][]const u8 {
    var lines = std.ArrayList([]const u8).init(alloc);
    var iter = std.mem.splitAny(u8, input, "\n");
    while (iter.next()) |line| lines.append(line) catch unreachable;
    if (lines.items[lines.items.len - 1].len == 0) _ = lines.pop();
    return lines.items;
}

pub fn opens_lock(key: Vec8, lock: Vec8) bool {
    const sum = key + lock;
    const max: Vec8 = @splat(8);
    return std.simd.countTrues(sum < max) == 8;
}

pub fn part1() void {
    var total: usize = 0;
    for (keys) |key| {
        for (locks) |lock| {
            if (opens_lock(key, lock)) {
                total += 1;
            }
        }
    }
    print("part_1={}", .{total});
}

pub fn part2() void {
    print("part_2=NONE!", .{});
    print("\n🎉 AoC 2024 Complete! 🎉", .{});
}

pub fn main() void {
    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();
    alloc = arena.allocator();
    print("\n[ Day 25 ]", .{});

    parse(data);
    part1();
    part2();
}
