const std = @import("std");
const Allocator = std.mem.Allocator;
const data = @embedFile("input.txt");

const verbose = false;
fn log(comptime s: []const u8, args: anytype) void {
    if (verbose) print(s, args);
}
fn print(comptime s: []const u8, args: anytype) void {
    std.debug.print(s, args);
    printNewLine();
}
fn printNewLine() void {
    std.debug.print("\n", .{});
}

var gpa_impl = std.heap.GeneralPurposeAllocator(.{}){};
var gpa = gpa_impl.allocator();

var alloc: Allocator = undefined;

pub const Op = enum {
    AND,
    OR,
    XOR,
    VALUE,
    UNDEF,
};

pub const Gate = struct {
    label: ?[]const u8 = null,
    value: ?bool = null,
    op: Op = Op.UNDEF,
    left: ?*Gate = null,
    right: ?*Gate = null,
    connections: usize = 0,
    pos: @Vector(2, usize) = .{ 0, 0 },

    pub fn print_self(self: *const Gate) void {
        if (self.label == null or self.value == null) return;
        print("Gate [{s}] -> {any}", .{ self.label.?, self.value.? });
        print(" - Connections: {} | Position: ({}, {})", .{ self.connections, self.pos[0], self.pos[1] });
        if (self.left) |left| {
            print(" - Left: ", .{});
            left.print_self();
        }
        if (self.right) |right| {
            print(" - Right: ", .{});
            right.print_self();
        }
    }
};

var gates: [1024]Gate = undefined;
var zIndex: [64]*Gate = undefined;
var gate_map: std.StringHashMap(*Gate) = undefined;
var position_hash: std.AutoHashMap(@Vector(2, u32), bool) = undefined;
var gate_count: usize = 0;
var z_count: usize = 0;
var ret: std.ArrayList([]const u8) = undefined;

pub inline fn add_gate(name: []const u8, gate: Gate) *Gate {
    gates[gate_count] = gate;
    gates[gate_count].label = name;

    gate_map.put(name, &gates[gate_count]) catch unreachable;
    gate_count += 1;
    return &gates[gate_count - 1];
}

pub fn parse(input: []const u8) void {
    var lines = std.mem.tokenizeScalar(u8, input, '\n');
    while (lines.next()) |line| {
        if (std.mem.containsAtLeastScalar(u8, line, 1, ':')) {
            const name = line[0..3];
            const value = line[5] == '1';
            _ = add_gate(name, Gate{ .value = value, .op = .VALUE });
        } else {
            const name = line[0..3];
            var shift: usize = 1;
            var op = Op.VALUE;

            switch (line[4]) {
                'A' => op = Op.AND,
                'X' => op = Op.XOR,
                'O' => {
                    op = Op.OR;
                    shift = 0;
                },
                else => unreachable,
            }
            const name2 = line[shift + 7 .. shift + 10];
            const name3 = line[shift + 14 ..];
            const gate_1 = gate_map.get(name) orelse add_gate(name, Gate{});
            const gate_2 = gate_map.get(name2) orelse add_gate(name2, Gate{});
            var gate_3 = gate_map.get(name3) orelse add_gate(name3, Gate{});

            gate_3.op = op;
            gate_3.left = gate_1;
            gate_3.right = gate_2;
            gate_1.connections += 1;
            gate_2.connections += 1;
            if (name3[0] == 'z') {
                const id = (name3[1] - '0') * 10 + (name3[2] - '0');
                zIndex[id] = gate_3;
                z_count += 1;
            }
        }
    }
}

pub fn eval(gate: *Gate) bool {
    if (gate.value != null) return gate.value.?;
    const left = eval(gate.left.?);
    const right = eval(gate.right.?);
    switch (gate.op) {
        Op.AND => gate.value = left and right,
        Op.OR => gate.value = left or right,
        Op.XOR => gate.value = left != right,
        else => {
            std.debug.panic("Unknown op: {}", .{gate.op});
        },
    }

    return gate.value.?;
}

pub fn part1(input: []const u8) void {
    parse(input);

    var result: usize = 0;
    for (0..z_count) |i| {
        const gate = zIndex[z_count - i - 1];
        result *= 2;
        if (eval(gate)) result += 1;
    }

    print("part_1={}", .{result});
}

pub const hstep = 38;
pub const vstep = 17;

