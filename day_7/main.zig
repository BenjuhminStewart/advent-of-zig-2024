const std = @import("std");
const Allocator = std.mem.Allocator;
const testing = std.testing;
const print = std.debug.print;
const data = @embedFile("input.txt");
const parseInt = std.fmt.parseInt;

var alloc: std.mem.Allocator = undefined;

var gpa_impl = std.heap.GeneralPurposeAllocator(.{}){};
pub const gpa = gpa_impl.allocator();

const Equation = struct {
    resultant: usize,
    parts: []usize,
};

var equations: []Equation = undefined;

fn solve(expected: usize, current_total: usize, parts: []usize) bool {
    if (parts.len == 0) return expected == current_total;
    const next_term = parts[0];
    const rest_of_terms = parts[1..];
    return solve(expected, current_total + next_term, rest_of_terms) or
        solve(expected, current_total * next_term, rest_of_terms);
}

fn concat(a: usize, b: usize) usize {
    const len_b: usize = std.math.log10_int(b) + 1;
    const exp = std.math.powi(usize, 10, len_b) catch unreachable;
    return a * exp + b;
}

fn solve2(expected: usize, current_total: usize, parts: []usize) bool {
    if (parts.len == 0) return expected == current_total;
    const next_term = parts[0];
    const rest_of_terms = parts[1..];
    return solve2(expected, current_total + next_term, rest_of_terms) or
        solve2(expected, current_total * next_term, rest_of_terms) or
        solve2(expected, concat(current_total, next_term), rest_of_terms);
}

fn parse(d: []const u8) !void {
    var eqList = std.ArrayList(Equation).init(alloc);
    var lines = std.mem.tokenizeScalar(u8, d, '\n');
    while (lines.next()) |line| {
        var parts = std.mem.tokenizeScalar(u8, line, ':');
        const left = parts.next() orelse unreachable;
        const right = parts.next() orelse unreachable;
        var terms = std.mem.tokenizeScalar(u8, right, ' ');
        var list = std.ArrayList(usize).init(alloc);
        while (terms.next()) |term| {
            try list.append(try parseInt(usize, term, 0));
        }
        try eqList.append(Equation{
            .resultant = try parseInt(usize, left, 0),
            .parts = list.items,
        });
    }
    equations = eqList.items;
}

fn part1() !usize {
    var total: usize = 0;
    for (equations) |eq| {
        if (solve(eq.resultant, 0, eq.parts)) {
            total += eq.resultant;
        }
    }
    return total;
}

fn part2() !usize {
    var total: usize = 0;
    for (equations) |eq| {
        if (solve2(eq.resultant, 0, eq.parts)) {
            total += eq.resultant;
        }
    }

    return total;
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(gpa);
    alloc = arena.allocator();
    defer arena.deinit();

    try parse(data);
    const part_1 = try part1();
    const part_2 = try part2();

    print("\n[ Day 7 ]\n", .{});
    print("part_1={}\n", .{part_1});
    print("part_2={}\n", .{part_2});
}
