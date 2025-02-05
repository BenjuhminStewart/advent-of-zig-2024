const std = @import("std");
const testing = std.testing;
const data = @embedFile("input.txt");
const tokenize = std.mem.tokenizeScalar;
const print = std.debug.print;
const ROWS = 140;
const COLS = 140;

pub fn main() void {
    const count = word_search(data);
    std.debug.print("part 1: {}\n", .{count});
    const count2 = word_search_2(data);
    std.debug.print("part 2: {}\n", .{count2});
}

fn word_search(input: []const u8) usize {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var count: usize = 0;
    const word_graph = construct_2d_array(input, allocator) catch {
        return count;
    };
    for (0..ROWS) |i| {
        for (0..COLS) |j| {
            count += check(i, j, word_graph);
        }
    }

    return count; // should be 2500
}

fn word_search_2(input: []const u8) usize {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var count: usize = 0;
    const word_graph = construct_2d_array(input, allocator) catch {
        print("Error: word_graph invalid", .{});
        return count;
    };
    for (0..ROWS) |i| {
        for (0..COLS) |j| {
            if (word_graph[i][j] == 'A') {
                if (check_x(i, j, word_graph)) {
                    count += 1;
                }
            }
        }
    }

    return count; // should be 2500
}

fn check(i: usize, j: usize, word_graph: [][]u8) usize {
    var count: usize = 0;

    // check left (j -> -j)
    if (j >= 3) {
        const word: [4]u8 = [4]u8{ word_graph[i][j], word_graph[i][j - 1], word_graph[i][j - 2], word_graph[i][j - 3] };
        if (word_is_xmas(&word)) {
            count += 1;
        }
    }

    // check right (j -> +j)
    if (check_is_in_bounds(i, j + 3)) {
        const word: [4]u8 = [4]u8{ word_graph[i][j], word_graph[i][j + 1], word_graph[i][j + 2], word_graph[i][j + 3] };
        if (word_is_xmas(&word)) {
            count += 1;
        }
    }

    // check up (i -> -i)
    if (i >= 3) {
        const word: [4]u8 = [4]u8{ word_graph[i][j], word_graph[i - 1][j], word_graph[i - 2][j], word_graph[i - 3][j] };
        if (word_is_xmas(&word)) {
            count += 1;
        }
    }

    // check down (i -> +i)
    if (check_is_in_bounds(i + 3, j)) {
        const word: [4]u8 = [4]u8{ word_graph[i][j], word_graph[i + 1][j], word_graph[i + 2][j], word_graph[i + 3][j] };
        if (word_is_xmas(&word)) {
            count += 1;
        }
    }

    // check up left (i -> -i, j -> -j)
    if (i >= 3 and j >= 3) {
        const word: [4]u8 = [4]u8{ word_graph[i][j], word_graph[i - 1][j - 1], word_graph[i - 2][j - 2], word_graph[i - 3][j - 3] };
        if (word_is_xmas(&word)) {
            count += 1;
        }
    }

    // check up right (i -> -i, j -> +j)
    if (i >= 3 and check_is_in_bounds(i, j + 3)) {
        const word: [4]u8 = [4]u8{ word_graph[i][j], word_graph[i - 1][j + 1], word_graph[i - 2][j + 2], word_graph[i - 3][j + 3] };
        if (word_is_xmas(&word)) {
            count += 1;
        }
    }

    // check down left (i -> +i, j -> -j)
    if (check_is_in_bounds(i + 3, j) and j >= 3) {
        const word: [4]u8 = [4]u8{ word_graph[i][j], word_graph[i + 1][j - 1], word_graph[i + 2][j - 2], word_graph[i + 3][j - 3] };
        if (word_is_xmas(&word)) {
            count += 1;
        }
    }

    // check down right (i -> +i, j -> +j)
    if (check_is_in_bounds(i + 3, j + 3)) {
        const word: [4]u8 = [4]u8{ word_graph[i][j], word_graph[i + 1][j + 1], word_graph[i + 2][j + 2], word_graph[i + 3][j + 3] };
        if (word_is_xmas(&word)) {
            count += 1;
        }
    }

    return count;
}

fn check_x(i: usize, j: usize, word_graph: [][]u8) bool {
    if (i < 1 or i + 1 >= ROWS or j < 1 or j + 1 >= COLS) {
        return false;
    }
    const q2q4: [3]u8 = [3]u8{ word_graph[i - 1][j - 1], word_graph[i][j], word_graph[i + 1][j + 1] };
    const q3q1: [3]u8 = [3]u8{ word_graph[i + 1][j - 1], word_graph[i][j], word_graph[i - 1][j + 1] };
    if (word_is_mas(&q2q4) and word_is_mas(&q3q1)) {
        return true;
    }
    return false;
}

fn word_is_mas(word: []const u8) bool {
    if (std.mem.eql(u8, word, "MAS") or std.mem.eql(u8, word, "SAM")) {
        return true;
    }
    return false;
}

fn check_is_in_bounds(i: usize, j: usize) bool {
    if (i < 0 or i >= ROWS) {
        return false;
    }
    if (j < 0 or j >= COLS) {
        return false;
    }
    return true;
}

fn word_is_xmas(word: []const u8) bool {
    if (std.mem.eql(u8, word, "XMAS")) {
        return true;
    }
    return false;
}

fn construct_2d_array(input: []const u8, allocator: std.mem.Allocator) ![][]u8 {
    var result: [][]u8 = try allocator.alloc([]u8, ROWS);
    for (result) |*row| {
        row.* = try allocator.alloc(u8, COLS);
    }

    var it = tokenize(u8, input, '\n');
    var i: usize = 0;
    while (it.next()) |line| {
        var j: usize = 0;
        while (j < COLS) : (j += 1) {
            result[i][j] = line[j];
        }
        i += 1;
    }
    return result;
}
