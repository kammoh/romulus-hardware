module mixcolumn (/*AUTOARG*/
   // Outputs
   so,
   // Inputs
   si
   ) ;
   output [127:0] so;
   input [127:0]  si;
   
   assign so[ 95:64] = si[127:96];
   assign so[ 63:32] = si[ 95:64] ^ si[63:32];
   assign so[ 31: 0] = si[127:96] ^ si[63:32];
   assign so[127:96] = si[ 31: 0] ^ so[31: 0]; 
endmodule // mixcolumn
