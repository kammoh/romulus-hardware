module hash_feedfwd (/*AUTOARG*/
		     // Outputs
		     so, lo, ro,
		     // Inputs
		     li, ri, si, clk, rst, mode, mode_first_cycle, cipher
		     ) ;
   output [31:0]  so;
   output [127:0] lo, ro;
   input [127:0]  li, ri;
   input [31:0]   si;
   input 	  clk, rst, mode, mode_first_cycle, cipher;
   
   reg [127:0] 	  l, r, t;

   assign ro = r;
   assign lo = l;
   
   assign so = mode_first_cycle ? 
	       l[127:96] ^ t[127:96] ^ {8'h01,24'h0} : 
	       l[127:96] ^ t[127:96];

   always @ (posedge clk) begin
      if (rst) begin	 
	 l <= 128'h0;	 
	 r <= 128'h0;
	 t <= 128'h0;	 
      end
      else if (cipher) begin
	 l <= li;
	 r <= ri;	 
      end
      else if (mode) begin
	 r <= {r[95:0], si ^ t[127:96] ^ {8'h01,24'h0}};
	   l <= {l[95:0], l[127:96] ^ t[127:96]};
	   t <= {t[95:0], l[127:96] ^ t[127:96]};
	end
      else begin
	 r <= r;
	 l <= l;
	 t <= t;	 
      end
   end
   
   
   
endmodule // hash_feedfwd
