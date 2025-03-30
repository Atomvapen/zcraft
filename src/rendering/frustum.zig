const rl = @import("raylib");
const vec = @import("../math/vec.zig");
const map = @import("../map/world.zig");

const chunkSize = map.chunkSize;
const Vec4f = vec.Vec4f;
const Vec3f = vec.Vec3f;
const FrustumPlanes = enum { Back, Front, Bottom, Top, Right, Left, MAX };

fn extractFrustum(frustum: *[6]Vec4f) void {
    const projection = rl.gl.rlGetMatrixProjection();
    const modelview = rl.gl.rlGetMatrixModelview();

    var planes: rl.Matrix = undefined;

    planes.m0 = modelview.m0 * projection.m0 + modelview.m1 * projection.m4 + modelview.m2 * projection.m8 + modelview.m3 * projection.m12;
    planes.m1 = modelview.m0 * projection.m1 + modelview.m1 * projection.m5 + modelview.m2 * projection.m9 + modelview.m3 * projection.m13;
    planes.m2 = modelview.m0 * projection.m2 + modelview.m1 * projection.m6 + modelview.m2 * projection.m10 + modelview.m3 * projection.m14;
    planes.m3 = modelview.m0 * projection.m3 + modelview.m1 * projection.m7 + modelview.m2 * projection.m11 + modelview.m3 * projection.m15;
    planes.m4 = modelview.m4 * projection.m0 + modelview.m5 * projection.m4 + modelview.m6 * projection.m8 + modelview.m7 * projection.m12;
    planes.m5 = modelview.m4 * projection.m1 + modelview.m5 * projection.m5 + modelview.m6 * projection.m9 + modelview.m7 * projection.m13;
    planes.m6 = modelview.m4 * projection.m2 + modelview.m5 * projection.m6 + modelview.m6 * projection.m10 + modelview.m7 * projection.m14;
    planes.m7 = modelview.m4 * projection.m3 + modelview.m5 * projection.m7 + modelview.m6 * projection.m11 + modelview.m7 * projection.m15;
    planes.m8 = modelview.m8 * projection.m0 + modelview.m9 * projection.m4 + modelview.m10 * projection.m8 + modelview.m11 * projection.m12;
    planes.m9 = modelview.m8 * projection.m1 + modelview.m9 * projection.m5 + modelview.m10 * projection.m9 + modelview.m11 * projection.m13;
    planes.m10 = modelview.m8 * projection.m2 + modelview.m9 * projection.m6 + modelview.m10 * projection.m10 + modelview.m11 * projection.m14;
    planes.m11 = modelview.m8 * projection.m3 + modelview.m9 * projection.m7 + modelview.m10 * projection.m11 + modelview.m11 * projection.m15;
    planes.m12 = modelview.m12 * projection.m0 + modelview.m13 * projection.m4 + modelview.m14 * projection.m8 + modelview.m15 * projection.m12;
    planes.m13 = modelview.m12 * projection.m1 + modelview.m13 * projection.m5 + modelview.m14 * projection.m9 + modelview.m15 * projection.m13;
    planes.m14 = modelview.m12 * projection.m2 + modelview.m13 * projection.m6 + modelview.m14 * projection.m10 + modelview.m15 * projection.m14;
    planes.m15 = modelview.m12 * projection.m3 + modelview.m13 * projection.m7 + modelview.m14 * projection.m11 + modelview.m15 * projection.m15;

    frustum[@intFromEnum(FrustumPlanes.Right)] = .{ planes.m3 - planes.m0, planes.m7 - planes.m4, planes.m11 - planes.m8, planes.m15 - planes.m12 };
    frustum[@intFromEnum(FrustumPlanes.Right)] = vec.normalize(frustum[@intFromEnum(FrustumPlanes.Right)]);

    frustum[@intFromEnum(FrustumPlanes.Left)] = .{ planes.m3 + planes.m0, planes.m7 + planes.m4, planes.m11 + planes.m8, planes.m15 + planes.m12 };
    frustum[@intFromEnum(FrustumPlanes.Left)] = vec.normalize(frustum[@intFromEnum(FrustumPlanes.Left)]);

    frustum[@intFromEnum(FrustumPlanes.Top)] = .{ planes.m3 - planes.m1, planes.m7 - planes.m5, planes.m11 - planes.m9, planes.m15 - planes.m13 };
    frustum[@intFromEnum(FrustumPlanes.Top)] = vec.normalize(frustum[@intFromEnum(FrustumPlanes.Top)]);

    frustum[@intFromEnum(FrustumPlanes.Bottom)] = .{ planes.m3 + planes.m1, planes.m7 + planes.m5, planes.m11 + planes.m9, planes.m15 + planes.m13 };
    frustum[@intFromEnum(FrustumPlanes.Bottom)] = vec.normalize(frustum[@intFromEnum(FrustumPlanes.Bottom)]);

    frustum[@intFromEnum(FrustumPlanes.Back)] = .{ planes.m3 - planes.m2, planes.m7 - planes.m6, planes.m11 - planes.m10, planes.m15 - planes.m14 };
    frustum[@intFromEnum(FrustumPlanes.Back)] = vec.normalize(frustum[@intFromEnum(FrustumPlanes.Back)]);

    frustum[@intFromEnum(FrustumPlanes.Front)] = .{ planes.m3 + planes.m2, planes.m7 + planes.m6, planes.m11 + planes.m10, planes.m15 + planes.m14 };
    frustum[@intFromEnum(FrustumPlanes.Front)] = vec.normalize(frustum[@intFromEnum(FrustumPlanes.Front)]);
}

pub fn isChunkVisible(position: rl.Vector3) bool {
    const pos: Vec3f = .{ position.x, position.y, position.z };
    const offset: Vec3f = @splat(0.5);
    const chunk: Vec3f = @splat(chunkSize);
    const min: Vec3f = vec.sub(pos, offset);
    const max: Vec3f = vec.add(vec.add(min, chunk), offset);

    var planes: [6]Vec4f = undefined;
    extractFrustum(&planes);

    if (isAABBInside(planes, min, max)) return true;
    return isAABBCrossing(planes, min, max);
}

pub fn isAABBInside(frustum: [6]Vec4f, pos: Vec3f, dim: Vec3f) bool {
    inline for (frustum) |plane| {
        var dist = plane[0] * pos[0] + plane[1] * pos[1] + plane[2] * pos[2] + plane[3];
        const normDim: Vec3f = .{ dim[0] * @abs(plane[0]), dim[1] * @abs(plane[1]), dim[2] * @abs(plane[2]) };
        const vec0: Vec3f = @splat(0);
        dist += @reduce(.Add, @max(vec0, normDim));
        if (dist < 0) return false;
    }
    return true;
}

pub fn isAABBCrossing(frustum: [6]Vec4f, min: Vec3f, max: Vec3f) bool {
    inline for (frustum) |plane| {
        var dist = plane[0] * (min[0] + max[0]) * 0.5 + plane[1] * (min[1] + max[1]) * 0.5 + plane[2] * (min[2] + max[2]) * 0.5 + plane[3];
        const normDim: Vec3f = .{ (max[0] - min[0]) * @abs(plane[0]) * 0.5, (max[1] - min[1]) * @abs(plane[1]) * 0.5, (max[2] - min[2]) * @abs(plane[2]) * 0.5 };
        dist += @reduce(.Add, normDim);
        if (dist < 0) return false;
    }
    return true;
}
