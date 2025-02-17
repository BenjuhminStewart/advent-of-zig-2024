const std = @import("std");
const Allocator = std.mem.Allocator;
const print = std.debug.print;
const data = @embedFile("input.txt");
const test_data = @embedFile("test_input.txt");
const testing = std.testing;

var gpa_impl = std.heap.GeneralPurposeAllocator(.{}){};
var gpa = gpa_impl.allocator();

var alloc: Allocator = undefined;

var patterns: std.ArrayList([]const u8) = undefined;
var designs: std.ArrayList([]const u8) = undefined;

pub fn parse(input: []const u8) void {
    var lines = std.mem.tokenizeScalar(u8, input, '\n');
    var pattern_list = std.mem.tokenizeSequence(u8, lines.next().?, ", ");
    while (pattern_list.next()) |pattern| {
        patterns.append(pattern) catch unreachable;
    }

    while (lines.next()) |line| {
        designs.append(line) catch unreachable;
    }
}

pub fn print_patterns() void {
    for (patterns.items, 0..) |pattern, i| {
        if (i != patterns.items.len - 1) {
            print("{s}, ", .{pattern});
            continue;
        } else {
            print("{s}", .{pattern});
        }
    }
    print("\n", .{});
}

pub fn print_designs() void {
    for (designs.items) |design| {
        print("{s}\n", .{design});
    }
}

pub fn part1(input: []const u8) void {
    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();
    alloc = arena.allocator();

    patterns = std.ArrayList([]const u8).init(alloc);
    designs = std.ArrayList([]const u8).init(alloc);

    parse(input);

    var possible: usize = 0;
    for (designs.items) |design| {
        if (is_possible(design)) {
            possible += 1;
        }
    }

    print("part_1={}\n", .{possible});
}

pub fn is_possible(design: []const u8) bool {
    if (design.len == 0) return true; // empty design is always possible

    for (patterns.items) |pattern| {
        if (pattern.len > design.len) continue;
        if (std.mem.startsWith(u8, design, pattern)) {
            if (is_possible(design[pattern.len..])) return true;
        }
    }

    return false;
}

pub fn part2(input: []const u8) void {
    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();
    alloc = arena.allocator();

    patterns = std.ArrayList([]const u8).init(alloc);
    designs = std.ArrayList([]const u8).init(alloc);

    parse(input);

    var count: usize = 0;
    var uniques = std.StringArrayHashMap(usize).init(alloc);
    for (designs.items) |design| {
        if (is_possible(design)) {
            count += unique_designs(design, &uniques) catch unreachable;
        }
    }
    uniques.deinit();

    print("part_2={}\n", .{count});
}

pub fn unique_designs(design: []const u8, uniques: *std.StringArrayHashMap(usize)) !usize {
    if (uniques.get(design)) |count| {
        return count;
    }

    if (design.len == 0) return 1;

    var count: usize = 0;
    for (patterns.items) |pattern| {
        if (pattern.len > design.len) continue;
        if (std.mem.startsWith(u8, design, pattern)) {
            count += unique_designs(design[pattern.len..], uniques) catch unreachable;
        }
    }
    uniques.put(design, count) catch unreachable;
    return count;
}

pub fn main() void {
    part1(data);
    part2(data);
}

test "part 1" {
    part1(test_data);
    print("   (E)=6\n\n", .{});
}

test "part 2" {
    part2(test_data);
    print("   (E)=16\n\n", .{});
}
