



pub fn SignExtend8To32(byte: u8) u32 {

    return @bitCast(@as(i32,@intCast(@as(i8, @bitCast(byte)))));

}

pub fn SignExtend16To32(byte: u16) u32 {

    return @bitCast(@as(i32,@intCast(@as(i16, @bitCast(byte)))));

}

