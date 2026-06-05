
const cpu = @import("cpu.zig");
const CPU = cpu.LSI3000A;
const types = @import("../utils/types.zig");
const Exceptions = types.Exceptions;
const utils = @import("../utils/utils.zig");

const I_Type = packed struct (u32) {
    immediate: u16,
    rt: u5,
    rs: u5,
    op: u6
};

const J_Type = packed struct (u32){
    target: u26,
    op: u6
};
///
///     |   op   |   rs    |   rt   |   rd   | shamt  | funct  |
///    |31     26|25     21|20    16|15    11|10     5|6       0
const R_Type = packed struct (u32){
    funct: u6,
    shamt: u5,
    rd: u5,
    rt: u5,
    rs: u5,
    op: u6
};

const LINK_REGISTER: u5 = 31;

pub fn Add(self: *CPU, opcode: u32) void {
    const instruction: R_Type = @bitCast(opcode);
    const rs = self.read_register(instruction.rs);
    const rt = self.read_register(instruction.rt);
    const carry_from_30: u32 = (rs & 0x7FFFFFFF ) +% (rt & 0x7FFFFFFF);
    const carry_from_31: u33 = @as(u33,rs) +% @as(u33, rt);
    if ((carry_from_30 >> 31) & 0x1 != @as(u32, carry_from_31 >> 32) & 0x1){
        self.HandleException(Exceptions.Ov);
    } else {
        self.write_register(instruction.rd, rs +% rt);
    }
}

pub fn AddI(self: *CPU, opcode: u32) void {
    const instruction: I_Type = @bitCast(opcode);
    const extended_imm: u32 = utils.SignExtend16To32(instruction.immediate);
    const rs_value = self.read_register(instruction.rs);
    const carry_from_30: u32 = (extended_imm & 0x7FFFFFFF ) +% (rs_value & 0x7FFFFFFF);
    const carry_from_31: u33 = @as(u33,extended_imm) +% @as(u33, rs_value);
    if ((carry_from_30 >> 31) & 0x1 != (carry_from_31 >> 32) & 0x1){
        self.HandleException(Exceptions.Ov);
    } else {
        self.write_register(instruction.rt, rs_value +% extended_imm);
    }
}

pub fn AddIU(self: *CPU, opcode: u32) void {
    const instruction: I_Type = @bitCast(opcode);
    const extended_imm: u32 = utils.SignExtend16To32((instruction.immediate));
    const rs_value = self.read_register(instruction.rs);
    self.write_register(instruction.rt, rs_value +% extended_imm);
}

pub fn AddU(self: *CPU, opcode: u32) void {
    const instruction: R_Type = @bitCast(opcode);
    const rs = self.read_register(instruction.rs);
    const rt = self.read_register(instruction.rt);
    self.write_register(instruction.rd, rs +% rt);
}

pub fn And(self: *CPU, opcode: u32) void {
    const instruction: R_Type = @bitCast(opcode);
    const rt_value = self.read_register(instruction.rt);
    const rs_value = self.read_register(instruction.rs);
    self.write_register(instruction.rd, rt_value & rs_value);
}

pub fn AndI(self: *CPU, opcode: u32) void {
    const instruction: I_Type = @bitCast(opcode);
    const extended_imm: u32 = @as(u32, instruction.immediate);
    const rs_value = self.read_register(instruction.rs);
    self.write_register(instruction.rt, extended_imm & rs_value);
}

pub fn BEQ(self: *CPU, opcode: u32) void {
    const instruction: I_Type = @bitCast(opcode);
    const extended_offset: u32 = utils.SignExtend16To32(instruction.immediate) << 2;
    const final_address = self.PC +% extended_offset;
    if (self.read_register(instruction.rs) == self.read_register(instruction.rt)){
        self.branch(final_address);
    }

}

pub fn BGEZ(self: *CPU, opcode: u32) void {
    const instruction: I_Type = @bitCast(opcode);
    const extended_offset: u32 = utils.SignExtend16To32(instruction.immediate) << 2;
    const final_address = self.PC +% extended_offset;
    if (!((self.read_register(instruction.rs) >> 31) & 1)){
        self.branch(final_address);
    }

}

