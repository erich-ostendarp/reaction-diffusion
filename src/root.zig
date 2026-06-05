const std = @import("std");
const c = @import("c");
const Io = std.Io;

const window_width = 1024;
const window_height = 1024;

const board_width = 256;
const board_height = 256;

fn errorCallback(a: c_int, b: [*c]const u8) callconv(.c) void {
    std.debug.print("{} {s}\n", .{ a, b });
}

pub fn update(alloc: std.mem.Allocator, pixels: []u8) !void {
    var buf = try alloc.alloc(u8, board_width * board_height * 3);
    defer alloc.free(buf);

    const temp1 = std.mem.bytesAsSlice(struct { u8, u8, u8 }, pixels[0..]);
    var temp2 = std.mem.bytesAsSlice(struct { u8, u8, u8 }, buf[0..]);
    for (temp1, temp2[0..], 0..) |p1, *p2, i| {
        const x = i % board_width;
        const y = i / board_width;

        var count: u4 = 0;
        for (0..3) |a| {
            const nx = x + a;
            for (0..3) |b| {
                if (a == 1 and b == 1) continue;
                const ny = y + b;
                if (0 < nx and nx <= board_width and 0 < ny and ny <= board_height) {
                    const ni = (ny - 1) * board_width + nx - 1;
                    if (temp1[ni][0] == 255) count += 1;
                }
            }
        }
        p2.* = .{0} ** 3;
        if (p1[0] == 255) {
            p2.* = if (count < 2 or count > 3) .{0} ** 3 else .{255} ** 3;
        } else if (count == 3) {
            p2.* = .{255} ** 3;
        }
    }
    @memcpy(pixels, buf);
}

pub fn main(init: std.process.Init) !void {
    var pixels = try init.gpa.alloc(u8, board_width * board_height * 3);
    defer init.gpa.free(pixels);
    for (std.mem.bytesAsSlice(struct { u8, u8, u8 }, pixels[0..]), 0..) |*pixel, i| {
        const x: f64 = @floatFromInt(i % board_width);
        const y: f64 = @floatFromInt(i / board_width);

        const cx = @as(f64, @floatFromInt(board_width)) / 2;
        const cy = @as(f64, @floatFromInt(board_height)) / 2;

        const a = x - cx;
        const b = y - cy;

        const d = std.math.sqrt(a * a + b * b);
        _ = d;

        pixel.* = if (x == 50) .{255} ** 3 else .{0} ** 3;
    }

    _ = c.glfwSetErrorCallback(errorCallback);

    if (c.glfwInit() != 1) return error.glfwInit;
    defer c.glfwTerminate();

    const window = c.glfwCreateWindow(window_width, window_height, "Reaction Diffusion", null, null) orelse return error.glfwCreateWindow;
    c.glfwMakeContextCurrent(window);

    var tex: c.GLuint = undefined;
    c.glGenTextures(1, &tex);
    defer c.glDeleteTextures(1, &tex);
    c.glBindTexture(c.GL_TEXTURE_2D, tex);

    c.glTexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_MIN_FILTER, c.GL_LINEAR);
    c.glTexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_MAG_FILTER, c.GL_LINEAR);
    c.glTexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_WRAP_S, c.GL_CLAMP_TO_EDGE);
    c.glTexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_WRAP_T, c.GL_CLAMP_TO_EDGE);

    c.glTexImage2D(c.GL_TEXTURE_2D, 0, c.GL_RGB, board_width, board_height, 0, c.GL_RGB, c.GL_UNSIGNED_BYTE, null);
    c.glEnable(c.GL_TEXTURE_2D);

    c.glMatrixMode(c.GL_PROJECTION);
    c.glLoadIdentity();
    c.glMatrixMode(c.GL_MODELVIEW);

    while (c.glfwWindowShouldClose(window) != 1) {
        const from = std.Io.Timestamp.now(init.io, .real);

        try update(init.gpa, pixels);
        c.glTexSubImage2D(c.GL_TEXTURE_2D, 0, 0, 0, board_width, board_height, c.GL_RGB, c.GL_UNSIGNED_BYTE, @ptrCast(pixels));

        c.glBegin(c.GL_QUADS);

        // tex coords: (0,0) = bottom-left in GL; flip Y if your buffer is top-down
        c.glTexCoord2f(0, 1);
        c.glVertex2f(-1, -1); // bottom-left
        c.glTexCoord2f(1, 1);
        c.glVertex2f(1, -1); // bottom-right
        c.glTexCoord2f(1, 0);
        c.glVertex2f(1, 1); // top-right
        c.glTexCoord2f(0, 0);
        c.glVertex2f(-1, 1); // top-left

        c.glEnd();

        c.glfwSwapBuffers(window);
        c.glfwPollEvents();

        const elapsed = from.durationTo(std.Io.Timestamp.now(init.io, .real));
        if (elapsed.nanoseconds < std.time.ns_per_s / 10) try init.io.sleep(.{ .nanoseconds = std.time.ns_per_s / 10 }, .real);
    }
}
