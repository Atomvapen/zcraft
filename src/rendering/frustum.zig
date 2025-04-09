const rl = @import("raylib");
const vec = @import("../math/vec.zig");
const map = @import("../map/world.zig");

const chunkSize = map.chunkSize;
const Vec4f = vec.Vec4f;
const Vec3f = vec.Vec3f;
const Vec3i = vec.Vec3i;

const Frustum = struct {
    const Planes = enum { Far, Near, Bottom, Top, Right, Left };

    planes: [6]Vec4f,

    pub fn extract(viewProj: rl.Matrix) Frustum {
        const r0: Vec4f = .{ viewProj.m0, viewProj.m4, viewProj.m8, viewProj.m12 };
        const r1: Vec4f = .{ viewProj.m1, viewProj.m5, viewProj.m9, viewProj.m13 };
        const r2: Vec4f = .{ viewProj.m2, viewProj.m6, viewProj.m10, viewProj.m14 };
        const r3: Vec4f = .{ viewProj.m3, viewProj.m7, viewProj.m11, viewProj.m15 };

        var self: Frustum = undefined;
        self.planes[@intFromEnum(Planes.Right)] = vec.normalize(r3 - r0);
        self.planes[@intFromEnum(Planes.Left)] = vec.normalize(r3 + r0);
        self.planes[@intFromEnum(Planes.Top)] = vec.normalize(r3 - r1);
        self.planes[@intFromEnum(Planes.Bottom)] = vec.normalize(r3 + r1);
        self.planes[@intFromEnum(Planes.Far)] = vec.normalize(r3 - r2);
        self.planes[@intFromEnum(Planes.Near)] = vec.normalize(r3 + r2);
        return self;
    }

    pub fn isAABBInside(self: *const Frustum, pos: Vec3f, dim: Vec3f) bool {
        const half: Vec3f = @splat(0.5);
        inline for (self.planes) |plane| {
            const normal: Vec3f = @shuffle(f32, plane, undefined, [_]i32{ 0, 1, 2 });
            const plane_offset = plane[3];
            var dist = @reduce(.Add, normal * pos);
            dist += @reduce(.Add, @abs(normal) * dim * half);
            if (dist + plane_offset < 0) return false;
        }
        return true;
    }

    pub fn isAABBCrossing(self: *const Frustum, min: Vec3f, max: Vec3f) bool {
        const half: Vec3f = @splat(0.5);
        const center = (min + max) * half;
        const extent = (max - min) * half;
        inline for (self.planes) |plane| {
            const normal: Vec3f = @shuffle(f32, plane, undefined, [_]i32{ 0, 1, 2 });
            const plane_offset = plane[3];
            var dist = @reduce(.Add, normal * center) + plane_offset;
            dist += @reduce(.Add, extent * @abs(normal));
            if (dist < 0) return false;
        }
        return true;
    }
};

pub fn isChunkVisible(pos: Vec3i) bool {
    const offset: Vec3f = @splat(0.5);
    const chunk: Vec3f = @splat(chunkSize);
    const min: Vec3f = vec.sub(vec.transform(pos, Vec3f), offset);
    const max: Vec3f = vec.add(min, chunk + offset);
    const projection: rl.Matrix = rl.gl.rlGetMatrixProjection();
    const modelview: rl.Matrix = rl.gl.rlGetMatrixModelview();
    const viewProj: rl.Matrix = rl.Matrix.multiply(modelview, projection);

    const frustum: Frustum = Frustum.extract(viewProj);
    if (frustum.isAABBInside(min, max)) return true;
    return frustum.isAABBCrossing(min, max);
}
