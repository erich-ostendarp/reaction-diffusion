const std = @import("std");
const Io = std.Io;

const c = @import("c");

pub fn main(init: std.process.Init) !void {
    _ = init;

    if (c.glfwInit() != 1) return error.glfwInit;

    const window = c.glfwCreateWindow(640, 480, "Hello, World!", null, null) orelse {
        c.glfwTerminate();
        return error.glfwCreateWindow;
    };

    c.glfwMakeContextCurrent(window);
    while (c.glfwWindowShouldClose(window) != 1) {
        // Render here
        c.glClear(c.GL_COLOR_BUFFER_BIT);

        c.glColor3f(0, 0.5, 0.5);
        c.glLineWidth(2);
        c.glBegin(c.GL_LINE_LOOP);

        c.glVertex2f(0, 0);
        c.glVertex2f(0.5, 0);
        c.glVertex2f(0.5, 0.5);
        c.glVertex2f(0, 0.5);
        c.glVertex2f(0, 0);

        c.glEnd();

        // Swap front and back buffers
        c.glfwSwapBuffers(window);

        // Poll for and process events
        c.glfwPollEvents();
    }

    c.glfwTerminate();
}
