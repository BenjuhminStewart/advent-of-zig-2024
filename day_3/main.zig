const std = @import("std");
const testing = std.testing;
const data = @embedFile("input.txt");
const print = std.debug.print;

pub fn main() void {
    print("\n[ Day 3 ]\n", .{});
    const sum = get_sum_of_mult_operations(data);
    std.debug.print("part_1={}\n", .{sum});

    const sum2 = get_sum_of_mult_operations2(data);
    std.debug.print("part_2={}\n", .{sum2});
}

fn get_sum_of_mult_operations(input: []const u8) i64 {
    var count: i64 = 0;
    var index: usize = 0;

    while (index < input.len) {
        if (input[index] == 'm' and input[index + 1] == 'u' and input[index + 2] == 'l' and input[index + 3] == '(') {
            var first: i32 = 0;
            var second: i32 = 0;
            var curr_i = index + 4;
            var end_i = index + 4;
            while (end_i < input.len and input[end_i] != ',') {
                end_i += 1;
            }

            // if can parse as int, then parse it. else continue loop.

            if (curr_i == end_i) {
                first = std.fmt.parseInt(i32, input[curr_i .. curr_i + 1], 10) catch {
                    index += 1;
                    continue;
                };
            } else {
                first = std.fmt.parseInt(i32, input[curr_i..end_i], 10) catch {
                    index += 1;
                    continue;
                };
            }

            end_i += 1;
            curr_i = end_i;

            while (end_i < input.len and input[end_i] != ')') {
                end_i += 1;
            }

            if (curr_i == end_i) {
                second = std.fmt.parseInt(i32, input[curr_i .. curr_i + 1], 10) catch {
                    index += 1;
                    continue;
                };
            } else {
                second = std.fmt.parseInt(i32, input[curr_i..end_i], 10) catch {
                    index += 1;
                    continue;
                };
            }

            count += first * second;

            index = end_i + 1;
        } else {
            index += 1;
        }
    }

    return count;
}

fn get_sum_of_mult_operations2(input: []const u8) i64 {
    var count: i64 = 0;
    var index: usize = 0;
    var curr_i: usize = 0;
    var end_i: usize = 0;
    var first: i32 = 0;
    var second: i32 = 0;

    var is_enabled: bool = true;

    while (index < input.len) {
        if (input[index] == 'd' and input[index + 1] == 'o') {
            if (index + 6 < input.len and input[index + 2] == 'n' and input[index + 3] == '\'' and input[index + 4] == 't' and input[index + 5] == '(' and input[index + 6] == ')') {
                is_enabled = false;
                index += 1;
                continue;
            } else if (input[index + 2] == '(' and input[index + 3] == ')') {
                is_enabled = true;
                index += 1;
                continue;
            }
        }
        if (input[index] == 'm' and input[index + 1] == 'u' and input[index + 2] == 'l' and input[index + 3] == '(') {
            if (!is_enabled) {
                index += 1;
                continue;
            }
            curr_i = index + 4;
            end_i = index + 4;
            while (end_i < input.len and input[end_i] != ',') {
                end_i += 1;
            }

            // if can parse as int, then parse it. else continue loop.
            if (curr_i == end_i) {
                first = std.fmt.parseInt(i32, input[curr_i .. curr_i + 1], 10) catch {
                    index += 1;
                    continue;
                };
            } else {
                first = std.fmt.parseInt(i32, input[curr_i..end_i], 10) catch {
                    index += 1;
                    continue;
                };
            }

            end_i += 1;
            curr_i = end_i;

            while (end_i < input.len and input[end_i] != ')') {
                end_i += 1;
            }

            if (curr_i == end_i) {
                second = std.fmt.parseInt(i32, input[curr_i .. curr_i + 1], 10) catch {
                    index += 1;
                    continue;
                };
            } else {
                second = std.fmt.parseInt(i32, input[curr_i..end_i], 10) catch {
                    index += 1;
                    continue;
                };
            }
            count += first * second;

            index = end_i + 1;
        } else {
            index += 1;
        }
    }
    return count;
}
