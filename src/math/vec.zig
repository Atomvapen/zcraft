pub const Vec2i = @Vector(2, i32);
pub const Vec3i = @Vector(3, i32);
pub const Vec4i = @Vector(4, i32);

pub const Vec2f = @Vector(2, f32);
pub const Vec3f = @Vector(3, f32);
pub const Vec4f = @Vector(4, f32);

pub fn normalize(v: anytype) @TypeOf(v) {
    return v / @as(@TypeOf(v), @splat(length(v)));
}

pub fn length(v: anytype) @typeInfo(@TypeOf(v)).vector.child {
    return @sqrt(@reduce(.Add, v * v));
}

pub fn distance(a: anytype, b: @TypeOf(a)) @typeInfo(@TypeOf(a)).vector.child {
    const diff = a - b;
    return @sqrt(@reduce(.Add, diff * diff));
}

pub fn distanceSquared(a: anytype, b: @TypeOf(a)) @typeInfo(@TypeOf(a)).vector.child {
    const diff = a - b;
    return @reduce(.Add, diff * diff);
}

pub fn descale(v: anytype, scalar: @typeInfo(@TypeOf(v)).vector.child) @TypeOf(v) {
    return v / @as(@TypeOf(v), @splat(scalar));
}

pub fn reflect(v: anytype, n: @TypeOf(v)) @TypeOf(v) {
    const dotProduct = dot(v * n);
    return v - (n * (2 * dotProduct));
}

pub fn mod(v: anytype, scalar: @typeInfo(@TypeOf(v)).vector.child) @TypeOf(v) {
    return @mod(v, @as(@TypeOf(v), @splat(scalar)));
}

pub fn scale(v: anytype, scalar: @typeInfo(@TypeOf(v)).vector.child) @TypeOf(v) {
    return v * @as(@TypeOf(v), @splat(scalar));
}

pub fn invert(v: anytype) @TypeOf(v) {
    return v * @as(@TypeOf(v), @splat(-1));
}

pub fn negate(v: anytype) @TypeOf(v) {
    return -v;
}

pub fn max(a: anytype, b: @TypeOf(a)) @TypeOf(a) {
    return @max(a, b);
}

pub fn min(a: anytype, b: @TypeOf(a)) @TypeOf(a) {
    return @min(a, b);
}

pub fn add(a: anytype, b: @TypeOf(a)) @TypeOf(a) {
    return a + b;
}

pub fn abs(v: anytype) @TypeOf(v) {
    return @abs(v);
}

pub fn sub(a: anytype, b: @TypeOf(a)) @TypeOf(a) {
    return a - b;
}

pub fn mul(a: anytype, b: @TypeOf(a)) @TypeOf(a) {
    return a * b;
}

pub fn div(a: anytype, b: @TypeOf(a)) @TypeOf(a) {
    return a / b;
}

pub fn dot(a: anytype, b: @TypeOf(a)) @typeInfo(@TypeOf(a)).vector.child {
    return @reduce(.Add, a * b);
}

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
            Vec3f => result = @Vector(3, f32){ @floatCast(self.x), @floatCast(self.y), @floatCast(self.z) },
            else => @compileError("Unsupported conversion."),
        },
        Vec3f => result = rl.Vector3{ .x = @floatCast(self[0]), .y = @floatCast(self[1]), .z = @floatCast(self[2]) },
        Vec3i => result = rl.Vector3{ .x = @floatFromInt(self[0]), .y = @floatFromInt(self[1]), .z = @floatFromInt(self[2]) },
        else => @compileError("Unsupported conversion."),
    }
    return result;
}

/// Produces a new vector from the first `n` elements of the imput vector.
///
/// Out-of-bounds element indexes of `n` result in compile errors.
pub fn slice(v: anytype, comptime n: usize) @Vector(n, @typeInfo(@TypeOf(v)).vector.child) {
    const info = @typeInfo(@TypeOf(v));
    if (info != .vector) @compileError("slice() can only be used on vectors.");
    if (info.vector.len < n) @compileError("Amount cannot be greater than vector length.");
    var result: @Vector(n, @typeInfo(@TypeOf(v)).vector.child) = undefined;
    inline for (0..n) |i| result[i] = v[i];
    return result;
}