pub fn BGEZAL(self: *CPU, opcode: u32) void {
    const instruction: I_Type = @bitCast(opcode);
    const extended_offset: u32 = utils.SignExtend16To32(instruction.immediate) << 2;
    const final_address = self.PC +% extended_offset;
    self.write_register(LINK_REGISTER, self.PC + 8);
    if (!((self.read_register(instruction.rs) >> 31) & 1)){
        self.branch(final_address);
    }
}

pub fn BGTZ(self: *CPU, opcode: u32) void {
    const instruction: I_Type = @bitCast(opcode);
    const extended_offset: u32 = utils.SignExtend16To32(instruction.immediate) << 2;
    const final_address = self.PC +% extended_offset;
    if (!((self.read_register(instruction.rs) >> 31) & 1) and self.ReadRegister(instruction.rs) != 0){
        self.branch(final_address);
    }
}

pub fn BLEZ(self: *CPU, opcode: u32) void {
    const instruction: I_Type = @bitCast(opcode);
    const extended_offset: u32 = utils.SignExtend16To32(instruction.immediate) << 2;
    const final_address = self.PC +% extended_offset;
    if ((self.read_register(instruction.rs) >> 31) & 1 or self.ReadRegister(instruction.rs) != 0){
        self.branch(final_address);
    }

}

pub fn BLTZ(self: *CPU, opcode: u32) void {
    const instruction: I_Type = @bitCast(opcode);
    const extended_offset: u32 = utils.SignExtend16To32(instruction.immediate) << 2;
    const final_address = self.PC +% extended_offset;
    if ((self.read_register(instruction.rs) >> 31) & 1 and self.ReadRegister(instruction.rs) != 0){
        self.branch(final_address);
    }

}

pub fn BLTZAL(self: *CPU, opcode: u32) void {
    const instruction: I_Type = @bitCast(opcode);
    const extended_offset: u32 = utils.SignExtend16To32(instruction.immediate) << 2;
    const final_address = self.PC +% extended_offset;
    self.write_register(LINK_REGISTER, self.PC + 8);
    if ((self.read_register(instruction.rs) >> 31) & 1 and self.ReadRegister(instruction.rs) != 0){
        self.branch(final_address);
    }

}


pub fn BNE(self: *CPU, opcode: u32) void {
    const instruction: I_Type = @bitCast(opcode);
    const extended_offset: u32 = utils.SignExtend16To32(instruction.immediate) << 2;
    const final_address = self.PC +% extended_offset;
    if (self.read_register(instruction.rs) != self.read_register(instruction.rt)){
        self.branch(final_address);
    }
}

pub fn Break(self: *CPU, opcode: u32) void {
    _ = opcode;
    self.HandleException(Exceptions.Bp);
}

pub fn CFCz(self: *CPU, opcode: u32) void {
    const instruction: R_Type = @bitCast(opcode);
    const coprocessor: u2 = instruction.op & 0x3;
    const reg_val = self.ReadCoprocessorControlReg(coprocessor, instruction.rd);
    
    if (self.CopIsUsable(coprocessor)) {
        self.LoadDelayRegister(instruction.rt,reg_val);
    } else {
        self.HandleException(.CpU);
    }
}

pub fn COPz(self: *CPU, opcode: u32) void {
    const instruction: J_Type = @bitCast(opcode);
    const coprocessor: u2 = instruction.op & 0x3;
    const cofun: u25 = instruction.target & 0x1FFFFFF;
    if (self.CopIsUsable(coprocessor)) {
        self.CoprocessorOperation(coprocessor, cofun);
    } else {
        self.HandleException(.CpU);
    }
}

pub fn CTCz(self: *CPU, opcode: u32) void {
    const instruction: R_Type = @bitCast(opcode);
    const coprocessor: u2 = instruction.op & 0x3;
    const control_register = instruction.rd;
    const rt_value = self.ReadRegister(instruction.rt);
    if (self.CopIsUsable(coprocessor)){
        self.LoadDelayCopConReg(coprocessor, control_register, rt_value);
    } else {
        self.HandleException(.CpU);
    }

}

