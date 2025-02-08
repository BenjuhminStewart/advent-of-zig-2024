const std = @import("std");
const Allocator = std.mem.Allocator;
const testing = std.testing;
const print = std.debug.print;
const data = @embedFile("input.txt");
const test_data = @embedFile("test_input.txt");

var gpa_impl = std.heap.GeneralPurposeAllocator(.{}){};
const gpa = gpa_impl.allocator();

var alloc: std.mem.Allocator = undefined;

const ANTINODE = '#';
const EMPTY = '.';

var antennae: Antennae = undefined;

var antennae2: Antennae = undefined;

const Antennae = struct {
    const Self = @This();
    list: std.ArrayList(Antenna),
    map: std.AutoHashMap(u8, Antennae),
    antinodes_map: std.AutoHashMap(Point, void),

    pub fn init(allocator: Allocator) Self {
        return Self{
            .list = std.ArrayList(Antenna).init(allocator),
            .map = std.AutoHashMap(u8, Antennae).init(allocator),
            .antinodes_map = std.AutoHashMap(Point, void).init(allocator),
        };
    }

    pub fn append(self: *Self, antenna: Antenna) void {
        self.list.append(antenna) catch unreachable;
    }

    pub fn print_map(self: *Self) void {
        var it = self.map.iterator();
        while (it.next()) |entry| {
            print("{c} | ", .{entry.key_ptr.*});
            for (entry.value_ptr.*.list.items) |antenna| {
                antenna.print_self();
            }
        }
    }
};

const Slope = struct {
    dx: i32,
    dy: i32,

    pub fn init(dx: i32, dy: i32) Slope {
        return Slope{
            .dx = dx,
            .dy = dy,
        };
    }
};

const Point = struct {
    x: i32,
    y: i32,

    pub fn init(x: i32, y: i32) Point {
        return Point{
            .x = x,
            .y = y,
        };
    }

    pub fn distance_from(self: Point, other: Point) f32 {
        const x1 = i32_to_f32(self.x);
        const y1 = i32_to_f32(self.y);
        const x2 = i32_to_f32(other.x);
        const y2 = i32_to_f32(other.y);
        var dx: f32 = undefined;
        if (x1 > x2) {
            dx = x1 - x2;
        } else {
            dx = x2 - x1;
        }

        var dy: f32 = undefined;
        if (y1 > y2) {
            dy = y1 - y2;
        } else {
            dy = y2 - y1;
        }
        const dist: f32 = std.math.sqrt(dx * dx + dy * dy);
        return dist;
    }

    pub fn get_slope(self: Point, other: Point) Slope {
        const dx = self.x - other.x;
        const dy = self.y - other.y;
        return Slope.init(dx, dy);
    }

    pub fn is_in_grid(self: Point, grid: [][]u8) bool {
        if (self.x < 0 or self.y < 0) {
            return false;
        }
        if (self.x >= grid.len or self.y >= grid[0].len) {
            return false;
        }

        return true;
    }
};

pub fn i32_to_usize(x: i32) !usize {
    if (x < 0) {
        return error.NegativeError;
    }
    var i: usize = 0;
    while (i < x) : (i += 1) {}
    return i;
}

pub fn i32_to_f32(x: i32) f32 {
    return @floatFromInt(x);
}

const Antenna = struct {
    const Self = @This();
    freq: u8,
    location: Point,

    pub fn init(freq: u8, location: Point) Self {
        return Self{
            .freq = freq,
            .location = location,
        };
    }

    pub fn print_self(self: Self) void {
        print("{c}({},{}) ", .{ self.freq, self.location.x, self.location.y });
    }
};

pub fn parse(input: []const u8) ![][]u8 {
    var grid: std.ArrayList([]u8) = std.ArrayList([]u8).init(alloc);
    var lines = std.mem.tokenizeScalar(u8, input, '\n');
    while (lines.next()) |line| {
        var line_grid: std.ArrayList(u8) = std.ArrayList(u8).init(alloc);
        for (line) |char| {
            line_grid.append(char) catch {
                return error.ParseLineGridError;
            };
        }
        grid.append(line_grid.items) catch {
            return error.ParseGridError;
        };
    }
    return grid.items;
}

