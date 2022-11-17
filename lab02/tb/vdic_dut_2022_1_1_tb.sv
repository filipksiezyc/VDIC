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
parameter numberOfInputWords = 9;

    
//------------------------------------------------------------------------------
// Type definitions
//------------------------------------------------------------------------------
typedef logic [9:0] singleCompleteWord;
typedef logic [15:0] sixteenBitUnpacked; 
typedef logic [9:0] threeWords [2:0]; 



//------------------------------------------------------------------------------
// Enumerations
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
	

typedef enum logic[7:0] {
	CMD_INV   = 8'b00011011,
	CMD_NOP   = 8'b00000000,
 	CMD_AND   = 8'b00000001, 
 	CMD_OR    = 8'b00000010,
 	CMD_XOR   = 8'b00000011, 
 	CMD_ADD   = 8'b00010000, 
 	CMD_SUB   = 8'b00100000  

} opCodes;
	

typedef enum logic[7:0] {
	CMD_INV_tb   = 8'b00011011,
	CMD_NOP_tb   = 8'b00000000,
 	CMD_AND_tb   = 8'b00000001, 
 	CMD_OR_tb    = 8'b00000010,
 	CMD_XOR_tb   = 8'b00000011, 
 	CMD_ADD_tb   = 8'b00010000, 
 	CMD_SUB_tb   = 8'b00100000,
 	CMD_RST_tb   = 8'b00110011

} opCodesTb;


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
	
	
typedef enum {
	NORMAL,
	MIN_VAL,
	MAX_VAL
} cornerType;


//------------------------------------------------------------------------------
// Inputs and outputs
//------------------------------------------------------------------------------
logic clk;
logic rst_n;
logic enable_n;
logic din;
logic dout;
logic dout_valid;

//BUG when invalid output data should be 0 (actually is nonzero);
//BUG documentation states that should "and" just two last arguments but ALU and'ing all input arguments so i do the same 

	
//------------------------------------------------------------------------------
// Task Communication
//------------------------------------------------------------------------------
logic currCode;
logic currParity;
logic [7:0] currWord;

opCodes operationCode;
opCodesTb opTbExclusive;
logic [9:0] inputWords [numberOfInputWords - 1 : 0];

logic [9:0] statusCalculated;
singleCompleteWord[1:0] data;
	
threeWords aluOutput;
	
	
logic done;

TestResult testResult;
	
//------------------------------------------------------------------------------
// Covergroups
//------------------------------------------------------------------------------

covergroup op_cov;

    option.name = "cg_op_cov";

    all_ops : coverpoint opTbExclusive {
        // #A1 test all operations
        bins A1_single_cycle[] = {[CMD_INV_tb : CMD_SUB_tb], CMD_RST_tb};
    }
    
    all_ops_twice_a_row : coverpoint opTbExclusive{
	    // #A2 two operations in row
        bins A2_twoops[]       = ([CMD_INV_tb : CMD_SUB_tb] [* 2]);
    }
    
    rst_after_ops : coverpoint opTbExclusive{
	    // #A3 reset after all operations
	    bins A3_rst_after_ops[] = ([CMD_INV_tb : CMD_SUB_tb] => CMD_RST_tb);
    } 
    
    ops_after_rst : coverpoint opTbExclusive{
	    // #A3 reset after all operations
	    bins A4_ops_after_rst[] = (CMD_RST_tb => [CMD_INV_tb : CMD_SUB_tb]);
    }
endgroup