// TODO Look into
pub fn DIV(self: *CPU, opcode: u32) void {
    const instruction: I_Type = @bitCast(opcode);
    const dividend = self.ReadRegister(instruction.rs);
    const divisor = self.ReadRegister(instruction.rt);
    const signed_dividend: i32 = @bitCast(dividend);
    const signed_divisor: i32 = @bitCast(divisor);


    if (divisor == 0) {
        self.Hi = @bitCast(dividend);
        self.Lo = @bitCast(if (signed_dividend >= 0) @as(i32, -1) else @as(i32, 1));
        return;
    }
    if ((signed_dividend == -2147483648) and (signed_divisor == -1)) {
        self.Lo = @bitCast(@as(i32, -2147483648));
        self.Hi = 0;
        return;
    }
    const quotient = @divTrunc(signed_dividend, signed_divisor);
    const remainder = @rem(signed_dividend, signed_divisor);
    self.Lo = @bitCast(quotient);
    self.Hi = @bitCast(remainder);
}

pub fn DIVU(self: *CPU, opcode: u32) void {
    const instruction: I_Type = @bitCast(opcode);
    const dividend = self.ReadRegister(instruction.rs);
    const divisor = self.ReadRegister(instruction.rt);

    if (divisor == 0) {
        return;
    }
    const quotient = dividend / divisor;
    const remainder = dividend % divisor;
    self.Lo = quotient;
    self.Hi = remainder;
}


pub fn J(self: *CPU, opcode: u32) void {
    const instruction: J_Type = @bitCast(opcode);
    const address = (self.PC & 0xF0000000) | (instruction.target << 2);
    self.Branch(address);
}

pub fn JAL(self: *CPU, opcode: u32) void {
    const instruction: J_Type = @bitCast(opcode);
    const address = (self.PC & 0xF0000000) | (instruction.target << 2);
    self.Branch(address);
    self.WriteRegister(LINK_REGISTER, self.PC + 4);
}

pub fn JALR(self: *CPU, opcode: u32) void {
    const instruction: R_Type = @bitCast(opcode);
    const address = self.ReadRegister(instruction.rs);

    if(address & 3 != 0){
        self.HandleException(.AdEL, address);
    } else {
        self.Branch(address);
        self.WriteRegister(instruction.rd, self.PC + 4);
    }
}

pub fn JR(self: *CPU, opcode: u32) void {
    const instruction: R_Type = @bitCast(opcode);
    const address = self.ReadRegister(instruction.rs);
    self.Branch(address);
}

pub fn LB(self: *CPU, opcode: u32) void {
    const instruction: I_Type = @bitCast(opcode);
    const sign_extended_offset: u32 = utils.SignExtend16To32(instruction.immediate);

    const address = sign_extended_offset +% self.ReadRegister(instruction.rs);
    const content: u32 =  utils.SignExtend8To32(self.BusRead8(address));
    self.LoadDelayRegister(instruction.rt, content);

}

pub fn LBU(self: *CPU, opcode: u32) void {
    const instruction: I_Type = @bitCast(opcode);
    const sign_extended_offset: u32 = utils.SignExtend16To32(instruction.immediate);

    const address = sign_extended_offset +% self.ReadRegister(instruction.rs);
    const content: u32 =  @intCast(self.BusRead8(address));
    self.LoadDelayRegister(instruction.rt, content);
}

pub fn LH(self: *CPU, opcode: u32) void {
    const instruction: I_Type = @bitCast(opcode);
    const sign_extended_offset: u32 = utils.SignExtend16To32(instruction.immediate);

    const address = sign_extended_offset +% self.ReadRegister(instruction.rs);
    if (address & 1 != 0) {
        self.HandleException(.AdEL, address);
    } else {
        const content: u32 =  utils.SignExtend16To32(self.BusRead16(address));
        self.LoadDelayRegister(instruction.rt, content);
    }
}

pub fn LHU(self: *CPU, opcode: u32) void {
    const instruction: I_Type = @bitCast(opcode);
    const sign_extended_offset: u32 = utils.SignExtend16To32(instruction.immediate);

    const address = sign_extended_offset +% self.ReadRegister(instruction.rs);
    if (address & 1 != 0) {
        self.HandleException(.AdEL, address);
    } else {
        const content: u32 =  @intCast(self.BusRead16(address));
        self.LoadDelayRegister(instruction.rt, content);
    }
}

pub fn LUI(self: *CPU, opcode: u32) void {
    const instruction: I_Type = @bitCast(opcode);
    const shifted_imm: u32 = @as(u32, instruction.immediate) << 16;
    self.WriteRegister(instruction.rt, shifted_imm);

}

