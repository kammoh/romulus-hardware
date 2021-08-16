module round_function (/*AUTOARG*/
		       // Outputs
		       round_out0, round_out1,
		       // Inputs
		       round_key0, round_key1, round_in0, round_in1, constant0, constant1,
		       switch
		       ) ;
   output [127:0] round_out0, round_out1;
   input [383:0]  round_key0, round_key1;
   input [127:0]  round_in0, round_in1;
   input [5:0] 	  constant0, constant1;
   input 	  switch;

   wire [127:0]   key0, key1;   
   wire [127:0]   sb0, atk0, shr0, mxc0;
   wire [127:0]   sb1, atk1, shr1, mxc1;
   wire [127:0]   round_switch;

   assign key0 = {round_key0[383:320]^round_key0[255:192]^round_key0[127:64],64'h0} ^
		 {4'h0,constant0[3:0],24'h0,6'h0,constant0[5:4],24'h0,8'h02,56'h0};
   assign key1 = {round_key1[383:320]^round_key1[255:192]^round_key1[127:64],64'h0} ^
		 {4'h0,constant1[3:0],24'h0,6'h0,constant1[5:4],24'h0,8'h02,56'h0};

   sboxlayer   sbox0   (sb0,round_in0);
   addtweakkey addkey0 (atk0,key0,sb0);
   shiftrow    shrows0 (shr0,atk0);
   mixcolumn   mix0    (mxc0,shr0);

   assign round_out0 = mxc0;

   assign round_switch = switch ? round_in1 : round_out0; 
   //assign round_switch = round_out0;   
   
   sboxlayer   sbox1   (sb1,round_switch);
   addtweakkey addkey1 (atk1,key1,sb1);
   shiftrow    shrows1 (shr1,atk1);
   mixcolumn   mix1    (mxc1,shr1);

   assign round_out1 = mxc1;
   
   
endmodule // round_function
