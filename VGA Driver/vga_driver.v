// Seckin Burak Cengiz | Simple VGA-Driver

module vga_driver(
    output wire oHSync,
    output wire oVSync,
    input wire iCLK,
    input wire iRST,
	 output wire [9:0] oPosX,
	 output wire [9:0] oPosY,
	 output wire oVideoOn
    );		
	 
	 localparam LB = 48, //Left buffer
					HD = 640, //Horizontal display
					RB = 16, //Right buffer
					HRT = 96, //Horizontal refresh
					TB = 29, //Top Buffer
					VD = 480, //Vertical Display
					BB = 10, //Bottom buffer
					VRT = 2; //Vertical refresh
					
	 reg [9:0] mVCount, mHCount, mVCountNext, mHCountNext;
	 wire mHTick, mVTick;
	 
	 reg mLowCounter;
	 wire mLowCounterNext;
	 wire mLowClock;
	 
	 always@(posedge iCLK, posedge iRST)
	 begin
		if(iRST) begin
			mLowCounter <= 0;
			mHCount <= 0;
			mVCount <= 0;
		end
		else begin
			mLowCounter <= mLowCounterNext;
			mVCount <= mVCountNext;
			mHCount <= mHCountNext;
		end
	 end
	 
	 assign mLowCounterNext = ~mLowCounter;
	 assign mLowClock = mLowCounter;
	 
	 always@* begin
		mHCountNext = mHCount;
		if(mHTick && mLowClock) begin
			mHCountNext = 0;
		end
		else if(mLowClock) begin
			mHCountNext = mHCount + 1;
		end
	 end
	 
	 always@* begin
		mVCountNext = mVCount;
		if(mVTick && mHTick && mLowClock) begin
		 mVCountNext = 0;
	   end
		else if(mLowClock && mHTick) begin
			mVCountNext = mVCount + 1;
		end
	 end
	 
	 // Outputs
	 assign mHTick = (mHCount == (LB + HD + RB + HRT - 1));
	 assign mVTick = (mVCount == (TB + VD + BB + VRT - 1));
	 	
	 //assign oVideoOn = (mHCount < HD && mVCount < VD);
	 assign oHSync = (mHCount >= (HD + RB)) && (mHCount <= (RB + HD + HRT));
	 assign oVSync = (mVCount >= (VD + BB)) && (mVCount <= (BB + VD + VRT));
	 assign oPosX = mHCount;
	 assign oPosY = mVCount;
	 assign oVideoOn = (mHCount < HD && mVCount < VD);

endmodule
