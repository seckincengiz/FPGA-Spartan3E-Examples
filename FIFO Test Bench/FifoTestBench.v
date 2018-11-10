/********************
*
* FIFO DEFINES!!
*
********************/

`define CQ_DELAY	1	
`define DEPTH 15	
`define HALF_FULL 8	
`define WIDTH 8	

module FifoTestBench();

//TEST-BENCH RELATED  
reg						mQuickReadFlag;		// Clock change for fast read
reg						mQuickWriteFlag;		// Clock change for fast write
reg						mIsSimulationEnded;	// testbench end of simulation!!
reg  [`WIDTH-1:0]	mExpectedData;  	//testbench - fifo
integer					mFifoElementNo;		// number of elements in fifo


// FIFO CONNECTING SIGNALS!!!
reg						mCLR_N; // clear
reg  [`WIDTH-1:0]	miData; // input data
reg						mReadCLK_N; // read clk
reg						mWriteCLK_N; // write clk
wire [`WIDTH-1:0]	moData; // outdata
wire					mIsFull; // is full
wire					mIsEmpty; // is empty
wire					mIsHalfFull; // is half full



//YOUR CODE GOES HERE

Fifo 
  #
  (
    .DEPTH(`DEPTH + 1),
    .HALF_FULL(`HALF_FULL),
    .WIDTH(`WIDTH)  
  )
  
  fifo
  (
    .iRSTN(mCLR_N),
    .iData(miData),
    .iRDCLKN(mReadCLK_N),
    .iWRCLKN(mWriteCLK_N),
    .oData(moData),
    .oFull(mIsFull),
    .oEmpty(mIsEmpty),
    .oHalfFull(mIsHalfFull)
  );

//END OF YOUR CODE!!

		

// INIT
initial begin
	miData = 0;
	mExpectedData = 0;
	mFifoElementNo = 0;
	mReadCLK_N = 1;
	mCLR_N=1;
	mWriteCLK_N = 1;
	mIsSimulationEnded = 0;

	// START WITH QUICK WRITE
	mQuickWriteFlag = 1;
	
	// NO QUICK READ
	mQuickReadFlag = 0;

	// RESET!!!
	mCLR_N = 0;
	#20 mCLR_N = 1;

	//INITIAL CHECKS!!!
	if (mIsEmpty !== 1) begin
		$display("\nERROR at time %0t:", $time);
		$display("RESET REQUIRES mIsEmpty SHOULD BE ASSERTED!!!\n");
		$stop;
	end
	if (mIsFull !== 0) begin
		$display("\nERROR at time %0t:", $time);
		$display("RESET REQUIRES mIsFull SHOULD BE DEASSERTED\n");
		$stop;
	end
	if (mIsHalfFull !== 0) begin
		$display("\nERROR at time %0t:", $time);
		$display("RESET REQUIRES mIsHalfFull SHOULD BE DEASSERTED\n");
		$stop;
	end
  //INITIAL WRITE/READ SCHEDULING
	mWriteCLK_N <= #40 0;
	mReadCLK_N <= #80 0;
end

//WRITE TEST
always @(negedge mWriteCLK_N) begin
	// ++
	mFifoElementNo = mFifoElementNo + 1;

	// make it high
	#10 mWriteCLK_N = 1;

	// Make Next Data  Ready
	#10 miData = miData + 1;

	// Fifo full , do not write
	wait (mIsFull === 0);

	// Arrange next negedge!!
	if (mQuickWriteFlag === 1)
		mWriteCLK_N <= #10 0;
	else
		mWriteCLK_N <= #30 0;
end



// READ TEST!!!
always @(negedge mReadCLK_N) begin
	// --
	mFifoElementNo = mFifoElementNo - 1;

	// Next negedge
	if (mQuickReadFlag === 1)
		#10;
	else
		#30;

  //TESTING OF THE DATA
	if (moData !== mExpectedData) begin
		$display("\nERROR at time %0t:", $time);
		$display("EXPECTED DATA = %h", mExpectedData);
		$display("INCOMING DATA = %h\n", moData);
				
		$stop;
	end

	// Make it high
	mReadCLK_N = 1;

	// Next read data must be one plus of the previous
	mExpectedData = mExpectedData + 1;

  // If empty, wait
	wait (mIsEmpty === 0);

	// Next Read scheduling
	mReadCLK_N <= #20 0;
