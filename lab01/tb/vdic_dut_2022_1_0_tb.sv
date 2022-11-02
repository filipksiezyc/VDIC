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

module vdic_dut_2022_1_0_tb;
	
	
//------------------------------------------------------------------------------
// Parameters
//------------------------------------------------------------------------------	
parameter numberOfInputWords = 2;

    
//------------------------------------------------------------------------------
// Type definitions
//------------------------------------------------------------------------------
typedef logic [9:0] singleCompleteWord;
typedef logic [15:0] sixteenBitUnpacked; 
typedef logic [9:0] threeWords [2:0]; 



//------------------------------------------------------------------------------
// Enums
//------------------------------------------------------------------------------
typedef enum{
	
	PASSED = 1, 
	FAILED = 0

} TestResult;
	

typedef enum logic{
	
	REPEAT = 1,
	SINGLE = 0
	
} RepeatTestcase;


typedef enum {
		
		COLOR_BOLD_BLACK_ON_GREEN,
		COLOR_BOLD_BLACK_ON_RED,
		COLOR_BOLD_BLACK_ON_YELLOW,
		COLOR_BOLD_BLUE_ON_WHITE,
		COLOR_BLUE_ON_WHITE,
		COLOR_DEFAULT

} printColorT;
	
	
typedef enum logic{
	
	DATA = 0,
	OPCODE = 1

} wordControllBit;
	

typedef enum logic[7:0]  {
	//commented out opcodes are unavailable now
	
	//CMD_NOP   = 8'b00000000,
 	CMD_AND     = 8'b00000001, 
 	//CMD_OR    = 8'b00000010,
 	//CMD_XOR   = 8'b00000011, 
 	CMD_ADD     = 8'b00010000, 
 	//CMD_SUB   = 8'b00100000,  
 	CMD_INVALID = 8'b01110011

} opCodes;
	

typedef enum logic [7:0]{ 
	S_NO_ERROR			   = 8'b00000000, 
	//S_MISSING_DATA 		   = 8'b00000001,
	//S_DATA_STACK_OVERFLOW  = 8'b00000010,
	//S_OUTPUT_FIFO_OVERFLOW = 8'b00000100,
	//S_DATA_PARITY_ERROR    = 8'b00100000,
	//S_COMMAND_PARITY_ERROR = 8'b01000000,
	S_INVALID_COMMAND 	   = 8'b10000000
 } aluOutputStatus;
	
	
typedef enum logic {
	
	START = 1,
	ENDED = 0
	
} testingOption;


//------------------------------------------------------------------------------
// Inputs and outputs
//------------------------------------------------------------------------------
logic clk;
logic rst_n;
logic enable_n;
logic din;
logic dout;
logic dout_valid;
	
	
//------------------------------------------------------------------------------
// Task Comunication
//------------------------------------------------------------------------------
logic currCode;
logic currParity;
logic [7:0] currWord;

opCodes operationCode;
logic [9:0] inputWords [numberOfInputWords - 1 : 0];

logic [9:0] statusCalculated;
singleCompleteWord[1:0] data;
	
threeWords aluOutput;
	
	
logic testResultValidator;
logic finished;


//------------------------------------------------------------------------------
// Clock generator
//------------------------------------------------------------------------------
initial begin
	clk = 0;
	
	forever #5 clk = ~clk; 
end


//------------------------------------------------------------------------------
// Dut initialization
//------------------------------------------------------------------------------

vdic_dut_2022 serial_ALU(
	.clk(clk), 
	.rst_n(rst_n), 
	.enable_n(enable_n), 
	.din(din),
	
	.dout(dout),
	.dout_valid(dout_valid));
	
	

