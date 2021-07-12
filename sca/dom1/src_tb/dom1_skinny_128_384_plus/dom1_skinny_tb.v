module dom1_skinny_tb () ;

   wire [7:0]     do_data;
   wire           di_ready, do_valid;

   wire [7:0]     di_data;
   reg            clk, di_valid, do_ready, rst;
   reg            init;   

   reg [127:0]    cnt, t, ksh1, ksh0, ssh1, ssh0, r;
   reg [128*7-1+8:0] buffer;   
   reg [127:0]       msk_s, msk_k;
   reg [7:0]         counter;   
   
   wire [127:0]      answer;   
   
   initial begin
      clk <= 0;      
      forever #1 clk <= ~clk;      
   end

   initial begin
      @(negedge clk) rst <= 1;
      msk_s <= {$random(),$random(),$random(),$random()};
      msk_k <= {$random(),$random(),$random(),$random()};
      #1;      
      cnt <= 128'hdf889548cfc7ea52d296339301797449;
      t <= 128'hab588a34a47f1ab2dfe9c8293fbea9a5;
      ksh1 <= 128'hab1afac2611012cd8cef952618c3ebe8^msk_k;
      ksh0 <= msk_k;
      ssh1 <= 128'ha3994b66ad85a3459f44e92b08f550cb^msk_s;
      ssh0 <= msk_s;      
      r <= {$random(),$random(),$random(),$random()};      
      #1;            
      @(negedge clk) rst <= 0;       
      
   end // initial begin

   assign di_data = buffer[128*7-1+8:128*7];

   assign answer = buffer[128*7-1:128*6] ^ buffer[128*6-1:128*5];   
   
   always @ (posedge clk) begin
      if (rst) begin     
         di_valid <= 0;  
         do_ready <= 0;
         init <= 1;
         counter <= 0;   
      end
      else begin
         if (init) begin
            buffer <= {8'h01,ssh1,ssh0,ksh1,ksh0,t,cnt,r};
            di_valid <= 1;
            init <= 0;      
         end
         else if (di_ready) begin
            di_valid <= 1;
            buffer <= {buffer[128*7-1:0],8'h00};            
         end
         else if (~di_ready) begin
            di_valid <= 0;          
            if (do_valid) begin
               do_ready <= 1;
               buffer <= {buffer[128*7-1:0],do_data};
               counter <= counter + 1;
               if (counter == 112) begin
		  @(posedge clk);
		  if (answer == 128'hff38d1d24c864c4352a853690fe36e5e) begin
		     $display("Successful test");		     
		  end		  
                  $finish;                
               end
            end
         end
      end
   end
   

   dom1_skinny_top uut (do_data, di_ready, do_valid,
                        di_data, clk, di_valid, do_ready, rst
                        );
   
endmodule // dom1_skinny_tb
