

const types = @import("../utils/types.zig");
const Exceptions = types.Exceptions;
const opcodes = @import("opcodes.zig");


const PRId = packed struct (u32) {
    Rev: u8,
    Imp: u8,
    reserved: u16
};

const SR = packed struct (u32) {
    IEc: bool,
    KUc: bool,
    IEp: bool,
    KUp: bool,
    IEo: bool,
    Kuo: bool,
    pad0 : u2,
    IM: u8,
    IsC: bool,
    SwC: bool,
    PZ: bool,
    CM: bool,
    PE: bool,
    TS: bool,
    BEV: bool,
    pad1 : u2,
    RE: bool,
    pad2: u2,
    CU0: bool,
    CU1: bool,
    CU2: bool,
    CU3: bool
};

const Cause = packed struct (u32) {
    pad0: u2,
    ExcCode: u5,
    pad2: u1,
    IP: u8,
    pad3: u12,
    CE: u2,
    pad4: u1,
    BD: bool
};


const load_delay_buffer = struct {
    reg_buffer: [2]u5 = [2](u5){0,0},
    value_buffer: [2]u32 = [2](u32){0,0},
    head_pointer: usize = 0,
    tail_pointer: usize = 0,
    size: usize = 0,


    pub fn push(self: *load_delay_buffer, reg: u5, value: u32) void {
        self.reg_buffer[self.head_pointer] = reg;
        self.value_buffer[self.head_pointer] = value;
        self.size += 1;
        self.head_pointer = (self.head_pointer + 1) % 2;
        self.size += 1;

    }

    pub fn pop(self: *load_delay_buffer) struct {u5, u32} {
        const res = .{
            self.reg_buffer[self.tail_pointer],
            self.value_buffer[self.tail_pointer]
        };
        self.tail_pointer = (self.tail_pointer + 1) % 2;
        self.size -= 1;
        return res;
    }

    pub fn is_empty(self: *load_delay_buffer) bool {
        return self.size == 0;
    }



};

const LSI3000A = struct {
    general_registers: [32]u32 = [32]u32{0},
    reg_delay_buffer: load_delay_buffer = .{},
    PC: u32 = 0xbfc00000,
    Hi: u32,
    Lo: u32,
    branch_called: bool = false,
    branch_address: u32,

    // CP0 registers
    PRid_Reg: PRId,
    SR_Reg: SR,
    Cause_Reg: Cause,
    EPC_Reg: u32,
    BadVaddr_Reg: u32,

    pub fn ReadRegister(self: *LSI3000A, register: u5) u32 {
        return self.general_registers[register];

    }

    pub fn WriteRegister(self: *LSI3000A, register: u5, value: u32) void {
        if (register == 0) return;
        self.general_registers[register] = value;
    }

    pub fn LoadDelayRegister(self: *LSI3000A, register: u5, value: u32) void {
        self.reg_delay_buffer.push(register, value);
    }

    pub fn BusWrite8(self: *LSI3000A, address: u32, value: u32) void {
        _ = value;
        _= address;
        _ = self;
    }

    pub fn BusRead8(self: *LSI3000A, address: u32) u32 {
        _ = address;
        _ = self;
    }

    pub fn BusWrite16(self: *LSI3000A, address: u32, value: u32) void {
        _ = value;
        _= address;
        _ = self;
    }

    pub fn BusRead16(self: *LSI3000A, address: u32) u32 {
        _ = address;
        _ = self;
    }

    pub fn BusWrite32(self: *LSI3000A, address: u32, value: u32) void {
        _ = value;
        _= address;
        _ = self;
    }

    pub fn BusRead32(self: *LSI3000A, address: u32) u32 {
        _ = address;
        _ = self;
    }



    pub fn Branch(self: *LSI3000A, address: u32) void {
        self.branch_called = true;
        self.branch_address = address;
    }

    pub fn ReadCP0(self: *LSI3000A, register: u5) u32 {
        // TODO Complete
        _ = register;
        return self.cp0_register[u5];
    }

    pub fn WriteCP0(self: *LSI3000A, register: u5, value: u32) void {
        // TODO Complete
        self.cp0_register[register] = value;
    }
    pub fn WriteCoprocessorControlReg(self: *LSI3000A, coprocessor: u2, register: u5, value: u32) void {
        _ = self;
        _ = coprocessor;
        _ = register;
        _ = value;
        // TODO: Complete
}

    pub fn ReadCoprocessorControlReg(self: *LSI3000A, coprocessor: u2, register: u5) u32 {
        _ = self;
        _ = coprocessor;
        _ = register;
        // TODO: Complete
    return 0;
    }

    pub fn CoprocessorOperation(self: *LSI3000A, coprocessor: u2, co_fun: u25) void {
        _ = self;
        _ = coprocessor;
        _ = co_fun;
        // TODO: Complete
}

    pub fn WriteCoprocessorGenReg(self: *LSI3000A, coprocessor: u2, register: u5, value: u32) void {
        _ = self;
        _ = coprocessor;
        _ = register;
        _ = value;
        // TODO: Complete
}

    pub fn ReadCoprocessorGenReg(self: *LSI3000A, coprocessor: u2, register: u5) u32 {
        _ = self;
        _ = coprocessor;
        _ = register;
        // TODO: Complete
    return 0;
    }

    pub fn LoadDelayCopGenReg(self: *LSI3000A, coprocessor: u2, register: u5, value: u32) void {
        _ = self;
        _ = coprocessor;
        _ = register;
        _ = value;
        // TODO: Complete
}

    pub fn LoadDelayCopConReg(self: *LSI3000A, coprocessor: u2, register: u5, value: u32) void {
        _ = self;
        _ = coprocessor;
        _ = register;
        _ = value;
        // TODO: Complete
}
    pub fn HandleException(self: *LSI3000A, exception_type: Exceptions, bad_address: ?u32) void {
        self.Cause_Reg.ExcCode = @as(u5, @intFromEnum(exception_type));
        self.EPC_Reg = if (self.branch_called) self.PC - 8 else self.PC - 4;
        self.Cause_Reg.BD = if (self.branch_called) true else false;
        self.PC = 0x80000080;

        const shifted_status: u6 = (@as(u32, (@bitCast(self.SR_Reg)) ) & 0x1F) << 2;
        self.SR_Reg = @bitCast((@as( u32,@bitCast(self.SR_Reg)) & 0xFFFFFFC0) | shifted_status);

        if (exception_type == Exceptions.AdEL or exception_type == Exceptions.AdES){
            self.BadVaddr_Reg = bad_address;
        }
    }

    pub fn CopIsUsable(self: *LSI3000A, coprocessor: u3) bool {
        switch (coprocessor) {
            0 => return self.SR_Reg.CU0,

            2 => return self.SR_Reg.CU2,
            // TODO add logging for illegal coprocessor



        }
    }



};