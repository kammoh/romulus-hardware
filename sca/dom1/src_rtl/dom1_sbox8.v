module dom1_sbox8 (/*AUTOARG*/
   // Outputs
   bo7, bo6, bo5, bo4, bo3, bo2, bo1, bo0,
   // Inputs
   bi7, bi6, bi5, bi4, bi3, bi2, bi1, bi0, r, clk
   ) ;
   output [1:0] bo7;
   output [1:0] bo6;
   output [1:0] bo5;
   output [1:0] bo4;
   output [1:0] bo3;
   output [1:0] bo2;
   output [1:0] bo1;
   output [1:0] bo0;
   
   input [1:0]  bi7;
   input [1:0]  bi6;
   input [1:0]  bi5;
   input [1:0]  bi4;
   input [1:0]  bi3;
   input [1:0]  bi2;
   input [1:0]  bi1;
   input [1:0]  bi0;

   input [7:0]  r;
   
   input        clk;

   wire [1:0]   a7;
   wire [1:0]   a6;
   wire [1:0]   a5;
   wire [1:0]   a4;
   wire [1:0]   a3;
   wire [1:0]   a2;
   wire [1:0]   a1;
   wire [1:0]   a0;
   
   dom1_sbox8_corefn b764 (a0,bi7,bi6,bi4,r[0],clk);
   dom1_sbox8_corefn b320 (a1,bi3,bi2,bi0,r[1],clk);
   dom1_sbox8_corefn b216 (a2,bi2,bi1,bi6,r[2],clk);
   dom1_sbox8_corefn b015 (a3,a0, a1, bi5,r[3],clk);
   dom1_sbox8_corefn b131 (a4,a1, bi3,bi1,r[4],clk);
   dom1_sbox8_corefn b237 (a5,a2, a3, bi7,r[5],clk);
   dom1_sbox8_corefn b303 (a6,a3, a0, bi3,r[6],clk);
   dom1_sbox8_corefn b422 (a7,a4, a2, bi2,r[7],clk);

   assign bo7 = a3;
   assign bo6 = a0;
   assign bo5 = a1;
   assign bo4 = a6;
   assign bo3 = a4;
   assign bo2 = a2;
   assign bo1 = a5;
   assign bo0 = a7;
   
endmodule // dom1_sbox8

module dom1_sbox8_fullreg (/*AUTOARG*/
   // Outputs
   bo7, bo6, bo5, bo4, bo3, bo2, bo1, bo0,
   // Inputs
   bi7, bi6, bi5, bi4, bi3, bi2, bi1, bi0, r, clk
   ) ;
   output [1:0] bo7;
   output [1:0] bo6;
   output [1:0] bo5;
   output [1:0] bo4;
   output [1:0] bo3;
   output [1:0] bo2;
   output [1:0] bo1;
   output [1:0] bo0;
   
   input [1:0]  bi7;
   input [1:0]  bi6;
   input [1:0]  bi5;
   input [1:0]  bi4;
   input [1:0]  bi3;
   input [1:0]  bi2;
   input [1:0]  bi1;
   input [1:0]  bi0;

   input [7:0]  r;
   
   input        clk;

   wire [1:0]   a7;
   wire [1:0]   a6;
   wire [1:0]   a5;
   wire [1:0]   a4;
   wire [1:0]   a3;
   wire [1:0]   a2;
   wire [1:0]   a1;
   wire [1:0]   a0;
   
   dom1_sbox8_corefn_fullreg b764 (a0,bi7,bi6,bi4,r[0],clk);
   dom1_sbox8_corefn_fullreg b320 (a1,bi3,bi2,bi0,r[1],clk);
   dom1_sbox8_corefn_fullreg b216 (a2,bi2,bi1,bi6,r[2],clk);
   dom1_sbox8_corefn_fullreg b015 (a3,a0, a1, bi5,r[3],clk);
   dom1_sbox8_corefn_fullreg b131 (a4,a1, bi3,bi1,r[4],clk);
   dom1_sbox8_corefn_fullreg b237 (a5,a2, a3, bi7,r[5],clk);
   dom1_sbox8_corefn_fullreg b303 (a6,a3, a0, bi3,r[6],clk);
   dom1_sbox8_corefn_fullreg b422 (a7,a4, a2, bi2,r[7],clk);

   assign bo7 = a3;
   assign bo6 = a0;
   assign bo5 = a1;
   assign bo4 = a6;
   assign bo3 = a4;
   assign bo2 = a2;
   assign bo1 = a5;
   assign bo0 = a7;
   
endmodule // dom1_sbox8_fullreg