pub fn LW(self: *CPU, opcode: u32) void {
    const instruction: I_Type = @bitCast(opcode);
    const sign_extended_offset: u32 = utils.SignExtend16To32(instruction.immediate);

    const address = sign_extended_offset +% self.ReadRegister(instruction.rs);
    if (address & 0x3 != 0) {
        self.HandleException(.AdEL, address);
    } else {
        const content: u32 =  self.BusRead32(address);
        self.LoadDelayRegister(instruction.rt, content);
    }
}

pub fn LWCz(self: *CPU, opcode: u32) void {
    const instruction: I_Type = @bitCast(opcode);
    const sign_extended_offset: u32 = utils.SignExtend16To32(instruction.immediate);
    const coprocessor = (instruction.op >> 26) & 0x3;

    if(!self.CopIsUsable(coprocessor)){
        self.HandleException(.CpU);
        return;
    }
    const address = sign_extended_offset +% self.ReadRegister(instruction.rs);
    if (address & 0x3 != 0) {
        self.HandleException(.AdEL, address);
        return;
    }

    const content: u32 =  self.BusRead32(address);
    

    self.LoadDelayCopGenReg(coprocessor, instruction.rt, content);
}



pub fn LWL(self: *CPU, opcode: u32) void {
    const instruction: I_Type = @bitCast(opcode);
    const sign_extended_offset: u32 = utils.SignExtend16To32(instruction.immediate);

    const address = sign_extended_offset +% self.ReadRegister(instruction.rs);
    const true_address = address & 0xFFFFFFFC;
    const start_byte_index = address & 0x3;
    const content = self.BusRead32(true_address);
    const current_rt_value: u32 = self.ReadRegister(instruction.rt);
    const rt_mask: u32 = if (start_byte_index != 0) 0xFFFFFFFF >> (((3 - start_byte_index) + 1) * 8) else 0;
    const masked_content: u32 = content << 8 * (3 - start_byte_index);
    const final_val: u32 = masked_content | (current_rt_value & rt_mask);

    self.LoadDelayRegister(instruction.rt, final_val);

}

pub fn LWR(self: *CPU, opcode: u32) void {
    const instruction: I_Type = @bitCast(opcode);
    const sign_extended_offset: u32 = utils.SignExtend16To32(instruction.immediate);

    const address = sign_extended_offset +% self.ReadRegister(instruction.rs);
    const true_address = address & 0xFFFFFFFC;
    const start_byte_index = address & 0x3;
    const content = self.BusRead32(true_address);
    const current_rt_value: u32 = self.ReadRegister(instruction.rt);
    const rt_mask: u32 = if (start_byte_index != 0) 0xFFFFFFFF << (((3 - start_byte_index) + 1) * 8) else 0;
    const masked_content: u32 = content >> 8 * start_byte_index;
    const final_val: u32 = masked_content | (current_rt_value & rt_mask);

    self.LoadDelayRegister(instruction.rt, final_val);

}

pub fn MFCz(self: *CPU, opcode: u32) void {
    const instruction: R_Type = @bitCast(opcode);
    const coprocessor: u2 = instruction.op & 0x3;
    const reg_val = self.ReadCoprocessorGenReg(coprocessor, instruction.rd);

    if (self.CopIsUsable(coprocessor)) {
        self.LoadDelayRegister(instruction.rt,reg_val);
    } else {
        self.HandleException(.CpU);
    }
}

pub fn MFHI(self: *CPU, opcode: u32) void {
    const instruction: R_Type = @bitCast(opcode);
    self.WriteRegister(instruction.rd, self.Hi);
}

pub fn MFLO(self: *CPU, opcode: u32) void {
    const instruction: R_Type = @bitCast(opcode);
    self.WriteRegister(instruction.rd, self.Lo);
}

pub fn MTCz(self: *CPU, opcode: u32) void {
    const instruction: R_Type = @bitCast(opcode);
    const coprocessor: u2 = instruction.op & 0x3;
    const control_register = instruction.rd;
    const rt_value = self.ReadRegister(instruction.rt);
    if (self.CopIsUsable(coprocessor)){
        self.LoadDelayCopGenRegReg(coprocessor, control_register, rt_value);
    } else {
        self.HandleException(.CpU);
    }

}

