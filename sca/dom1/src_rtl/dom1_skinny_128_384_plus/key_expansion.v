/*
 Designer: Mustafa Khairallah
 Nanyang Technological University
 Singapore
 Date: July, 2021
 */

/* 
 TK3 Key expansion corresponding to the 
 secret key in Romulus. 
 */
module key_expansion (/*AUTOARG*/
   // Outputs
   ko,
   // Inputs
   ki
   ) ;
   output [127:0] ko;
   input  [127:0] ki;

   wire [127:0]   kp;

   assign kp[127:120] = ki[ 55: 48];
   assign kp[119:112] = ki[  7:  0];
   assign kp[111:104] = ki[ 63: 56];
   assign kp[103: 96] = ki[ 23: 16];
   assign kp[ 95: 88] = ki[ 47: 40];
   assign kp[ 87: 80] = ki[ 15:  8];
   assign kp[ 79: 72] = ki[ 31: 24];
   assign kp[ 71: 64] = ki[ 39: 32];
   assign kp[ 63: 56] = ki[127:120];
   assign kp[ 55: 48] = ki[119:112];
   assign kp[ 47: 40] = ki[111:104];
   assign kp[ 39: 32] = ki[103: 96];
   assign kp[ 31: 24] = ki[ 95: 88];
   assign kp[ 23: 16] = ki[ 87: 80];
   assign kp[ 15:  8] = ki[ 79: 72];
   assign kp[  7:  0] = ki[ 71: 64];

   assign ko[127:120] = {kp[120]^kp[126],kp[127:121]};
   assign ko[119:112] = {kp[112]^kp[118],kp[119:113]};
   assign ko[111:104] = {kp[104]^kp[110],kp[111:105]};
   assign ko[103: 96] = {kp[ 96]^kp[102],kp[103: 97]};
   assign ko[ 95: 88] = {kp[ 88]^kp[ 94],kp[ 95: 89]};
   assign ko[ 87: 80] = {kp[ 80]^kp[ 86],kp[ 87: 81]};
   assign ko[ 79: 72] = {kp[ 72]^kp[ 78],kp[ 79: 73]};
   assign ko[ 71: 64] = {kp[ 64]^kp[ 70],kp[ 71: 65]};

   assign ko[ 63:  0] = kp[ 63:  0];
   
endmodule // key_expansion
