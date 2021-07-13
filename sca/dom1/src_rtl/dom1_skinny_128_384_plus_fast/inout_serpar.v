/*
 Designer: Mustafa Khairallah
 Nanyang Technological University
 Singapore
 Date: July, 2021
 */


/*
 This serial to parallel buffer takes the input byte-wise
 for one invocation of the masked cipher, and is then loaded
 into the cipher core in parallel. The output also can be
 read in byte-serial, starting from the most significant 
 bytes.
 */

module inout_serpar (/*AUTOARG*/
   // Outputs
   bfr, data_out,
   // Inputs
   data_in, data_core, wr, rd, clk, en, ken
   ) ;
   output reg [128*7-1:0] bfr;
   output [7:0]           data_out;
   
   input [7:0]            data_in;
   input [128*7-1:0]      data_core;
   input                  wr, rd, clk, en, ken;

   reg [6:0]              cnt;

   assign data_out = bfr[128*7-1:128*7-8];

   always @ (posedge clk) begin
      if (wr) begin
         bfr <= {bfr[128*7-9:0], data_in};
      end
      else if (rd) begin
         bfr <= {bfr[128*7-9:0], 8'h00};
      end
      else if (en) begin
         bfr <= {data_core[128*7-1:128*5],bfr[128*5-1:0]};       
      end
      else if (ken) begin
 	 bfr <= {bfr[128*7-1:128*5],data_core[128*5-1:0]};       
      end
   end
   
endmodule // inout_serpar

