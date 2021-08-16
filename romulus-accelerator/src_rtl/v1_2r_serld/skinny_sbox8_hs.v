/*
 Designer: Mustafa Khairallah
 Nanyang Technological University
 Singapore
 Date: July, 2021
 */

/*
 A shorter logic depth variant of Skinny Sbox8.
 */
module skinny_sbox8_hs (
                        // Outputs
                        so,
                        // Inputs
                        si
                        ) ;
   output [7:0] so;
   input [7:0]  si;

   wire [7:0]   a;

   assign a[0] = ((~si[7]) & (~si[6])) ^ si[4];
   assign a[1] = ((~si[3]) & (~si[2])) ^ si[0];
   assign a[2] = ((~si[2]) & (~si[1])) ^ si[6];
   assign a[3] = ((~si[7]) & (~si[6]) & (~si[3]) & (~si[2])) ^
                 ((~si[7]) & (~si[6]) & (~si[0])) ^
                 ((~si[4]) & (~si[3]) & (~si[2])) ^
                 ((~si[4]) & (~si[0])) ^
                 si[5];
   assign a[4] = ((~si[3]) & (~si[2])) ^
                 ((~si[0]) & (~si[3])) ^
                 si[1];
   assign a[5] = ((~a[2]) & (~a[3])) ^ si[7];
   assign a[6] = ((~a[3]) & (~a[0])) ^ si[3];
   assign a[7] = ((~a[2]) & (~a[3]) & (~a[4])) ^
                 ((~si[7]) & (~a[4])) ^
                 si[2];

   assign so[6] = a[0];
   assign so[5] = a[1];
   assign so[2] = a[2];
   assign so[7] = a[3];
   assign so[3] = a[4];
   assign so[1] = a[5];
   assign so[4] = a[6];
   assign so[0] = a[7];
   
endmodule // skinny_sbox8_hs