pub fn rotate2D(v: anytype, angle: f32) @TypeOf(v) {
    const info = @typeInfo(@TypeOf(v));
    if (info != .vector) @compileError("rotate2D() can only be used on vectors.");
    if (info.vector.len == 3) @compileError("Vector must have 2 elements.");

    const cosTheta = @cos(angle);
    const sinTheta = @sin(angle);

    return .{
        v[0] * cosTheta - v[1] * sinTheta, // x′ = x * cos(θ) − y * sin(θ)
        v[0] * sinTheta + v[1] * cosTheta, // y' = x * sin(θ) + y * cos(θ)
    };
}

/// Returns the `.x` component of a vector.
///
/// Supports any vector with at least 1 component.
pub fn x(v: anytype) @typeInfo(@TypeOf(v)).vector.child {
    const info = @typeInfo(@TypeOf(v));
    if (info != .vector) @compileError("x() can only be used on vectors.");
    if (info.vector.len < 1) @compileError("Vector must have at least 1 element.");
    return v[0];
}

/// Returns the `.y` component of a vector.
///
/// Supports any vector with at least 2 components.
pub fn y(v: anytype) @typeInfo(@TypeOf(v)).vector.child {
    const info = @typeInfo(@TypeOf(v));
    if (info != .vector) @compileError("y() can only be used on vectors.");
    if (info.vector.len < 2) @compileError("Vector must have at least 2 element.");
    return v[1];
}

/// Returns the `.z` component of a vector.
///
/// Supports any vector with at least 3 components.
pub fn z(v: anytype) @typeInfo(@TypeOf(v)).vector.child {
    const info = @typeInfo(@TypeOf(v));
    if (info != .vector) @compileError("z() can only be used on vectors.");
    if (info.vector.len < 3) @compileError("Vector must have at least 3 element.");
    return v[2];
}

/// Returns the `.w` component of a vector.
///
/// Supports any vector with at least 4 components.
pub fn w(v: anytype) @typeInfo(@TypeOf(v)).vector.child {
    const info = @typeInfo(@TypeOf(v));
    if (info != .vector) @compileError("w() can only be used on vectors.");
    if (info.vector.len < 4) @compileError("Vector must have at least 4 element.");
    return v[3];
}

/// Returns a new vector containing the `.x` and `.y` components of the input.
///
/// Works with any vector that has at least 2 components.
pub fn xy(v: anytype) @Vector(2, @typeInfo(@TypeOf(v)).vector.child) {
    const info = @typeInfo(@TypeOf(v));
    if (info != .vector) @compileError("xy() can only be used on vectors.");
    if (info.vector.len < 2) @compileError("Vector must have at least 2 elements.");
    return @shuffle(info.vector.child, v, undefined, [_]i32{ 0, 1 });
}

/// Returns a new vector containing the `.x`, `.y`, and `.z` components of the input.
///
/// Works with any vector that has at least 3 components.
pub fn xyz(v: anytype) @Vector(3, @typeInfo(@TypeOf(v)).vector.child) {
    const info = @typeInfo(@TypeOf(v));
    if (info != .vector) @compileError("xyz() can only be used on vectors.");
    if (info.vector.len < 3) @compileError("Vector must have at least 3 elements.");
    return @shuffle(@typeInfo(@TypeOf(v)).vector.child, v, undefined, [_]i32{ 0, 1, 2 });
}

/// Returns a new vector containing the `.x`, `.y`, `.z`, and `.w` components of the input.
///
/// Works with any vector that has at least 4 components.
pub fn xyzw(v: anytype) @Vector(4, @typeInfo(@TypeOf(v)).vector.child) {
    const info = @typeInfo(@TypeOf(v));
    if (info != .vector) @compileError("xyzw() can only be used on vectors.");
    if (info.vector.len < 4) @compileError("Vector must have at least 4 elements.");
    return @shuffle(info.vector.child, v, undefined, [_]i32{ 0, 1, 2, 3 });
}