pub fn MTHI(self: *CPU, opcode: u32) void {
    const instruction: R_Type = @bitCast(opcode);
    self.Hi = self.ReadRegister(instruction.rs);
}

pub fn MTLO(self: *CPU, opcode: u32) void {
    const instruction: R_Type = @bitCast(opcode);
    self.Lo = self.ReadRegister(instruction.rs);
}

pub fn MULT(self: *CPU, opcode: u32) void {
    const instruction: R_Type = @bitCast(opcode);
    const mult_result: i64 = @as( i64,@intCast(@as(i32, @bitCast(self.ReadRegister(instruction.rt))))) * @as( i64,@intCast(@as(i32, @bitCast(self.ReadRegister(instruction.rs)))));
    self.Hi = @bitCast(@as(i32, @truncate(mult_result >> 32)));
    self.Lo = @bitCast(@as(i32, @truncate(mult_result)));
}

pub fn MULTU(self: *CPU, opcode: u32) void {
    const instruction: R_Type = @bitCast(opcode);
    const mult_result: u64 = self.ReadRegister(instruction.rt) * self.ReadRegister(instruction.rs);
    self.Hi = @truncate(mult_result >> 32);
    self.Lo = @truncate(mult_result);
}

pub fn NOR(self: *CPU, opcode: u32) void {
    const instruction: R_Type = @bitCast(opcode);
    const result = ~(self.ReadRegister(instruction.rs) | self.ReadRegister(instruction.rt));
    self.WriteRegister(instruction.rd, result);
}

pub fn OR(self: *CPU, opcode: u32) void {
    const instruction: R_Type = @bitCast(opcode);
    const result = self.ReadRegister(instruction.rs) | self.ReadRegister(instruction.rt);
    self.WriteRegister(instruction.rd, result);
}

pub fn ORI(self: *CPU, opcode: u32) void {
    const instruction: I_Type = @bitCast(opcode);
    const zero_extend_imm: u32 = @intCast(instruction.immediate);
    const result: u32 = self.ReadRegister(instruction.rs) | zero_extend_imm;
    self.WriteRegister(instruction.rt, result);
}

pub fn SB(self: *CPU, opcode: u32) void {
    const instruction: I_Type = @bitCast(opcode);
    const address = self.ReadRegister(instruction.rs) +% utils.SignExtend16To32(instruction.immediate);
    const value: u8 = @truncate(self.ReadRegister(instruction.rt));
    self.BusWrite8(address, value);
}

pub fn SH(self: *CPU, opcode: u32) void {
    const instruction: I_Type = @bitCast(opcode);
    const address = self.ReadRegister(instruction.rs) +% utils.SignExtend16To32(instruction.immediate);
    if (address & 1 != 0) {
        self.HandleException(.AdES, address);
    } else {
        const value: u16 = @truncate(self.ReadRegister(instruction.rt));
        self.BusWrite16(address, value);
    }
}

pub fn SLL(self: *CPU, opcode: u32) void {
    const instruction: R_Type = @bitCast(opcode);
    const shifted_value: u32 = self.ReadRegister(instruction.rt) << instruction.shamt;
    self.WriteRegister(instruction.rd, shifted_value);
}

pub fn SLLV(self: *CPU, opcode: u32) void {
    const instruction: R_Type = @bitCast(opcode);
    const shift: u5 = @truncate(self.ReadRegister(instruction.rs));
    const shifted_value: u32 = self.ReadRegister(instruction.rt) << shift;
    self.WriteRegister(instruction.rd, shifted_value);
}

pub fn SLT(self: *CPU, opcode: u32) void {
    const instruction: R_Type = @bitCast(opcode);
    const rs_signed: i32 = @bitCast(self.ReadRegister(instruction.rs));
    const rt_signed: i32 = @bitCast(self.ReadRegister(instruction.rt));

    if (rs_signed < rt_signed){
        self.WriteRegister(instruction.rd, 1);

    }else {
        self.WriteRegister(instruction.rd, 0);
    }
}