pub fn order(g: *Gate) void {
    print("Start Ordering...", .{});
    if (g.pos[0] != 0) return;
    if (g.op == Op.VALUE) {
        g.pos[1] = 40;
        g.pos[0] = 0;
        if (g.label.?[0] == 'y') {
            g.pos[1] += vstep * 2;
            g.pos[0] = hstep / 2;
        }
        const id: u32 = @intCast((g.label.?[1] - '0') * 10 + (g.label.?[2] - '0'));
        g.pos[0] += id * hstep;
        print("Finished Ordering...", .{});
        return;
    }

    g.left.?.connections += 1;
    order(g.left.?);
    g.right.?.connections += 1;
    order(g.right.?);
    if (g.left.?.pos[0] > g.right.?.pos[0]) {
        const temp = g.left;
        g.left = g.right;
        g.right = temp;
    }
    g.pos[0] = g.left.?.pos[0];
    if (g.left.?.pos[0] == g.right.?.pos[0] and g.right.?.op != Op.AND) {
        const temp = g.left;
        g.left = g.right;
        g.right = temp;
    }
    g.pos[1] = @max(g.left.?.pos[1], g.right.?.pos[1]) + vstep;
    if (g.left.?.op == Op.VALUE and g.right.?.op == Op.VALUE) {
        g.pos[1] += vstep;
        if (g.op != .AND) g.pos[1] += vstep * 2;
    } else if (g.op == .OR and g.left.?.op == .AND) {
        g.pos[1] += g.left.?.pos[1];
        g.pos[0] += g.left.?.pos[0] + hstep;
    }
    if (g.label.?[0] == 'z') {
        g.pos[1] = 1000; // bottom
        const id: u32 = @intCast((g.label.?[1] - '0') * 10 + (g.label.?[2] - '0'));
        g.pos[0] = 40 + id * hstep;
    }
    while (position_hash.contains(g.pos)) g.pos[0] += hstep;
    position_hash.put(g.pos, true) catch unreachable;
}

pub fn reorder() void {
    position_hash.clearRetainingCapacity();
    for (0..gate_count) |idx| {
        gates[idx].pos = .{ 0, 0 };
        gates[idx].connections = 0;
    }
    for (0..gate_count) |idx| {
        if (gates[idx].label.?[0] == 'z') order(&gates[idx]);
    }
}

pub fn swap(a: *Gate, b: *Gate) void {
    std.debug.print("Swapping {s} and {s}\n", .{ a.label.?, b.label.? });
    const tg = a.*;
    a.* = b.*;
    b.* = tg;
    const tmp = a.label;
    a.label = b.label;
    b.label = tmp;
}

pub fn reset(idx: usize) void {
    for (0..gate_count) |i| {
        const g = &gates[i];
        if (g.op == Op.VALUE) {
            const id: u32 = @intCast((g.label.?[1] - '0') * 10 + (g.label.?[2] - '0'));
            g.value = idx == id;
        } else g.value = null;
    }
}

pub fn isbad(g: *const Gate) bool {
    if (g.op == Op.VALUE) return false;
    if (g.label.?[0] == 'z') {
        const id: u32 = @intCast((g.label.?[1] - '0') * 10 + (g.label.?[2] - '0'));
        if (id < 45) return g.op != .XOR;
        return false;
    }
    if (g.op == .XOR and (g.left.?.op != .VALUE or g.right.?.op != .VALUE)) return true;
    if (g.left.?.op == .VALUE and g.right.?.op == .VALUE and g.op == .AND) {
        if (g.left.?.label.?[1] == '0' and g.left.?.label.?[2] == '0') return g.connections != 2;
        return g.connections != 1;
    }
    if (g.left.?.op == .VALUE and g.right.?.op == .VALUE and g.op == .XOR) return g.connections != 2;

    return false;
}

pub fn hdist(a: *Gate, b: *Gate) u32 {
    if (a.pos[0] > b.pos[0]) return a.pos[0] - b.pos[0];
    return b.pos[0] - a.pos[0];
}

fn compareStrings(_: void, lhs: []const u8, rhs: []const u8) bool {
    return std.mem.order(u8, lhs, rhs).compare(std.math.CompareOperator.lt);
}

pub fn part2() !void {
    for (0..gate_count) |i| {
        const g = &gates[i];
        if (isbad(g)) {
            ret.append(g.label.?) catch {
                print("Out of memory", .{});
                return error.OutOfMemory;
            };
        }
    }
    std.mem.sort([]const u8, ret.items, {}, compareStrings);
    std.debug.print("part_2=", .{});
    for (ret.items, 0..) |item, i| {
        if (i == ret.items.len - 1) {
            print("{s}", .{item});
            continue;
        }
        std.debug.print("{s},", .{item});
    }
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();
    alloc = arena.allocator();

    gate_map = std.StringHashMap(*Gate).init(alloc);
    position_hash = std.AutoHashMap(@Vector(2, u32), bool).init(alloc);
    ret = std.ArrayList([]const u8).init(alloc);

    print("\n[ Day 24 ]", .{});
    part1(data);
    try part2();
}
