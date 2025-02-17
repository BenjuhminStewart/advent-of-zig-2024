const std = @import("std");
const Allocator = std.mem.Allocator;
const print = std.debug.print;
const data = @embedFile("input.txt");
const test_data = @embedFile("test_input.txt");
const test_2 = @embedFile("test_2.txt");
const testing = std.testing;

var gpa_impl = std.heap.GeneralPurposeAllocator(.{}){};
var gpa = gpa_impl.allocator();

var alloc: Allocator = undefined;

var registers: [3]usize = [3]usize{ 0, 0, 0 };
var program: std.ArrayList(usize) = undefined;
var output: std.ArrayList(usize) = undefined;

var instruction_pointer: usize = 0;

const A = 0;
const B = 1;
const C = 2;

pub fn parse(input: []const u8) !void {
    var lines = std.mem.tokenizeSequence(u8, input, "\n");
    var i: usize = 0;
    while (lines.next()) |line| {
        if (i < 3) {
            var curr = std.mem.tokenizeSequence(u8, line, " ");
            _ = curr.next();
            _ = curr.next();
            const num = std.fmt.parseInt(usize, curr.next().?, 10) catch {
                return error.ParseError;
            };
            registers[i] = num;
            i += 1;
        } else {
            var operation_strings = std.mem.tokenizeSequence(u8, line, ",");
            var j: usize = 0;
            while (operation_strings.next()) |op| {
                if (j == 0) {
                    var first_op = std.mem.tokenizeSequence(u8, op, " ");
                    _ = first_op.next();
                    const op_num = std.fmt.parseInt(usize, first_op.next().?, 10) catch {
                        return error.ParseError;
                    };
                    program.append(op_num) catch {
                        return error.ParseError;
                    };
                    j += 1;
                    continue;
                }
                const op_num = std.fmt.parseInt(usize, op, 10) catch {
                    return error.OpsError;
                };
                program.append(op_num) catch {
                    return error.OpsError;
                };
                j += 1;
            }
        }
    }
}

pub fn combo(operand: usize, reg: [3]usize) usize {
    return switch (operand) {
        1, 2, 3 => operand,
        4 => reg[A],
        5 => reg[B],
        6 => reg[C],
        else => unreachable,
    };
}

const State = struct {
    pc: usize,
    out: usize,
    registers: [3]usize,
};
fn run(prog: []usize, a: usize) State {
    var s = State{ .pc = 0, .out = 0, .registers = .{ a, 0, 0 } };
    var reg = s.registers;
    var out: usize = 0;
    while (s.pc < prog.len) {
        const opcode = prog[s.pc];
        const operand = prog[s.pc + 1];
        switch (opcode) {
            //adv
            0 => {
                const num = reg[0];
                const denom = std.math.pow(usize, 2, combo(operand, reg));
                reg[0] = num / denom;
            },
            //bxl
            1 => reg[1] ^= operand,
            //bst
            2 => reg[1] = combo(operand, reg) % 8,
            //jnz
            3 => {
                s.registers = reg;
                s.out = out;
                if (reg[0] == 0) {
                    s.pc += 2;
                    return s;
                }
                s.pc = operand;
                return s;
            },
            //bxc
            4 => reg[1] ^= reg[2],
            //out
            5 => out = combo(operand, reg) % 8,
            //bdv
            6 => {
                const num = reg[0];
                const denom = std.math.pow(usize, 2, combo(operand, reg));
                reg[1] = num / denom;
            },
            //cdv
            7 => {
                const num = reg[0];
                const denom = std.math.pow(usize, 2, combo(operand, reg));
                reg[2] = num / denom;
            },
            else => unreachable,
        }
        s.pc += 2;
    }
    return s;
}

fn solve(prog: []usize, a: usize, offset: usize) usize {
    if (offset == prog.len) return a;
    for (0..8) |i| {
        if (i == 0 and a == 0) continue;
        const s = run(prog, a * 8 + i);
        if (s.out == prog[prog.len - offset - 1]) {
            const tmp = solve(prog, a * 8 + i, offset + 1);
            if (tmp > 0) return tmp;
        }
    }
    return 0;
}

pub fn part1(input: []const u8) !void {
    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();
    alloc = arena.allocator();

    program = std.ArrayList(usize).init(alloc);
    output = std.ArrayList(usize).init(alloc);

    try parse(input);

    var state = State{ .pc = 0, .out = 0, .registers = registers };
    while (state.pc == 0) {
        const new_state = run(program.items, state.registers[A]);
        state = new_state;
        try output.append(state.out);
    }
    print("part_1=", .{});
    for (output.items, 0..) |item, i| {
        if (i == output.items.len - 1) {
            print("{}\n", .{item});
        } else {
            print("{},", .{item});
        }
    }
}

pub fn part2(input: []const u8) !void {
    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();
    alloc = arena.allocator();

    program = std.ArrayList(usize).init(alloc);
    output = std.ArrayList(usize).init(alloc);

    try parse(input);

    const a = solve(program.items, 0, 0);
    print("part_2={}\n", .{a});
}

pub fn main() !void {
    try part1(data);
    try part2(data);
}

test "part 1" {
    try part1(test_data);
}

test "part 2" {
    try part2(test_2);
}
