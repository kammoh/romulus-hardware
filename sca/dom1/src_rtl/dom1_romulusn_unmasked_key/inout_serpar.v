/*
 Designer: Mustafa Khairallah
 Nanyang Technological University
 Singapore
 Date: July, 2021
 */


/*
 This serial to parallel buffer loads the input blocks into
 the TBC state with 32-bit resolution. It automatically
 applies the mode's combined feedback on the fly for
 both encryption and decryption. The shares are fed per word,
 i.e., all the shares of a 32-bit word are loaded before the
 next word. When communicating with the cipher logic, it has
 to be interleaved and de-interleaved, which can be done for
 free.
 */

module inout_serpar (/*AUTOARG*/
   // Outputs
   state, pdo,
   // Inputs
   pdi, data_core, decrypt, wr, clk, en, rst
   ) ;
   parameter d = 2;
   
   output [128*d-1:0] state;  
   output [31:0]      pdo;
   
   input [31:0]       pdi;
   input [128*d-1:0]  data_core;
   input [3:0] 	      decrypt;
   input 	      wr, clk, en, rst;   

   wire [31:0] 	      pdi_eff;
   wire [31:0] 	      gofs;
   wire [31:0] 	      state_buf;
   
   reg [128*d-1:0]    bfr;
   
   assign state_buf = bfr[128*d-1:128*d-32];   

   assign pdi_eff[ 7: 0] = decrypt[0] ? pdo[ 7: 0] : pdi[ 7: 0];
   assign pdi_eff[15: 8] = decrypt[1] ? pdo[15: 8] : pdi[15: 8];
   assign pdi_eff[23:16] = decrypt[2] ? pdo[23:16] : pdi[23:16];
   assign pdi_eff[31:24] = decrypt[3] ? pdo[31:24] : pdi[31:24];

   assign gofs[ 7: 0] = {state_buf[ 0]^state_buf[ 7],state_buf[ 7: 1]};
   assign gofs[15: 8] = {state_buf[ 8]^state_buf[15],state_buf[15: 9]};
   assign gofs[23:16] = {state_buf[16]^state_buf[23],state_buf[23:17]};
   assign gofs[31:24] = {state_buf[24]^state_buf[31],state_buf[31:25]};
   
   assign pdo = pdi ^ gofs;

   assign state = {bfr[255:224],bfr[191:160],bfr[127: 96],bfr[ 63: 32],
		   bfr[223:192],bfr[159:128],bfr[ 95: 64],bfr[ 31:  0]};   

   always @ (posedge clk) begin
      if (rst) begin
	 bfr <= 0;	 
      end
      else if (wr) begin
         bfr <= {bfr[128*d-33:0], 
		 pdi_eff ^ bfr[128*d-1:128*d-32]};
      end
      else if (en) begin
         bfr <= {data_core[255:224],data_core[127: 96],
		 data_core[223:192],data_core[ 95: 64],
		 data_core[191:160],data_core[ 63: 32],
		 data_core[159:128],data_core[ 31:  0]};       
      end
   end // always @ (posedge clk)
   
   
endmodule // inout_serpar

