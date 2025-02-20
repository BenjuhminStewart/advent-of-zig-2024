const std = @import("std");
const data = @embedFile("input.txt");
const tokenize = std.mem.tokenizeScalar;
const print = std.debug.print;
const parseInt = std.fmt.parseInt;

pub fn main() !void {
    print("\n[ Day 2 ]\n", .{});
    const safe_reports = get_safe_reports(data);
    std.debug.print("part_1={}\n", .{safe_reports});

    const safe_reports_with_dampener = get_safe_reports_with_dampener(data);
    std.debug.print("part_2={}\n", .{safe_reports_with_dampener});
}

fn get_safe_reports(input: []const u8) u32 {
    var count: u32 = 0;
    var lines = tokenize(u8, input, '\n');
    while (lines.next()) |line| {
        if (is_safe(line)) {
            count += 1;
        }
    }

    return count;
}

fn is_safe(input: []const u8) bool {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const allocator = gpa.allocator();

    var arr: std.ArrayList(i8) = std.ArrayList(i8).init(allocator);
    defer arr.deinit();

    var line = tokenize(u8, input, ' ');
    var i: usize = 0;
    while (line.next()) |token| {
        const value = parseInt(i8, token, 10) catch unreachable;
        arr.append(value) catch unreachable;
        i += 1;
    }

    // checks for safe:
    // all increasing OR all decreasing
    // adjacent values differ by at least 1 and at most 3
    // anything else is not safe

    var last_value: i8 = arr.items[0];
    const is_increasing = arr.items[0] < arr.items[1];

    for (arr.items[1..]) |value| {
        if (is_increasing) {
            if (value <= last_value) {
                return false;
            }
            if ((value - last_value) > 3) {
                return false;
            }
        } else {
            if (value >= last_value) {
                return false;
            }
            if ((last_value - value) > 3) {
                return false;
            }
        }
        last_value = value;
    }

    return true;
}

fn get_safe_reports_with_dampener(input: []const u8) u32 {
    var count: u32 = 0;
    var lines = tokenize(u8, input, '\n');
    while (lines.next()) |line| {
        if (try is_safe_with_dampener(line)) {
            count += 1;
        }
    }

    return count;
}

fn is_safe_helper(list: []i8) bool {
    var last_value: i8 = list[0];
    const is_increasing = list[0] < list[1];

    for (list[1..]) |value| {
        if (is_increasing) {
            if (value <= last_value) {
                return false;
            }
            if ((value - last_value) > 3) {
                return false;
            }
        } else {
            if (value >= last_value) {
                return false;
            }
            if ((last_value - value) > 3) {
                return false;
            }
        }
        last_value = value;
    }

    return true;
}

fn is_safe_with_dampener(input: []const u8) !bool {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const allocator = gpa.allocator();

    var arr: std.ArrayList(i8) = std.ArrayList(i8).init(allocator);
    defer arr.deinit();

    var line = tokenize(u8, input, ' ');
    var i: usize = 0;
    while (line.next()) |token| {
        const value = parseInt(i8, token, 10) catch unreachable;
        arr.append(value) catch unreachable;
        i += 1;
    }

    // checks for safe:
    // all increasing OR all decreasing
    // adjacent values differ by at least 1 and at most 3
    // HOWERVER, if it can remove a value and still be safe, it is safe
    // anything else is not safe

    // brute force check every possible removal

    if (!is_safe_helper(arr.items)) {
        var i_to_exclude: usize = 0;

        while (i_to_exclude < arr.items.len) {
            var new_arr: std.ArrayList(i8) = std.ArrayList(i8).init(allocator);
            defer new_arr.deinit();

            for (0..arr.items.len) |j| {
                if (j != i_to_exclude) {
                    new_arr.append(arr.items[j]) catch unreachable;
                }
            }

            if (is_safe_helper(new_arr.items)) {
                return true;
            } else {
                i_to_exclude += 1;
            }
        }
    } else {
        return true;
    }

    return false;
}
