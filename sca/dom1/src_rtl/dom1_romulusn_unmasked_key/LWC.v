/*
 Designer: Mustafa Khairallah
 Nanyang Technological University
 Singapore
 Date: July, 2021
 */

/*
 Top module for a GMU LWC-compliant DOM1-Romulus-N core.
 */

module LWC (/*AUTOARG*/
   // Outputs
   do_data, pdi_ready, sdi_ready, rdi_ready, do_valid, do_last,
   // Inputs
   pdi_data, sdi_data, rdi_data, pdi_valid, sdi_valid, do_ready,
   rdi_valid, clk, rst
   ) ;
   output [31:0] do_data;
   output 	 pdi_ready, sdi_ready, rdi_ready, do_valid, do_last;

   input [31:0]  pdi_data, sdi_data;
   input [47:0] rdi_data;
   input 	 pdi_valid, sdi_valid, do_ready, rdi_valid;

   input 	 clk, rst;

   wire [31:0] pdi;

   wire [7:0]  domain;
   wire [3:0]  decrypt;
   wire	       swr, srst;
   wire	       kwr, ken, kcrct;
   wire	       twr, ten, tcrct;
   wire	       rwr, ren, rcrct;
   wire	       crst, cen, ccrct;
   wire	       correct_cnt;
   wire [5:0]  rnd_cnst;
   wire [4:0]  tbcen;
   wire	       tk1s;
   
   wire [55:0]	    counter;   
   wire [31:0]	    pdo;

   api control_unit (// Outputs
		     do_data, pdi, pdi_ready, sdi_ready, rdi_ready, do_valid, do_last,
		     domain, decrypt, swr, srst, kwr, ken, kcrct, twr, ten, tcrct, crst,
		     cen, ccrct, correct_cnt, rnd_cnst, tbcen, tk1s,
		     // Inputs
		     counter, pdi_data, pdo, sdi_data, pdi_valid, sdi_valid, rdi_valid,
		     do_ready, clk, rst
		     ) ;

   dom1_mode_top datapath (// Outputs
			   pdo, counter,
			   // Inputs
			   pdi, sdi_data, rdi_data, domain, decrypt,
			   clk, swr, srst, kwr, ken, kcrct,
			   twr, ten, tcrct, crst, cen, ccrct, correct_cnt, rnd_cnst, tbcen,
			   tk1s
			   ) ;
   
endmodule // LWC
