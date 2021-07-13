/*
 Designer: Mustafa Khairallah
 Nanyang Technological University
 Singapore
 Date: July, 2021
 */


/*
 This serial to parallel buffer loads the key shares,
 rnd keys and corrected secret keys.
 */

module key_serpar (/*AUTOARG*/
   // Outputs
   key,
   // Inputs
   sdi, data_core, data_mode, wr, clk, en, crct
   ) ;
   parameter kd = 1;
   
   output [128*kd-1:0] key;
   
   input [31:0]       sdi;
   input [128*kd-1:0]  data_core, data_mode;
   input 	      wr, clk, en, crct;

   reg [128*kd-1:0]    bfr;

   assign key = bfr;
   
   always @ (posedge clk) begin
      if (wr) begin
         bfr <= {bfr[128*kd-33:0], 
		 sdi};
      end
      else if (en) begin
         bfr <= data_core;
      end
      else if (crct) begin
	 bfr <= data_mode;
      end
   end
   
endmodule // key_serpar


