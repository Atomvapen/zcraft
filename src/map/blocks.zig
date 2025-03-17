pub const Type = enum(u8) {
    air = 0,
    grass,
    glass,
    brick,
    stone,
    wood,
    leaf,

    pub fn toInt(self: Type) i32 {
        return @intFromEnum(self);
    }

    pub fn transparent(i: u8) bool {
        return switch (@as(Type, @enumFromInt(i))) {
            .air, .glass, .leaf => true,
            else => false,
        };
    }

    pub fn solid(i: u8) bool {
        return switch (@as(Type, @enumFromInt(i))) {
            .air => true,
            else => false,
        };
    }
};

pub const Block = struct {
    type: Type,
};
