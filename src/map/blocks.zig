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

    pub fn toType(i: u8) Type {
        return @enumFromInt(i);
    }

    pub fn transparent(i: u8) bool {
        return switch (@as(Type, @enumFromInt(i))) {
            .air, .glass, .leaf => true,
            else => false,
        };
    }

    pub fn solid(i: u8) bool {
        return switch (@as(Type, @enumFromInt(i))) {
            .air => false,
            else => true,
        };
    }

    pub fn valid(i: u8) bool {
        const field_count = @typeInfo(Type).@"enum".fields.len;
        return i < field_count;
    }
};

pub const Block = struct {
    type: Type,
};