pub fn unique_locations_with_antinode(grid: [][]u8) !usize {
    build_antennae(grid) catch {
        return error.BuildAntennaeError;
    };

    // loop through the antennae map
    var it = antennae.map.iterator();
    while (it.next()) |entry| {
        // const key = entry.key_ptr.*;
        const value = entry.value_ptr.*;

        // loop through the antennae list
        for (value.list.items, 0..) |antenna, i| {
            const current = antenna;
            for (value.list.items, 0..) |other, j| {
                if (i == j) {
                    continue;
                }
                const slope = current.location.get_slope(other.location);
                check_and_append_antinode(grid, current, other, slope) catch {
                    return error.CheckAndAppendAntinodeError;
                };
            }
        }
    }

    var antinodes: usize = 0;
    var it_antinodes = antennae.antinodes_map.iterator();
    while (it_antinodes.next()) |_| {
        antinodes += 1;
    }

    return antinodes;
}

pub fn unique_locations_with_antinode2(grid: [][]u8) !usize {
    build_antennae(grid) catch {
        return error.BuildAntennaeError;
    };

    // loop through the antennae map
    var it = antennae.map.iterator();
    while (it.next()) |entry| {
        // const key = entry.key_ptr.*;
        const value = entry.value_ptr.*;

        // loop through the antennae list
        for (value.list.items, 0..) |antenna, i| {
            const current = antenna;
            for (value.list.items, 0..) |other, j| {
                if (i == j) {
                    continue;
                }
                const slope = current.location.get_slope(other.location);
                if (current.location.x == other.location.x and current.location.y == other.location.y) {
                    continue;
                }
                check_and_append_antinode2(grid, current, other, slope) catch {
                    return error.CheckAndAppendAntinodeError;
                };
            }
        }
    }

    var antinodes: usize = 0;
    var it_antinodes = antennae.antinodes_map.iterator();
    while (it_antinodes.next()) |_| {
        antinodes += 1;
    }

    return antinodes;
}

pub fn check_and_append_antinode2(grid: [][]u8, a1: Antenna, a2: Antenna, slope: Slope) !void {
    const a1_x = a1.location.x;
    const a2_x = a2.location.x;
    const a1_y = a1.location.y;
    const a2_y = a2.location.y;
    const dx = slope.dx;
    const dy = slope.dy;

    var an1 = Point.init(a1_x + dx, a1_y + dy);
    while (an1.is_in_grid(grid)) {
        antennae.antinodes_map.put(an1, void{}) catch {
            return error.AntinodesMapError;
        };
        an1 = Point.init(an1.x + dx, an1.y + dy);
    }

    var an2 = Point.init(a2_x - dx, a2_y - dy);
    while (an2.is_in_grid(grid)) {
        antennae.antinodes_map.put(an2, void{}) catch {
            return error.AntinodesMapError;
        };
        an2 = Point.init(an2.x - dx, an2.y - dy);
    }

    var an3 = Point.init(a1_x - dx, a1_y - dy);
    while (an3.is_in_grid(grid)) {
        antennae.antinodes_map.put(an3, void{}) catch {
            return error.AntinodesMapError;
        };
        an3 = Point.init(an3.x - dx, an3.y - dy);
    }

    var an4 = Point.init(a2_x + dx, a2_y + dy);
    while (an4.is_in_grid(grid)) {
        antennae.antinodes_map.put(an4, void{}) catch {
            return error.AntinodesMapError;
        };
        an4 = Point.init(an4.x + dx, an4.y + dy);
    }
}

