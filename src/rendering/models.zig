const std = @import("std");
const util = @import("../rendering/utilities.zig");
const shader = @import("shader.zig");

const rl = @import("raylib");

pub fn setTexture(model: rl.Model, tex: rl.Texture) void {
    model.materials[0].maps[@intFromEnum(rl.MaterialMapIndex.albedo)].texture = tex;
}

pub fn setShadowShader(model: rl.Model) void {
    model.materials[0].shader = shader.shadowShader;
}

pub fn unloadMesh(mesh: rl.Mesh) void {
    //const mesh = self.Model.?.meshes.*;
    const vc: f64 = @floatFromInt(mesh.vertexCount);

    util.allocator.free(mesh.indices[0..@intFromFloat(vc * 1.5)]);
    //util.allocator.free(mesh.texcoords[0..@intFromFloat(vc * 2)]);
    //util.allocator.free(mesh.texcoords[0..@intFromFloat(vc * 2)]);

    rl.gl.rlUnloadVertexArray(@intCast(mesh.vaoId));
    // rl.unloadMesh(mesh);

    for (0..7) |i| {
        // rl.gl.rlUnloadVertexBuffer(mesh.vboId[@intCast(i)]);
        rl.gl.rlUnloadVertexBuffer(@intCast(mesh.vboId[@intCast(i)]));
    }
}

pub fn UploadMesh(mesh: *rl.Mesh, verts: [*]u32) !void {
    if (mesh.vaoId > 0) {
        // Check if mesh has already been loaded in GPU
        std.debug.print("VAO: [ID {}] Trying to re-load an already loaded mesh \n", .{mesh.vaoId});
        return;
    }
    const vboid = try util.allocator.alloc(u32, 9);
    // mesh.vboId = vboid.ptr;
    mesh.vboId = @as([*c]c_int, @ptrCast(vboid.ptr));

    mesh.vaoId = 0; // Vertex Array Object
    mesh.vboId[rl.gl.rl_default_shader_attrib_location_position] = 0; // Vertex buffer: positions RL_DEFAULT_SHADER_ATTRIB_LOCATION_POSITION
    mesh.vboId[rl.gl.rl_default_shader_attrib_location_texcoord] = 0; // Vertex buffer: texcoords
    mesh.vboId[rl.gl.rl_default_shader_attrib_location_normal] = 0; // Vertex buffer: normals
    mesh.vboId[rl.gl.rl_default_shader_attrib_location_color] = 0; // Vertex buffer: colors
    mesh.vboId[rl.gl.rl_default_shader_attrib_location_tangent] = 0; // Vertex buffer: tangents
    mesh.vboId[rl.gl.rl_default_shader_attrib_location_texcoord2] = 0; // Vertex buffer: texcoords2
    mesh.vboId[rl.gl.rl_default_shader_attrib_location_indices] = 0; // Vertex buffer: indices

    mesh.vaoId = @intCast(rl.gl.rlLoadVertexArray());
    _ = rl.gl.rlEnableVertexArray(@intCast(mesh.vaoId));

    // NOTE: Vertex attributes must be uploaded considering default locations points and available vertex data

    // Enable vertex attributes: position (shader-location = 0)
    //const vertices = mesh.vertices;
    //rayRL.gl.rlSetVertexAttributeI();
    // mesh.vboId[rl.gl.rl_default_shader_attrib_location_position] = rl.gl.rlLoadVertexBuffer(verts, mesh.vertexCount * 1 * @sizeOf(u32), false);
    mesh.vboId[rl.gl.rl_default_shader_attrib_location_position] = @intCast(rl.gl.rlLoadVertexBuffer(verts, mesh.vertexCount * 1 * @sizeOf(u32), false));
    // rl.gl.rlSetVertexAttributeI(rl.gl.rl_default_shader_attrib_location_position, 1, 0x1405, 0, 0);
    rl.gl.rlSetVertexAttribute(rl.gl.rl_default_shader_attrib_location_position, 1, @as(i32, 0x1406), false, 0, 0);
    rl.gl.rlEnableVertexAttribute(rl.gl.rl_default_shader_attrib_location_position);

    // Enable vertex attributes: texcoords (shader-location = 1)
    //    mesh.vboId[ray.RL_DEFAULT_SHADER_ATTRIB_LOCATION_TEXCOORD] = ray.rlLoadVertexBuffer(tex, mesh.vertexCount*2*@sizeOf(f32), false);
    //    ray.rlSetVertexAttribute(ray.RL_DEFAULT_SHADER_ATTRIB_LOCATION_TEXCOORD, 2, ray.RL_FLOAT, false, 0, 0);
    //    ray.rlEnableVertexAttribute(ray.RL_DEFAULT_SHADER_ATTRIB_LOCATION_TEXCOORD);

    // WARNING: When setting default vertex attribute values, the values for each generic vertex attribute
    // is part of current state, and it is maintained even if a different program object is used

    // Default vertex attribute: normal
    // WARNING: Default value provided to shader if location available
    {
        const value = [_]f32{ 1.0, 1.0, 1.0 };
        rl.gl.rlSetVertexAttributeDefault(rl.gl.rl_default_shader_attrib_location_normal, &value, @intFromEnum(rl.ShaderAttribute.vec3), 3);
        rl.gl.rlDisableVertexAttribute(rl.gl.rl_default_shader_attrib_location_normal);
    }

    // Default vertex attribute: color
    // WARNING: Default value provided to shader if location available
    {
        const value = [_]f32{ 1.0, 1.0, 1.0, 1.0 }; // WHITE
        rl.gl.rlSetVertexAttributeDefault(rl.gl.rl_default_shader_attrib_location_color, &value, @intFromEnum(rl.ShaderAttribute.vec4), 4);
        rl.gl.rlDisableVertexAttribute(rl.gl.rl_default_shader_attrib_location_color);
    }

    // Default vertex attribute: tangent
    // WARNING: Default value provided to shader if location available
    {
        const value = [_]f32{ 0.0, 0.0, 0.0, 0.0 };
        rl.gl.rlSetVertexAttributeDefault(rl.gl.rl_default_shader_attrib_location_tangent, &value, @intFromEnum(rl.ShaderAttribute.vec4), 4);
        rl.gl.rlDisableVertexAttribute(rl.gl.rl_default_shader_attrib_location_tangent);
    }

    // Default vertex attribute: texcoord2
    // WARNING: Default value provided to shader if location available
    {
        const value = [_]f32{ 0.0, 0.0 };
        rl.gl.rlSetVertexAttributeDefault(rl.gl.rl_default_shader_attrib_location_texcoord2, &value, @intFromEnum(rl.ShaderAttribute.vec2), 2);
        rl.gl.rlDisableVertexAttribute(rl.gl.rl_default_shader_attrib_location_texcoord2);
    }

    mesh.vboId[rl.gl.rl_default_shader_attrib_location_indices] = @intCast(rl.gl.rlLoadVertexBufferElement(mesh.indices, mesh.triangleCount * 3 * @sizeOf(u16), false));

    if (mesh.vaoId > 0) {
        std.debug.print("INFO: VAO: [ID {}] Mesh uploaded successfully to VRAM (GPU) \n", .{mesh.vaoId});
    } else std.debug.print("VBO: Mesh uploaded successfully to VRAM (GPU) \n", .{});

    rl.gl.rlDisableVertexArray();
}
