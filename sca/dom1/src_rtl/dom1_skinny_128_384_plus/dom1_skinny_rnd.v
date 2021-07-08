module dom1_skinny_rnd (/*AUTOARG*/
   // Outputs
   ssho0, ssho1,
   // Inputs
   sshi0, sshi1, ksh0, ksh1, r, en, clk
   ) ;
   output [127:0] ssho0, ssho1;
   input [127:0]  sshi0, sshi1, ksh0, ksh1, r;
   input [3:0] 	  en;   
   input          clk;

   wire [127:0]   sbi0, sbi1;
   wire [127:0]   sbo0, sbo1;
   wire [127:0]   mxc0, mxc1;
   wire [127:0]   atk0, atk1;
   wire [127:0]   shr0, shr1;

   // Except in the first round, the SBox takes the output
   // of the MixColumn step.
   assign sbi0 = sshi0;
   assign sbi1 = sshi1;

   // Assigning the output
   assign ssho0 = mxc0;
   assign ssho1 = mxc1;   

   // DOM SBox takes (sbi0,sbi1) => (sbo0, sbo1),   
   dom1_sbox8 sbox0  (sbo1[ 7 :	0],sbo0[ 7 :  0],sbi0[ 7 :  0],sbi1[ 7 :  0],r[ 7 :  0],en,clk);
   dom1_sbox8 sbox1  (sbo1[ 15:	8],sbo0[ 15:  8],sbi0[ 15:  8],sbi1[ 15:  8],r[ 15:  8],en,clk);
   dom1_sbox8 sbox2  (sbo1[ 23: 16],sbo0[ 23: 16],sbi0[ 23: 16],sbi1[ 23: 16],r[ 23: 16],en,clk);
   dom1_sbox8 sbox3  (sbo1[ 31: 24],sbo0[ 31: 24],sbi0[ 31: 24],sbi1[ 31: 24],r[ 31: 24],en,clk);
   dom1_sbox8 sbox4  (sbo1[ 39: 32],sbo0[ 39: 32],sbi0[ 39: 32],sbi1[ 39: 32],r[ 39: 32],en,clk);
   dom1_sbox8 sbox5  (sbo1[ 47: 40],sbo0[ 47: 40],sbi0[ 47: 40],sbi1[ 47: 40],r[ 47: 40],en,clk);
   dom1_sbox8 sbox6  (sbo1[ 55: 48],sbo0[ 55: 48],sbi0[ 55: 48],sbi1[ 55: 48],r[ 55: 48],en,clk);
   dom1_sbox8 sbox7  (sbo1[ 63: 56],sbo0[ 63: 56],sbi0[ 63: 56],sbi1[ 63: 56],r[ 63: 56],en,clk);
   dom1_sbox8 sbox8  (sbo1[ 71: 64],sbo0[ 71: 64],sbi0[ 71: 64],sbi1[ 71: 64],r[ 71: 64],en,clk);
   dom1_sbox8 sbox9  (sbo1[ 79: 72],sbo0[ 79: 72],sbi0[ 79: 72],sbi1[ 79: 72],r[ 79: 72],en,clk);
   dom1_sbox8 sbox10 (sbo1[ 87: 80],sbo0[ 87: 80],sbi0[ 87: 80],sbi1[ 87: 80],r[ 87: 80],en,clk);
   dom1_sbox8 sbox11 (sbo1[ 95: 88],sbo0[ 95: 88],sbi0[ 95: 88],sbi1[ 95: 88],r[ 95: 88],en,clk);
   dom1_sbox8 sbox12 (sbo1[103: 96],sbo0[103: 96],sbi0[103: 96],sbi1[103: 96],r[103: 96],en,clk);
   dom1_sbox8 sbox13 (sbo1[111:104],sbo0[111:104],sbi0[111:104],sbi1[111:104],r[111:104],en,clk);
   dom1_sbox8 sbox14 (sbo1[119:112],sbo0[119:112],sbi0[119:112],sbi1[119:112],r[119:112],en,clk);
   dom1_sbox8 sbox15 (sbo1[127:120],sbo0[127:120],sbi0[127:120],sbi1[127:120],r[127:120],en,clk);

   // Addtweakey: the input key shares (ksh0,ksh1) already include
   // the round constants, secret key and tweaks. 
   assign atk0 = ksh0 ^ sbo0;
   assign atk1 = ksh1 ^ sbo1;

   // ShiftRows: This step is basically just renaming the wires
   assign shr0[127:96] =  atk0[127:96];
   assign shr0[ 95:64] = {atk0[ 71:64],atk0[95:72]};
   assign shr0[ 63:32] = {atk0[ 47:32],atk0[63:48]};
   assign shr0[ 31: 0] = {atk0[ 23: 0],atk0[31:24]};

   assign shr1[127:96] =  atk1[127:96];
   assign shr1[ 95:64] = {atk1[ 71:64],atk1[95:72]};
   assign shr1[ 63:32] = {atk1[ 47:32],atk1[63:48]};
   assign shr1[ 31: 0] = {atk1[ 23: 0],atk1[31:24]};

   // MixColumn: Share-wise
   assign mxc0[ 95:64] = shr0[127:96];
   assign mxc0[ 63:32] = shr0[ 95:64] ^ shr0[63:32];
   assign mxc0[ 31: 0] = shr0[127:96] ^ shr0[63:32];
   assign mxc0[127:96] = shr0[ 31: 0] ^ mxc0[31: 0]; 

   assign mxc1[ 95:64] = shr1[127:96];
   assign mxc1[ 63:32] = shr1[ 95:64] ^ shr1[63:32];
   assign mxc1[ 31: 0] = shr1[127:96] ^ shr1[63:32];
   assign mxc1[127:96] = shr1[ 31: 0] ^ mxc1[31: 0]; 
   
