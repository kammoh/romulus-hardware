module api (/*AUTOARG*/
            // Outputs
            pdo_data, pdi, pdi_ready, sdi_ready, pdo_valid, do_last, domain, srst, senc,
            sse, xrst, xenc, xse, yrst, yenc, yse, zrst, zenc, zse, erst,
            decrypt, correct_cnt, constant, constant2, tk1s,
            // Inputs
            counter, pdi_data, pdo, sdi_data, pdi_valid, sdi_valid, pdo_ready, clk, rst
            ) ;
   // SKINNY FINAL CONSTANT
   parameter FINCONST = 7'b011010;

   // BLK COUNTER INITIAL CONSTANT
   parameter INITCTR = 56'h02000000000000;  
   parameter INITCTR2 = 56'h01000000000000;  

   // MODES
   parameter ROMULUSN = 2'b00;
   parameter ROMULUSM = 2'b01;
   parameter ROMULUSH = 2'b10;
   parameter ROMULUST = 2'b11;

   // INSTRUCTIONS
   parameter LDKEY = 4;
   parameter ACTKEY = 7; 
   parameter NENC = 2;
   parameter NDEC = 3;
   parameter MENC = 5;   
   parameter MDEC = 6;
   parameter MENC2 = 9;   
   parameter MDEC2 = 10;
   parameter TENC = 11;
   parameter TDEC = 12;
   parameter TENC2 = 13;
   parameter TDEC2 = 0;
   parameter HASH = 8;   
   parameter SUCCESS = 14;
   parameter FAILURE = 15;

   //SEGMENT HEADERS
   parameter RSRVD1 = 0;
   parameter AD = 1;
   parameter NpubAD = 2; 
   parameter ADNpub = 3; 
   parameter PLAIN = 4; 
   parameter CIPHER = 5; 
   parameter CIPHERTAG = 6; 
   parameter RSRVD = 7; 
   parameter TAG = 8; 
   parameter RSRVD2 = 9; 
   parameter LENGTH = 10;
   parameter RSRVD3 = 11;  
   parameter KEY = 12; 
   parameter Npub = 13; 
   parameter Nsec = 14; 
   parameter ENCNsec = 15;

   // DOMAINS For Romulus-N
   parameter nadnormal = 8;
   parameter nadfinal = 24;
   parameter nadpadded = 26;
   parameter nmsgnormal = 4;
   parameter nmsgfinal = 20;
   parameter nmsgpadded = 21;

   // DOMAINS For Romulus-M
   parameter madnormal = 40;
   parameter mmacnormal = 44;
   parameter mmacfinal = 48;   
   parameter mmsgnormal = 36;   

   // STATES
   parameter idle         = 0;
   parameter loadkey      = 1;
   parameter keyheader    = 2;   
   parameter storekey     = 3;
   parameter nonceheader  = 4;
   parameter storen       = 5;
   parameter adheader     = 6;
   parameter adheader2    = 7;
   parameter msgheader    = 8;
   parameter storeadsf    = 9;
   parameter storeadtf    = 10;
   parameter storeadsp    = 11;
   parameter storeadtp    = 12;
   parameter storemf      = 13;
   parameter storemp      = 14;
   parameter encryptad    = 15;
   parameter encryptn     = 16;
   parameter encryptm     = 17;
   parameter outputtag0   = 18;
   parameter outputtag1   = 19;   
   parameter verifytag0   = 20;
   parameter verifytag1   = 21;
   parameter statuse      = 22;  
   parameter statusdf     = 23;  
   parameter statusds     = 24;
   parameter macheader    = 25;
   parameter macheader2   = 26;
   parameter storemacsf   = 27;
   parameter storemactf   = 28;
   parameter storemacsp   = 29;
   parameter storemactp   = 30; 
   parameter encryptmac   = 31;
   parameter tagheader    = 32;
   parameter storetag     = 33;  
   parameter encrypttag   = 34;
   parameter nonceheader2 = 35;
   parameter storen2      = 36;
   parameter hmsgheader   = 37;   
   parameter storehmsg0   = 38;
   parameter storehmsg1   = 39;   
   parameter storehmsgp0  = 40;
   parameter storehmsgp1  = 41;   
   parameter encrypthash  = 42;
   parameter feedforward  = 43;  
   parameter outputhash0  = 44;
   parameter outputhash1  = 45;   
   
   output reg [31:0] pdo_data, pdi;
   output reg        pdi_ready, sdi_ready, pdo_valid, do_last;

   output reg [7:0]  domain;
   output reg        srst, senc, sse;
   output reg        xrst, xenc, xse;
   output reg        yrst, yenc, yse;
   output reg        zrst, zenc, zse;
   output reg        erst;
   output reg [3:0]  decrypt;
   output reg        correct_cnt;
   output [5:0]      constant; 
   output [5:0]      constant2;         
   output reg        tk1s; 
   
   input [55:0]      counter;   
   input [31:0]      pdi_data, pdo, sdi_data;
   input             pdi_valid, sdi_valid, pdo_ready;

   input             clk, rst;

   reg [7:0]         fsm, fsmn;
   reg [15:0]        seglen, seglenn;  
   reg [3:0]         flags, flagsn;
   reg [1:0]         mode, moden; 
   // 2'b00: Romulus-N, 
   // 2'b01: Romulus-M, 
   // 2'b10: Romulus-H, 
   // 2'b11: Romulus-T
   reg 		     adeven,meven,adpad,mpad;
   reg 		     adevenn,mevenn,adpadn,mpadn;
   reg               dec, decn;
   reg [7:0]         nonce_domain, nonce_domainn;
   reg [5:0]         cnt, cntn;   
   reg               correct_cntn;
   reg               st0, st0n;
   reg               c2, c2n;
   reg               tk1sn;

   assign constant = cnt;
   assign constant2 = {cnt[4:0], cnt[5]^cnt[4]^1'b1};   

   always @ (posedge clk) begin
      if (rst) begin
         fsm <= idle;
         seglen <= 0;
         flags <= 0;
         dec <= 0;
         correct_cnt <= 1;
         cnt <= 6'h01;   
         st0 <= 0;
         mode <= 0;      
         c2 <= 0;        
         tk1s <= 1;      
         nonce_domain <= nadpadded;  
	 adeven <= 1;
	 meven <= 1;
	 mpad <= 0;
	 adpad <= 0;	 
      end
      else begin
         fsm <= fsmn;
         seglen <= seglenn;
         flags <= flagsn;
         dec <= decn;
         cnt <= cntn; 
         mode <= moden;  
         nonce_domain <= nonce_domainn;
         st0 <= st0n;
         c2 <= c2n;
         tk1s <= tk1sn;  
         correct_cnt <= correct_cntn; 
	 adeven <= adevenn;
	 meven <= mevenn;
	 mpad <= mpadn;
	 adpad <= adpadn;	    
      end
   end
   
   always @ (*) begin
      pdo_data <= 0;      
      pdi <= pdi_data;  
      do_last <= 0;    
      domain <= 0;         
      srst   <= 0;
      senc   <= 0;
      sse    <= 0;
      xrst   <= 0;
      xenc   <= 0;
      xse    <= 0;
      yrst   <= 0;
      yenc   <= 0;
      yse    <= 0;
      zrst   <= 0;
      zenc   <= 0;
      zse    <= 0;
      erst   <= 0;
      decrypt <= 0; 
      moden <= mode;      
      sdi_ready <= 0;
      pdi_ready <= 0;
      pdo_valid <= 0;
      tk1sn <= tk1s;      
      nonce_domainn <= nonce_domain;      
      fsmn <= fsm;
      seglenn <= seglen; 
      flagsn <= flags;
      decn <= dec;
      correct_cntn <= correct_cnt;
      st0n <= st0;
      c2n <= c2;           
      cntn <= cnt;
      adevenn <= adeven;
      mevenn <= meven;
      mpadn <= mpad;
      adpadn <= adpad;	       
      case (fsm) 
        idle: begin
           pdi_ready <= 1;
           srst <= 1;
           sse <= 1;
           senc <= 1;      
           tk1sn <= 1;     
           nonce_domainn <= nadpadded;      
           if (pdi_valid) begin
              pdi_ready <= 1;
              if (pdi_data[31:28] == ACTKEY) begin
                 fsmn <= loadkey;              
              end
              else if (pdi_data[31:28] == NENC) begin
                 moden <= ROMULUSN;              
                 zenc <= 1;        
                 zrst <= 1;
                 correct_cntn <= 1;           
                 zse <= 1;         
                 fsmn <= adheader;
                 decn <= 0;              
              end
	      else if (pdi_data[31:28] == NDEC) begin
                 moden <= ROMULUSN;              
                 zenc <= 1;        
                 zrst <= 1;
                 correct_cntn <= 1;           
                 zse <= 1;         
                 fsmn <= adheader;
                 decn <= 1;             
              end
              else if (pdi_data[31:28] == MENC) begin
                 moden <= ROMULUSM;              
                 zenc <= 1;        
                 zrst <= 1;
                 correct_cntn <= 1;           
                 zse <= 1;         
                 fsmn <= adheader;
                 decn <= 0;              
              end
	      else if (pdi_data[31:28] == MDEC) begin
                 moden <= ROMULUSM;              
                 zenc <= 1;        
                 zrst <= 1;
                 correct_cntn <= 1;           
                 zse <= 1;         
                 fsmn <= adheader;
                 decn <= 1;              
              end
	      else if (pdi_data[31:28] == MENC2) begin
                 moden <= ROMULUSM;              
                 zenc <= 1;        
                 zrst <= 1;
                 correct_cntn <= 1;           
                 zse <= 1;         
                 fsmn <= tagheader;
                 decn <= 0;              
              end
	      else if (pdi_data[31:28] == MDEC2) begin
                 moden <= ROMULUSM;              
                 zenc <= 1;        
                 zrst <= 1;
                 correct_cntn <= 1;           
                 zse <= 1;         
                 fsmn <= adheader;
                 decn <= 1;              
              end              
           end     
        end // case: idle
        loadkey: begin
           if (sdi_valid) begin
              sdi_ready <= 1;
              if (sdi_data[31:28] == LDKEY) begin
                 fsmn <= keyheader;               
              end             
           end
        end
        keyheader: begin
           if (sdi_valid) begin
              sdi_ready <= 1;
              if (sdi_data[31:28] == KEY) begin
                 fsmn <= storekey;               
              end             
           end
           else if (pdi_valid) begin
              if (pdi_data[31:28] == NENC) begin
                 moden <= ROMULUSN;              
                 zenc <= 1;        
                 zrst <= 1;
                 correct_cntn <= 1;           
                 zse <= 1;         
                 fsmn <= adheader;
                 decn <= 0;              
              end
              else if (pdi_data[31:28] == NDEC) begin
                 moden <= ROMULUSN;              
                 zenc <= 1;        
                 zrst <= 1;
                 correct_cntn <= 1;           
                 zse <= 1;         
                 fsmn <= adheader;
                 decn <= 1;             
              end
              else if (pdi_data[31:28] == MENC) begin
                 moden <= ROMULUSM;              
                 zenc <= 1;        
                 zrst <= 1;
                 correct_cntn <= 1;           
                 zse <= 1;         
                 fsmn <= adheader;
                 decn <= 0;              
              end
	      else if (pdi_data[31:28] == MDEC) begin
                 moden <= ROMULUSM;              
                 zenc <= 1;        
                 zrst <= 1;
                 correct_cntn <= 1;           
                 zse <= 1;         
                 fsmn <= adheader;
                 decn <= 1;              
              end
	      else if (pdi_data[31:28] == MENC2) begin
                 moden <= ROMULUSM;              
                 zenc <= 1;        
                 zrst <= 1;
                 correct_cntn <= 1;           
                 zse <= 1;         
                 fsmn <= tagheader;
                 decn <= 0;              
              end
	      else if (pdi_data[31:28] == MDEC2) begin
                 moden <= ROMULUSM;              
                 zenc <= 1;        
                 zrst <= 1;
                 correct_cntn <= 1;           
                 zse <= 1;         
                 fsmn <= adheader;
                 decn <= 1;              
              end              
           end
        end
        storekey: begin
           if (sdi_valid) begin
              sdi_ready <= 1;
              xrst <= 1;
              xenc <= 1;
              xse <= 1;
              if (cnt == 5'h0F) begin
                 cntn <= 6'h01;
                 fsmn <= idle;           
              end
              else begin
                 cntn <= {cnt[4:0], cnt[5]^cnt[4]^1'b1};                
              end
           end
        end // case: storekey
        nonceheader: begin
           if (pdi_valid) begin
              pdi_ready <= 1;
              if (pdi_data[31:28] == Npub) begin
                 fsmn <= storen;             
              end             
           end
        end
        storen: begin
           if (pdi_valid) begin
              pdi_ready <= 1;
              yenc <= 1;
              yse <= 1;
              yrst <= 1;                      
              if (cnt == 5'h0F) begin
                 domain <= nonce_domain;
                 //zenc <= 1;
                 //zse <= 1;
                 //if (counter != INITCTR) begin
                 // xse <= 1;
                 // xenc <= 1;              
                 //end           
                 cntn <= 6'h01;
                 fsmn <= encryptn;               
              end
              else begin
                 cntn <= {cnt[4:0], cnt[5]^cnt[4]^1'b1};                
              end
           end
        end // case: storen
        adheader: begin
           if (pdi_valid) begin
              pdi_ready <= 1;
              if (pdi_data[31:28] == AD) begin
                 seglenn <= pdi_data[15:0];
                 flagsn <= pdi_data[27:24];              
                 if ((pdi_data[25] == 1) && (pdi_data[15:0] < 16)) begin
                    fsmn <= storeadsp;
                 end
                 else begin
                    fsmn <= storeadsf;
                 end
              end             
           end
        end // case: adheader
        adheader2: begin
           if (pdi_valid) begin
              pdi_ready <= 1;
              if (pdi_data[31:28] == AD) begin
                 seglenn <= pdi_data[15:0];
                 flagsn <= pdi_data[27:24];              
                 if ((pdi_data[25] == 1) && (pdi_data[15:0] < 16)) begin
                    fsmn <= storeadtp;
                 end
                 else begin
                    fsmn <= storeadtf;
                 end
              end             
           end
        end // case: adheader2  
        storeadsf: begin
           if (pdi_valid) begin
              pdi_ready <= 1;                 
              senc <= 1;
              sse <= 1;
              if (cnt == 5'h01) begin
                 seglenn <= seglen - 16;
              end       
              if (cnt == 5'h0F) begin
                 if (counter != INITCTR2) begin
                    xse <= 1;
                    xenc <= 1;              
                 end 
                 cntn <= 6'h01;
                 zenc <= 1;
                 zse <= 1;
                 if (seglen == 0) begin          
                    if (flags[1] == 1) begin
                       if (mode == ROMULUSN) begin
                          fsmn <= nonceheader;
			  nonce_domainn <= nadfinal;
			  domain <= nadfinal;
                       end
                       else if (mode == ROMULUSM) begin
                          fsmn <= macheader;
			  nonce_domainn <= mmacfinal;
			  domain <= mmacnormal;
			  adevenn <= 0;
			  adpadn <= 0;			  
                       end                                          
                    end
                    else begin
                       fsmn <= adheader2;
		       if (mode == ROMULUSN) begin
			  domain <= nadnormal;       
		       end
		       else if (mode == ROMULUSM) begin
			  domain <= madnormal;			  
		       end
                    end
                 end
                 else if (seglen < 16) begin
                    fsmn <= storeadtp;
                    if (mode == ROMULUSN) begin
		       domain <= nadnormal;       
		    end
		    else if (mode == ROMULUSM) begin
		       domain <= madnormal;			  
		    end
                 end
                 else begin
                    fsmn <= storeadtf;
		    if (mode == ROMULUSN) begin
		       domain <= nadnormal;       
		    end
		    else if (mode == ROMULUSM) begin
		       domain <= madnormal;			  
		    end
                 end
              end
              else begin
                 cntn <= {cnt[4:0], cnt[5]^cnt[4]^1'b1};                
              end
           end     
        end     
        storeadsp: begin
           case (cnt) 
             6'h01: begin
                if (seglen > 0) begin
                   if (pdi_valid) begin
                      pdi_ready <= 1;                 
                      senc <= 1;
                      sse <= 1;
                      cntn <= {cnt[4:0], cnt[5]^cnt[4]^1'b1};           
                   end                     
                end // if (seglen >= 0)
                else begin
                   pdi <= 0;               
                   senc <= 1;
                   sse <= 1;
                   cntn <= {cnt[4:0], cnt[5]^cnt[4]^1'b1};                                 
                end // else: !if(seglen >= 0)
             end // case: 6'h01      
             6'h03: begin
                if (seglen > 4) begin
                   if (pdi_valid) begin
                      pdi_ready <= 1;                 
                      senc <= 1;
                      sse <= 1;
                      cntn <= {cnt[4:0], cnt[5]^cnt[4]^1'b1};           
                   end                     
                end // if (seglen >= 0)
                else begin
                   pdi <= 0;               
                   senc <= 1;
                   sse <= 1;
                   cntn <= {cnt[4:0], cnt[5]^cnt[4]^1'b1};                                 
                end             
             end
             6'h07: begin
                if (seglen > 8) begin
                   if (pdi_valid) begin
                      pdi_ready <= 1;                 
                      senc <= 1;
                      sse <= 1;
                      cntn <= {cnt[4:0], cnt[5]^cnt[4]^1'b1};           
                   end                     
                end // if (seglen >= 0)
                else begin
                   pdi <= 0;               
                   senc <= 1;
                   sse <= 1;
                   cntn <= {cnt[4:0], cnt[5]^cnt[4]^1'b1};                                 
                end             
             end
             6'h0F: begin
                seglenn <= 0;
                if (seglen > 12) begin
                   if (pdi_valid) begin
                      if (counter != INITCTR2) begin
                         xse <= 1;
                         xenc <= 1;                 
                      end 
                      pdi_ready <= 1;
                      pdi <= {pdi_data[31:4],seglen[3:0]};                                 
                      senc <= 1;
                      sse <= 1;
                      zenc <= 1;
                      zse <= 1; 
                      domain <= nadpadded;
                      nonce_domainn <= nadpadded;                      
                      cntn <= 6'h01;
                      if (mode == ROMULUSN) begin
                         fsmn <= nonceheader;     
                      end
                      else if (mode == ROMULUSM) begin
                         fsmn <= macheader; 
			 adevenn <= 0;
			 adpadn <= 1;                       
                      end
                   end                     
                end // if (seglen >= 0)
                else begin
                   if (counter != INITCTR2) begin
                      xse <= 1;
                      xenc <= 1;                    
                   end 
                   pdi <= {28'h0,seglen[3:0]};                  
                   senc <= 1;
                   sse <= 1;
                   zenc <= 1;
                   zse <= 1;                               
                   domain <= nonce_domain;
                   nonce_domainn <= nadpadded;                 
                   cntn <= 6'h01;
                   if (mode == ROMULUSN) begin
                      fsmn <= nonceheader;    		      		      
                   end
                   else if (mode == ROMULUSM) begin
                      fsmn <= macheader;   
		      adevenn <= 0;
		      adpadn <= 1;                      
                   end
                end                             
             end // case: 6'h0F      
           endcase // case (cnt)              
        end // case: storeadsp
        storeadtf: begin
           if (pdi_valid) begin
              pdi_ready <= 1;                 
              yenc <= 1;
              yse <= 1;
              yrst <= 1;              
              if (cnt == 5'h01) begin
                 seglenn <= seglen - 16;
              end                                 
              if (cnt == 5'h0F) begin
                 cntn <= 6'h01;
                 if (flags[1] == 1) begin
		    if (mode == ROMULUSN) begin
                       nonce_domainn <= nadfinal; 
		    end
		    adevenn <= 1;
		    adpadn <= 1; 
                 end
                 fsmn <= encryptad;
              end
              else begin
                 cntn <= {cnt[4:0], cnt[5]^cnt[4]^1'b1};                
              end
           end
        end // case: storeadtf	
        storeadtp: begin
           case (cnt) 
             6'h01: begin
                if (seglen > 0) begin
                   if (pdi_valid) begin
                      pdi_ready <= 1;                 
                      yenc <= 1;
                      yse <= 1;
                      yrst <= 1;                      
                      cntn <= {cnt[4:0], cnt[5]^cnt[4]^1'b1};           
                   end                     
                end // if (seglen >= 0)
                else begin
                   pdi <= 0;
                   yenc <= 1;
                   yse <= 1;
                   yrst <= 1;                 
                   cntn <= {cnt[4:0], cnt[5]^cnt[4]^1'b1};                                 
                end // else: !if(seglen >= 0)
             end // case: 6'h01      
             6'h03: begin
                if (seglen > 4) begin
                   if (pdi_valid) begin
                      pdi_ready <= 1;                 
                      yenc <= 1;
                      yse <= 1;
                      yrst <= 1;                      
                      cntn <= {cnt[4:0], cnt[5]^cnt[4]^1'b1};           
                   end                     
                end // if (seglen >= 0)
                else begin
                   pdi <= 0;               
                   yenc <= 1;
                   yse <= 1;
                   yrst <= 1;                 
                   cntn <= {cnt[4:0], cnt[5]^cnt[4]^1'b1};                                 
                end             
             end
             6'h07: begin
                if (seglen > 8) begin
                   if (pdi_valid) begin
                      pdi_ready <= 1;                 
                      yenc <= 1;
                      yse <= 1;
                      yrst <= 1;                      
                      cntn <= {cnt[4:0], cnt[5]^cnt[4]^1'b1};           
                   end                     
                end // if (seglen >= 0)
                else begin
                   pdi <= 0;               
                   yenc <= 1;
                   yse <= 1;
                   yrst <= 1;                 
                   cntn <= {cnt[4:0], cnt[5]^cnt[4]^1'b1};                                 
                end             
             end
             6'h0F: begin
		adevenn <= 1;
		adpadn <= 1; 
                seglenn <= 0;
                if (seglen > 12) begin
                   if (pdi_valid) begin
                      pdi_ready <= 1;
                      pdi <= {pdi_data[31:4],seglen[3:0]};                 
                      yenc <= 1;
                      yse <= 1;
                      yrst <= 1;                      
                      cntn <= 6'h01;
                      nonce_domainn <= nadpadded;                      
                      cntn <= 6'h01;                                  
                      fsmn <= encryptad;                      
                   end                     
                end // if (seglen >= 0)
                else begin
                   pdi <= {28'h0,seglen[3:0]};                  
                   yenc <= 1;
                   yse <= 1;
                   yrst <= 1;    
                   nonce_domainn <= nadpadded;                 
                   cntn <= 6'h01;
                   fsmn <= encryptad;                 
                end                             
             end // case: 6'h0F      
           endcase // case (cnt)              
        end // case: storeadtp
        msgheader: begin
           if (pdi_valid) begin
              if (dec == 1) begin
                 if (pdi_data[31:28] == CIPHER) begin            
                    seglenn <= pdi_data[15:0];
                    flagsn <= pdi_data[27:24];           
                    if ((pdi_data[25] == 1) && (pdi_data[15:0] < 16)) begin
                       if (pdo_ready) begin
                          fsmn <= storemp;
                          pdi_ready <= 1;
                          pdo_valid <= 1;
                          pdo_data <= {PLAIN , pdi_data[27], 1'b0, pdi_data[25],pdi_data[25],pdi_data[23:0]};
                       end                     
                    end
                    else begin
                       if (pdo_ready) begin
                          pdi_ready <= 1;
                          fsmn <= storemf;
                          pdo_valid <= 1;
                          pdo_data <= {PLAIN , pdi_data[27], 1'b0, pdi_data[25],pdi_data[25],pdi_data[23:0]};
                       end
                    end
                 end          
              end // if (dec == 1)
              else begin
                 seglenn <= pdi_data[15:0];
                 flagsn <= pdi_data[27:24];           
                 if ((pdi_data[25] == 1) && (pdi_data[15:0] < 16)) begin
                    if (pdo_ready) begin
                       fsmn <= storemp;
                       pdi_ready <= 1;
                       pdo_valid <= 1;
                       pdo_data <= {CIPHER , pdi_data[27], 1'b0, pdi_data[25],1'b0,pdi_data[23:0]};
                    end
                 end
                 else begin
                    if (pdo_ready) begin
                       pdi_ready <= 1;
                       fsmn <= storemf;
                       pdo_valid <= 1;
                       pdo_data <= {CIPHER, pdi_data[27], 1'b0, pdi_data[25],1'b0,pdi_data[23:0]};
                    end
                 end // if (pdo_ready)                 
              end // else: !if(dec == 1)              
           end // if (pdi_valid)           
        end // case: msgheader
        storemf: begin
           if (pdi_valid) begin
              if (pdo_ready) begin
                 decrypt <= {dec,dec,dec,dec};           
                 pdo_valid <= 1;
                 pdo_data <= pdo;                
                 pdi_ready <= 1;                 
                 senc <= 1;
                 sse <= 1;
                 if (cnt == 5'h01) begin
                    seglenn <= seglen - 16;
                 end
                 if (cnt == 5'h0F) begin
                    zenc <= 1;
                    zse <= 1;
                    yenc <= 1;
                    yse <= 1;
                    xenc <= 1;
                    xse <= 1;
                    correct_cntn <= 1; 		    
                    if ((seglen == 0) && (flags[1] == 1)) begin
		       if (mode == ROMULUSN) begin			  
			  fsmn <= encryptm;               
			  domain <= nmsgfinal;
			  nonce_domainn <= nadpadded;
		       end
		       else if (mode == ROMULUSM) begin
			  fsmn <= statuse;			  
		       end
                    end
                    else begin
		       if (mode == ROMULUSN) begin			  
			  fsmn <= encryptm;               
			  domain <= nmsgnormal;              
		       end
		       else if (mode == ROMULUSM) begin
			  fsmn <= encryptm;               
			  domain <= mmsgnormal;              			  
		       end
                    end
                    cntn <= 6'h01;
                    
                 end
                 else begin
                    cntn <= {cnt[4:0], cnt[5]^cnt[4]^1'b1};                
                 end
              end // if (pdo_ready)           
           end          
        end
        storemp: begin
           case (cnt) 
             6'h01: begin               
                if (seglen > 0) begin
                   if (pdo_ready) begin
                      if (pdi_valid) begin
                         pdo_valid <= 1;
                         case (seglen) 
                           1: begin
                              pdo_data <= {pdo[31:24],24'h0};
                              decrypt <= {dec,3'b0};             
                           end
                           2: begin
                              pdo_data <= {pdo[31:16],16'h0};
                              decrypt <= {dec,dec,2'b0};                 
                           end
                           3: begin
                              pdo_data <= {pdo[31:8],8'h0};
                              decrypt <= {dec,dec,dec,1'b0};             
                           end
                           default: begin
                              pdo_data <= pdo;          
                              decrypt <= {dec,dec,dec,dec};                           
                           end
                         endcase // case (seglen)                        
                         pdi_ready <= 1;                 
                         senc <= 1;
                         sse <= 1;
                         cntn <= {cnt[4:0], cnt[5]^cnt[4]^1'b1};           
                      end                     
                   end             
                end             
                else begin
                   pdi <= 0;
                   senc <= 1;
                   sse <= 1;
                   cntn <= {cnt[4:0], cnt[5]^cnt[4]^1'b1};                                 
                end // else: !if(seglen >= 0)
             end // case: 6'h01      
             6'h03: begin
                if (seglen > 4) begin
                   if (pdo_ready) begin
                      if (pdi_valid) begin
                         pdo_valid <= 1;
                         case (seglen) 
                           5: begin
                              pdo_data <= {pdo[31:24],24'h0};           
                              decrypt <= {dec,3'b0};                          
                           end
                           6: begin
                              pdo_data <= {pdo[31:16],16'h0};
                              decrypt <= {dec,dec,2'b0};                 
                           end
                           7: begin
                              pdo_data <= {pdo[31:8],8'h0};
                              decrypt <= {dec,dec,dec,1'b0};             
                           end
                           default: begin
                              pdo_data <= pdo;          
                              decrypt <= {dec,dec,dec,dec};                           
                           end
                         endcase // case (seglen)                        
                         pdi_ready <= 1;                 
                         senc <= 1;
                         sse <= 1;
                         cntn <= {cnt[4:0], cnt[5]^cnt[4]^1'b1};           
                      end               
                   end      
                end // if (seglen >= 0)
                else begin
                   pdi <= 0;               
                   senc <= 1;
                   sse <= 1;                  
                   cntn <= {cnt[4:0], cnt[5]^cnt[4]^1'b1};                                 
                end             
             end
             6'h07: begin
                if (seglen > 8) begin
                   if (pdo_ready) begin
                      if (pdi_valid) begin
                         pdo_valid <= 1;
                         case (seglen) 
                           9: begin
                              pdo_data <= {pdo[31:24],24'h0};           
                              decrypt <= {dec,3'b0};             
                           end
                           10: begin
                              pdo_data <= {pdo[31:16],16'h0};
                              decrypt <= {dec,dec,2'b0};                 
                           end
                           11: begin
                              pdo_data <= {pdo[31:8],8'h0};
                              decrypt <= {dec,dec,dec,1'b0};             
                           end
                           default: begin
                              pdo_data <= pdo;          
                              decrypt <= {dec,dec,dec,dec};                           
                           end
                         endcase // case (seglen)                                                
                         pdi_ready <= 1;                 
                         senc <= 1;
                         sse <= 1;
                         cntn <= {cnt[4:0], cnt[5]^cnt[4]^1'b1};           
                      end               
                   end      
                end // if (seglen >= 0)
                else begin
                   pdi <= 0;               
                   senc <= 1;
                   sse <= 1;
                   cntn <= {cnt[4:0], cnt[5]^cnt[4]^1'b1};                                 
                end             
             end
             6'h0F: begin
                seglenn <= 0;
                if (seglen > 12) begin
                   if (pdo_ready) begin               
                      if (pdi_valid) begin
                         pdo_valid <= 1;
                         case (seglen) 
                           13: begin
                              pdo_data <= {pdo[31:24],24'h0};           
                              decrypt <= {dec,3'b0};                          
                           end
                           14: begin
                              pdo_data <= {pdo[31:16],16'h0};
                              decrypt <= {dec,dec,2'b0};                 
                           end
                           15: begin
                              pdo_data <= {pdo[31:8],8'h0};
                              decrypt <= {dec,dec,dec,1'b0};             
                           end
                           default: begin
                              pdo_data <= pdo;          
                              decrypt <= {dec,dec,dec,dec};              
                           end
                         endcase // case (seglen)
			 if (mode == ROMULUSN) begin
                            domain <= nmsgpadded;
                            zenc <= 1;
                            zse <= 1;
                            correct_cntn <= 1;           
                            yenc <= 1;
                            yse <= 1;
                            xenc <= 1;
                            xse <= 1;                                    
                            pdi_ready <= 1;
                            pdi <= {pdi_data[31:4],seglen[3:0]};                 
                            senc <= 1;
                            sse <= 1;
                            cntn <= 6'h01;
                            fsmn <= encryptm;
			 end // if (mode == ROMULUSN)
			 else if (mode == ROMULUSM) begin
			    fsmn <= statuse;			    
			 end
                      end            
                   end         
                end // if (seglen >= 0)
                else begin
		   if (mode == ROMULUSN) begin
                      domain <= nmsgpadded;
                      zenc <= 1;
                      zse <= 1;
                      correct_cntn <= 1;         
                      yenc <= 1;
                      yse <= 1;
                      xenc <= 1;
                      xse <= 1;                               
                      pdi <= {28'h0,seglen[3:0]};                  
                      senc <= 1;
                      sse <= 1;
                      cntn <= 6'h01;
                      fsmn <= encryptm;
		   end
                   else if (mode == ROMULUSM) begin
		      fsmn <= statuse;			    
		   end
                end                             
             end // case: 6'h0F      
           endcase // case (cnt)                   
        end // case: storemp
        encryptad: begin
           correct_cntn <= 0;
           tk1sn <= ~tk1s;         
           senc <= 1;
           xenc <= 1;
           yenc <= 1;
           zenc <= 1;
           cntn <= {constant2[4:0], constant2[5]^constant2[4]^1'b1};
           if (constant2 == FINCONST) begin
              cntn <= 6'h01;
              if (seglen == 0) begin
                 if (flags[1] == 1) begin
		    if (mode == ROMULUSN) begin
                       fsmn <= nonceheader;
                       seglenn <= 0;           
                       st0n <= 1;
                       c2n <= 0;    
		    end
		    else if (mode == ROMULUSM) begin
		       fsmn <= macheader;
                       seglenn <= 0;           
                       st0n <= 0;
                       c2n <= 0;
		    end		    
                 end
                 else begin
                    correct_cntn <= 1;
                    zenc <= 1;
                    zse <= 1;            
                    fsmn <= adheader;
                    c2n <= 1;                  
                 end    
              end // if (seglen == 0)	      
              else if (seglen < 16) begin
                 correct_cntn <= 1;
                 fsmn <= storeadsp;
                 zenc <= 1;
                 zse <= 1;
                 c2n <= 1;
              end
              else begin
                 correct_cntn <= 1;
                 fsmn <= storeadsf;
                 zenc <= 1;
                 zse <= 1;
                 c2n <= 1;
              end                                 
           end // if (cnt == FINCONST)    
        end // case: encryptad
	encryptmac: begin
           correct_cntn <= 0;
           tk1sn <= ~tk1s;         
           senc <= 1;
           xenc <= 1;
           yenc <= 1;
           zenc <= 1;
           cntn <= {constant2[4:0], constant2[5]^constant2[4]^1'b1};
           if (constant2 == FINCONST) begin
              cntn <= 6'h01;
              if (seglen == 0) begin
                 if (flags[1] == 1) begin
		    fsmn <= nonceheader;
                    seglenn <= 0;           
                    st0n <= 1;
                    c2n <= 0;
                 end
                 else begin
                    correct_cntn <= 1;
                    zenc <= 1;
                    zse <= 1;            
                    fsmn <= macheader;
                    c2n <= 1;                  
                 end    
              end // if (seglen == 0)	      
              else if (seglen < 16) begin
                 correct_cntn <= 1;
                 fsmn <= storemacsp;
                 zenc <= 1;
                 zse <= 1;
                 c2n <= 1;
              end
              else begin
                 correct_cntn <= 1;
                 fsmn <= storemacsf;
                 zenc <= 1;
                 zse <= 1;
                 c2n <= 1;
              end                                 
           end // if (cnt == FINCONST)    
        end // case: encryptmac	
	macheader: begin
           if (pdi_valid) begin
              pdi_ready <= 1;
              if (pdi_data[31:28] == PLAIN) begin
                 seglenn <= pdi_data[15:0];
                 flagsn <= pdi_data[27:24];              
                 if ((pdi_data[25] == 1) && (pdi_data[15:0] < 16)) begin
                    fsmn <= storemacsp;
                 end
                 else begin
                    fsmn <= storemacsf;
                 end
              end             
           end
        end // case: macheader
	macheader2: begin
           if (pdi_valid) begin
              pdi_ready <= 1;
              if (pdi_data[31:28] == PLAIN) begin
                 seglenn <= pdi_data[15:0];
                 flagsn <= pdi_data[27:24];              
                 if ((pdi_data[25] == 1) && (pdi_data[15:0] < 16)) begin
                    fsmn <= storemactp;
                 end
                 else begin
                    fsmn <= storemactf;
                 end
              end             
           end
        end // case: macheader2	
	storemacsf: begin
           if (pdi_valid) begin
              pdi_ready <= 1;                 
              senc <= 1;
              sse <= 1;
              if (cnt == 5'h01) begin
                 seglenn <= seglen - 16;
              end       
              if (cnt == 5'h0F) begin
                 if (counter != INITCTR2) begin
                    xse <= 1;
                    xenc <= 1;              
                 end 
                 cntn <= 6'h01;
                 zenc <= 1;
                 zse <= 1;
                 if (seglen == 0) begin          
                    if (flags[1] == 1) begin
                       fsmn <= nonceheader;
                       mevenn <= 0;
		       mpadn <= 0;			  
                       nonce_domainn <= mmacfinal^{4'h0,adeven,adpad,1'b0,1'b0};
                       domain <= nadfinal;                   
                    end
                    else begin
                       fsmn <= macheader2;
                       domain <= mmacnormal;                  
                    end
                 end
                 else if (seglen < 16) begin
                    fsmn <= storemactp;
                    domain <= mmacnormal;
                 end
                 else begin
                    fsmn <= storemactf;
                    domain <= mmacnormal;
                 end
              end
              else begin
                 cntn <= {cnt[4:0], cnt[5]^cnt[4]^1'b1};                
              end
           end     
        end // case: storemacsf
	storemacsp: begin
           case (cnt) 
             6'h01: begin
                if (seglen > 0) begin
                   if (pdi_valid) begin
                      pdi_ready <= 1;                 
                      senc <= 1;
                      sse <= 1;
                      cntn <= {cnt[4:0], cnt[5]^cnt[4]^1'b1};           
                   end                     
                end // if (seglen >= 0)
                else begin
                   pdi <= 0;               
                   senc <= 1;
                   sse <= 1;
                   cntn <= {cnt[4:0], cnt[5]^cnt[4]^1'b1};                                 
                end // else: !if(seglen >= 0)
             end // case: 6'h01      
             6'h03: begin
                if (seglen > 4) begin
                   if (pdi_valid) begin
                      pdi_ready <= 1;                 
                      senc <= 1;
                      sse <= 1;
                      cntn <= {cnt[4:0], cnt[5]^cnt[4]^1'b1};           
                   end                     
                end // if (seglen >= 0)
                else begin
                   pdi <= 0;               
                   senc <= 1;
                   sse <= 1;
                   cntn <= {cnt[4:0], cnt[5]^cnt[4]^1'b1};                                 
                end             
             end
             6'h07: begin
                if (seglen > 8) begin
                   if (pdi_valid) begin
                      pdi_ready <= 1;                 
                      senc <= 1;
                      sse <= 1;
                      cntn <= {cnt[4:0], cnt[5]^cnt[4]^1'b1};           
                   end                     
                end // if (seglen >= 0)
                else begin
                   pdi <= 0;               
                   senc <= 1;
                   sse <= 1;
                   cntn <= {cnt[4:0], cnt[5]^cnt[4]^1'b1};                                 
                end             
             end
             6'h0F: begin
                seglenn <= 0;
                if (seglen > 12) begin
                   if (pdi_valid) begin
                      if (counter != INITCTR2) begin
                         xse <= 1;
                         xenc <= 1;                 
                      end 
                      pdi_ready <= 1;
                      pdi <= {pdi_data[31:4],seglen[3:0]};                                 
                      senc <= 1;
                      sse <= 1;
                      zenc <= 1;
                      zse <= 1; 
                      domain <= mmacfinal^{4'h0,adeven,adpad,1'b0,1'b1};
                      nonce_domainn <= mmacfinal^{4'h0,adeven,adpad,1'b0,1'b1};
                      cntn <= 6'h01;
		      fsmn <= nonceheader;     
                   end                     
                end // if (seglen >= 0)
                else begin
                   if (counter != INITCTR2) begin
                      xse <= 1;
                      xenc <= 1;                    
                   end 
                   pdi <= {28'h0,seglen[3:0]};                  
                   senc <= 1;
                   sse <= 1;
                   zenc <= 1;
                   zse <= 1;
		   domain <= nonce_domain;		   
                   nonce_domainn <= mmacfinal^{4'h0,adeven,adpad,1'b0,1'b1};
                   cntn <= 6'h01;
                   fsmn <= nonceheader;    		      		      
                end                             
             end // case: 6'h0F      
           endcase // case (cnt)              
        end // case: storemacsp
	storemactf: begin
           if (pdi_valid) begin
              pdi_ready <= 1;                 
              yenc <= 1;
              yse <= 1;
              yrst <= 1;              
              if (cnt == 5'h01) begin
                 seglenn <= seglen - 16;
              end                                 
              if (cnt == 5'h0F) begin
                 cntn <= 6'h01;
                 if (flags[1] == 1) begin
		    if (seglen == 0) begin
		       nonce_domainn <= mmacfinal^{4'h0,adeven,adpad,1'b1,1'b0};
		    end
		    else begin
		       nonce_domainn <= mmacfinal^{4'h0,adeven,adpad,1'b0,1'b0};
		    end
                 end
                 fsmn <= encryptad;
              end
              else begin
                 cntn <= {cnt[4:0], cnt[5]^cnt[4]^1'b1};                
              end
           end
        end // case: storemactf
	storemactp: begin
           case (cnt) 
             6'h01: begin
                if (seglen > 0) begin
                   if (pdi_valid) begin
                      pdi_ready <= 1;                 
                      yenc <= 1;
                      yse <= 1;
                      yrst <= 1;                      
                      cntn <= {cnt[4:0], cnt[5]^cnt[4]^1'b1};           
                   end                     
                end // if (seglen >= 0)
                else begin
                   pdi <= 0;
                   yenc <= 1;
                   yse <= 1;
                   yrst <= 1;                 
                   cntn <= {cnt[4:0], cnt[5]^cnt[4]^1'b1};                                 
                end // else: !if(seglen >= 0)
             end // case: 6'h01      
             6'h03: begin
                if (seglen > 4) begin
                   if (pdi_valid) begin
                      pdi_ready <= 1;                 
                      yenc <= 1;
                      yse <= 1;
                      yrst <= 1;                      
                      cntn <= {cnt[4:0], cnt[5]^cnt[4]^1'b1};           
                   end                     
                end // if (seglen >= 0)
                else begin
                   pdi <= 0;               
                   yenc <= 1;
                   yse <= 1;
                   yrst <= 1;                 
                   cntn <= {cnt[4:0], cnt[5]^cnt[4]^1'b1};                                 
                end             
             end
             6'h07: begin
                if (seglen > 8) begin
                   if (pdi_valid) begin
                      pdi_ready <= 1;                 
                      yenc <= 1;
                      yse <= 1;
                      yrst <= 1;                      
                      cntn <= {cnt[4:0], cnt[5]^cnt[4]^1'b1};           
                   end                     
                end // if (seglen >= 0)
                else begin
                   pdi <= 0;               
                   yenc <= 1;
                   yse <= 1;
                   yrst <= 1;                 
                   cntn <= {cnt[4:0], cnt[5]^cnt[4]^1'b1};                                 
                end             
             end
             6'h0F: begin
		adevenn <= 1;
		adpadn <= 1; 
                seglenn <= 0;
                if (seglen > 12) begin
                   if (pdi_valid) begin
                      pdi_ready <= 1;
                      pdi <= {pdi_data[31:4],seglen[3:0]};                 
                      yenc <= 1;
                      yse <= 1;
                      yrst <= 1;                      
                      cntn <= 6'h01;
                      nonce_domainn <= mmacfinal^{4'h0,adeven,adpad,1'b1,1'b1};
                      cntn <= 6'h01;                                  
                      fsmn <= encryptmac;                      
                   end                     
                end // if (seglen >= 0)
                else begin
                   pdi <= {28'h0,seglen[3:0]};                  
                   yenc <= 1;
                   yse <= 1;
                   yrst <= 1;    
                   nonce_domainn <= mmacfinal^{4'h0,adeven,adpad,1'b1,1'b1};               
                   cntn <= 6'h01;
                   fsmn <= encryptmac;                 
                end                             
             end // case: 6'h0F      
           endcase // case (cnt)              
        end // case: storemactp	
        encryptn: begin
           correct_cntn <= 0;
           tk1sn <= ~tk1s;         
           senc <= 1;
           xenc <= 1;
           yenc <= 1;
           zenc <= 1;
           cntn <= {constant2[4:0], constant2[5]^constant2[4]^1'b1};
           if (constant2 == FINCONST) begin
	      if (mode == ROMULUSN) begin
		 cntn <= 6'h01;          
		 fsmn <= msgheader;
		 zrst <= 1;
		 zenc <= 1;
		 zse <= 1;
		 correct_cntn <= 1;              
		 c2n <= 1;      
	      end
	      else if (mode == ROMULUSM) begin
		 cntn <= 6'h01;
		 if (dec) begin
		    fsmn <= verifytag0;
		 end
		 else begin
		    fsmn <= outputtag0;
		 end
		 zrst <= 1;
		 zenc <= 1;
		 zse <= 1;
		 correct_cntn <= 1;              
		 c2n <= 1;
	      end
           end // if (cnt == FINCONST)     
        end // case: encryptn
        encryptm: begin
           correct_cntn <= 0;
           tk1sn <= ~tk1s;         
           senc <= 1;
           xenc <= 1;
           yenc <= 1;
           zenc <= 1;
           cntn <= {constant2[4:0], constant2[5]^constant2[4]^1'b1};
           if (constant2 == FINCONST) begin
              cntn <= 6'h01;
              if (seglen == 0) begin                              
                 if (flags[1] == 1) begin
                    if (dec == 1) begin
                       fsmn <= verifytag0;
                    end
                    else begin
                       fsmn <= outputtag0;
                    end
                    seglenn <= 0;           
                    st0n <= 1;
                    c2n <= 0;               
                 end
                 else begin
                    fsmn <= msgheader;
                    c2n <= 1;                  
                 end
              end
              else if (seglen < 16) begin
                 fsmn <= storemp;
                 c2n <= 1;
              end
              else begin
                 fsmn <= storemf;
                 c2n <= 1;
              end                                 
           end // if (cnt == FINCONST)
        end // case: encryptm
        outputtag0: begin
           if (pdo_ready) begin
              pdi <= 0;    
              pdo_valid <= 1;      
              pdo_data <= {TAG,4'h3,8'h0,16'h010};
              fsmn <= outputtag1;             
           end
        end
        outputtag1: begin
           if (pdo_ready) begin
              pdi <= 0;    
              senc <= 1;
              sse <= 1;              
              pdo_valid <= 1;      
              pdo_data <= pdo;
              cntn <= {cnt[4:0], cnt[5]^cnt[4]^1'b1};
              if (cnt == 6'h0F) begin
                 fsmn <= statuse;
                 cntn <= 6'h01;
              end
           end // if (pdo_ready)           
        end // case: outputtag1 
        verifytag0: begin
           if (pdi_valid) begin
              if (pdi_data[31:28] == TAG) begin
                 fsmn <= verifytag1;
                 pdi_ready <= 1;
              end             
           end     
        end
        verifytag1: begin
           if (pdi_valid) begin
              pdi_ready <= 1;
              if (cnt == 6'h0F) begin
                 cntn <= 6'h01;
                 if ((pdo != 32'h0) || (dec == 0)) begin
                    fsmn <= statusdf;
                 end
                 else begin
                    fsmn <= statusds;
                 end // else: !if((pdo != 32'h0) || (dec == 0))          
              end // if (cnt == 6'h0F)
              else begin
                 cntn <= {cnt[4:0], cnt[5]^cnt[4]^1'b1};     
                 senc <= 1;
                 sse <= 1;         
                 if (pdo != 32'h0) begin
                    decn <= 0;           
                 end
              end // else: !if(cnt == 6'h0F)          
           end // if (pdi_valid)           
        end // case: verifytag1  
        statusds: begin
           if (pdo_ready) begin
              pdo_valid <= 1;
              pdo_data <= {SUCCESS, 28'h0};
              do_last <= 1;
              fsmn <= idle;
              xse <= 1;
              xenc <= 1;
           end
        end     
        statusdf: begin
           if (pdo_ready) begin
              pdo_valid <= 1;
              pdo_data <= {FAILURE, 28'h0};
              do_last <= 1;
              fsmn <= idle;
              xse <= 1;
              xenc <= 1;
           end
        end     
        statuse: begin
           if (pdo_ready) begin
              pdo_valid <= 1;
              pdo_data <= {SUCCESS, 28'h0};
              do_last <= 1;
              fsmn <= idle;
              xse <= 1;
              xenc <= 1;
           end
        end
	tagheader: begin
           if (pdi_valid) begin
              pdi_ready <= 1;
              if (pdi_data[31:28] == TAG) begin
                 fsmn <= storetag;
              end             
           end
        end // case: tagheader
	storetag: begin
	   if (pdi_valid) begin
              pdi_ready <= 1;                 
              senc <= 1;
              sse <= 1;
              if (cnt == 5'h0F) begin
		 if (counter != INITCTR2) begin
                    xse <= 1;
                    xenc <= 1;              
                 end 
                 cntn <= 6'h01;
                 zenc <= 1;
                 zse <= 1;
		 domain <= mmsgnormal;
		 fsmn <= nonceheader2;		 
	      end // if (cnt == 5'h0F)
	      else begin
		 cntn <= {cnt[4:0], cnt[5]^cnt[4]^1'b1};                
	      end
	   end
	end // case: storetag
	nonceheader2: begin
           if (pdi_valid) begin
              pdi_ready <= 1;
              if (pdi_data[31:28] == Npub) begin
                 fsmn <= storen;             
              end             
           end
        end
        storen2: begin
           if (pdi_valid) begin
              pdi_ready <= 1;
              yenc <= 1;
              yse <= 1;
              yrst <= 1;                      
              if (cnt == 5'h0F) begin
                 domain <= mmsgnormal;
                 //zenc <= 1;
                 //zse <= 1;
                 //if (counter != INITCTR) begin
                 // xse <= 1;
                 // xenc <= 1;              
                 //end           
                 cntn <= 6'h01;
                 fsmn <= encrypttag;               
              end
              else begin
                 cntn <= {cnt[4:0], cnt[5]^cnt[4]^1'b1};                
              end
           end
        end // case: storen2
	encrypttag: begin
           correct_cntn <= 0;
           tk1sn <= ~tk1s;         
           senc <= 1;
           xenc <= 1;
           yenc <= 1;
           zenc <= 1;
           cntn <= {constant2[4:0], constant2[5]^constant2[4]^1'b1};
           if (constant2 == FINCONST) begin
	      cntn <= 6'h01;
	      fsmn <= msgheader;
	      zrst <= 1;
	      zenc <= 1;
	      zse <= 1;
	      correct_cntn <= 1;              
	      c2n <= 1;
           end // if (cnt == FINCONST)     
        end // case: encrypttag
	/*hmsgheader: begin
	   if (pdi_valid) begin
	      pdi_ready <= 1;
	      if (pdi_data[31:28] == PLAIN) begin
		 seglenn <= pdi_data[15:0];
                 flagsn <= pdi_data[27:24];
		 if ((pdi_data[25] == 1) && (pdi_data[15:0] < 32)) begin
		    fsmn <= storehmsgp;
		 end
		 else begin
		    fsmn <= storehmsg0;
		 end
	      end
	   end
	end // case: hmsgheader
	storehmsg0:begin
	   if (pdi_valid) begin
	      pdi_ready <= 1;
	      cntn <= {cnt[4:0], cnt[5]^cnt[4]^1'b1};
	      if (cnt == 5'h01) begin
                 seglenn <= seglen - 16;
              end
	      if (cnt == 5'h0F) begin
		 cnt <= 5'h01;		 
		 fsmn <= storehsmg0;
	      end
	   end
	end
	end	
	storehmsg1: begin
	   if (pdi_valid) begin
	      pdi_ready <= 1;
	      cntn <= {cnt[4:0], cnt[5]^cnt[4]^1'b1};
	      if (cnt == 5'h01) begin
                 seglenn <= seglen - 16;
              end
	      if (cnt == 5'h0F) begin
		 cnt <= 5'h01;
		 fsmn <= encrypthash;
	      end
	   end
	end
	encrypthash */
      endcase // case (fsm)      
   end
   
endmodule // api
