/*
 Designer: Mustafa Khairallah
 Nanyang Technological University
 Singapore
 Date: July, 2021
 */

/* 
 FSM for the input output protocol for testing the DOM1
 SKINNY-128/384+ on FPGA.
 */
module dom1_skinny_fpga_fsm (/*AUTOARG*/
   // Outputs
   di_ready, do_valid, iwr, ord, core_rst,
   // Inputs
   di_data, di_valid, do_ready, clk, rst, core_done
   ) ;
   parameter IDLE = 0;
   parameter LOAD = 1;
   parameter ENC = 2;
   parameter STORE = 3;

   output reg  di_ready, do_valid;
   output reg  iwr, ord, core_rst;

   input [7:0] di_data;
   input       di_valid, do_ready;
   input       clk, rst;
   input       core_done;
   
   reg [1:0]   fsm, fsmn;
   reg [7:0]   cnt, cntn;   
   
   always @ (posedge clk) begin
      if (rst) begin
	 fsm <= IDLE;
	 cnt <= 0;	 
      end
      else begin
	 fsm <= fsmn;
	 cnt <= cntn;	 
      end
   end

   always @ ( /*AUTOSENSE*/cnt or core_done or di_data or di_valid
	     or do_ready or fsm) begin
      fsmn <= fsm;
      cntn <= cnt;      
      di_ready <= 0;   
      iwr <= 0;
      ord <= 0;      
      core_rst <= 0; 
      do_valid <= 0;     
      case (fsm) 
	IDLE: begin
	   di_ready <= 1;
	   if (di_valid) begin
	      if (di_data == 8'h01) begin
		 fsmn <= LOAD;		 
	      end
	   end
	end
	LOAD: begin
	   iwr <= 1;
	   di_ready <= 1;	   
	   if (cnt == 111) begin
	      fsmn <= ENC;
	      cntn <= 0;	     
	      core_rst <= 1;	     
	   end
	   else begin
	      fsmn <= LOAD;
	      cntn <= cnt + 1;
	   end
	end
	ENC: begin
	   if (core_done) begin
	      fsmn <= STORE;	      
	   end
	   else begin
	      fsmn <= ENC;	      
	   end
	end
	STORE: begin
	   do_valid <= 1;
	   if (do_ready) begin
	      ord <= 1;	      
	      if (cnt == 111) begin
		 fsmn <= IDLE;
		 cntn <= 0;	     		 	     
	      end
	      else begin
		 fsmn <= STORE;
		 cntn <= cnt + 1;
	      end     
	   end // if (do_ready)	   
	end
      endcase	  
   end
   
   
endmodule // dom1_skinny_fpga_fsm
