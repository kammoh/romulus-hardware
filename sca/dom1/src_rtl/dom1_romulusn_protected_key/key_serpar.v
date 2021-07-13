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
   parameter d = 2;
   
   output [128*d-1:0] key;
   
   input [31:0]       sdi;
   input [128*d-1:0]  data_core, data_mode;
   input 	      wr, clk, en, crct;

   reg [128*d-1:0]    bfr;

   assign key = {bfr[255:224],bfr[191:160],bfr[127: 96],bfr[ 63: 32],
		 bfr[223:192],bfr[159:128],bfr[ 95: 64],bfr[ 31:  0]};
   
   always @ (posedge clk) begin
      if (wr) begin
         bfr <= {bfr[128*d-33:0], 
		 sdi};
      end
      else if (en) begin
         bfr <= {data_core[255:224],data_core[127: 96],
		 data_core[223:192],data_core[ 95: 64],
		 data_core[191:160],data_core[ 63: 32],
		 data_core[159:128],data_core[ 31:  0]};        
      end
      else if (crct) begin
	 bfr <= {data_mode[255:224],data_mode[127: 96],
		 data_mode[223:192],data_mode[ 95: 64],
		 data_mode[191:160],data_mode[ 63: 32],
		 data_mode[159:128],data_mode[ 31:  0]}; 
      end
   end
   
endmodule // key_serpar


