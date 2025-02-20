const std = @import("std");
const testing = std.testing;
const print = std.debug.print;
const data = @embedFile("input.txt");
const mem = std.mem;
const parseInt = std.fmt.parseInt;

const Pair = struct { x: i32, y: i32 };
pub fn main() void {
    const scores = try get_scores_of_updates(data);
    print("\n[ Day 5 ]\n", .{});
    print("part_1={d}\n", .{scores[0]});
    print("part_2={d}\n", .{scores[1]});
}

fn get_scores_of_updates(input: []const u8) ![2]i32 {
    var scores: [2]i32 = [2]i32{ 0, 0 };
    var sections = mem.tokenizeSequence(u8, input, "\n\n");

    const section1 = sections.next().?;
    const section2 = sections.next().?;

    var rules = get_rules(section1, std.heap.page_allocator) catch {
        return scores;
    };
    defer rules.deinit();

    var lines = mem.tokenizeScalar(u8, section2, '\n');
    while (lines.next()) |line| {
        var nums = mem.tokenizeScalar(u8, line, ',');
        var update = std.ArrayList(i32).init(std.heap.page_allocator);
        while (nums.next()) |num| {
            const int = parseInt(i32, num, 10) catch {
                return scores;
            };
            update.append(int) catch {
                return scores;
            };
        }
        const scoring = score_of_update(rules, update);
        scores[0] += scoring[0];
        scores[1] += scoring[1];
    }

    return scores;
}

fn score_of_update(rules: std.AutoHashMap(Pair, void), update: std.ArrayList(i32)) [2]i32 {
    var swaps: i32 = 0;

    const items = update.items;
    for (0..items.len) |_| {
        for (0..items.len - 1) |i| {
            if (rules.contains(Pair{ .x = items[i + 1], .y = items[i] })) {
                swaps += 1;
                const temp = items[i];
                items[i] = items[i + 1];
                items[i + 1] = temp;
            }
        }
    }

    if (swaps == 0) {
        return [2]i32{ items[items.len / 2], 0 };
    } else {
        return [2]i32{ 0, items[items.len / 2] };
    }
}

fn get_rules(input: []const u8, allocator: std.mem.Allocator) !std.AutoHashMap(Pair, void) {
    var rules = std.AutoHashMap(Pair, void).init(allocator);

    var line = mem.tokenizeScalar(u8, input, '\n');
    while (line.next()) |l| {
        var parts = mem.tokenizeScalar(u8, l, '|');
        const a = parseInt(i32, parts.next().?, 10) catch {
            return error.InvalidInput;
        };
        const b = parseInt(i32, parts.next().?, 10) catch {
            return error.InvalidInput;
        };
        _ = try rules.getOrPut(Pair{ .x = a, .y = b });
    }

    return rules;
}
