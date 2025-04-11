pub const Vec2i = @Vector(2, i32);
pub const Vec3i = @Vector(3, i32);
pub const Vec4i = @Vector(4, i32);

pub const Vec2f = @Vector(2, f32);
pub const Vec3f = @Vector(3, f32);
pub const Vec4f = @Vector(4, f32);

/// Produces a new vector from of type `target`.
///
/// Non-same vector length result in compile errors. Non-valid type conversion result in compile errors.
///
/// Supported conversions are between `Vec3i, Vec3f` and `rl.Vector3` .
pub fn rlTransform(self: anytype, comptime Target: type) Target {
    const rl = @import("raylib");
    const self_info = @typeInfo(@TypeOf(self));
    const target_info = @typeInfo(Target);

    if (!(self_info == .vector or @TypeOf(self) == rl.Vector3) and !(target_info == .vector or Target == rl.Vector3)) {
        @compileError("rlTransform() only supports conversions between rl.Vector3 and @Vector(3, T).");
    }
    if ((self_info == .vector and self_info.vector.len != 3) or (target_info == .vector and target_info.vector.len != 3)) {
        @compileError("rlTransform() only supports 3D vectors.");
    }
    if (@TypeOf(self) == Target) @compileError("Transformation from and to the same type."); //return self;

    var result: Target = undefined;

    switch (@TypeOf(self)) {
        rl.Vector3 => switch (Target) {
            Vec3i => result = @Vector(3, i32){ @as(i32, @intFromFloat(self.x)), @as(i32, @intFromFloat(self.y)), @as(i32, @intFromFloat(self.z)) },
            Vec3f => result = @Vector(3, f32){ self.x, self.y, self.z },
            else => @compileError("Unsupported conversion."),
        },
        Vec3f => result = rl.Vector3{ .x = self[0], .y = self[1], .z = self[2] },
        Vec3i => result = rl.Vector3{ .x = @floatFromInt(self[0]), .y = @floatFromInt(self[1]), .z = @floatFromInt(self[2]) },
        else => @compileError("Unsupported conversion."),
    }

    return result;
}

/// Produces a new vector from of type `target`.
///
/// Non-same vector length result in compile errors. Non-valid type conversion result in compile errors.
///
/// Supported conversions are between `i32` and `f32`.
pub fn transform(self: anytype, comptime Target: type) Target {
    const self_info = @typeInfo(@TypeOf(self));
    const target_info = @typeInfo(Target);

    if (self_info != .vector) @compileError("Transformation can only be used on vectors.");
    if (target_info != .vector) @compileError("Transformation can only be done to vectors.");
    // if (self_info.vector.len != target_info.vector.len) @compileError("Vectors must have the same length.");
    if (@TypeOf(self) == Target) @compileError("Transformation from and to the same type."); //return self;

    var result: Target = undefined;

    // const SrcElem = self_info.vector.child;
    // const DstElem = target_info.vector.child;

    // const kind = blk: {
    //     if (SrcElem == DstElem) break :blk .Same;
    //     if (@typeInfo(SrcElem) == .int and @typeInfo(DstElem) == .float) break :blk .IntToFloat;
    //     if (@typeInfo(SrcElem) == .float and @typeInfo(DstElem) == .int) break :blk .FloatToInt;
    //     if (@typeInfo(SrcElem) == .float and @typeInfo(DstElem) == .float) break :blk .FloatToFloat;
    //     if (@typeInfo(SrcElem) == .int and @typeInfo(DstElem) == .int) break :blk .IntToInt;
    //     if (@typeInfo(SrcElem) == .Usize and @typeInfo(DstElem) == .Float) break :blk .UsizeToFloat;
    //     if (@typeInfo(SrcElem) == .Usize and @typeInfo(DstElem) == .Int) break :blk .UsizeToInt;
    //     if (@typeInfo(SrcElem) == .Int and @typeInfo(DstElem) == .Usize) break :blk .IntToUsize;
    //     if (@typeInfo(SrcElem) == .Float and @typeInfo(DstElem) == .Usize) break :blk .FloatToUsize;
    //     if (@typeInfo(SrcElem) == .Usize and @typeInfo(DstElem) == .Usize) break :blk .UsizeToUsize;
    //     break :blk .Unsupported;
    // };

    // inline for (0..@min(self_info.vector.len, target_info.vector.len)) |i| {
    //     result[i] = switch (kind) {
    //         .Same => self[i],
    //         .IntToFloat => @floatFromInt(self[i]),
    //         .IntToInt => @intCast(self[i]),
    //         .IntToUsize => @intCast(self[i]),
    //         .FloatToInt => @intFromFloat(self[i]),
    //         .FloatToFloat => @floatCast(self[i]),
    //         .FloatToUsize => @intFromFloat(self[i]),
    //         .UsizeToFloat => @floatFromInt(self[i]),
    //         .UsizeToInt => @intCast(self[i]),
    //         .UsizeToUsize => @intCast(self[i]),
    //         else => @compileError("Unsupported vector element type."),
    //     };
    // }

    inline for (0..@min(self_info.vector.len, target_info.vector.len)) |i| {
        result[i] = switch (self_info.vector.child) {
            i32 => @floatFromInt(self[i]),
            f32 => @intFromFloat(self[i]),
            else => @compileError("Unsupported vector element type."),
        };
    }
    return result;
}