pub fn check_and_append_antinode(grid: [][]u8, a1: Antenna, a2: Antenna, slope: Slope) !void {
    const a1_x = a1.location.x;
    const a2_x = a2.location.x;
    const a1_y = a1.location.y;
    const a2_y = a2.location.y;
    const dx = slope.dx;
    const dy = slope.dy;

    const distance = a1.location.distance_from(a2.location);

    var an1 = Point.init(a1_x + dx, a1_y + dy);
    var an2 = Point.init(a2_x - dx, a2_y - dy);
    var an3 = Point.init(a1_x - dx, a1_y - dy);
    var an4 = Point.init(a2_x + dx, a2_y + dy);

    if (an1.is_in_grid(grid) and an1.distance_from(a1.location) == distance and an1.distance_from(a2.location) == 2 * distance) {
        antennae.antinodes_map.put(an1, void{}) catch {
            return error.AntinodesMapError;
        };
    } else if (an1.is_in_grid(grid) and an1.distance_from(a2.location) == distance and an1.distance_from(a1.location) == 2 * distance) {
        antennae.antinodes_map.put(an1, void{}) catch {
            return error.AntinodesMapError;
        };
    }

    if (an2.is_in_grid(grid) and an2.distance_from(a1.location) == distance and an2.distance_from(a2.location) == 2 * distance) {
        antennae.antinodes_map.put(an2, void{}) catch {
            return error.AntinodesMapError;
        };
    } else if (an2.is_in_grid(grid) and an2.distance_from(a2.location) == distance and an2.distance_from(a1.location) == 2 * distance) {
        antennae.antinodes_map.put(an2, void{}) catch {
            return error.AntinodesMapError;
        };
    }

    if (an3.is_in_grid(grid) and an3.distance_from(a1.location) == distance and an3.distance_from(a2.location) == 2 * distance) {
        antennae.antinodes_map.put(an3, void{}) catch {
            return error.AntinodesMapError;
        };
    } else if (an3.is_in_grid(grid) and an3.distance_from(a2.location) == distance and an3.distance_from(a1.location) == 2 * distance) {
        antennae.antinodes_map.put(an3, void{}) catch {
            return error.AntinodesMapError;
        };
    }

    if (an4.is_in_grid(grid) and an4.distance_from(a1.location) == distance and an4.distance_from(a2.location) == 2 * distance) {
        antennae.antinodes_map.put(an4, void{}) catch {
            return error.AntinodesMapError;
        };
    } else if (an4.is_in_grid(grid) and an4.distance_from(a2.location) == distance and an4.distance_from(a1.location) == 2 * distance) {
        antennae.antinodes_map.put(an4, void{}) catch {
            return error.AntinodesMapError;
        };
    }
}

pub fn build_antennae(grid: [][]u8) !void {
    for (grid, 0..) |row, x| {
        for (row, 0..) |char, y| {
            if (char != EMPTY) {
                antennae.append(Antenna.init(char, Point.init(@intCast(x), @intCast(y))));
            }
        }
    }

    // build antennae
    for (antennae.list.items) |antenna| {
        const freq = antenna.freq;
        const list = antennae.map.getOrPut(freq) catch {
            return error.AtennaeMapError;
        };
        if (!list.found_existing) {
            list.value_ptr.* = Antennae.init(alloc);
        }
        list.value_ptr.*.append(antenna);
    }
    return;
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();
    alloc = arena.allocator();

    antennae = Antennae.init(alloc);
    antennae2 = Antennae.init(alloc);

    const grid = parse(data) catch {
        return error.ParseError;
    };
    const actual = unique_locations_with_antinode(grid) catch {
        return error.UniqueLocationsError;
    };
    print("part_1={}\n", .{actual});

    const grid2 = parse(data) catch {
        return error.ParseError;
    };
    const actual2 = unique_locations_with_antinode2(grid2) catch {
        return error.UniqueLocationsError;
    };

    print("part_2={}\n", .{actual2});
}

test "part_1" {
    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();
    alloc = arena.allocator();

    antennae = Antennae.init(alloc);

    const grid = parse(test_data) catch {
        return error.ParseError;
    };

    const actual = unique_locations_with_antinode(grid) catch {
        return error.UniqueLocationsError;
    };

    const expected = 14;
    try testing.expectEqual(expected, actual);
}

test "part_2" {
    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();
    alloc = arena.allocator();

    antennae = Antennae.init(alloc);

    const grid = parse(test_data) catch {
        return error.ParseError;
    };

    const actual = unique_locations_with_antinode2(grid) catch {
        return error.UniqueLocationsError;
    };

    const expected = 34;
    try testing.expectEqual(expected, actual);
}
