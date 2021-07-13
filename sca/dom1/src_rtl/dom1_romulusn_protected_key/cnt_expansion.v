/*
 Designer: Mustafa Khairallah
 Nanyang Technological University
 Singapore
 Date: July, 2021
 */

/* 
 TK1 Key expansion corresponding to the 
 counter in Romulus. 
 */
module cnt_expansion (/*AUTOARG*/
   // Outputs
   ko,
   // Inputs
   ki
   ) ;
   output [63:0] ko;
   input  [63:0] ki;

   wire [63:0]   kp;

   assign kp[63:56] = ki[55:48];
   assign kp[55:48] = ki[ 7: 0];
   assign kp[47:40] = ki[63:56];
   assign kp[39:32] = ki[23:16];
   assign kp[31:24] = ki[47:40];
   assign kp[23:16] = ki[15: 8];
   assign kp[15: 8] = ki[31:24];
   assign kp[ 7: 0] = ki[39:32];

   assign ko = kp;
   
endmodule // cnt_expansion


