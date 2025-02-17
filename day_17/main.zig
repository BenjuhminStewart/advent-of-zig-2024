const std = @import("std");
const Allocator = std.mem.Allocator;
const print = std.debug.print;
const data = @embedFile("input.txt");
const test_data = @embedFile("test_input.txt");
const testing = std.testing;

var gpa_impl = std.heap.GeneralPurposeAllocator(.{}){};
var gpa = gpa_impl.allocator();

var alloc: Allocator = undefined;

var ops: std.ArrayList(Instruction) = undefined;
var registers: [3]i64 = [3]i64{ 0, 0, 0 };
var output: std.ArrayList(i64) = undefined;

var instruction_pointer: usize = 0;

const A = 0;
const B = 1;
const C = 2;

const Instruction = struct {
    opcode: u3,
    operand: u3,

    pub fn print_self(self: Instruction) void {
        print("opcode: {} | operand: {}\n", .{ self.opcode, self.operand });
    }
};

pub fn parse(input: []const u8) !void {
    var lines = std.mem.tokenizeSequence(u8, input, "\n");
    var i: usize = 0;
    var temp_instructions = std.ArrayList(u3).init(alloc);
    while (lines.next()) |line| {
        if (i < 3) {
            var curr = std.mem.tokenizeSequence(u8, line, " ");
            _ = curr.next();
            _ = curr.next();
            const num = std.fmt.parseInt(i64, curr.next().?, 10) catch {
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
                    const op_num = std.fmt.parseInt(u3, first_op.next().?, 10) catch {
                        return error.ParseError;
                    };
                    temp_instructions.append(op_num) catch {
                        return error.ParseError;
                    };
                    j += 1;
                    continue;
                }
                const op_num = std.fmt.parseInt(u3, op, 10) catch {
                    return error.OpsError;
                };
                temp_instructions.append(op_num) catch {
                    return error.OpsError;
                };
                j += 1;
            }
        }
    }
    var op_i: usize = 0;
    while (op_i < temp_instructions.items.len) : (op_i += 2) {
        const instruction = Instruction{
            .opcode = temp_instructions.items[op_i],
            .operand = temp_instructions.items[op_i + 1],
        };
        ops.append(instruction) catch {
            return error.OpsError;
        };
    }
}

pub fn get_combo_operand(combo: u3) !i64 {
    switch (combo) {
        1, 2, 3 => return combo,
        4 => return registers[A],
        5 => return registers[B],
        6 => return registers[C],
        else => return error.TryingToAccessReservedOperand,
    }
}

pub fn adv(literal: u3) !void {
    print("ADV BEFORE: Instruction Pointer: {}", .{instruction_pointer});
    const combo = get_combo_operand(literal) catch {
        return error.TryingToAccessReservedOperand;
    };

    const numerator = registers[A];
    const denominator = std.math.pow(i64, 2, combo);

    const result = @divTrunc(numerator, denominator);

    print("dividing {} by 2^({}) = {} | Storing in A\n", .{ numerator, combo, result });

    registers[A] = result;
    instruction_pointer += 1;
    print("ADV AFTER: Instruction Pointer: {}", .{instruction_pointer});
}

pub fn bxl(literal: u3) void {
    const xor = registers[1] ^ literal;

    print("xoring {} with {} = {} | Storing in B\n", .{ registers[B], literal, xor });

    registers[B] = xor;
    instruction_pointer += 1;
}

pub fn bst(literal: u3) !void {
    const combo = get_combo_operand(literal) catch {
        return error.TryingToAccessReservedOperand;
    };
    const result = @mod(combo, 8);

    print("modding {} by 8 = {} | Storing in B\n", .{ combo, result });
    registers[B] = result;
    instruction_pointer += 1;
}

pub fn jnz(literal: u3) void {
    if (registers[A] == 0) {
        instruction_pointer += 1;
        print("Doing Nothing because A == 0\n", .{});
        return;
    }

    print("Jumping to instruction {}\n", .{literal});
    instruction_pointer = literal;
}

pub fn bxc() void {
    const result = registers[B] ^ registers[C];
    print("xoring {} and {} = {} | Store in B\n", .{ registers[B], registers[C], result });
    registers[B] = result;

    instruction_pointer += 1;
}

pub fn out(literal: u3) !void {
    const combo = get_combo_operand(literal) catch {
        return error.TryingToAccessReservedOperand;
    };

    const result = @mod(combo, 8);
    output.append(result) catch {
        return error.OutputError;
    };

    print("Adding {} mod 8 = {} to the output list\n", .{ combo, result });

    instruction_pointer += 1;
}

pub fn bdv(literal: u3) !void {
    const combo = get_combo_operand(literal) catch {
        return error.TryingToAccessReservedOperand;
    };

    const numerator = registers[0];
    const denominator = std.math.pow(i64, 2, combo);

    const result = @divTrunc(numerator, denominator);

    print("dividing {} by 2^({}) = {} | Storing in B\n", .{ numerator, combo, result });

    registers[B] = result;
    instruction_pointer += 1;
}

pub fn cdv(literal: u3) !void {
    const combo = get_combo_operand(literal) catch {
        return error.TryingToAccessReservedOperand;
    };

    const numerator = registers[0];
    const denominator = std.math.pow(i64, 2, combo);

    const result = @divTrunc(numerator, denominator);

    print("dividing {} by 2^({}) = {} | Storing in C\n", .{ numerator, combo, result });

    registers[C] = result;
    instruction_pointer += 1;
}

pub fn solve() !void {
    while (instruction_pointer < ops.items.len) {
        const instruction = ops.items[instruction_pointer];
        const opcode = instruction.opcode;
        const operand = instruction.operand;
        print("registers before: {any}\n", .{registers});
        print("instruction pointer: {}", .{instruction_pointer});
        instruction.print_self();
        switch (opcode) {
            0 => adv(operand) catch {
                return error.AdvError;
            },
            1 => bxl(operand),
            2 => bst(operand) catch {
                return error.BstError;
            },
            3 => jnz(operand),
            4 => bxc(),
            5 => out(operand) catch {
                return error.OutError;
            },
            6 => bdv(operand) catch {
                return error.BdvError;
            },
            7 => cdv(operand) catch {
                return error.CdvError;
            },
        }
        print("registers after: {any}\n", .{registers});
        print_out();
    }
}

pub fn print_out() void {
    var i: usize = 0;
    while (i < output.items.len) : (i += 1) {
        if (i == output.items.len - 1) {
            print("{}\n", .{output.items[i]});
        } else {
            print("{},", .{output.items[i]});
        }
    }
    print("\n", .{});
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();
    alloc = arena.allocator();

    ops = std.ArrayList(Instruction).init(alloc);
    output = std.ArrayList(i64).init(alloc);

    try parse(data);
    try solve();
}

test "part 1" {
    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();
    alloc = arena.allocator();

    ops = std.ArrayList(Instruction).init(alloc);
    output = std.ArrayList(i64).init(alloc);

    try parse(test_data);
    try solve();

    const expected = [_]u3{ 4, 6, 3, 5, 6, 3, 5, 2, 1, 0 };
    const actual = output.items;

    for (expected, 0..) |expected_val, i| {
        try testing.expectEqual(expected_val, actual[i]);
    }
}

test "part 2" {}