module dom1_sbox8_4share (/*AUTOARG*/
   // Outputs
   bo7, bo6, bo5, bo4, bo3, bo2, bo1, bo0,
   // Inputs
   bi7, bi6, bi5, bi4, bi3, bi2, bi1, bi0, r, clk
   ) ;
   output [7:0] bo3;
   output [7:0] bo2;
   output [7:0] bo1;
   output [7:0] bo0;

   input [7:0] 	si0, si1;
   input [7:0] 	r;   
   input        clk;
   
   wire [1:0]  bi7;
   wire [1:0]  bi6;
   wire [1:0]  bi5;
   wire [1:0]  bi4;
   wire [1:0]  bi3;
   wire [1:0]  bi2;
   wire [1:0]  bi1;
   wire [1:0]  bi0;

   wire [1:0]   a7;
   wire [1:0]   a6;
   wire [1:0]   a5;
   wire [1:0]   a4;
   wire [1:0]   a3;
   wire [1:0]   a2;
   wire [1:0]   a1;
   wire [1:0]   a0;

   assign bi0 = {si1[0],si0[0]};
   assign bi1 = {si1[1],si0[1]};
   assign bi2 = {si1[2],si0[2]};
   assign bi3 = {si1[3],si0[3]};
   assign bi4 = {si1[4],si0[4]};
   assign bi5 = {si1[5],si0[5]};
   assign bi6 = {si1[6],si0[6]};
   assign bi7 = {si1[7],si0[7]};
   
   dom1_sbox8_corefn_fullreg_dualoutput b764 ({bo1[6],bo0[6]},{bo3[6],bo2[6]},a0,bi7,bi6,bi4,r[0],clk);
   dom1_sbox8_corefn_fullreg_dualoutput b320 ({bo1[5],bo0[5]},{bo3[5],bo2[5]},a1,bi3,bi2,bi0,r[1],clk);
   dom1_sbox8_corefn_fullreg_dualoutput b216 ({bo1[2],bo0[2]},{bo3[2],bo2[2]},a2,bi2,bi1,bi6,r[2],clk);
   dom1_sbox8_corefn_fullreg_dualoutput b015 ({bo1[7],bo0[7]},{bo3[7],bo2[7]},a3,a0, a1, bi5,r[3],clk);
   dom1_sbox8_corefn_fullreg_dualoutput b131 ({bo1[3],bo0[3]},{bo3[3],bo2[3]},a4,a1, bi3,bi1,r[4],clk);
   dom1_sbox8_corefn_fullreg_dualoutput b237 ({bo1[1],bo0[1]},{bo3[1],bo2[1]},a5,a2, a3, bi7,r[5],clk);
   dom1_sbox8_corefn_fullreg_dualoutput b303 ({bo1[4],bo0[4]},{bo3[4],bo2[4]},a6,a3, a0, bi3,r[6],clk);
   dom1_sbox8_corefn_fullreg_dualoutput b422 ({bo1[0],bo0[0]},{bo3[0],bo2[0]},a7,a4, a2, bi2,r[7],clk);

   
endmodule // dom1_sbox8_4share

module dom1_sbox8_corefn (/*AUTOARG*/
   // Outputs
   f,
   // Inputs
   x, y, z, r, clk
   ) ;
   output [1:0] f;
   input [1:0]  x, y, z;
   input        r, clk;

   wire [1:0]   g, t;
   reg [1:0]    d;

   assign g[1] = (~x[1]) & (~y[1]);
   assign g[0] =   x[0]  &   y[0] ;

   assign t[1] = ((~x[1]) &  y[0] ) ^ r;
   assign t[0] = ((~y[1]) &  x[0] ) ^ r;

   always @ (posedge clk) begin
      d <= t;      
   end

   assign f[0] = d[0] ^ g[0] ^ z[0];
   assign f[1] = d[1] ^ g[1] ^ z[1];
   
endmodule // dom1_sbox8_corefn

module dom1_sbox8_corefn_fullreg (/*AUTOARG*/
   // Outputs
   f,
   // Inputs
   x, y, z, r, clk
   ) ;
   output [1:0] f;
   input [1:0]  x, y, z;
   input        r, clk;

   reg [1:0]    g, t;

   always @ (posedge clk) begin
      g[1] <= (~x[1]) & (~y[1]) ^ z[1];
      g[0] <=   x[0]  &   y[0]  ^ z[0];

      t[1] <= ((~x[1]) &  y[0] ) ^ r;
      t[0] <= ((~y[1]) &  x[0] ) ^ r;
   end

   assign f[0] = t[0] ^ g[0];
   assign f[1] = t[1] ^ g[1];
   
endmodule // dom1_sbox8_corefn_fullreg

module dom1_sbox8_corefn_fullreg_dualoutput (/*AUTOARG*/
   // Outputs
   g, t, f,
   // Inputs
   x, y, z, r, clk
   ) ;
   output reg [1:0]    g, t;
   output [1:0]        f;
   input [1:0] 	       x, y, z;
   input 	       r, clk;

   always @ (posedge clk) begin
      g[1] <= (~x[1]) & (~y[1]) ^ z[1];
      g[0] <=   x[0]  &   y[0]  ^ z[0];

      t[1] <= ((~x[1]) &  y[0] ) ^ r;
      t[0] <= ((~y[1]) &  x[0] ) ^ r;
   end

   assign f[0] = t[0] ^ g[0];
   assign f[1] = t[1] ^ g[1];
   
endmodule // dom1_sbox8_corefn_fullreg

