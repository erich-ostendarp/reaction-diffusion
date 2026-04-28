const std = @import("std");
const c = @import("c");
const Io = std.Io;

const Chemical = struct {
    reaction_rate: f64,
    diffusion_rate: f64,
    amount: f64 = 0,
    color: struct { u8, u8, u8 } = .{ 0, 255, 0 },
};

const Cell = struct {
    producer: Chemical = .{ .reaction_rate = 0.1, .diffusion_rate = 0.1, .color = .{ 255, 0, 0 } },
    consumer: Chemical = .{ .reaction_rate = 0.1, .diffusion_rate = 0.1, .color = .{ 0, 0, 255 } },
};

pub fn main(init: std.process.Init) !void {
    _ = init;

    const window_width = 512;
    const window_height = 512;

    const board_width = 512;
    const board_height = 512;

    var cells: [board_width * board_height]Cell = undefined;
    _ = &cells;

    var pixels: [board_width * board_height * 3]u8 = [_]u8{ 0, 0, 0 } ** (board_width * board_height);
    _ = &pixels;

    _ = c.glfwSetErrorCallback(struct {
        fn callback(a: c_int, b: [*c]const u8) callconv(.c) void {
            std.debug.print("{} {s}\n", .{ a, b });
        }
    }.callback);
    if (c.glfwInit() != 1) return error.glfwInit;

    const window = c.glfwCreateWindow(window_width, window_height, "Hello, World!", null, null) orelse {
        c.glfwTerminate();
        return error.glfwCreateWindow;
    };

    c.glfwMakeContextCurrent(window);
    while (c.glfwWindowShouldClose(window) != 1) {
        c.glRasterPos2i(-1, -1);
        c.glDrawPixels(board_width, board_height, c.GL_RGB, c.GL_UNSIGNED_BYTE, @ptrCast(&pixels));

        c.glfwSwapBuffers(window);

        c.glfwPollEvents();
    }

    c.glfwTerminate();
}
