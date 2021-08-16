module shiftrow (/*AUTOARG*/
   // Outputs
   so, si
   ) ;
   output [127:0] so;
   output [127:0] si;

   assign so[127:96] =  si[127:96];
   assign so[ 95:64] = {si[ 71:64],si[95:72]};
   assign so[ 63:32] = {si[ 47:32],si[63:48]};
   assign so[ 31: 0] = {si[ 23: 0],si[31:24]};

endmodule // shiftrows
