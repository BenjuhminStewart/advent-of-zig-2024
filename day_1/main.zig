const std = @import("std");
const fs = std.fs;
const print = std.debug.print;
const Allocator = std.mem.Allocator;
const parseInt = std.fmt.parseInt;

const data = @embedFile("input.txt");
var gpa_impl = std.heap.GeneralPurposeAllocator(.{}){};
const gpa = gpa_impl.allocator();

var alloc: std.mem.Allocator = undefined;

pub fn main() !void {
    print("\n[ Day 1 ]\n", .{});
    try part1();
    try part2();
}

pub fn part1() !void {
    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();
    alloc = arena.allocator();

    left = std.ArrayList(i32).init(alloc);
    right = std.ArrayList(i32).init(alloc);

    try parse();

    const part_1 = getDistance();
    print("part_1={d}\n", .{part_1});
}

pub fn part2() !void {
    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();
    alloc = arena.allocator();

    left = std.ArrayList(i32).init(alloc);
    right = std.ArrayList(i32).init(alloc);

    try parse();

    const part_2 = getSimilarityScore();
    print("part_2={d}\n", .{part_2});
}

var left: std.ArrayList(i32) = undefined;
var right: std.ArrayList(i32) = undefined;

pub fn parse() !void {
    var lines = std.mem.tokenizeScalar(u8, data, '\n');
    var i: usize = 0;
    while (lines.next()) |token| {
        var line = std.mem.tokenizeScalar(u8, token, ' ');
        while (line.next()) |number| {
            if (i % 2 == 0) {
                const num = parseInt(i32, number, 10) catch {
                    print("error parsing number: {s}\n", .{number});
                    return error.ParseError;
                };
                left.append(num) catch return {
                    return error.OutOfMemory;
                };
            } else {
                const num = parseInt(i32, number, 10) catch {
                    print("error parsing number: {s}\n", .{number});
                    return error.ParseError;
                };
                right.append(num) catch return {
                    return error.OutOfMemory;
                };
            }
            i += 1;
        }
    }
}

pub fn getDistance() u32 {
    var distance: u32 = 0;
    std.mem.sort(i32, left.items, {}, std.sort.asc(i32));
    std.mem.sort(i32, right.items, {}, std.sort.asc(i32));

    for (left.items, right.items) |left_word, right_word| {
        const local_distance = right_word - left_word;
        distance += @abs(local_distance);
    }

    return distance;
}
pub fn getSimilarityScore() i32 {
    var score: i32 = 0;

    var map = std.AutoHashMap(i32, i32).init(alloc);
    defer map.deinit();

    for (left.items) |left_word| {
        map.put(left_word, 0) catch unreachable;
    }

    for (right.items) |right_word| {
        if (map.get(right_word)) |count| {
            map.put(right_word, count + 1) catch unreachable;
        } else {
            map.put(right_word, 1) catch unreachable;
        }
    }

    for (left.items) |left_word| {
        score += left_word * map.get(left_word).?;
    }
    return score;
}