// Covergroup checking for min and max arguments of the ALU
covergroup zeros_or_ones_on_ops with function sample(logic [7:0] word);

    option.name = "cg_zeros_or_ones_on_ops";

    all_ops : coverpoint opTbExclusive {
        ignore_bins null_ops = {CMD_RST_tb, CMD_INV_tb, CMD_NOP_tb};
    }

    input_val: coverpoint word {
        bins zeros = {'h00};
        bins others= {['h01:'hFE]};
        bins ones  = {'hFF};
    }
    

    B_op_00_FF: cross input_val, all_ops {

        // #B1 simulate all zero input for all the operations

        bins B1_add_00          = binsof (all_ops) intersect {CMD_ADD_tb} && binsof (input_val.zeros);

        bins B1_and_00          = binsof (all_ops) intersect {CMD_AND_tb} && binsof (input_val.zeros);

        bins B1_xor_00          = binsof (all_ops) intersect {CMD_XOR_tb} && binsof (input_val.zeros);

        bins B1_or_00           = binsof (all_ops) intersect {CMD_OR_tb}  && binsof (input_val.zeros);
	    
	    bins B1_sub_00          = binsof (all_ops) intersect {CMD_SUB_tb} && binsof (input_val.zeros);

        // #B2 simulate all one input for all the operations

        bins B2_add_FF          = binsof (all_ops) intersect {CMD_ADD_tb} && binsof (input_val.ones);

        bins B2_and_FF          = binsof (all_ops) intersect {CMD_AND_tb} && binsof (input_val.ones);

        bins B2_xor_FF          = binsof (all_ops) intersect {CMD_XOR_tb} && binsof (input_val.ones);

        bins B2_or_FF           = binsof (all_ops) intersect {CMD_OR_tb} && binsof (input_val.ones);

        bins B2_sub_FF          = binsof (all_ops) intersect {CMD_SUB_tb} && binsof (input_val.ones);


        ignore_bins others_only = binsof(input_val.others);
    }

endgroup


//------------------------------------------------------------------------------
// Coverage
//------------------------------------------------------------------------------

op_cov oc;
zeros_or_ones_on_ops z_or_o;

initial begin : coverage
    oc = new();
	z_or_o = new();
	
	fork
    forever begin : sample_ops
        @(posedge clk);
        oc.sample();
	    
    end
    
    forever begin : sample_values
	    @(posedge done);
	    foreach(inputWords[i])
		    z_or_o.sample(inputWords[i][8:1]);
    end
    join
end : coverage


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
	operationCode = operationCode.first();
	opTbExclusive = opTbExclusive.first();
	testResult = PASSED;
	din = 0;
	done = 1'b0;
	
	aluEnableReset();
	
	resetAlu();
	
	//testing for all operations
	for(int i = 0; i < operationCode.num(); i++) begin
		
		tester(operationCode, NORMAL);
		tester(operationCode, MAX_VAL);
		tester(operationCode, MIN_VAL);
		
		operationCode = operationCode.next();
	end
	
	
	//testing for all operations after reset
	operationCode = operationCode.first();
	
	for(int i = 0; i < operationCode.num(); i++) begin
		
		resetAlu();
		tester(operationCode, NORMAL);
		tester(operationCode, MAX_VAL);
		tester(operationCode, MIN_VAL);
		
		operationCode = operationCode.next();
	end
	
	
	//testing for reset after all operations
	operationCode = operationCode.first();
	
	for(int i = 0; i<operationCode.num(); i++) begin
		
		tester(operationCode, NORMAL);
		tester(operationCode, MAX_VAL);
		tester(operationCode, MIN_VAL);
		resetAlu();
		
		operationCode = operationCode.next();
	end
	
	
	//testing all operations twice a row
	operationCode = operationCode.first();
	
	for(int i = 0; i < operationCode.num(); i++) begin
		
		for(int j = 0; j < 2; j++)begin
			tester(operationCode, NORMAL);
			tester(operationCode, MAX_VAL);
			tester(operationCode, MIN_VAL);
		end
		
		operationCode = operationCode.next();
	end
	    
	operationCode = CMD_INV;
	for(int j = 0; j < 2; j++)begin
		tester(operationCode, NORMAL);
		tester(operationCode, MAX_VAL);
		tester(operationCode, MIN_VAL);
	end
	
	operationCode = CMD_SUB;
	for(int j = 0; j < 2; j++)begin
		tester(operationCode, NORMAL);
		tester(operationCode, MAX_VAL);
		tester(operationCode, MIN_VAL);
	end
	
	$finish;
end
//------------------------------------------------------------------------------
// Scoreboard
//------------------------------------------------------------------------------
always @(negedge clk) begin : scoreboard
    if(done == 1) begin:verify_result
	    logic [19:0] result;
	    logic testResultValidator;
	    logic tempVal;
	    
	    result[9:0] <= aluOutput[0];
	    result[19:10] <= aluOutput[1];
	    testResultValidator = 1'b1;
	    
        resultPrediction(operationCode);
		
		tempVal = checkResultWithPredict();
		testResultValidator = testResultValidator & tempVal;

        CHK_RESULT: assert(testResultValidator === 1'b1) begin
           `ifdef DEBUG
            $write("%0t Test passed for op_set=%0d and arguments: ", $time, operationCode);
	        foreach(inputWords[i])begin
		        $write("%0d, ", inputWords[i]);
		    end
           `endif
        end
        else begin
            $error("%0t Test FAILED for op_set=%s\nExpected: %d  received: %d",
            $time, operationCode.name() , data, result);
	        $write("Input arguments used: ");
	        foreach(inputWords[i])begin
		        $write("%0d, ", inputWords[i]);
	        end
	        $display("\n");
	        testResult <= FAILED;
        end;
    	
    	done <= 0;
    end
end : scoreboard


final begin
	printTestResult(testResult);
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


task tester(
	input logic [7:0] operationCode,
	cornerType cornertype);
	
	
	aluEnableSet();
	inputInjector(numberOfInputWords, operationCode, cornertype);
	aluEnableReset();
		
	monitor();
		
	@(posedge clk);
	@(posedge clk);

endtask


task automatic inputInjector(
	input integer numberOfWords,
	input logic [7:0] op,
	cornerType cornertype);
	
	currCode = DATA;
	enable_n = 0;
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
		inputWords[i] = currCompleteWord;
		wordSender({currCode, currWord, currParity});
	end
		
	currCode = OPCODE;
	currWord = op;
	$cast(opTbExclusive, op);
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
	done = 1;
endtask : monitor


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


function automatic void resultPrediction(opCodes opCode);
	logic inEnum;
	opCodes opCodeIterator;
	
	//data prediction
	calcForAllArgs(opCode);
	
	//status prediction
	statusCalculated[9] = OPCODE;
	
	inEnum = 1'b0;
	opCodeIterator = opCodeIterator.first();
	
	
	for(int i = 0; i < opCodeIterator.num(); i++)begin
		if(opCode != opCodeIterator)
			opCodeIterator = opCodeIterator.next();
		else begin
			inEnum = 1'b1;
			break;
		end
	end
	
	
	if(!inEnum)begin
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


function void calcForAllArgs(input byte opCode);
	singleCompleteWord [1:0] tempOutput;
	singleCompleteWord singleWordOne, singleWordTwo;
	sixteenBitUnpacked res;
	sixteenBitUnpacked mid;
	logic [9:0] currWord;
	logic [1:0] twoWordsCounter;
	
	tempOutput = {10'b0000000000, 10'b0000000000};
	singleWordOne = 0;
	singleWordTwo = 0;
	currWord = 0;
	res = '0;
	mid = '0;
	twoWordsCounter = 0;
	
	inputWords.reverse();
	foreach(inputWords[i])begin
		currWord = inputWords[i];

		case(opCode)
			CMD_NOP : res = '0;
			
			CMD_ADD : res = res + currWord[8:1];
			
			CMD_AND : begin
				mid[7:0] = currWord[8:1]; 
				if(twoWordsCounter < 2)begin
	 				if(twoWordsCounter == 0)begin
		 				res = mid;
	 				end
	 				else begin
		 				res = res & mid; 
		 			end
		 			twoWordsCounter++;
				end
				else begin
					res = res;
				end
		    end
		    
		    CMD_OR  : res = res | currWord[8:1];
 			
 			CMD_XOR : res = res ^ currWord[8:1]; 
 			
 			CMD_SUB : begin
	 			mid[7:0] = currWord[8:1]; 
	 			if(twoWordsCounter == 0)begin
		 			res = mid;
		 			twoWordsCounter++;
	 			end
	 			else begin
		 			res = res - mid; 
		 		end
	 		end 
			
			default : 
				res = '0;
		endcase
		
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