pub fn SLTI(self: *CPU, opcode: u32) void {
    const instruction: I_Type = @bitCast(opcode);
    const rs_signed: i32 = @bitCast(self.ReadRegister(instruction.rs));
    const imm_signed: i32 = @bitCast(utils.SignExtend16To32(instruction.immediate));


    if (rs_signed < imm_signed){
        self.WriteRegister(instruction.rt, 1);

    }else {
        self.WriteRegister(instruction.rt, 0);
    }
}

pub fn SLTIU(self: *CPU, opcode: u32) void {
    const instruction: I_Type = @bitCast(opcode);
    const imm_extended: u32 = utils.SignExtend16To32(instruction.immediate);


    if (self.ReadRegister(instruction.rs) < imm_extended){
        self.WriteRegister(instruction.rt, 1);

    }else {
        self.WriteRegister(instruction.rt, 0);
    }
}

pub fn SLTU(self: *CPU, opcode: u32) void {
    const instruction: R_Type = @bitCast(opcode);
    const rs_val: u32 = self.ReadRegister(instruction.rs);
    const rt_val: u32 = self.ReadRegister(instruction.rt);

    if (rs_val < rt_val){
        self.WriteRegister(instruction.rd, 1);

    }else {
        self.WriteRegister(instruction.rd, 0);
    }
}


pub fn SRA(self: *CPU, opcode: u32) void {
    const instruction: R_Type = @bitCast(opcode);
    const rt_value: i32 = @bitCast(self.ReadRegister(instruction.rt));
    const shifted_value: u32 = @bitCast(rt_value >> instruction.shamt);
    self.WriteRegister(instruction.rd, shifted_value );
}


pub fn SRAV(self: *CPU, opcode: u32) void {
    const instruction: R_Type = @bitCast(opcode);
    const rt_value: i32 = @bitCast(self.ReadRegister(instruction.rt));
    const shift: u5 = @truncate(self.ReadRegister(instruction.rs));
    const shifted_value: u32 = @bitCast(rt_value >> shift);
    self.WriteRegister(instruction.rd, shifted_value);
}

pub fn SRL(self: *CPU, opcode: u32) void {
    const instruction: R_Type = @bitCast(opcode);
    const shifted_value: u32 = self.ReadRegister(instruction.rt) >> instruction.shamt;
    self.WriteRegister(instruction.rd, shifted_value);
}

pub fn SRLV(self: *CPU, opcode: u32) void {
    const instruction: R_Type = @bitCast(opcode);
    const shift: u5 = @truncate(self.ReadRegister(instruction.rs));
    const shifted_value: u32 = self.ReadRegister(instruction.rt) >> shift;
    self.WriteRegister(instruction.rd, shifted_value);
}

pub fn SUB(self: *CPU, opcode: u32) void {
    const instruction: R_Type = @bitCast(opcode);
    const rt_value: i64 = @intCast(@as(i32, @bitCast(self.ReadRegister(instruction.rt))));
    const rs_value: i64 = @intCast(@as(i32, @bitCast(self.ReadRegister(instruction.rs))));
    const initial_res = rs_value - rt_value;
    if (initial_res < -2147483648 or initial_res > 2147483647){
        self.HandleException(.Ov);
        return;
    }
    const final_u32: u32 = @bitCast(@as(i32, @truncate(initial_res)));
    self.WriteRegister(instruction.rd, final_u32);
}

pub fn SUBU(self: *CPU, opcode: u32) void {
    const instruction: R_Type = @bitCast(opcode);
    self.WriteRegister(instruction.rd, self.ReadRegister(instruction.rs) -% self.ReadRegister(instruction.rt));

}

pub fn SW(self: *CPU, opcode: u32) void {
    const instruction: I_Type = @bitCast(opcode);
    const address = self.ReadRegister(instruction.rs) +% utils.SignExtend16To32(instruction.immediate);
    if (address & 3 != 0) {
        self.HandleException(.AdES, address);
        return;
    }
    self.BusWrite32(address, self.ReadRegister(instruction.rt));

}

pub fn SWZc(self: *CPU, opcode: u32) void {
    const instruction: I_Type = @bitCast(opcode);
    const address = self.ReadRegister(instruction.rs) +% utils.SignExtend16To32(instruction.immediate);
    const coprocessor: u2 = @truncate(instruction.op);
    if (!self.CopIsUsable(coprocessor)){
        self.HandleException(.CpU);
        return;
    }

    if (address & 3 != 0) {
        self.HandleException(.AdES, address);
    } else {
        const value: u32 = self.ReadCoprocessorGenReg(coprocessor, instruction.rt);
        self.BusWrite32(address, value);
    }
}