/// Reorders the components of a vector based on a given mask.
///
/// The mask is an array of indices that specifies how to reorder the vector components.
pub fn shuffle(v: anytype, mask: []i32) @Vector(mask.len, @typeInfo(@TypeOf(v)).vector.child) {
    const info = @typeInfo(@TypeOf(v));
    if (info != .vector) @compileError("shuffle() can only be used on vectors.");
    if (info.vector.len < mask.len) @compileError("Mask length cannot exceed vector length.");
    return @shuffle(info.vector.child, v, undefined, mask);
}

/// Computes the cross product of two 3D vectors.
///
/// The result is a vector that is perpendicular to both `a` and `b`.
/// Only 3D vectors are supported.
pub fn cross(a: anytype, b: @TypeOf(a)) @TypeOf(a) {
    const info = @typeInfo(@TypeOf(a));
    if (info != .vector) @compileError("crossProduct() can only be used on vectors.");
    if (info.vector.len != 3) @compileError("crossProduct only supports 3D vectors.");
    return @Vector(3, info.vector.child){
        a[1] * b[2] - a[2] * b[1], // x = (ay * bz - az * by)
        a[2] * b[0] - a[0] * b[2], // y = (az * bx - ax * bz)
        a[0] * b[1] - a[1] * b[0], // z = (ax * by - ay * bx)
    };
}

/// Returns true if all components of `a` and `b` are equal.
pub fn equal(a: anytype, b: @TypeOf(a)) bool {
    const info = @typeInfo(@TypeOf(a));
    if (info != .vector) @compileError("equal() can only be used on vectors.");
    return @reduce(.And, a == b);
}

/// Clamps each component of vector `v` between the scalar values `min_v` and `max_v`.
///
/// The same scalar `min_v` and `max_v` are applied to all components of `v`.
pub fn clampComponents(v: anytype, min_v: f32, max_v: f32) @TypeOf(v) {
    const info = @typeInfo(@TypeOf(v));
    if (info != .vector) @compileError("clampComponents() can only be used on vectors.");
    var result: @TypeOf(v) = undefined;
    for (0..info.vector.len) |i| result[i] = @max(min_v, @min(v[i], max_v));
    return result;
}

/// Clamps each component of vector `v` between the corresponding components
/// of vectors `min_v` and `max_v`.
pub fn clamp(v: anytype, min_v: @TypeOf(v), max_v: @TypeOf(v)) @TypeOf(v) {
    const info = @typeInfo(@TypeOf(v));
    if (info != .vector) @compileError("clamp() can only be used on vectors.");
    return @max(min_v, @min(v, max_v));
}

/// Moves vector `start` towards vector `end` by a maximum distance of `step`.
pub fn moveTowards(start: anytype, end: @TypeOf(start), step: @typeInfo(@TypeOf(start)).vector.child) @TypeOf(start) {
    const info = @typeInfo(@TypeOf(start));
    if (info != .vector) @compileError("moveTowards() can only be used on vectors.");
    const direction = end - start;
    const distanceSq = @reduce(.Add, direction * direction);
    const stepSq = step * step;

    if (distanceSq <= stepSq) return end;

    const len = @sqrt(distanceSq);
    const stepVec = @as(@TypeOf(start), @splat(step / len));
    return start + direction * stepVec;
}

/// Linearly interpolates between `start` and `end` by the factor `t`.
/// `t` should be in the range `0..1`.
pub fn lerp(start: anytype, end: @TypeOf(start), t: @typeInfo(@TypeOf(start)).vector.child) @TypeOf(start) {
    const info = @typeInfo(@TypeOf(start));
    if (info != .vector) @compileError("lerp() can only be used on vectors.");
    return start + (end - start) * t;
}
