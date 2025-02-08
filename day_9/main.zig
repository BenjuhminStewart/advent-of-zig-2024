// IMPORTS
const std = @import("std");
const Allocator = std.mem.Allocator;
const testing = std.testing;
const print = std.debug.print;
const data = @embedFile("input.txt");
const test_data = @embedFile("test_input.txt");

var gpa_impl = std.heap.GeneralPurposeAllocator(.{}){};
const gpa = gpa_impl.allocator();

var alloc: Allocator = undefined;

var disks: std.ArrayList(Disk) = undefined;
var file_system: std.ArrayList(i64) = undefined;

const Disk = struct {
    const Self = @This();
    id: usize,
    file_size: u8,
    free_space: u8,

    pub fn init(id: usize, file_size: u8, free_space: u8) Self {
        return Self{
            .id = id,
            .file_size = file_size,
            .free_space = free_space,
        };
    }

    pub fn print_disk(self: Self) void {
        print("Disk {}: file_size={}, free_space={}\n", .{ self.id, self.file_size, self.free_space });
    }
};

pub fn parse(input: []const u8) !void {
    disks = std.ArrayList(Disk).init(alloc);
    var curr_id: usize = 0;
    var i: usize = 0;
    while (i < input.len) : (i += 2) {
        const file_size: u8 = input[i];
        const free_space: u8 = input[i + 1];
        disks.append(Disk.init(curr_id, file_size, free_space)) catch {
            return error.DiskAppendError;
        };
        curr_id += 1;
    }
}
pub fn build_file_system() !void {
    file_system = std.ArrayList(i64).init(alloc);
    for (disks.items) |disk| {
        const file_size: usize = as_usize(disk.file_size);
        for (0..file_size) |_| {
            const id: i64 = @intCast(disk.id);
            file_system.append(id) catch {
                return error.FileSystemAppendError;
            };
        }
        const free_space: usize = as_usize(disk.free_space);
        for (0..free_space) |_| {
            file_system.append(-1) catch {
                return error.FileSystemAppendError;
            };
        }
    }
}
pub fn shift() void {
    var last: usize = file_system.items.len - 1;
    var empty_spots = get_empty_spots();
    while (last > empty_spots.items[0]) {
        if (file_system.items[last] != -1) {
            file_system.items[empty_spots.items[0]] = file_system.items[last];
            file_system.items[last] = -1;
            _ = empty_spots.orderedRemove(0);
            empty_spots.append(last) catch unreachable;
        }
        last -= 1;
    }
}
pub fn get_checksum() i64 {
    var checksum: i64 = 0;
    for (file_system.items, 0..) |id, i| {
        if (id == -1) {
            continue;
        }
        const position: i64 = @intCast(i);
        checksum += (position * id);
    }

    return checksum;
}
pub fn shift_if_enough_space() void {
    const empty_spots = get_empty_spots_2();
    const filled_spots = get_filled_spots();
    var visited: std.AutoHashMap(i64, void) = std.AutoHashMap(i64, void).init(alloc);
    var i: usize = file_system.items.len - 1;
    while (i > 0) {
        if (file_system.items[i] == -1) {
            i -= 1;
            continue;
        }
        const curr_id: i64 = file_system.items[i];
        const count_of_id = filled_spots.get(curr_id) orelse 0;
        if (visited.get(curr_id)) |_| {
            i -= 1;
            continue;
        } else {
            visited.put(curr_id, {}) catch unreachable;
        }
        var j: usize = 0;
        while (j < empty_spots.items.len) : (j += 1) {
            const spots = empty_spots.items[j].items.len;
            if (empty_spots.items[j].items.len == 0) {
                continue;
            }
            const first_empty_spot = empty_spots.items[j].items[0];
            if (i < first_empty_spot) {
                break;
            }
            if (spots >= count_of_id) {
                var spot = first_empty_spot;
                var spot_moving_from = i;
                var new_empty_spots: std.ArrayList(usize) = std.ArrayList(usize).init(alloc);
                for (first_empty_spot..first_empty_spot + count_of_id) |_| {
                    file_system.items[spot] = curr_id;
                    file_system.items[spot_moving_from] = -1;
                    _ = empty_spots.items[j].orderedRemove(0);
                    new_empty_spots.append(spot_moving_from) catch unreachable;
                    spot_moving_from -= 1;
                    if (empty_spots.items[j].items.len == 0) {
                        break;
                    }
                    spot = empty_spots.items[j].items[0];
                }
                break;
            }
        }
        i -= 1;
    }
}
pub fn get_filled_spots() std.AutoHashMap(i64, usize) {
    var i: usize = file_system.items.len - 1;
    var id_to_count: std.AutoHashMap(i64, usize) = std.AutoHashMap(i64, usize).init(alloc);
    var last_id: i64 = file_system.items[i];
    var count: usize = 1;
    while (i > 0) {
        if (file_system.items[i - 1] == last_id) {
            count += 1;
            if (i == 1) {
                id_to_count.put(last_id, count) catch unreachable;
                break;
            }
        } else {
            if (last_id != -1) {
                id_to_count.put(last_id, count) catch unreachable;
            }
            count = 1;
            last_id = file_system.items[i - 1];
        }
        i -= 1;
    }

    return id_to_count;
}
pub fn get_empty_spots() std.ArrayList(usize) {
    var empty_spots: std.ArrayList(usize) = std.ArrayList(usize).init(alloc);
    for (file_system.items, 0..) |file, i| {
        if (file == -1) {
            empty_spots.append(i) catch unreachable;
        }
    }

    return empty_spots;
}
pub fn get_empty_spots_2() std.ArrayList(std.ArrayList(usize)) {
    var empty_spots: std.ArrayList(std.ArrayList(usize)) = std.ArrayList(std.ArrayList(usize)).init(alloc);
    var i: usize = 0;
    while (i < file_system.items.len) : (i += 1) {
        var empty_spot_list: std.ArrayList(usize) = std.ArrayList(usize).init(alloc);
        while (file_system.items[i] == -1) {
            empty_spot_list.append(i) catch unreachable;
            i += 1;
        }
        if (empty_spot_list.items.len > 0) {
            empty_spots.append(empty_spot_list) catch unreachable;
        } else {
            empty_spot_list.deinit();
        }
    }

    return empty_spots;
}
pub fn as_usize(self: u8) usize {
    var digit: usize = 0;
    switch (self) {
        '0' => digit = 0,
        '1' => digit = 1,
        '2' => digit = 2,
        '3' => digit = 3,
        '4' => digit = 4,
        '5' => digit = 5,
        '6' => digit = 6,
        '7' => digit = 7,
        '8' => digit = 8,
        '9' => digit = 9,
        else => return 0,
    }
    return digit;
}

// RUNNER
pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();
    alloc = arena.allocator();

    try parse(data);
    try build_file_system();
    shift();

    const checksum: i64 = get_checksum();
    print("part_1={}\n", .{checksum});

    try parse(data);
    try build_file_system();
    shift_if_enough_space();
    const checksum_2: i64 = get_checksum();
    print("part_2={}\n", .{checksum_2});
}

test "part 1" {
    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();
    alloc = arena.allocator();

    try parse(test_data);
    try build_file_system();
    shift();

    const checksum: i64 = get_checksum();
    const expected: i64 = 1928;
    try testing.expectEqual(expected, checksum);
}
test "part 2" {
    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();
    alloc = arena.allocator();

    try parse(test_data);
    try build_file_system();
    shift_if_enough_space();

    const checksum: i64 = get_checksum();
    const expected: i64 = 2858;
    try testing.expectEqual(expected, checksum);
}