pub fn SWL(self: *CPU, opcode: u32) void {
    const instruction: I_Type = @bitCast(opcode);
    const address = (self.ReadRegister(instruction.rs) +% utils.SignExtend16To32(instruction.immediate));
    const virtual_address: u32 = address & 0xFFFFFFFC;
    const start_index: u2 = address & 0x3;
    const mask: u32 = if (start_index != 3) 0xFFFFFFFF <<  ((start_index + 1) * 8) else 0;
    const current_mem_val = self.BusRead32(virtual_address) & mask;
    const content = self.ReadRegister(instruction.rt) >> (8 * (3 - start_index));

    self.BusWrite32(virtual_address,current_mem_val | content);
}

pub fn SWR(self: *CPU, opcode: u32) void {
    const instruction: I_Type = @bitCast(opcode);
    const address = (self.ReadRegister(instruction.rs) +% utils.SignExtend16To32(instruction.immediate));
    const virtual_address: u32 = address & 0xFFFFFFFC;
    const start_index: u2 = address & 0x3;
    const mask: u32 = if (start_index != 0) 0xFFFFFFFF >> (((3 - start_index ) + 1) * 8) else 0;
    const current_mem_val = self.BusRead32(virtual_address) & mask;
    const content = self.ReadRegister(instruction.rt) << (8 * start_index);

    self.BusWrite32(virtual_address,current_mem_val | content);
}

pub fn SYSCALL(self: *CPU, opcode: u32) void {
    _ = opcode;
    self.HandleException(.Sys);
}

pub fn XOR(self: *CPU, opcode: u32) void {
    const instruction: R_Type = @bitCast(opcode);
    const value: u32 = self.ReadRegister(instruction.rt) ^ self.ReadRegister(instruction.rs);
    self.WriteRegister(instruction.rd, value);
}

pub fn XORI(self: *CPU, opcode: u32) void {
    const instruction: I_Type = @bitCast(opcode);
    const zero_imm: u32 = @intCast(instruction.immediate);
    const value: u32 = zero_imm ^ self.ReadRegister(instruction.rs);
    self.WriteRegister(instruction.rt, value);
}

pub fn InvalidOpcode(self: *CPU, opcode: u32) void {
    _ = self;
    _ = opcode;
}

pub fn RFE(self: *CPU, opcode: u32) void {
    const current_sr: u32 = @bitCast(self.SR_Reg);
    const status_shifted: u4 = @truncate(current_sr >> 2);
    const res: u32 = current_sr & 0xFFFFFFF0 | status_shifted;
    self.SR_Reg = @bitCast(res);
}

pub const op0_table: [44](*const fn(*CPU, u32) void) = [44](*const fn(*CPU, u32) void ){
    &SLL, &InvalidOpcode,&SRL, &SRA, &SLLV, &InvalidOpcode, &SRLV, &SRAV, &JR, &JALR, &InvalidOpcode, &InvalidOpcode,
    &SYSCALL, &Break, &InvalidOpcode, &InvalidOpcode, &MFHI, &MTHI, &MFLO, &MTLO, &InvalidOpcode, &InvalidOpcode, &InvalidOpcode,
    &InvalidOpcode, &MULT, &MULTU, &DIV, &DIVU, &InvalidOpcode, &InvalidOpcode, &InvalidOpcode, &InvalidOpcode, &Add, &AddU, &SUB,
    &SUBU, &And, &OR, &XOR, &NOR, &InvalidOpcode, &InvalidOpcode, &SLT, &SLTU
};

const op1_table: [17](*const fn(*CPU, u32) void) = [17](*const fn(*CPU, u32) void ){
    &BLTZ, &BGEZ, &InvalidOpcode,  &InvalidOpcode, &InvalidOpcode, &InvalidOpcode, &InvalidOpcode, &InvalidOpcode, &InvalidOpcode,
    &InvalidOpcode, &InvalidOpcode, &InvalidOpcode, &InvalidOpcode, &InvalidOpcode, &InvalidOpcode, &InvalidOpcode, &BLTZAL, &BGEZAL
};