/// Produces a new vector from the first `n` elements of the imput vector.
///
/// Out-of-bounds element indexes of `n` result in compile errors.
pub fn slice(self: anytype, comptime n: usize) @Vector(n, @typeInfo(@TypeOf(self)).vector.child) {
    const info = @typeInfo(@TypeOf(self));
    if (info != .vector) @compileError("slice() can only be used on vectors.");
    if (info.vector.len < n) @compileError("Amount cannot be greater than vector length.");
    var result: @Vector(n, @typeInfo(@TypeOf(self)).vector.child) = undefined;
    inline for (0..n) |i| result[i] = self[i];

    return result;
}

pub fn xy(self: anytype) @Vector(2, @typeInfo(@TypeOf(self)).vector.child) {
    const info = @typeInfo(@TypeOf(self));
    if (info != .vector) @compileError("xy() can only be used on vectors.");
    if (info.vector.len < 2) @compileError("Vector must have at least 2 elements.");
    return @shuffle(info.vector.child, self, undefined, [_]i32{ 0, 1 });
}

pub fn xyz(self: anytype) @Vector(3, @typeInfo(@TypeOf(self)).vector.child) {
    const info = @typeInfo(@TypeOf(self));
    if (info != .vector) @compileError("xyz() can only be used on vectors.");
    if (info.vector.len < 3) @compileError("Vector must have at least 3 elements.");
    return @shuffle(@typeInfo(@TypeOf(self)).vector.child, self, undefined, [_]i32{ 0, 1, 2 });
}

pub fn xyzw(self: anytype) @Vector(4, @typeInfo(@TypeOf(self)).vector.child) {
    const info = @typeInfo(@TypeOf(self));
    if (info != .vector) @compileError("xyzw() can only be used on vectors.");
    if (info.vector.len < 4) @compileError("Vector must have at least 4 elements.");

    return @shuffle(info.vector.child, self, undefined, [_]i32{ 0, 1, 2, 3 });
}

pub fn normalize(self: anytype) @TypeOf(self) {
    return self / @as(@TypeOf(self), @splat(length(self)));
}

pub fn length(self: anytype) @typeInfo(@TypeOf(self)).vector.child {
    return @sqrt(@reduce(.Add, self * self));
}

pub fn descale(self: anytype, scalar: @typeInfo(@TypeOf(self)).vector.child) @TypeOf(self) {
    return self / @as(@TypeOf(self), @splat(scalar));
}

pub fn mod(self: anytype, scalar: @typeInfo(@TypeOf(self)).vector.child) @TypeOf(self) {
    return @mod(self, @as(@TypeOf(self), @splat(scalar)));
}

pub fn scale(self: anytype, scalar: @typeInfo(@TypeOf(self)).vector.child) @TypeOf(self) {
    return self * @as(@TypeOf(self), @splat(scalar));
}

pub fn add(self: anytype, other: @TypeOf(self)) @TypeOf(self) {
    return self + other;
}

pub fn abs(self: anytype) @TypeOf(self) {
    return @abs(self);
}

pub fn sub(self: anytype, other: @TypeOf(self)) @TypeOf(self) {
    return self - other;
}

pub fn mul(self: anytype, other: @TypeOf(self)) @TypeOf(self) {
    return self * other;
}

pub fn dot(self: anytype, other: @TypeOf(self)) @typeInfo(@TypeOf(self)).vector.child {
    return @reduce(.Add, self * other);
}

pub fn addProduct(self: anytype, other: @TypeOf(self)) @typeInfo(@TypeOf(self)).vector.child {
    return @reduce(.Add, self + other);
}

pub fn crossProduct(a: anytype, b: @TypeOf(a)) @TypeOf(a) {
    const info = @typeInfo(@TypeOf(a));
    if (info.len != 3) @compileError("crossProduct only supports 3D vectors.");
    return @Vector(3, info.vector.child){
        a[1] * b[2] - a[2] * b[1], // x = (ay * bz - az * by)
        a[2] * b[0] - a[0] * b[2], // y = (az * bx - ax * bz)
        a[0] * b[1] - a[1] * b[0], // z = (ax * by - ay * bx)
    };
}

pub fn subProduct(self: anytype, other: @TypeOf(self)) @typeInfo(@TypeOf(self)).vector.child {
    return @reduce(.Add, self - other);
}

pub fn compare(a: anytype, b: @TypeOf(a)) bool {
    return @reduce(.And, a == b);
}

pub fn moveTowards(self: anytype, target: @TypeOf(self), step: @typeInfo(@TypeOf(self)).vector.child) @TypeOf(self) {
    const direction = target - self;
    const distanceSq = @reduce(.Add, direction * direction);
    const stepSq = step * step;

    if (distanceSq <= stepSq) return target;

    const len = @sqrt(distanceSq);
    const stepVec = @as(@TypeOf(self), @splat(step / len));
    return self + direction * stepVec;
}

pub fn descaleProduct(self: anytype, value: @typeInfo(@TypeOf(self)).vector.child) @typeInfo(@TypeOf(self)).vector.child {
    return @reduce(.Add, self / @as(@TypeOf(self), @splat(value)));
}

pub fn scaleProduct(self: anytype, value: @typeInfo(@TypeOf(self)).vector.child) @typeInfo(@TypeOf(self)).vector.child {
    return @reduce(.Add, self * @as(@TypeOf(self), @splat(value)));
}
