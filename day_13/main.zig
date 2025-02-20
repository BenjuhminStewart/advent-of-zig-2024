const std = @import("std");
const Allocator = std.mem.Allocator;
const print = std.debug.print;
const data = @embedFile("input.txt");

var gpa_impl = std.heap.GeneralPurposeAllocator(.{}){};
var gpa = gpa_impl.allocator();

var alloc: Allocator = undefined;

const Point = struct {
    const Self = @This();
    x: i64,
    y: i64,

    pub fn init(x: i64, y: i64) Self {
        return Self{
            .x = x,
            .y = y,
        };
    }
};

const Button = struct {
    const Self = @This();
    dx: i64,
    dy: i64,
    price: i64,

    pub fn init(price: i64, dx: i64, dy: i64) Self {
        return Self{
            .price = price,
            .dx = dx,
            .dy = dy,
        };
    }
};

const ClawMachine = struct {
    const Self = @This();
    buttons: [2]Button,
    prize: Point,

    pub fn init(button_a: Button, button_b: Button, prize: Point) Self {
        return Self{
            .buttons = [2]Button{ button_a, button_b },
            .prize = prize,
        };
    }
};

var machines: std.ArrayList(ClawMachine) = undefined;

pub fn main() !void {
    print("\n[ Day 13 ]\n", .{});
    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();
    alloc = arena.allocator();

    machines = std.ArrayList(ClawMachine).init(alloc);
    defer machines.deinit();
    try parse(data);

    const part_1 = solve(0);
    print("part_1={}\n", .{part_1});

    const part_2 = solve(10000000000000);
    print("part_2={}\n", .{part_2});
}

pub fn parse(input: []const u8) !void {
    var lines = std.mem.tokenizeSequence(u8, input, "\n");
    while (lines.next()) |line| {
        const a_button_str = line;
        const b_button_str = lines.next().?;
        const prize_str = lines.next().?;

        // a button
        var a_split = std.mem.tokenizeSequence(u8, a_button_str, " ");
        _ = a_split.next().?;
        _ = a_split.next().?;
        const a_xstr = a_split.next().?;
        const a_ystr = a_split.next().?;
        const a_x = std.fmt.parseInt(i64, a_xstr[2 .. a_xstr.len - 1], 10) catch {
            return error.ParseInput;
        };
        const a_y = std.fmt.parseInt(i64, a_ystr[2..], 10) catch {
            return error.ParseInput;
        };

        const a_button = Button.init(3, a_x, a_y);

        // b button
        var b_split = std.mem.tokenizeSequence(u8, b_button_str, " ");
        _ = b_split.next().?;
        _ = b_split.next().?;
        const b_xstr = b_split.next().?;
        const b_ystr = b_split.next().?;
        const b_x = std.fmt.parseInt(i64, b_xstr[2 .. b_xstr.len - 1], 10) catch {
            return error.ParseInput;
        };
        const b_y = std.fmt.parseInt(i64, b_ystr[2..], 10) catch {
            return error.ParseInput;
        };

        const b_button = Button.init(1, b_x, b_y);

        // prize
        var prize_split = std.mem.tokenizeSequence(u8, prize_str, " ");
        _ = prize_split.next().?;
        const prize_xstr = prize_split.next().?;
        const prize_ystr = prize_split.next().?;
        const prize_x = std.fmt.parseInt(i64, prize_xstr[2 .. prize_xstr.len - 1], 10) catch {
            return error.ParseInput;
        };
        const prize_y = std.fmt.parseInt(i64, prize_ystr[2..], 10) catch {
            return error.ParseInput;
        };

        const prize = Point.init(prize_x, prize_y);

        machines.append(ClawMachine.init(a_button, b_button, prize)) catch {
            return error.ParseInput;
        };
    }
}

pub fn print_machines() void {
    for (machines.items) |machine| {
        print("\nButton A: ({}, {}) | price = {}\n", .{ machine.buttons[0].dx, machine.buttons[0].dy, machine.buttons[0].price });
        print("Button B: ({}, {}) | price = {}\n", .{ machine.buttons[1].dx, machine.buttons[1].dy, machine.buttons[1].price });
        print("Prize: ({}, {})\n", .{ machine.prize.x, machine.prize.y });
    }
}

pub fn solve(adjustment: i64) i64 {
    var total_cost: i64 = 0;

    for (machines.items) |machine| {
        const prize_x = machine.prize.x + adjustment;
        const prize_y = machine.prize.y + adjustment;

        const a_dx = machine.buttons[0].dx;
        const a_dy = machine.buttons[0].dy;

        const b_dx = machine.buttons[1].dx;
        const b_dy = machine.buttons[1].dy;

        const a_det: i64 = @intCast(@abs(a_dx * b_dy - a_dy * b_dx));
        if (a_det == 0) {
            continue;
        }

        const a1_det: i64 = @intCast(@abs(prize_x * b_dy - prize_y * b_dx));
        const a2_det: i64 = @intCast(@abs(prize_y * a_dx - prize_x * a_dy));

        if (@mod(a1_det, a_det) == 0 and @mod(a2_det, a_det) == 0) {
            total_cost += @divFloor(a1_det, a_det) * machine.buttons[0].price + @divFloor(a2_det, a_det);
        }
    }

    return total_cost;
}
