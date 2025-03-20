const std = @import("std");
const renderer = @import("renderer.zig");
const rl = @import("raylib");
const Context = @import("../Context.zig");
pub var shadowShader: rl.Shader = undefined;

pub fn setShadowColor(color: rl.Color) void {
    // light color
    const lightColorNormalized = rl.colorNormalize(color);
    const lightColLoc = rl.getShaderLocation(shadowShader, "lightColor");
    rl.setShaderValue(shadowShader, lightColLoc, &lightColorNormalized, .vec4);
}

var shadowMap: rl.RenderTexture2D = undefined;
var lightVPLoc: c_int = undefined;
var shadowMapLoc: c_int = undefined;
pub var lightCam: rl.Camera3D = undefined;

pub fn deinit() void {
    shadowMap.unload();
    shadowShader.deactivate();
}

pub fn init() void {
    shadowShader = rl.loadShader("res/shaders/vertShadowMap.glsl", "res/shaders/fragShadowMap.glsl") catch unreachable;
    // shadowShader.locs[ray.SHADER_LOC_VECTOR_VIEW] = rl.getShaderLocation(shadowShader, "viewPos");
    shadowShader.locs[@intFromEnum(rl.ShaderLocationIndex.vector_view)] = rl.getShaderLocation(shadowShader, "viewPos");

    lightVPLoc = rl.getShaderLocation(shadowShader, "lightVP");
    shadowMapLoc = rl.getShaderLocation(shadowShader, "shadowMap");
    const shadowMapResolution: c_int = 4096;
    rl.setShaderValue(shadowShader, rl.getShaderLocation(shadowShader, "shadowMapResolution"), &shadowMapResolution, .int);

    shadowMap = LoadShadowmapRenderTexture(shadowMapResolution, shadowMapResolution);
    lightCam = undefined;
    lightCam.position = rl.Vector3{ .x = 0, .y = 50, .z = 0 }; //ray.Vector3Scale(lightDir, -15.0);
    lightCam.target = lightCam.position;
    lightCam.target.z += 0.001;
    lightCam.target.y -= 15;
    lightCam.projection = rl.CameraProjection.orthographic;
    lightCam.up = rl.Vector3{ .x = 0.0, .y = 1.0, .z = 0.0 };
    lightCam.fovy = 170.0;

    // light direction
    var lightDir = rl.Vector3.normalize(rl.Vector3{ .x = lightCam.target.x - lightCam.position.x, .y = -1.0, .z = lightCam.target.z - lightCam.position.z });
    const lightDirLoc = rl.getShaderLocation(shadowShader, "lightDir");
    rl.setShaderValue(shadowShader, lightDirLoc, &lightDir, .vec3);

    // Default shadow color
    setShadowColor(rl.Color.white);
}

pub fn drawShadow(ctx: *Context) void {
    var lightDir = rl.Vector3.normalize(rl.Vector3{ .x = lightCam.target.x - lightCam.position.x, .y = -1.0, .z = lightCam.target.z - lightCam.position.z });
    const lightDirLoc = rl.getShaderLocation(shadowShader, "lightDir");
    rl.setShaderValue(shadowShader, lightDirLoc, &lightDir, .vec3);

    // rl.setShaderValue(shadowShader, shadowShader.locs[ray.SHADER_LOC_VECTOR_VIEW], &p.camera.position, .vec3);
    rl.setShaderValue(shadowShader, shadowShader.locs[@intFromEnum(rl.ShaderLocationIndex.vector_view)], &ctx.player.camera.position, .vec3);
    rl.beginTextureMode(shadowMap);
    rl.clearBackground(rl.Color.ray_white);
    //ray.rlSetCullFace(ray.RL_CULL_FACE_FRONT);

    rl.beginMode3D(lightCam);
    const lightView = rl.gl.rlGetMatrixModelview();
    const lightProj = rl.gl.rlGetMatrixProjection();
    try renderer.render3D(ctx);
    rl.endMode3D();
    rl.endTextureMode();
    //ray.rlSetCullFace(ray.RL_CULL_FACE_BACK);

    const lightViewProj = rl.Matrix.multiply(lightView, lightProj);

    rl.setShaderValueMatrix(shadowShader, lightVPLoc, lightViewProj);

    rl.gl.rlEnableShader(shadowShader.id);
    // rl.Shader.activate(shadowShader);
    const slot: c_int = 10;
    rl.gl.rlActiveTextureSlot(slot);
    rl.gl.rlEnableTexture(shadowMap.depth.id);

    // rl.gl.rlSetUniform(shadowMapLoc, &slot, ray.SHADER_UNIFORM_INT, 1);
    rl.gl.rlSetUniform(shadowMapLoc, &slot, @intFromEnum(rl.ShaderUniformDataType.int), 1);
}

fn LoadShadowmapRenderTexture(width: u32, height: u32) rl.RenderTexture2D {
    var target: rl.RenderTexture2D = undefined;

    target.id = rl.gl.rlLoadFramebuffer();
    target.texture.width = @intCast(width);
    target.texture.height = @intCast(height);

    if (target.id > 0) {
        rl.gl.rlEnableFramebuffer(target.id);

        target.depth.id = rl.gl.rlLoadTextureDepth(@intCast(width), @intCast(height), false);
        target.depth.width = @intCast(width);
        target.depth.height = @intCast(height);
        target.depth.format = .compressed_etc2_rgb; //DEPTH_COMPONENT_24BIT?
        target.depth.mipmaps = 1;

        // Attach depth texture to FBO
        // rl.gl.rlFramebufferAttach(target.id, target.depth.id, ray.RL_ATTACHMENT_DEPTH, ray.RL_ATTACHMENT_TEXTURE2D, 0);
        rl.gl.rlFramebufferAttach(target.id, target.depth.id, @intFromEnum(rl.gl.rlFramebufferAttachType.rl_attachment_depth), @intFromEnum(rl.gl.rlFramebufferAttachTextureType.rl_attachment_texture2d), 0);

        // Check if fbo is complete with attachments (valid)
        if (!rl.gl.rlFramebufferComplete(target.id)) {
            std.debug.print("SHADOWMAP FAIL \n", .{});
        }

        rl.gl.rlDisableFramebuffer();
    } else std.debug.print("SHADOWMAP FAIL \n", .{});

    return target;
}
