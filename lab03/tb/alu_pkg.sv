package alu_pkg;

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
	
endpackage : alu_pkg	
	