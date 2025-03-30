pub const Vec2i = @Vector(2, i32);
pub const Vec3i = @Vector(3, i32);
pub const Vec4i = @Vector(4, i32);

pub const Vec2f = @Vector(2, f32);
pub const Vec3f = @Vector(3, f32);
pub const Vec4f = @Vector(4, f32);

pub fn elementType(self: anytype) type {
    const info = @typeInfo(@TypeOf(self));
    if (info != .vector) @compileError("elementType() can only be used on vectors.");
    return info.vector.child;
}

pub fn size(self: anytype) i32 {
    const info = @typeInfo(@TypeOf(self));
    if (info != .vector) @compileError("size() can only be used on vectors.");
    return info.vector.len;
}

/// Produces a new vector from of type `target`.
///
/// Non-same vector length result in compile errors. Non-valid type conversion result in compile errors.
///
/// Supports conversions are between `i32` and `f32`.
pub fn transform(self: anytype, target: type) target {
    const info = @typeInfo(@TypeOf(self));
    if (info != .vector) @compileError("transform() can only be used on vectors.");
    if (info.vector.len != @typeInfo(target).vector.len) @compileError("Vectors must have the same length.");
    if (@TypeOf(self) == target) return self; // @compileError("Cannot transform to the same type."); /// - Triggers `@compileError("Cannot transform to the same type.")` if `self` and `target` are the same type.

    const ChildType: type = info.vector.child;
    const vector_length: i32 = info.vector.len;
    var result: target = undefined;
    inline for (0..vector_length) |i| {
        result[i] = switch (ChildType) {
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
pub fn extract(self: anytype, n: usize) @Vector(n, @typeInfo(@TypeOf(self)).vector.child) {
    const info = @typeInfo(@TypeOf(self));
    if (info != .vector) @compileError("extract() can only be used on vectors.");
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

pub fn scale(self: anytype, scalar: @typeInfo(@TypeOf(self)).vector.child) @TypeOf(self) {
    return self * @as(@TypeOf(self), @splat(scalar));
}

pub fn add(self: anytype, other: @TypeOf(self)) @TypeOf(self) {
    return self + other;
}

pub fn sub(self: anytype, other: @TypeOf(self)) @TypeOf(self) {
    return self - other;
}

pub fn mul(self: anytype, other: @TypeOf(self)) @TypeOf(self) {
    return self * other;
}

pub fn dotProduct(self: anytype, other: @TypeOf(self)) @typeInfo(@TypeOf(self)).vector.child {
    return @reduce(.Add, self * other);
}

pub fn addProduct(self: anytype, other: @TypeOf(self)) @typeInfo(@TypeOf(self)).vector.child {
    return @reduce(.Add, self + other);
}

pub fn subProduct(self: anytype, other: @TypeOf(self)) @typeInfo(@TypeOf(self)).vector.child {
    return @reduce(.Add, self - other);
}

// pub fn descaleProduct(self: anytype, value: @typeInfo(@TypeOf(self)).vector.child) @typeInfo(@TypeOf(self)).vector.child {
//     return @reduce(.Add, self / @as(@TypeOf(self), @splat(value)));
// }

// pub fn scaleProduct(self: anytype, value: @typeInfo(@TypeOf(self)).vector.child) @typeInfo(@TypeOf(self)).vector.child {
//     return @reduce(.Add, self * @as(@TypeOf(self), @splat(value)));
// }

// pub fn crossProduct(a: anytype, b: @TypeOf(a)) !@TypeOf(a) {
//     const ChildType = @typeInfo(@TypeOf(a)).vector.child;
//     const vector_length = @typeInfo(@TypeOf(a)).vector.len;

//     if (vector_length != 3) return error.InvalidVectorLength;

//     // Create shuffle indices based on vector length
//     const a_yzx = @shuffle(ChildType, a, a, [_]i32{ 1, 2, 0 }); // (Ay, Az, Ax)
//     const b_yzx = @shuffle(ChildType, b, b, [_]i32{ 1, 2, 0 }); // (By, Bz, Bx)

//     const a_zxy = @shuffle(ChildType, a, a, [_]i32{ 2, 0, 1 }); // (Az, Ax, Ay)
//     const b_zxy = @shuffle(ChildType, b, b, [_]i32{ 2, 0, 1 }); // (Bz, Bx, By)

//     // Perform element-wise multiplication and subtraction for any vector type
//     return a_yzx * b_zxy - a_zxy * b_yzx;
// }
