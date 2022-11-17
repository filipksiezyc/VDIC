/******************************************************************************
 * (C) Copyright 2013 <Company Name> All Rights Reserved
 *
 * MODULE:    name
 * DEVICE:
 * PROJECT:
 * AUTHOR:    fksiezyc
 * DATE:      2022 4:06:34 PM
 *
 * ABSTRACT:  You can customize the file content from Window -> Preferences -> DVT -> Code Templates -> "verilog File"
 *
 *******************************************************************************/

module top;
alu_bfm bfm();
tester tester_alu(bfm);
scoreboard scoreboard_alu(bfm);
coverage coverage_alu(bfm);

//------------------------------------------------------------------------------
// Dut initialization
//------------------------------------------------------------------------------
vdic_dut_2022 serial_ALU(
	.clk(bfm.clk), 
	.rst_n(bfm.rst_n), 
	.enable_n(bfm.enable_n), 
	.din(bfm.din),
	
	.dout(bfm.dout),
	.dout_valid(bfm.dout_valid));
	
	



endmodule : top
