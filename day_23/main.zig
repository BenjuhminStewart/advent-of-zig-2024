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

const LINES = 3380;

var gpa_impl = std.heap.GeneralPurposeAllocator(.{}){};
var gpa = gpa_impl.allocator();

var alloc: Allocator = undefined;

const Node = struct {
    id: u16,
    connections: []u16,
};

var connections: [LINES]u32 = undefined;
var nodes: [1024]Node = undefined;
var computer1: []u16 = undefined;
var computer2: []u16 = undefined;
var computer3: []u16 = undefined;

pub fn parse(input: []const u8) void {
    var ecnt = [_]usize{0} ** 1024;
    var lines = std.mem.tokenizeScalar(u8, input, '\n');
    var i: usize = 0;
    while (lines.next()) |line| {
        var id: u32 = @intCast(line[0] - 'a' + 1);
        id *= 32;
        id += @intCast(line[1] - 'a' + 1);
        id *= 32;
        id += @intCast(line[3] - 'a' + 1);
        id *= 32;
        id += @intCast(line[4] - 'a' + 1);
        ecnt[id >> 10] += 1;
        ecnt[id & 1023] += 1;

        connections[i] = id;
        i += 1;
    }

    for (ecnt, 0..) |s, id| {
        nodes[id].id = @intCast(id);
        if (s > 0) {
            nodes[id].connections = alloc.alloc(u16, s + 1) catch unreachable;
            nodes[id].connections[0] = @intCast(id);
            ecnt[id] = 1;
        } else {
            nodes[id].connections.len = 0;
        }
    }

    for (connections) |connection| {
        const id1: u16 = @intCast(connection >> 10);
        const id2: u16 = @intCast(connection & 1023);
        var node1 = &nodes[id1];
        var node2 = &nodes[id2];
        node1.connections[ecnt[id1]] = id2;
        ecnt[id1] += 1;
        node2.connections[ecnt[id2]] = id1;
        ecnt[id2] += 1;
    }

    for (nodes) |node| {
        if (node.connections.len == 0) continue;
        std.mem.sort(u16, node.connections, {}, std.sort.asc(u16));
    }

    computer1 = alloc.alloc(u16, 16) catch unreachable;
    computer2 = alloc.alloc(u16, 16) catch unreachable;
    computer3 = alloc.alloc(u16, 16) catch unreachable;
}

pub fn ordered_key(id1: u16, id2: u16, id3: u16) u32 {
    const min = @min(@min(id1, id2), id3);
    const max = @max(@max(id1, id2), id3);
    const mid = id1 + id2 + id3 - min - max;
    return @as(u32, @intCast(min)) << 20 | @as(u32, @intCast(mid)) << 10 | @as(u32, @intCast(max));
}

pub fn common_count(connections1: *[]u16, connections2: *[]u16, computer: *[]u16) usize {
    var p1: usize = 0;
    var p2: usize = 0;
    var count: usize = 0;
    computer.len = 16;
    while (p1 < connections1.len and p2 < connections2.len) {
        if (connections1.*[p1] == connections2.*[p2]) {
            computer.*[count] = connections1.*[p1];
            count += 1;
            p1 += 1;
            p2 += 1;
        } else if (connections1.*[p1] < connections2.*[p2]) {
            p1 += 1;
        } else {
            p2 += 1;
        }
    }
    computer.len = count;
    return count;
}

pub fn larget_lan(id1: u16, id2: u16, threshold: comptime_int) usize {
    var min_count = common_count(&nodes[id1].connections, &nodes[id2].connections, &computer3);
    if (min_count < threshold) return 0;
    computer1 = computer3[0..min_count];
    for (computer1) |id3| {
        if (id3 == id2) continue;
        const count1 = common_count(&computer3, &nodes[id3].connections, &computer2);
        if (count1 < min_count) {
            min_count = count1;
            computer3 = computer2[0..count1];
        }
        if (threshold > 0 and min_count <= threshold) break;
    }
    if (min_count > threshold) return min_count;
    return 0;
}

pub fn sort_party() []u8 {
    var ret = alloc.alloc(u8, computer3.len * 3) catch unreachable;
    std.mem.sort(u16, computer3, {}, std.sort.asc(u16));
    for (computer3, 0..) |id, i| {
        if (i > 0) ret[i * 3 - 1] = ',';
        ret[i * 3] = @as(u8, @intCast('a' - 1 + (id >> 5)));
        ret[i * 3 + 1] = @as(u8, @intCast('a' - 1 + (id & 31)));
    }
    ret[computer3.len * 3 - 1] = 0;
    return ret;
}

pub fn part1(input: []const u8) void {
    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();
    alloc = arena.allocator();

    parse(input);

    var visited = std.AutoHashMap(u32, bool).init(alloc);
    visited.ensureTotalCapacity(LINES) catch unreachable;

    for (connections) |connection| {
        const id1: u16 = @intCast(connection >> 10);
        const id2: u16 = @intCast(connection & 1023);

        // do they start with a 't'?
        if ((id1 >> 5) != 20 and (id2 >> 5) != 20) continue; // if not, continue

        const count = common_count(&nodes[id1].connections, &nodes[id2].connections, &computer1);
        if (count == 0) continue;

        for (computer1) |id3| {
            if (id3 == id1 or id3 == id2) continue;
            const key = ordered_key(id1, id2, id3);
            if (!visited.contains(key)) {
                visited.put(key, true) catch unreachable;
            }
        }
    }
    print("part_1={d}", .{visited.count()});
}

pub fn part2(input: []const u8) void {
    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();
    alloc = arena.allocator();

    parse(input);

    var max: usize = 0;
    var ret: []u8 = undefined;
    for (connections) |connection| {
        const id1: u16 = @intCast(connection >> 10);
        const id2: u16 = @intCast(connection & 1023);

        const t = larget_lan(id1, id2, 12);
        if (t > max) {
            max = t;
            ret = sort_party();
            if (max == nodes[id1].connections.len - 1) break;
        }
    }

    print("part_2={s}", .{ret});
}

pub fn main() void {
    print("[ Day 23 ]", .{});
    part1(data);
    part2(data);
}
