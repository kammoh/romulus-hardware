/*
 Designer: Mustafa Khairallah
 Nanyang Technological University
 Singapore
 Date: July, 2021
 */

/* 
 A stand-alone version of Skinny protected
 with first order domain-oriented masking.
 */
module dom1_skinny_top (/*AUTOARG*/
   // Outputs
   do_data, di_ready, do_valid,
   // Inputs
   di_data, clk, di_valid, do_ready, rst
   ) ;
   output [7:0]     do_data;
   output           di_ready, do_valid;

   input [7:0]      di_data;
   input            clk, di_valid, do_ready, rst;
   
   wire 	    core_rst;
   wire             iwr;
   wire             ord;
   
   wire [127:0]     sshr0, sshr1;
   wire [127:0]     sshi0, sshi1, kshi0, kshi1, ri, ti, cnti;
   wire [127:0]     ksh0n,ksh1n;
   wire [127:0]     tn;
   wire [127:0]     cntn;
   wire [127:0]     rn;   
   wire [127:0]     rksh0, rksh1;
   wire [127:0]     ssho0, ssho1;
   wire [127:0]     kshr0, kshr1, tr, cntr;
   wire 	    kstore;   
   
   reg [3:0] 	    en;
   reg 		    store, core_rst_delayed;
   reg 		    core_done;
   reg [5:0] 	    rnd_cnst;   

   dom1_skinny_fpga_fsm control_unit (di_ready, do_valid, iwr, ord, core_rst,
				      di_data, di_valid, do_ready, clk, rst, core_done);   

   inout_serpar buffer ({sshr1,sshr0,kshr1,kshr0,tr,cntr,ri},
			do_data,
			di_data,
			{ssho1,ssho0,ksh1n,ksh0n,tn,cntn,rn},
			iwr,ord,clk,store,kstore);
   
   assign rn = {ri[126:0],ri[127]}^{120'h0,ri[127],4'h0,ri[127],ri[127],1'b0};   

   assign sshi0 = kstore ? ssho0 : sshr0;
   assign sshi1 = kstore ? ssho1 : sshr1;
   
   dom1_skinny_rnd state_update (ssho0,ssho1,sshi0,sshi1,rksh0,rksh1,ri,en[3:0],clk);
   key_expansion key_schedule_0 (ksh0n,kshr0);
   key_expansion key_schedule_1 (ksh1n,kshr1);
   tweak_expansion tweak_schedule (tn,tr);
   cnt_expansion cnt_schedule (cntn,cntr);
   
   assign rksh0 = {kshr0[127:64],64'h0} ^ 
                  {tr[127:64],64'h0} ^
                  {4'h0,rnd_cnst[3:0],24'h0,6'h0,rnd_cnst[5:4],24'h0,8'h02,56'h0};
   assign rksh1 = {kshr1[127:64],64'h0} ^ 
                  {cntr[127:64],64'h0};   

   assign kstore = en[0] && ~core_rst_delayed;
   
   always @ (posedge clk) begin      
      if (core_rst) begin
         en <= 4'b0001;
         core_done <= 0;
	 store <= 0;
      end      
      else begin
         en <= {en[2:0],en[3]};
         if ((en[3] == 1) && (rnd_cnst == 6'h1a)) begin
	    store <= 1;
	 end
	 else begin
	    store <= 0;	    
	 end
	 if (store) begin
            core_done <= 1;      
         end
         else begin
            core_done <= 0;      
         end
      end // else: !if(rst)
   end // always @ (posedge clk)

   always @ (posedge clk) begin
      if (core_rst) begin         
         rnd_cnst <= 6'h01;      
      end
      else begin
         if (kstore) begin
            rnd_cnst <= {rnd_cnst[4:0],rnd_cnst[5]^rnd_cnst[4]^1'b1};
         end
      end
   end

   always @ (posedge clk) begin
      core_rst_delayed <= core_rst;      
   end
   
endmodule // skinny_top
