module sboxlayer (/*AUTOARG*/
   // Outputs
   so,
   // Inputs
   si
   ) ;
   output [127:0] so;
   input [127:0]  si;

   skinny_sbox8_hs sbox15 (so[127:120],si[127:120]);
   skinny_sbox8_hs sbox14 (so[119:112],si[119:112]);
   skinny_sbox8_hs sbox13 (so[111:104],si[111:104]);
   skinny_sbox8_hs sbox12 (so[103:96],si[103:96]);
   skinny_sbox8_hs sbox11 (so[95:88],si[95:88]);
   skinny_sbox8_hs sbox10 (so[87:80],si[87:80]);
   skinny_sbox8_hs sbox9 (so[79:72],si[79:72]);
   skinny_sbox8_hs sbox8 (so[71:64],si[71:64]);
   skinny_sbox8_hs sbox7 (so[63:56],si[63:56]);
   skinny_sbox8_hs sbox6 (so[55:48],si[55:48]);
   skinny_sbox8_hs sbox5 (so[47:40],si[47:40]);
   skinny_sbox8_hs sbox4 (so[39:32],si[39:32]);
   skinny_sbox8_hs sbox3 (so[31:24],si[31:24]);
   skinny_sbox8_hs sbox2 (so[23:16],si[23:16]);
   skinny_sbox8_hs sbox1 (so[15:8],si[15:8]);
   skinny_sbox8_hs sbox0 (so[7:0],si[7:0]);
   
   
endmodule // sboxlayer
