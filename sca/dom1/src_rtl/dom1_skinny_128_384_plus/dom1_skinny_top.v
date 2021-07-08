module dom1_skinny_top (/*AUTOARG*/
                        // Outputs
                        sshr0, sshr1, done,
                        // Inputs
                        sshi0, sshi1, kshi0, kshi1, ri, ti, cnti, clk, rst
                        ) ;
   output reg [127:0]     sshr0, sshr1;
   output reg             done;
   
   input [127:0]          sshi0, sshi1, kshi0, kshi1, ri, ti, cnti;
   input                  clk, rst;

   wire [127:0]           ksh0n,ksh1n;
   wire [127:0]           tn;
   wire [127:0]           cntn;
   wire [127:0]           rksh0, rksh1;
   wire [127:0]           ssho0, ssho1;
   
   reg [4:0]              en;
   reg [127:0]            kshr0, kshr1, r, tr, cntr;
   reg [5:0]              rnd_cnst; 
   
   dom1_skinny_rnd state_update (ssho0,ssho1,sshr0,sshr1,rksh0,rksh1,r,en[3:0],clk);
   key_expansion key_schedule_0 (ksh0n,kshr0);
   key_expansion key_schedule_1 (ksh1n,kshr1);
   tweak_expansion tweak_schedule (tn,tr);
   cnt_expansion cnt_schedule (cntn,cntr);
   
   assign rksh0 = {kshr0[127:64],64'h0} ^ 
                  {tr[127:64],64'h0} ^
                  {4'h0,rnd_cnst[3:0],24'h0,6'h0,rnd_cnst[5:4],24'h0,8'h02,56'h0};
   assign rksh1 = {kshr1[127:64],64'h0} ^ 
                  {cntr[127:64],64'h0};   

   always @ (posedge clk) begin
      if (rst) begin
         en <= 5'b00001;
         done <= 0;      
      end      
      else begin
         en <= {en[3:0],en[4]};
         if ((en[4] == 1) && (rnd_cnst == 6'h1a)) begin
            done <= 1;      
         end
         else begin
            done <= 0;      
         end
      end // else: !if(rst)
   end // always @ (posedge clk)

   always @ (posedge clk) begin
      if (rst) begin
         sshr0 <= sshi0;
         sshr1 <= sshi1;
         kshr0 <= kshi0;
         kshr1 <= kshi1;
         tr <= ti;
         cntr <= cnti;
         r <= ri;
         rnd_cnst <= 6'h01;      
      end
      else begin
         if (en[4] == 1'b1) begin
            kshr0 <= ksh0n;
            kshr1 <= ksh1n;
            tr <= tn;
            cntr <= cntn;
            r <= ri;
            rnd_cnst <= {rnd_cnst[4:0],rnd_cnst[5]^rnd_cnst[4]^1'b1};                
            sshr0 <= ssho0;
            sshr1 <= ssho1;
         end
      end
   end
   
   
   
endmodule // skinny_top
