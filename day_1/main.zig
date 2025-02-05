const std = @import("std");
const fs = std.fs;
const print = std.debug.print;
const Allocator = std.mem.Allocator;
const parseInt = std.fmt.parseInt;

const data = @embedFile("input.txt");

pub fn main() !void {
    const score = getSimilarityScore(data);
    const distance = getDistance(data);

    print("Distance: {d}\n", .{distance});
    print("Similarity Score: {d}\n", .{score});
}

pub fn getDistance(input: []const u8) u32 {
    var distance: u32 = 0;
    var left: [1000]i32 = undefined;
    var right: [1000]i32 = undefined;

    var lines = std.mem.tokenizeScalar(u8, input, '\n');
    var i: usize = 0;
    while (lines.next()) |token| {
        var line = std.mem.tokenizeScalar(u8, token, ' ');
        while (line.next()) |number| {
            if (i % 2 == 0) {
                left[i / 2] = parseInt(i32, number, 10) catch unreachable;
            } else {
                right[i / 2] = parseInt(i32, number, 10) catch unreachable;
            }
            i += 1;
        }
    }

    std.mem.sort(i32, &left, {}, std.sort.asc(i32));
    std.mem.sort(i32, &right, {}, std.sort.asc(i32));

    for (left, right) |left_word, right_word| {
        const local_distance = right_word - left_word;
        distance += @abs(local_distance);
    }

    return distance;
}

pub fn getSimilarityScore(input: []const u8) i32 {
    var score: i32 = 0;

    var left: [1000]i32 = undefined;
    var right: [1000]i32 = undefined;

    var lines = std.mem.tokenizeScalar(u8, input, '\n');
    var i: usize = 0;
    while (lines.next()) |token| {
        var line = std.mem.tokenizeScalar(u8, token, ' ');
        while (line.next()) |number| {
            if (i % 2 == 0) {
                left[i / 2] = parseInt(i32, number, 10) catch unreachable;
            } else {
                right[i / 2] = parseInt(i32, number, 10) catch unreachable;
            }
            i += 1;
        }
    }

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const allocator = gpa.allocator();

    var map = std.AutoHashMap(i32, i32).init(allocator);
    defer map.deinit();

    for (left) |left_word| {
        map.put(left_word, 0) catch unreachable;
    }

    for (right) |right_word| {
        if (map.get(right_word)) |count| {
            map.put(right_word, count + 1) catch unreachable;
        } else {
            map.put(right_word, 1) catch unreachable;
        }
    }

    for (left) |left_word| {
        score += left_word * map.get(left_word).?;
    }
    return score;
}
