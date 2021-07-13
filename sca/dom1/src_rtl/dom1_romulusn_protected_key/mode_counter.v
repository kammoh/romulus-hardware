/*
 Designer: Mustafa Khairallah
 Nanyang Technological University
 Singapore
 Date: July, 2021
 */


/*
 This module holds the counter and its corresponding 
 round keys.
 */

module mode_counter (/*AUTOARG*/
   // Outputs
   cnt,
   // Inputs
   data_core, data_mode, rst, clk, en, crct
   );
   
   output reg [63:0] cnt;
   
   input [63:0]      data_core, data_mode;
   input 	     rst, clk, en, crct;

   always @ (posedge clk) begin
      if (rst) begin
         cnt <= 64'h0100000000000000; 
      end
      else if (en) begin
         cnt <= data_core;       
      end
      else if (crct) begin
	 cnt <= data_mode;	 
      end
   end
   
endmodule // mode_counter



