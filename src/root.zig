const std = @import("std");
const c = @import("c");
const Io = std.Io;

const Chemical = struct {
    reaction_rate: f64,
    diffusion_rate: f64,
    amount: f64 = 0,
    color: @Vector(3, u8) = .{ 0, 255, 0 },
};

const Cell = struct {
    producer: Chemical,
    consumer: Chemical,
};

fn errorCallback(a: c_int, b: [*c]const u8) callconv(.c) void {
    std.debug.print("{} {s}\n", .{ a, b });
}

pub fn main(init: std.process.Init) !void {
    const window_width = 512;
    const window_height = 512;

    const board_width = 512;
    const board_height = 512;

    var cells = try init.gpa.alloc(Cell, board_width * board_height);
    defer init.gpa.free(cells);
    for (cells[0..], 0..) |*cell, i| {
        const x = i % board_width;
        const y = i / board_width;

        if (128 < x and x < board_width - 128 and 128 < y and y < board_height - 128) {
            cell.* = .{
                .consumer = .{ .reaction_rate = 0.1, .diffusion_rate = 0.1, .color = .{ 255, 0, 0 }, .amount = 1 },
                .producer = .{ .reaction_rate = 0.1, .diffusion_rate = 0.1, .color = .{ 0, 0, 255 }, .amount = 1 },
            };
        } else {
            cell.* = .{
                .consumer = .{ .reaction_rate = 0.1, .diffusion_rate = 0.1, .color = .{ 255, 0, 0 }, .amount = 0 },
                .producer = .{ .reaction_rate = 0.1, .diffusion_rate = 0.1, .color = .{ 0, 0, 255 }, .amount = 0 },
            };
        }
    }

    var pixels = try init.gpa.alloc(u8, board_width * board_height * 3);
    defer init.gpa.free(pixels);

    _ = c.glfwSetErrorCallback(errorCallback);

    if (c.glfwInit() != 1) return error.glfwInit;
    defer c.glfwTerminate();

    const window = c.glfwCreateWindow(window_width, window_height, "Hello, World!", null, null) orelse return error.glfwCreateWindow;
    c.glfwMakeContextCurrent(window);

    while (c.glfwWindowShouldClose(window) != 1) {
        for (std.mem.bytesAsSlice(struct { u8, u8, u8 }, pixels[0..]), cells) |*pixel, cell| {
            const c_float: @Vector(3, f64) = cell.consumer.color;
            const p_float: @Vector(3, f64) = cell.producer.color;
            const c_scaled = c_float * @as(@Vector(3, f64), @splat(cell.consumer.amount));
            const p_scaled = p_float * @as(@Vector(3, f64), @splat(cell.producer.amount));
            const color: @Vector(3, u8) = @intFromFloat(c_scaled + p_scaled);
            pixel.* = .{ color[0], color[1], color[2] };
        }

        c.glRasterPos2i(-1, -1);
        c.glDrawPixels(board_width, board_height, c.GL_RGB, c.GL_UNSIGNED_BYTE, @ptrCast(pixels));

        c.glfwSwapBuffers(window);

        c.glfwPollEvents();
    }
}
