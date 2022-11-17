module scoreboard(alu_bfm bfm);

import alu_pkg::*;

//------------------------------------------------------------------------------
// Scoreboard
//------------------------------------------------------------------------------
initial forever begin : scoreboard
	@(negedge bfm.clk) 
    if(bfm.done == 1) begin:verify_result
	    logic [19:0] result;
	    logic testResultValidator;
	    logic tempVal;
	    
	    result[9:0] <= bfm.aluOutput[0];
	    result[19:10] <= bfm.aluOutput[1];
	    testResultValidator = 1'b1;
	    
        resultPrediction(bfm.operationCode);
		
		tempVal = checkResultWithPredict();
		testResultValidator = testResultValidator & tempVal;

        CHK_RESULT: assert(testResultValidator === 1'b1) begin
           `ifdef DEBUG
            $write("%0t Test passed for op_set=%0d and arguments: ", $time, bfm.operationCode);
	        foreach(bfm.inputWords[i])begin
		        $write("%0d, ", bfm.inputWords[i]);
		    end
           `endif
        end
        else begin
            $error("%0t Test FAILED for op_set=%s\nExpected: %d  received: %d",
            $time, bfm.operationCode.name() , bfm.data, result);
	        $write("Input arguments used: ");
	        foreach(bfm.inputWords[i])begin
		        $write("%0d, ", bfm.inputWords[i]);
	        end
	        $display("\n");
	        bfm.testResult <= FAILED;
        end;
    	
    	bfm.done <= 0;
    end
end : scoreboard


final begin
	printTestResult(bfm.testResult);
end

//------------------------------------------------------------------------------
// Tasks definitions
//------------------------------------------------------------------------------


function logic checkResultWithPredict();
	logic tempResult;
	
	if(bfm.statusCalculated == 10'h300) begin
		tempResult = (bfm.aluOutput[0] == bfm.statusCalculated) ? 1'b1 : 1'b0; 
	end
	else begin
		if ((bfm.aluOutput[0] == bfm.statusCalculated) && (bfm.aluOutput[1] == bfm.data[1]) && (bfm.aluOutput[2] == bfm.data[0]))
			tempResult = 1'b1;
		else 
			tempResult = 1'b0;
	end
	
	return tempResult;
endfunction : checkResultWithPredict




function automatic void resultPrediction(opCodes opCode);
	logic inEnum;
	opCodes opCodeIterator;
	
	//data prediction
	calcForAllArgs(opCode);
	
	//status prediction
	bfm.statusCalculated[9] = OPCODE;
	
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
		bfm.statusCalculated[8:1] = S_INVALID_COMMAND;
		bfm.statusCalculated[0] = calcParity(OPCODE, S_INVALID_COMMAND);
	end
	else begin
		bfm.statusCalculated[8:1]  = S_NO_ERROR;
		bfm.statusCalculated[0] = calcParity(OPCODE, S_NO_ERROR);
	end
		
	
endfunction : resultPrediction



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
	
	bfm.inputWords.reverse();
	foreach(bfm.inputWords[i])begin
		currWord = bfm.inputWords[i];

		case(opCode)
			CMD_NOP : res = '0;
			
			CMD_ADD : res = res + currWord[8:1];
			
			CMD_AND : res = res & currWord[8:1]; 
		    
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
		
		
	bfm.data[0] = singleWordOne;
	bfm.data[1] = singleWordTwo;
	
endfunction : calcForAllArgs


//------------------------------------------------------------------------------
// Function definitions
//------------------------------------------------------------------------------

function logic calcParity(wordControllBit b, logic [7:0] word);
	logic parity;
	
	parity = b;
	foreach(word[i])begin
		parity = parity + word[i];
	end

	return parity;

endfunction
//------------------------------------------------------------------------------
// Printing functions
//------------------------------------------------------------------------------

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


endmodule : scoreboard