//------------------------------------------------------------------------------
// Main (running all the tests)
//------------------------------------------------------------------------------
initial begin
	statusCalculated = 0;
	aluOutput[0] = {10'b0000000000};
	aluOutput[1] = {10'b0000000000};
	aluOutput[2] = {10'b0000000000};
	inputWords[0] = {10'b0000000000};
	inputWords[1] = {10'b0000000000};
	data[0] = {10'b0000000000};
	data[1] = {10'b0000000000};
	operationCode = CMD_AND;//operationCode.first();
	testResultValidator = 1'b1;
	finished = 0;
	din = 0;
	
	aluEnableReset();
	
	resetAlu();
	
	//testing for all operations
	for(int i = 0; i<operationCode.num(); i++) begin
		
		tester(operationCode);
		
		operationCode = operationCode.next();
	end
	
	
	
	//testing for all operations after reset
	operationCode = operationCode.first();
	
	for(int i = 0; i<operationCode.num(); i++) begin
		
		resetAlu();
		tester(operationCode);
		
		operationCode = operationCode.next();
	end
	
	
	//testing for reset after all operations
	operationCode = operationCode.first();
	
	for(int i = 0; i<operationCode.num(); i++) begin
		
		tester(operationCode);
		resetAlu();
		
		operationCode = operationCode.next();
	end
	
	
	//testing all operations twice a row
	operationCode = operationCode.first();
	
	for(int i = 0; i < operationCode.num(); i++) begin
		
		for(int j = 0; j < 2; j++)begin
			tester(operationCode);
		end
		
		operationCode = operationCode.next();
	end
	

	if(testResultValidator == 1'b1)
		printTestResult(PASSED);
	else
		printTestResult(FAILED);
		
	$finish;
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
	
endtask : aluEnableReset;


task automatic resetAlu();
	`ifdef DEBUG
		$display("%0t DEBUG: reset_alu", $time);
	`endif
		//enable_n = 1'b1;
		rst_n = 1'b0;
		@(negedge clk);
		rst_n = 1'b1;
	
		@(posedge clk);
		@(posedge clk);
endtask : resetAlu

task tester(
	input opCodes operationCode);
	
	aluEnableSet();
	inputInjector(numberOfInputWords, operationCode);
	aluEnableReset();
		
	monitor();
		
	@(posedge clk);
	@(posedge clk);

endtask

task automatic inputInjector(
	input integer numberOfWords,
	input opCodes op);
	
	currCode = DATA;
	enable_n = 0;
	for(int i=0; i < numberOfWords; i++)begin
		singleCompleteWord currCompleteWord;
		
		currWord = getRandomData();
		currParity = calcParity(DATA, currWord);
		
		currCompleteWord[9] = currCode;
		currCompleteWord[8:1] = currWord;
		currCompleteWord[0] = currParity;
		inputWords[i] = currCompleteWord;
		wordSender({currCode, currWord, currParity});
	end
		
	currCode = OPCODE;
	currWord = op;
	currParity = calcParity(OPCODE, currWord);
	wordSender({currCode, currWord, currParity});
		
endtask : inputInjector


task automatic wordSender(
	input logic [9 : 0] word);

	for(int i = 9; i >= 0; i--)begin
		@(negedge clk) din = word[i];
	end
	
endtask : wordSender


task automatic monitor();
	threeWords resultDataTemp;
	integer wordsIterator;
	integer bitsIterator;
	singleCompleteWord currWord;
	
	currWord = 0;
	resultDataTemp = {currWord, currWord, currWord};
	
	@(posedge dout_valid);
	for(wordsIterator = 0; wordsIterator < 3; wordsIterator++)begin
		currWord = 0;
		
		for(bitsIterator = 9; bitsIterator >=0; bitsIterator--)begin
			@(posedge clk);
			currWord[bitsIterator] = dout;
		end
		
		resultDataTemp[wordsIterator] = currWord;
	end
	
	aluOutput = resultDataTemp;
	resultPrediction(operationCode);
	testIfPassed();
endtask : monitor


//------------------------------------------------------------------------------
// Function definitions
//------------------------------------------------------------------------------
function logic checkResultWithPredict();
	logic tempResult;
	
	if(statusCalculated == 10'h300) begin
		tempResult = (aluOutput[0] == statusCalculated) ? 1'b1 : 1'b0; 
	end
	else begin
		if ((aluOutput[0] == statusCalculated) && (aluOutput[1] == data[1]) && (aluOutput[2] == data[0]))
			tempResult = 1'b1;
		else 
			tempResult = 1'b0;
	end
	
	return tempResult;
endfunction : checkResultWithPredict


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


function void testIfPassed();
	logic tempVal;
	
	tempVal = checkResultWithPredict();
	testResultValidator = testResultValidator & tempVal;
endfunction : testIfPassed



function automatic void resultPrediction(opCodes opCode);
	
	//data prediction
	calcForAllArgs(opCode);
	
	//status prediction
	statusCalculated[9] = OPCODE;
	
	if(opCode == CMD_INVALID)begin
		statusCalculated[8:1] = S_INVALID_COMMAND;
		statusCalculated[0] = calcParity(OPCODE, S_INVALID_COMMAND);
	end
	else begin
		statusCalculated[8:1]  = S_NO_ERROR;
		statusCalculated[0] = calcParity(OPCODE, S_NO_ERROR);
	end
		
	
endfunction : resultPrediction


function logic calcParity(wordControllBit b, logic [7:0] word);
	logic parity;
	
	parity = b;
	foreach(word[i])begin
		parity = parity + word[i];
	end

	return parity;

endfunction


function void calcForAllArgs(input opCodes opCode);
	singleCompleteWord [1:0] tempOutput;
	singleCompleteWord singleWordOne, singleWordTwo;
	sixteenBitUnpacked res;
	logic [9:0] currWord;
	
	tempOutput = {10'b0000000000, 10'b0000000000};
	singleWordOne = 0;
	singleWordTwo = 0;
	currWord = 0;
	res = (opCode == CMD_AND) ? 16'hFF : 0;
	
	
	foreach(inputWords[i])begin
		currWord = inputWords[i];

		if(opCode == CMD_ADD)
			res = res + currWord[8:1];
		else if(opCode == CMD_AND)
			res = res & currWord[8:1];
		else 
			res = 0;
		
		inputWords[i] = 0;
	end
	
	singleWordOne[9] = DATA;
	singleWordOne[8:1] = res[7 : 0];
	singleWordOne[0] = calcParity(DATA, singleWordOne[8:1]);
	
	singleWordTwo[9] = DATA;
	singleWordTwo[8:1] = res[15 : 8];
	singleWordTwo[0] = calcParity(DATA, singleWordTwo[8:1]);
		
		
	data[0] = singleWordOne;
	data[1] = singleWordTwo;
	
endfunction : calcForAllArgs


//------------------------------------------------------------------------------
// Printing functions
//------------------------------------------------------------------------------
function void opcodeTesting(opCodes o, testingOption opt);
	string added ;
	added = opt ? "started" : "finished";
	
	case(o)
		
 		CMD_AND : begin
			setPrintColor(COLOR_BOLD_BLACK_ON_YELLOW);
			$write({"Testing of AND ", added});
			setPrintColor(COLOR_DEFAULT);
		end


 		CMD_ADD : begin
			setPrintColor(COLOR_BOLD_BLACK_ON_YELLOW);
			$write({"Testing of ADD ", added});
			setPrintColor(COLOR_DEFAULT);
		end


		default : begin
			setPrintColor(COLOR_DEFAULT);
		end
		
		endcase
endfunction : opcodeTesting


function void setPrintColor ( printColorT c );
	string ctl;
	case(c)
		COLOR_BOLD_BLACK_ON_GREEN : ctl  = "\033\[1;30m\033\[102m";
		COLOR_BOLD_BLACK_ON_RED : ctl    = "\033\[1;30m\033\[101m";
		COLOR_BOLD_BLACK_ON_YELLOW : ctl = "\033\[1;30m\033\[103m";
		COLOR_BOLD_BLUE_ON_WHITE : ctl   = "\033\[1;34m\033\[107m";
		COLOR_BLUE_ON_WHITE : ctl        = "\033\[0;34m\033\[107m";
		COLOR_DEFAULT : ctl              = "\033\[0m\n";
		default : begin
			$error("setPrintColor: bad argument");
			ctl                          = "";
		end
	endcase
	$write(ctl);
endfunction : setPrintColor


function void printTestResult (TestResult r);
	if(r == PASSED) begin
		setPrintColor(COLOR_BOLD_BLACK_ON_GREEN);
		$write ("-----------------------------------\n");
		$write ("----------- Test PASSED -----------\n");
		$write ("-----------------------------------");
		setPrintColor(COLOR_DEFAULT);
		$write ("\n");
	end
	else begin
		setPrintColor(COLOR_BOLD_BLACK_ON_RED);
		$write ("-----------------------------------\n");
		$write ("----------- Test FAILED -----------\n");
		$write ("-----------------------------------");
		setPrintColor(COLOR_DEFAULT);
		$write ("\n");
	end
endfunction : printTestResult


endmodule : vdic_dut_2022_1_0_tb
