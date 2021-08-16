/*
 Designer: Mustafa Khairallah
 Nanyang Technological University
 Singapore
 Date: July, 2021
 */

/*
 This file is the basic implementation of the logic-based Skinny Sbox8.
 */

module skinny_sbox8_logic (
                     // Outputs
                     so,
                     // Inputs
                     si
                     ) ;
   output [7:0] so;
   input [7:0]  si;

   wire [7:0]   a;

   skinny_sbox8_cfn b764 (a[0],si[7],si[6],si[4]);
   skinny_sbox8_cfn b320 (a[1],si[3],si[2],si[0]);
   skinny_sbox8_cfn b216 (a[2],si[2],si[1],si[6]);
   skinny_sbox8_cfn b015 (a[3], a[0], a[1],si[5]);
   skinny_sbox8_cfn b131 (a[4], a[1],si[3],si[1]);
   skinny_sbox8_cfn b237 (a[5], a[2], a[3],si[7]);
   skinny_sbox8_cfn b303 (a[6], a[3], a[0],si[3]);
   skinny_sbox8_cfn b452 (a[7], a[4], a[5],si[2]);

   assign so[6] = a[0];
   assign so[5] = a[1];
   assign so[2] = a[2];
   assign so[7] = a[3];
   assign so[3] = a[4];
   assign so[1] = a[5];
   assign so[4] = a[6];
   assign so[0] = a[7];
   
endmodule // skinny_sbox8

// The core repeated function (x nor y) xor z
module skinny_sbox8_cfn (
                         // Outputs
                         f,
                         // Inputs
                         x, y, z
                         ) ;
   output f;
   input  x, y, z;

   assign f = ((~x) & (~y)) ^ z;
   
endmodule // skinny_sbox8_cfn