const op24_table: [9](*const fn(*CPU, u32) void) = [9](*const fn(*CPU, u32) void ){

};

pub fn InitOpc0Table(self: *CPU, opcode_0_table: [17](*const fn(*CPU, u32) void) ) void {
    _ = self;
    opcode_0_table[0x00] = &SLL;
    opcode_0_table[0x02] = &SRL;
    opcode_0_table[0x03] = &SRA;
    opcode_0_table[0x04] = &SLLV;
    opcode_0_table[0x06] = &SRLV;
    opcode_0_table[0x07] = &SRAV;
    opcode_0_table[0x08] = &JR;
    opcode_0_table[0x09] = &JALR;
    opcode_0_table[0x0C] = &SYSCALL;
    opcode_0_table[0x0D] = &Break;
    opcode_0_table[0x10] = &MFHI;
    opcode_0_table[0x11] = &MTHI;
    opcode_0_table[0x12] = &MFLO;
    opcode_0_table[0x13] = &MTLO;
    opcode_0_table[0x18] = &MULT;
    opcode_0_table[0x19] = &MULTU;
    opcode_0_table[0x1A] = &DIV;
    opcode_0_table[0x1B] = &DIVU;
    opcode_0_table[0x20] = &Add;
    opcode_0_table[0x21] = &AddU;
    opcode_0_table[0x22] = &SUB;
    opcode_0_table[0x23] = &SUBU;
    opcode_0_table[0x24] = &And;
    opcode_0_table[0x25] = &OR;
    opcode_0_table[0x26] = &XOR;
    opcode_0_table[0x27] = &NOR;
    opcode_0_table[0x2A] = &SLT;
    opcode_0_table[0x2B] = &SLTU;


}

pub fn InitOpcodeTable(self: *CPU) void {
    _ = self;
    const opcode_table: [57](*const fn(*CPU, u32) void) = [57](*const fn(*CPU, u32) void ){};
    opcode_table[0x00] = &DecodeOpcodeZero;
    opcode_table[0x01] = &DecodeOpcodeBranch;
    opcode_table[0x02] = &J;
    opcode_table[0x03] = &JAL;
    opcode_table[0x04] = &BEQ;
    opcode_table[0x05] = &BNE;
    opcode_table[0x06] = &BLEZ;
    opcode_table[0x07] = &BGTZ;
    opcode_table[0x08] = &AddI;
    opcode_table[0x09] = &AddIU;
    opcode_table[0x0C] = &AndI;
    opcode_table[0x0D] = &ORI;
    opcode_table[0x0E] = &XORI;
    opcode_table[0x0F] = &LUI;
    opcode_table[0x0A] = &SLTI;
    opcode_table[0x0B] = &SLTIU;
    opcode_table[0x10] = &DecodeOpcodeCop;
    opcode_table[0x12] = &DecodeOpcodeCop;
    opcode_table[0x20] = &LB;
    opcode_table[0x21] = &LH;
    opcode_table[0x22] = &LWL;
    opcode_table[0x23] = &LW;
    opcode_table[0x24] = &LBU;
    opcode_table[0x25] = &LHU;
    opcode_table[0x26] = &LWR;
    opcode_table[0x28] = &SB;
    opcode_table[0x29] = &SH;
    opcode_table[0x2A] = &SWL;
    opcode_table[0x2B] = &SW;
    opcode_table[0x2E] = &SWR;
    opcode_table[0x32] = &LWCz;
    opcode_table[0x3A] = &SWZc;


}
pub fn DecodeOpcodeZero(self: *CPU, opcode: u32) void{
    const funct: u6 = @truncate(opcode);
    op0_table[funct](self, opcode);
}

pub fn DecodeOpcodeBranch(self: *CPU, opcode: u32) void {
    const index: u5 = @truncate(opcode >> 16);
    op1_table[index](self, opcode);
}
pub fn DecodeOpcodeCop(self: *CPU, opcode: u32) void {
    const index: u5 = @truncate(opcode >> 16);
    op1_table[index](self, opcode);
}

pub fn DecodeOpcode(self: *CPU, opcode: u32) void {
    const index: u6 = @truncate(opcode >> 26);
    opcode_table[index](self, opcode);

}

// Decoding
//

