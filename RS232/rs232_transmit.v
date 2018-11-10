// --------------------------------------------------------------------
//
// --------------------------------------------------------------------
// RS232 TRANSMITTING INTERFACE
// --------------------------------------------------------------------
module uart_tx
   #(
     parameter DBIT = 8,     // # data bits
               STOP_TICK = 16  // # ticks for stop bits
   )
   (
    input wire iCLK_50, 
    input wire iRST_N,
    input wire iTX_START, 
    input wire iBAUD_RATE_TICK,
    input wire [7:0] iDATA,
    output reg oTRANSMITTED_TICK,
    output wire oTX
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
   reg tx_reg, tx_next;

// --------------------------------------------------------------------
// RS232 TRANSMITTING INTERFACE (SEQUENTIAL)
// --------------------------------------------------------------------
   always @(posedge iCLK_50, negedge iRST_N)
      if (!iRST_N)
         begin
            state_reg <= idle;
            s_reg <= 0;
            n_reg <= 0;
            b_reg <= 0;
            tx_reg <= 1'b1;
         end
      else
         begin
            state_reg <= state_next;
            s_reg <= s_next;
            n_reg <= n_next;
            b_reg <= b_next;
            tx_reg <= tx_next;
         end

// --------------------------------------------------------------------
// RS232 TRANSMITTING INTERFACE (COMBINATIONAL) NEXT STATE
// --------------------------------------------------------------------
   always @*
   begin
      state_next = state_reg;
      oTRANSMITTED_TICK = 1'b0;
      s_next = s_reg;
      n_next = n_reg;
      b_next = b_reg;
      tx_next = tx_reg ;
      case (state_reg)
         idle:// idle state
            begin 
               tx_next = 1'b1;
               if (iTX_START) // start signal
                  begin
                     state_next = start;
                     s_next = 0;
                     b_next = iDATA;
                  end
            end
         start: //SENDING START BIT
            begin
               tx_next = 1'b0;
               if (iBAUD_RATE_TICK)
                  if (s_reg==15)
                     begin
                        state_next = data;
                        s_next = 0;
                        n_next = 0;
                     end
                  else
                     s_next = s_reg + 1;
            end
         data: // SENDING DATA
            begin
               tx_next = b_reg[0];
               if (iBAUD_RATE_TICK)
                  if (s_reg==15)
                     begin
                        s_next = 0;
                        b_next = b_reg >> 1;
                        if (n_reg==(DBIT-1))
                           state_next = stop ;
                        else
                           n_next = n_reg + 1;
                     end
                  else
                     s_next = s_reg + 1;
            end
         stop: // STOP
            begin
               tx_next = 1'b1;
               if (iBAUD_RATE_TICK)
                  if (s_reg==(STOP_TICK-1))
                     begin
                        state_next = idle;
                        oTRANSMITTED_TICK = 1'b1;
                     end
                  else
                     s_next = s_reg + 1;
            end
      endcase
   end
   // output
   assign oTX = tx_reg;

endmodule
