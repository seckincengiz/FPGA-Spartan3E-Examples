// --------------------------------------------------------------------
//
// --------------------------------------------------------------------
// RS232 RECEIVING INTERFACE
// --------------------------------------------------------------------


module uart_rx
   #(
     parameter DBIT = 8,     // # data bits
               STOP_TICK = 16  // # ticks for stop bits
   )
   (
    input wire iCLK_50, 
    input wire iRST_N,
    input wire iRX, 
    input wire iBAUD_RATE_TICK,
    output reg oRECEIVED_TICK,
    output wire [7:0] oDATA
   );

   // symbolic state declaration
   localparam [1:0]
      idle  = 2'b00,
      start = 2'b01,
      data  = 2'b10,
      stop  = 2'b11;

   // signal declaration
   reg [1:0] state_reg, state_next;
   reg [3:0] s_reg, s_next;
   reg [2:0] n_reg, n_next;
   reg [7:0] b_reg, b_next;

// --------------------------------------------------------------------
// RS232 RECEIVING INTERFACE (SEQUENTIAL)
// --------------------------------------------------------------------
   always @(posedge iCLK_50, negedge iRST_N)
      if (!iRST_N)
         begin
            state_reg <= idle;
            s_reg <= 0;
            n_reg <= 0;
            b_reg <= 0;
         end
      else
         begin
            state_reg <= state_next;
            s_reg <= s_next;
            n_reg <= n_next;
            b_reg <= b_next;
         end

// --------------------------------------------------------------------
// RS232 RECEIVING INTERFACE (COMBINATIONAL) , NEXT STATE
// --------------------------------------------------------------------
   always @*
   begin
      state_next = state_reg;
      oRECEIVED_TICK = 1'b0;
      s_next = s_reg;
      n_next = n_reg;
      b_next = b_reg;
      case (state_reg)
         idle:  // idle state
            if (~iRX) //received incoming signal 0
               begin
                  state_next = start;
                  s_next = 0;
               end
         start: // count up to 7 to reach the middle of start data bit
            if (iBAUD_RATE_TICK)
               if (s_reg==7)
                  begin
                     state_next = data;
                     s_next = 0;
                     n_next = 0;
                  end
               else
                  s_next = s_reg + 1;
         data: // receive data
            if (iBAUD_RATE_TICK)
               if (s_reg==15)
                  begin
                     s_next = 0;
                     b_next = {iRX, b_reg[7:1]};
                     if (n_reg==(DBIT-1))
                        state_next = stop ;
                      else
                        n_next = n_reg + 1;
                   end
               else
                  s_next = s_reg + 1;
         stop: // stop
            if (iBAUD_RATE_TICK)
               if (s_reg==(STOP_TICK-1))
                  begin
                     state_next = idle;
                     oRECEIVED_TICK =1'b1;
                  end
               else
                  s_next = s_reg + 1;
      endcase
   end
   // output
   assign oDATA = b_reg;

endmodule