endmodule // dom_skinny_rnd

// The DOM-Indep multiplier based sbox8 with registered
// shares.
module dom1_sbox8 (/*AUTOARG*/
   // Outputs
   bo1, bo0,
   // Inputs
   si0, si1, r, en, clk
   ) ;
   output [7:0] bo1;
   output [7:0] bo0;

   input [7:0]  si0, si1;
   input [7:0]  r;
   input [3:0] 	en;   
   input        clk;
   
   wire [1:0]   bi7;
   wire [1:0]   bi6;
   wire [1:0]   bi5;
   wire [1:0]   bi4;
   wire [1:0]   bi3;
   wire [1:0]   bi2;
   wire [1:0]   bi1;
   wire [1:0]   bi0;

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
   
   dom1_sbox8_cfn_fr b764 (a0,bi7,bi6,bi4,r[0],clk,en[0]);
   dom1_sbox8_cfn_fr b320 (a1,bi3,bi2,bi0,r[1],clk,en[0]);
   dom1_sbox8_cfn_fr b216 (a2,bi2,bi1,bi6,r[2],clk,en[0]);
   dom1_sbox8_cfn_fr b015 (a3,a0, a1, bi5,r[3],clk,en[1]);
   dom1_sbox8_cfn_fr b131 (a4,a1, bi3,bi1,r[4],clk,en[1]);
   dom1_sbox8_cfn_fr b237 (a5,a2, a3, bi7,r[5],clk,en[2]);
   dom1_sbox8_cfn_fr b303 (a6,a3, a0, bi3,r[6],clk,en[2]);
   dom1_sbox8_cfn_fr b422 (a7,a4, a5, bi2,r[7],clk,en[3]);

   assign {bo1[6],bo0[6]} = a0;
   assign {bo1[5],bo0[5]} = a1;
   assign {bo1[2],bo0[2]} = a2;
   assign {bo1[7],bo0[7]} = a3;
   assign {bo1[3],bo0[3]} = a4;
   assign {bo1[1],bo0[1]} = a5;
   assign {bo1[4],bo0[4]} = a6;
   assign {bo1[0],bo0[0]} = a7;
   
endmodule // dom1_sbox8

// The core registered function of the skinny sbox8.
// fr: fully registered, all and operations are
// registered.
// cfn: core function
// The core function is basically (x nor y) xor z
// We use de morgan's law to convert it to:
// ((~x) and (~y)) xor z and use the DOM-Indep
// multiplier for the and gate. We add the shares of
// z to the independent and gates and register the
// output of (a and b) xor c, while for the mixed
// shares we also use (a and b) xor c, but c is the
// fresh randomness.
module dom1_sbox8_cfn_fr (/*AUTOARG*/
   // Outputs
   f,
   // Inputs
   x, y, z, r, clk, en
   ) ;
   output [1:0]        f;
   input [1:0]         x, y, z;
   input               r, clk, en;

   reg [1:0]    g, t;
   always @ (posedge clk) begin
      if (en) begin
	 g[1] <= (~x[1]) & (~y[1]) ^ z[1];
	 g[0] <=   x[0]  &   y[0]  ^ z[0];
	 
	 t[1] <= ((~x[1]) &  y[0] ) ^ r;
	 t[0] <= ((~y[1]) &  x[0] ) ^ r;
      end      
   end   

   assign f[0] = t[0] ^ g[0];
   assign f[1] = t[1] ^ g[1];
   
endmodule // dom1_sbox8_corefn_fullreg

