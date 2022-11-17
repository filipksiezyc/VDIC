interface alu_bfm;
	
import alu_pkg::*;


//------------------------------------------------------------------------------
// Parameters
//------------------------------------------------------------------------------	
parameter numberOfInputWords = 9;
	

//------------------------------------------------------------------------------
// WIRES
//------------------------------------------------------------------------------	
logic clk;
logic rst_n;
logic enable_n;
logic din;
logic dout;
logic dout_valid;
logic done;

logic [9:0] inputWords [numberOfInputWords - 1 : 0];
logic [9:0] statusCalculated;

opCodes operationCode;
opCodesTb opTbExclusive;

singleCompleteWord[1:0] data;
threeWords aluOutput;	
TestResult testResult;
	
	
//------------------------------------------------------------------------------
// Clock generator
//------------------------------------------------------------------------------
initial begin
	clk = 0;
	
	forever #5 clk = ~clk; 
end

//------------------------------------------------------------------------------
// Tasks definitions
//------------------------------------------------------------------------------
task aluEnableSet();
	
	while(dout_valid == 1) @(negedge clk);	
	#1 enable_n = 1'b0;

endtask : aluEnableSet
	

task aluEnableReset();
	
	@(negedge clk);
	#1 enable_n = 1'b1;
	
endtask : aluEnableReset


task automatic resetAlu();
	`ifdef DEBUG
		$display("%0t DEBUG: reset_alu", $time);
	`endif
        opTbExclusive = CMD_RST_tb;
	
		rst_n = 1'b0;
		@(negedge clk);
		rst_n = 1'b1;
	
		@(posedge clk);
		@(posedge clk);
endtask : resetAlu



task automatic wordSender(
	input logic [9 : 0] word);

	for(int i = 9; i >= 0; i--)begin
		@(negedge clk) din = word[i];
	end
	
endtask : wordSender

	
endinterface : alu_bfm