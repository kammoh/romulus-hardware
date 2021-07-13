/*
 Designer: Mustafa Khairallah
 Nanyang Technological University
 Singapore
 Date: July, 2021
 */

/*
 Integration layer of different block of the Romulus-N mode.
 */

module dom1_mode_top (/*AUTOARG*/
   // Outputs
   pdo, counter,
   // Inputs
   pdi, sdi, rdi, domain, decrypt, clk, swr, srst, kwr, ken, kcrct,
   twr, ten, tcrct, crst, cen, ccrct, correct_cnt, rnd_cnst, tbcen,
   tk1s
   ) ;
   parameter        d  = 2;
   parameter        kd = 1;  // 1 for unmasked key, in general: the number of key shares, 
   // not fully parameterized yet. 
   
   output [31:0]    pdo;
   output [55:0]    counter;
   		     
   input [31:0]     pdi;
   input [31:0]     sdi;
   input [47:0]     rdi;
   input [7:0] 	    domain;
   input [3:0] 	    decrypt;
   input 	    clk;
   input 	    swr, srst;
   input 	    kwr, ken, kcrct;
   input 	    twr, ten, tcrct;
   input 	    crst, cen, ccrct;
   input 	    correct_cnt;
   input [5:0] 	    rnd_cnst;
   input [4:0] 	    tbcen;
   input 	    tk1s;

   wire [127:0]     rksh0, rksh1;
   wire [128*kd-1:0] tk3;
   wire [127:0]     tk2;
   wire [63:0] 	    tk1;
   wire [128*kd-1:0] tka;
   wire [127:0]     tkb;
   wire [63:0] 	    tkc;   
   wire [128*d-1:0] skinnyS;
   wire [128*kd-1:0] skinnyX;
   wire [127:0]     skinnyY;
   wire [63:0] 	    skinnyZ;
   wire [128*d-1:0] S;
   wire [128*kd-1:0] TKX;
   wire [127:0]     TKY, TKZZ;   
   wire [63:0] 	    TKZ;
   wire [55:0] 	    cin;

   wire 	    sen;   

   genvar 	    i;   
   
   assign counter = TKZ[63:8];
   assign sen = tbcen[4];   

   inout_serpar #(d) STATE (.state(S), .pdo(pdo), .pdi(pdi), 
			    .data_core(skinnyS), .decrypt(decrypt),
			    .wr(swr), .clk(clk), .en(sen), .rst(srst));

   key_serpar   #(kd) TKEYX (.key(TKX), .sdi(sdi), 
			     .data_core(skinnyX), .data_mode(tk3), 
			     .wr(kwr), .clk(clk), .en(ken), .crct(kcrct));

   tweak_serpar      TKEYY (.key(TKY), .pdi(pdi), 
			    .data_core(skinnyY), .data_mode(tk2), 
			    .wr(twr), .clk(clk), .en(ten), .crct(tcrct));


   mode_counter      CNT   (.cnt(TKZ), .data_core(skinnyZ), .data_mode(tk1),
			    .rst(crst), .clk(clk), .en(cen), .crct(ccrct));

   
   assign cin = correct_cnt ? TKZ[63:8] : tkc[63:8];
   assign TKZZ = tk1s ? {TKZ, 64'h0} : 128'h0;

   assign rksh0 = {TKX[127:64],64'h0} ^ 
                  {TKY[127:64],64'h0} ^
                  {4'h0,rnd_cnst[3:0],24'h0,6'h0,rnd_cnst[5:4],24'h0,8'h02,56'h0};
   assign rksh1 = {TKZZ[127:64],64'h0}; 

   generate
      for (i = 1; i <= kd; i = i + 1) begin:key_shares
	 pt8          permA        (.tk1o(tka[128*i-1:128*(i-1)]),
				    .tk1i(TKX[128*i-1:128*(i-1)]));
	 lfsr2_20      LFSR2        (.so(tk3[128*i-1:128*(i-1)]), 
				     .si(tka[128*i-1:128*(i-1)]));
	 key_expansion key_schedule (skinnyX[128*i-1:128*(i-1)],
				     TKX[128*i-1:128*(i-1)]);
      end
   endgenerate

   pt8             permB          (.tk1o(tkb), .tk1i(TKY));
   lfsr3_20        LFSR2          (.so(tk2), .si(tkb));
   tweak_expansion tweak_schedule (skinnyY,TKY);

   pt4           permC        (.tk1o(tkc), .tk1i(TKZ));
   lfsr_gf56     CNT_EXEC     (.so(tk1), .si(cin), .domain(domain));
   cnt_expansion cnt_schedule (skinnyZ,TKZ);

   dom1_skinny_rnd state_update (skinnyS[127:0],skinnyS[255:128],
				 S[127:0],S[255:128],
				 rksh0,rksh1,rdi,tbcen[3:0],
				 clk);

   
endmodule // dom1_mode_top

