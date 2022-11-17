module tester(alu_bfm bfm);

import alu_pkg::*;

logic currCode;
logic currParity;
	
logic [7:0] currWord;

//------------------------------------------------------------------------------
// All test specs
//------------------------------------------------------------------------------
initial begin
	bfm.statusCalculated = 0;
	bfm.aluOutput[0] = {10'b0000000000};
	bfm.aluOutput[1] = {10'b0000000000};
	bfm.aluOutput[2] = {10'b0000000000};
	bfm.inputWords[0] = {10'b0000000000};
	bfm.inputWords[1] = {10'b0000000000};
	bfm.data[0] = {10'b0000000000};
	bfm.data[1] = {10'b0000000000};
	bfm.operationCode = bfm.operationCode.first();
	bfm.opTbExclusive = bfm.opTbExclusive.first();
	bfm.testResult = PASSED;
	bfm.din = 0;
	bfm.done = 1'b0;
	
	bfm.aluEnableReset();
	
	bfm.resetAlu();
	
	//testing for all operations
	for(int i = 0; i < bfm.operationCode.num(); i++) begin
		
		tester(bfm.operationCode, NORMAL);
		tester(bfm.operationCode, MAX_VAL);
		tester(bfm.operationCode, MIN_VAL);
		
		bfm.operationCode = bfm.operationCode.next();
	end
	
	
	//testing for all operations after reset
	bfm.operationCode = bfm.operationCode.first();
	
	for(int i = 0; i < bfm.operationCode.num(); i++) begin
		
		bfm.resetAlu();
		tester(bfm.operationCode, NORMAL);
		tester(bfm.operationCode, MAX_VAL);
		tester(bfm.operationCode, MIN_VAL);
		
		bfm.operationCode = bfm.operationCode.next();
	end
	
	
	//testing for reset after all operations
	bfm.operationCode = bfm.operationCode.first();
	
	for(int i = 0; i< bfm.operationCode.num(); i++) begin
		
		tester(bfm.operationCode, NORMAL);
		tester(bfm.operationCode, MAX_VAL);
		tester(bfm.operationCode, MIN_VAL);
		bfm.resetAlu();
		
		bfm.operationCode = bfm.operationCode.next();
	end
	
	
	//testing all operations twice a row
	bfm.operationCode = bfm.operationCode.first();
	
	for(int i = 0; i < bfm.operationCode.num(); i++) begin
		
		for(int j = 0; j < 2; j++)begin
			tester(bfm.operationCode, NORMAL);
			tester(bfm.operationCode, MAX_VAL);
			tester(bfm.operationCode, MIN_VAL);
		end
		
		bfm.operationCode = bfm.operationCode.next();
	end
	    
	bfm.operationCode = CMD_INV;
	for(int j = 0; j < 2; j++)begin
		tester(bfm.operationCode, NORMAL);
		tester(bfm.operationCode, MAX_VAL);
		tester(bfm.operationCode, MIN_VAL);
	end
	
	bfm.operationCode = CMD_SUB;
	for(int j = 0; j < 2; j++)begin
		tester(bfm.operationCode, NORMAL);
		tester(bfm.operationCode, MAX_VAL);
		tester(bfm.operationCode, MIN_VAL);
	end
	
	$finish;
end


//------------------------------------------------------------------------------
// Tasks
//------------------------------------------------------------------------------

task tester(
	input logic [7:0] operationCode,
	cornerType cornertype);
	
	
	bfm.aluEnableSet();
	inputInjector(bfm.numberOfInputWords, operationCode, cornertype);
	bfm.aluEnableReset();
		
	monitor();
		
	@(posedge bfm.clk);
	@(posedge bfm.clk);

endtask




task automatic monitor();
	threeWords resultDataTemp;
	integer wordsIterator;
	integer bitsIterator;
	singleCompleteWord currWord;
	
	currWord = 0;
	resultDataTemp = {currWord, currWord, currWord};
	
	@(posedge bfm.dout_valid);
	for(wordsIterator = 0; wordsIterator < 3; wordsIterator++)begin
		currWord = 0;
		
		for(bitsIterator = 9; bitsIterator >=0; bitsIterator--)begin
			@(posedge bfm.clk);
			currWord[bitsIterator] = bfm.dout;
		end
		
		resultDataTemp[wordsIterator] = currWord;
	end
	
	bfm.aluOutput = resultDataTemp;
	bfm.done = 1;
endtask : monitor



task automatic inputInjector(
	input integer numberOfWords,
	input logic [7:0] op,
	cornerType cornertype);
	
	currCode = DATA;
	//enable_n = 0;
	for(int i=0; i < numberOfWords; i++)begin
		singleCompleteWord currCompleteWord;
		
		if(cornertype == NORMAL)
			currWord = getRandomData();
		else if(cornertype == MAX_VAL)
			currWord = 8'hFF;
		else
			currWord = 8'h00;
		
		currParity = calcParity(DATA, currWord);
		
		currCompleteWord[9] = currCode;
		currCompleteWord[8:1] = currWord;
		currCompleteWord[0] = currParity;
		bfm.inputWords[i] = currCompleteWord;
		bfm.wordSender({currCode, currWord, currParity});
	end
		
	currCode = OPCODE;
	currWord = op;
	$cast(bfm.opTbExclusive, op);
	currParity = calcParity(OPCODE, currWord);
	bfm.wordSender({currCode, currWord, currParity});
		
endtask : inputInjector


//------------------------------------------------------------------------------
// Function definitions
//------------------------------------------------------------------------------
function byte getOpcode();
	logic [2:0] random;
	
	random = 3'($random);
	
	case(random)
		000 : return CMD_NOP;
 		001 : return CMD_AND;
 		010 : return CMD_OR;
 		011 : return CMD_XOR;
 		100 : return CMD_ADD;
 		101 : return CMD_SUB;
		
		default return 8'($random);
		
	endcase

endfunction : getOpcode


function byte getRandomData();

		bit [7:0] zero_ones;

		zero_ones = 2'($random);

		if (zero_ones == 2'b00)
			return 8'h00;
		else if (zero_ones == 2'b11)
			return 8'hFF;
		else
			return 8'($random);
endfunction : getRandomData


function logic calcParity(wordControllBit b, logic [7:0] word);
	logic parity;
	
	parity = b;
	foreach(word[i])begin
		parity = parity + word[i];
	end

	return parity;

endfunction


endmodule