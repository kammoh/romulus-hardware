module dom1_skinny_tb () ;
   wire [127:0] ssho0, ssho1, ssho;
   wire 	done;
   
   reg [127:0]  sshi0, sshi1, kshi0, kshi1, ri, ti, cnti, scrbrd, msk_s, msk_k;
   reg          clk, rnd1, rst;

   assign ssho = ssho1 ^ ssho0;   

   initial begin
      clk <= 0;      
      forever #1 clk <= ~clk;      
   end

   initial begin
      msk_s <= {$random(),$random(),$random(),$random()};
      msk_k <= {$random(),$random(),$random(),$random()};  
      #1;      
      cnti <= 128'hdf889548cfc7ea52d296339301797449;
      ti <= 128'hab588a34a47f1ab2dfe9c8293fbea9a5;
      kshi1 <= 128'hab1afac2611012cd8cef952618c3ebe8^msk_k;
      kshi0 <= msk_k;
      sshi1 <= 128'ha3994b66ad85a3459f44e92b08f550cb^msk_s;
      sshi0 <= msk_s;
      ri <= {$random(),$random(),$random(),$random()};      
      #1;
      @(negedge clk) rst <= 1;
      @(negedge clk) rst <= 0; 
      rnd1 <= 1;
      @(negedge clk);
      @(negedge clk);
      @(negedge clk);
      @(negedge clk);
      rnd1 <= 0;

      while (done == 0) begin
	 @(posedge clk);	 
      end

      scrbrd <= ssho^128'hff38d1d24c864c4352a853690fe36e5e;
      #0.5
      $display("%x",scrbrd);
      $finish;      
      
   end // initial begin

   dom1_skinny_top uut (ssho0, ssho1, done,                       
                        sshi0, sshi1, kshi0, kshi1, ri, ti, cnti, clk, rst);   
   
endmodule // dom1_skinny_tb