end


//TESTING ON EVERY TIMES A READ / WRITE OCCURS
always @(mFifoElementNo) begin
	// Wait a moment to evaluate everything
	#`CQ_DELAY;
	#`CQ_DELAY
	#`CQ_DELAY;

	case (mFifoElementNo)
		0: begin
			if ((mIsEmpty !== 1) || (mIsHalfFull !== 0) ||
					(mIsFull !== 0)) begin
			  $display("\nWHILE FIFO IS EMPTY; WE ENCOUNTERED : \n");
				$display("\nERROR at time %0t:", $time);
				$display("    mFifoElementNo = %h", mFifoElementNo);
				$display("    mIsEmpty = %b", mIsEmpty);
				$display("    mIsHalfFull  = %b", mIsHalfFull);
				$display("    mIsFull  = %b\n", mIsFull);
						
				$stop;
			end

			if (mIsSimulationEnded === 1) begin
				// The FIFO has filled and emptied
				$display("\nSimulation complete - no errors\n");
				$finish;
			end
		end
		`HALF_FULL: begin
			if ((mIsEmpty !== 0) || (mIsHalfFull !== 1) ||
					(mIsFull !== 0)) begin
        $display("\nWHILE FIFO IS HALF FULL; WE ENCOUNTERED : \n");					  
				$display("\nERROR at time %0t:", $time);
				$display("    mFifoElementNo = %h", mFifoElementNo);
				$display("    mIsEmpty = %b", mIsEmpty);
				$display("    mIsHalfFull  = %b", mIsHalfFull);
				$display("    mIsFull  = %b\n", mIsFull);
						
				$stop;
			end
		end
		`DEPTH: begin
			if ((mIsEmpty !== 0) || (mIsHalfFull !== 1) ||
					(mIsFull !== 1)) begin
        $display("\nWHILE FIFO IS FULL; WE ENCOUNTERED : \n");					  
				$display("\nERROR at time %0t:", $time);
				$display("    mFifoElementNo = %h", mFifoElementNo);
				$display("    mIsEmpty = %b", mIsEmpty);
				$display("    mIsHalfFull  = %b", mIsHalfFull);
				$display("    mIsFull  = %b\n", mIsFull);
						
				$stop;
			end

			// FIFO IS FILLED - END OF SIMULATION
			mIsSimulationEnded = 1;

      //FROM NOW ON, IT IS NICE TO WRITE SLOWLY!!
			mQuickWriteFlag = 0;
			// AND WITH QUICK READING!!!
			mQuickReadFlag = 1;
		end
		default: begin
			if ((mIsEmpty !== 0) || (mIsFull !== 0)) begin
				$display("\nERROR at time %0t:", $time);
				$display("    mFifoElementNo = %h", mFifoElementNo);
				$display("    mIsEmpty = %b", mIsEmpty);
				$display("    mIsHalfFull  = %b", mIsHalfFull);
				$display("    mIsFull  = %b\n", mIsFull);						
				$stop;
			end
			if (((mFifoElementNo < `HALF_FULL) &&
					(mIsHalfFull === 1)) ||
				((mFifoElementNo >= `HALF_FULL) &&
					(mIsHalfFull === 0))) begin
				$display("\nHALF FULL AND # OF ELEMENTS DO NOT COMPLY :\n");	  
				$display("\nERROR at time %0t:", $time);
				$display("    mFifoElementNo = %h", mFifoElementNo);
				$display("    mIsEmpty = %b", mIsEmpty);
				$display("    mIsHalfFull  = %b", mIsHalfFull);
				$display("    mIsFull  = %b\n", mIsFull);
						
				$stop;
			end
		end
	endcase
end
endmodule