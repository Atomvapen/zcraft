const std = @import("std");
const renderer = @import("renderer.zig");
const rl = @import("raylib");
const Context = @import("../Context.zig");
pub var shadowShader: rl.Shader = undefined;

pub fn setShadowColor(color: rl.Color) void {
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
    rl.unloadShader(shadowShader);
}

pub fn init() void {
    shadowShader = rl.loadShader("res/shaders/vertShadowMap.glsl", "res/shaders/fragShadowMap.glsl") catch unreachable;
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

pub fn drawShadow(ctx: *Context) !void {
    var lightDir = rl.Vector3.normalize(rl.Vector3{ .x = lightCam.target.x - lightCam.position.x, .y = -1.0, .z = lightCam.target.z - lightCam.position.z });
    const lightDirLoc = rl.getShaderLocation(shadowShader, "lightDir");
    rl.setShaderValue(shadowShader, lightDirLoc, &lightDir, .vec3);
    rl.setShaderValue(shadowShader, shadowShader.locs[@intFromEnum(rl.ShaderLocationIndex.vector_view)], &ctx.player.camera.position, .vec3);

    // Start rendering to shadow map texture
    rl.beginTextureMode(shadowMap);
    rl.clearBackground(rl.Color.ray_white); // Clear depth buffer

    // Set culling mode to render front-facing polygons for the shadow map
    rl.gl.rlSetCullFace(@intFromEnum(rl.gl.rlCullMode.rl_cull_face_front)); // Cull back faces

    rl.beginMode3D(lightCam); // Begin 3D mode with the light's camera
    const lightView = rl.gl.rlGetMatrixModelview(); // Get the light view matrix
    const lightProj = rl.gl.rlGetMatrixProjection(); // Get the light projection matrix

    // Render the world geometry in depth-only mode
    try renderer.renderWorld(ctx);

    rl.endMode3D(); // End 3D rendering
    rl.endTextureMode(); // End render to shadow map

    // Reset culling mode back to default (rendering back faces)
    rl.gl.rlSetCullFace(@intFromEnum(rl.gl.rlCullMode.rl_cull_face_back));

    // Set the view-projection matrix to the shader for shadow calculation
    const lightViewProj = rl.Matrix.multiply(lightView, lightProj);
    rl.setShaderValueMatrix(shadowShader, lightVPLoc, lightViewProj);

    // Enable the shadow shader and bind the shadow map texture
    rl.gl.rlEnableShader(shadowShader.id);
    const slot: c_int = 10;
    rl.gl.rlActiveTextureSlot(slot);
    rl.gl.rlEnableTexture(shadowMap.depth.id);
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
        target.depth.format = .uncompressed_r32; //DEPTH_COMPONENT_24BIT?
        target.depth.mipmaps = 1;

        // Attach depth texture to FBO
        rl.gl.rlFramebufferAttach(target.id, target.depth.id, @intFromEnum(rl.gl.rlFramebufferAttachType.rl_attachment_depth), @intFromEnum(rl.gl.rlFramebufferAttachTextureType.rl_attachment_texture2d), 0);

        // Check if fbo is complete with attachments (valid)
        if (!rl.gl.rlFramebufferComplete(target.id)) {
            std.debug.print("SHADOWMAP FAIL \n", .{});
        }

        rl.gl.rlDisableFramebuffer();
    } else std.debug.print("SHADOWMAP FAIL \n", .{});

    return target;
}
