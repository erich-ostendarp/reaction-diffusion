const std = @import("std");
const Io = std.Io;

const reaction_diffusion = @import("reaction_diffusion");

pub fn main(init: std.process.Init) !void {
    try reaction_diffusion.main(init);
}
