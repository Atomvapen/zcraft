const rows: i32 = 10;
const columns: i32 = 12;

items: [rows][columns]u8 = undefined,

const Command = enum(8) {
    open = 0,
    close,
    deposit,
    drop = 5,
    clear = 8,
};

const Slot = struct {
    // content: Content,
    slot: u32,
};

pub fn contains(b: u8) bool {
    _ = b;
    return true;
}
