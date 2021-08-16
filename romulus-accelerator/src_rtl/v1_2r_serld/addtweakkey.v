module addtweakkey (/*AUTOARG*/
   // Outputs
   so,
   // Inputs
   key, state
   ) ;
   output [127:0] so;
   input  [127:0] key, state;

   assign so = {key[127:56] ^ state[127:56], state[55:0]};
endmodule // addtweakkey

