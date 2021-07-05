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
   
   input [1:0] 	bi7;
   input [1:0] 	bi6;
   input [1:0] 	bi5;
   input [1:0] 	bi4;
   input [1:0] 	bi3;
   input [1:0] 	bi2;
   input [1:0] 	bi1;
   input [1:0] 	bi0;

   input [7:0] 	r;
   
   input 	clk;

   wire [1:0] 	a7;
   wire [1:0] 	a6;
   wire [1:0] 	a5;
   wire [1:0] 	a4;
   wire [1:0] 	a3;
   wire [1:0] 	a2;
   wire [1:0] 	a1;
   wire [1:0] 	a0;
   
   dom1_sbox8 b764 (a0,bi7,bi6,bi4,r[0],clk);
   dom1_sbox8 b320 (a1,bi3,bi2,bi0,r[1],clk);
   dom1_sbox8 b216 (a2,bi2,bi1,bi6,r[2],clk);
   dom1_sbox8 b015 (a3,a0, a1, bi5,r[3],clk);
   dom1_sbox8 b131 (a4,a1, bi3,bi1,r[4],clk);
   dom1_sbox8 b237 (a5,a2, a3, bi7,r[5],clk);
   dom1_sbox8 b303 (a6,a3, a0, bi3,r[6],clk);
   dom1_sbox8 b422 (a7,a4, a2, bi2,r[7],clk);

   assign bo7 = a3;
   assign bo6 = a0;
   assign bo5 = a1;
   assign bo4 = a6;
   assign bo3 = a4;
   assign bo2 = a2;
   assign bo1 = a5;
   assign bo0 = a7;
   
endmodule // dom1_sbox8

module dom1_sbox8_corefn (/*AUTOARG*/
   // Outputs
   f,
   // Inputs
   x, y, z, r, clk
   ) ;
   output [1:0] f;
   input [1:0] 	x, y, z;
   input 	r, clk;

   wire [1:0] 	g, t;
   reg [1:0] 	d;

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
