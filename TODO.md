* [X] DeltaTime from RayLib
* [X] Raylib-zig "rl.gl.rl_default_shader_attrib_location_indices"
* [ ] Placement of blocks
* [ ] Refactoring player movement
* [ ] Movement  
* [X] Refactor ActionBuffer (remove)
* [X] Fix camera panning
* [X] GetBlock middle mouse button for selected block
* [ ] Fix camera movements (feels like pos and cam distance gets greater)
* [X] Fix chunk gen lag:
    * [X] Fix chunk gen lag again
* [X] remove profiler
* [ ] Move utiliteis fn
* [X] Settings menu
* [X] Basic main menu (expand)
* [X] Refactor Map
* [X] Load block types from zig.zon
* [ ] Use block types
* [X] create chunks with allocator and store pointer
* [X] "Better" system for structures
* [ ] Leverage SIMD:
    * [X] Frustum
    * [ ] World
    * [ ] Player
* [ ] Use @atomicXXX:
    @atomicLoad(comptime T: type, ptr: *const T, comptime ordering: AtomicOrder)
    @atomicRmw(comptime T: type, ptr: *T, comptime op: AtomicRmwOp, operand: T, comptime ordering: AtomicOrder)
    @atomicStore(comptime T: type, ptr: *T, value: T, comptime ordering: AtomicOrder)