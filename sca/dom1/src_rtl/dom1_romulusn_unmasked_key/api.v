/*
 Designer: Mustafa Khairallah
 Nanyang Technological University
 Singapore
 Date: July, 2021
 */

/*
 GMU LWC-compliant DOM1-Romulus-N control unit.
 */

module api (/*AUTOARG*/
   // Outputs
   pdo_data, pdi, pdi_ready, sdi_ready, rdi_ready, pdo_valid, do_last,
   domain, decrypt, swr, srst, kwr, ken, kcrct, twr, ten, tcrct, crst,
   cen, ccrct, correct_cnt, rnd_cnst, tbcen, tk1s,
   // Inputs
   counter, pdi_data, pdo, sdi_data, pdi_valid, sdi_valid, rdi_valid,
   pdo_ready, clk, rst
   ) ;

   // Skinny Final Round Constant
   parameter FINCONST    = 7'b011010;
   // Block Counter Initial Constant
   parameter INITCTR     = 56'h02000000000000;
   parameter INITCTR2    = 56'h01000000000000;
   
   // API Commands : HASH not supported yet.    
   parameter ENC         = 4'h2;
   parameter DEC         = 4'h3;
   parameter LDKEY       = 4'h4;
   parameter ACTKEY      = 4'h7;
   parameter HASH        = 4'h8;
   parameter SUCCESS     = 4'he;
   parameter FAILURE     = 4'hf;

   // Segment Types : only AD, Npub, Ptxt, Ctxt
   // and Tg are supported.
   parameter RSVRD0      = 4'h0;
   parameter AD          = 4'h1;
   parameter NpubAD      = 4'h2;
   parameter ADNpub      = 4'h3;
   parameter Ptxt        = 4'h4;
   parameter Ctxt        = 4'h5;
   parameter CtxtTg      = 4'h6;
   parameter HshMsg      = 4'h7;
   parameter Tg          = 4'h8;
   parameter HshVlu      = 4'h9;
   parameter Length      = 4'ha;
   parameter RSVRD1      = 4'hb;
   parameter Key         = 4'hc;
   parameter Npub        = 4'hd;
   parameter Nsec        = 4'he;
   parameter EncNsec     = 4'hf;
   
   // Mode Domains              
   parameter adnormal    =  8;
   parameter adfinal     = 24;
   parameter adpadded    = 26;
   parameter msgnormal   =  4;
   parameter msgfinal    = 20;
   parameter msgpadded   = 21; 

   // FSM States
   parameter idle        =  0;
   parameter loadkey     =  1;
   parameter keyheader   =  2;
   parameter storekey    =  3;
   parameter nonceheader =  4;
   parameter storen      =  5;
   parameter adheader    =  6;
   parameter adheader2   =  7;
   parameter msgheader   =  8;
   parameter storeadsf   =  9;
   parameter storeadtf   = 10;
   parameter storeadsp   = 11;
   parameter storeadtp   = 12;
   parameter storemf     = 13;
   parameter storemp     = 14;
   parameter encryptad   = 15;
   parameter encryptn    = 16;
   parameter encryptm    = 17;
   parameter outputtag0  = 18;
   parameter outputtag1  = 19;   
   parameter verifytag0  = 20;
   parameter verifytag1  = 21;
   parameter statuse     = 22;  
   parameter statusdf    = 23;  
   parameter statusds    = 24;

   output reg [31:0] pdo_data, pdi;
   output reg        pdi_ready, sdi_ready, rdi_ready, pdo_valid, do_last;

   output reg [7:0]  domain;
   output reg [3:0]  decrypt;
   output reg        swr, srst;
   output reg        kwr, ken, kcrct;
   output reg        twr, ten, tcrct;
   output reg        crst, cen, ccrct;
   output reg        correct_cnt;
   output reg [5:0]  rnd_cnst;
   output reg [4:0]  tbcen;
   output reg        tk1s;
   
   input [55:0]      counter;   
   input [31:0]      pdi_data, pdo, sdi_data;
   input             pdi_valid, sdi_valid, rdi_valid, pdo_ready;

   input             clk, rst;

   reg [31:0] 	     tag_acc, tag_accn;   
   reg [4:0]         fsm, fsmn;
   reg [15:0]        seglen, seglenn;  
   reg [3:0]         flags, flagsn;
   reg               dec, decn;
   reg [7:0]         nonce_domain, nonce_domainn;
   reg [5:0]         cnt, cntn;
   reg [4:0]         tbcenn;   
   reg               correct_cntn;
   reg               st0, st0n;
   reg               c2, c2n;
   reg               tk1sn;

   wire [31:0] 	     final_tag_acc;   
   wire [3:0]        cmd, scmd;

   assign cmd  = pdi_data[31:28];
   assign scmd = sdi_data[31:28];  

   assign final_tag_acc = pdo ^ tag_acc; 

   always @ (posedge clk) begin
      if (rst) begin
         fsm          <= idle;
         seglen       <= 0;
         flags        <= 0;
         dec          <= 0;
         correct_cnt  <= 1;
         cnt          <= 6'h01;   
         st0          <= 0;
         c2           <= 0;        
         tk1s         <= 1;  
         tbcen        <= 5'h01;         
         nonce_domain <= adpadded; 
	 tag_acc <= 0;	 
      end
      else begin
         fsm          <= fsmn;
         seglen       <= seglenn;
         flags        <= flagsn;
         dec          <= decn;
         cnt          <= cntn;    
         nonce_domain <= nonce_domainn;
         st0          <= st0n;
         c2           <= c2n;
         tk1s         <= tk1sn;
         tbcen        <= tbcenn;        
         correct_cnt  <= correct_cntn;
	 tag_acc <= tag_accn;	 
      end
   end // always @ (posedge clk)

   always @ ( /*AUTOSENSE*/c2 or cmd or cnt or correct_cnt or counter
	     or dec or final_tag_acc or flags or fsm or nonce_domain
	     or pdi_data or pdi_valid or pdo or pdo_ready or scmd
	     or sdi_valid or seglen or st0 or tag_acc or tbcen or tk1s) begin
      pdo_data      <= 0;      
      pdi           <= pdi_data;    
      do_last       <= 0;               
      domain        <= 0;
      decrypt       <= 0;
      swr           <= 0;
      srst          <= 0;
      kwr           <= 0;
      ken           <= 0;
      kcrct         <= 0;
      twr           <= 0;
      ten           <= 0;
      tcrct         <= 0;
      crst          <= 0;
      cen           <= 0;
      ccrct         <= 0;
      tbcenn        <= tbcen;
      tk1sn         <= tk1s;      
      sdi_ready     <= 0;
      pdi_ready     <= 0;
      rdi_ready     <= 0;      
      pdo_valid     <= 0;
      nonce_domainn <= nonce_domain;      
      fsmn          <= fsm;
      seglenn       <= seglen; 
      flagsn        <= flags;
      decn          <= dec;
      correct_cntn  <= correct_cnt;
      st0n          <= st0;
      c2n           <= c2;           
      cntn          <= cnt;
      rnd_cnst      <= cnt;
      tag_accn      <= tag_acc;      
      case (fsm)
        idle: begin
           pdi_ready <= 1;
           srst <= 1;
           tk1sn <= 1;     
           nonce_domainn <= adpadded;
	   tag_accn <= 0;	   
           if (pdi_valid) begin
              if (cmd == ACTKEY) begin
                 fsmn <= loadkey;                
              end
              else if (cmd == ENC) begin
                 crst <= 1;
                 correct_cntn <= 1;
                 decn <= 0;
                 fsmn <= adheader;                  
              end
              else if (cmd == DEC) begin
                 crst <= 1;
                 correct_cntn <= 1;
                 decn <= 1;
                 fsmn <= adheader;                  
              end
           end     
        end // case: idle
        loadkey: begin
           sdi_ready <= 1;         
           if (sdi_valid) begin
              if (scmd == LDKEY) begin
                 fsmn <= keyheader;              
              end
           end
           else begin
              pdi_ready <= 1;
              if (pdi_valid) begin
                 if (cmd == ENC) begin
                    crst <= 1;
                    correct_cntn <= 1;
                    decn <= 0;
                    fsmn <= adheader;               
                 end
                 else if (cmd == DEC) begin
                    crst <= 1;
                    correct_cntn <= 1;
                    decn <= 1;
                    fsmn <= adheader;               
                 end
              end // if (pdi_valid)           
           end // else: !if(sdi_valid)     
        end // case: loadkey
        keyheader: begin
           sdi_ready <= 1;
           if (sdi_valid) begin
              if (scmd == Key) begin
                 fsmn <= storekey;               
              end
           end
        end // case: keyheader
        storekey: begin
           sdi_ready <= 1;
           if (sdi_valid) begin
              kwr <= 1;
              if (cnt == 6'h1f) begin
                 cntn <= 6'h01;
                 fsmn <= idle;
              end
              else begin
                 cntn <= {cnt[4:0], cnt[5]^cnt[4]^1'b1};
              end
           end
        end // case: storekey
        nonceheader: begin
           pdi_ready <= 1;
           if (pdi_valid) begin              
              if (cmd == Npub) begin
                 fsmn <= storen;             
              end             
           end
        end // case: nonceheader
        storen: begin
           pdi_ready <= 1;
           if (pdi_valid) begin
              twr <= 1;
              if (cnt == 6'h3b) begin
                 domain <= nonce_domain;
                 cntn <= 6'h01;
                 fsmn <= encryptn;
              end
           end
           else begin
              cntn <= {cnt[4:0], cnt[5]^cnt[4]^1'b1};                
           end
        end // case: storen
        adheader: begin
           pdi_ready <= 1;
           if (pdi_valid) begin
              if (cmd == AD) begin
                 seglenn <= pdi_data[15:0];
                 flagsn <= pdi_data[27:24];              
                 if ((pdi_data[25] == 1) && (pdi_data[15:0] < 16)) begin
                    fsmn <= storeadsp;
                 end
                 else begin
                    fsmn <= storeadsf;
                 end
              end             
           end // if (pdi_valid)           
        end // case: adheader
        adheader2: begin
           pdi_ready <= 1;
           if (pdi_valid) begin              
              if (cmd == AD) begin
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
	      swr <= 1;
	      if (cnt == 5'h01) begin
                 seglenn <= seglen - 16;
	      end       
	      if (cnt == 6'h3b) begin
                 if (counter != INITCTR2) begin
                    kcrct <= 1;
                 end 
                 cntn <= 6'h01;
                 ccrct <= 1;
                 if (seglen == 0) begin          
                    if (flags[1] == 1) begin
		       fsmn <= nonceheader;
		       nonce_domainn <= adfinal;
		       domain <= adfinal;                   
                    end
                    else begin
		       fsmn <= adheader2;
		       domain <= adnormal;                  
                    end
                 end
                 else if (seglen < 16) begin
                    fsmn <= storeadtp;
                    domain <= adnormal;
                 end
                 else begin
                    fsmn <= storeadtf;
                    domain <= adnormal;
                 end
	      end // if (cnt == 6'h3b)
	      else begin
                 cntn <= {cnt[4:0], cnt[5]^cnt[4]^1'b1};                
	      end // else: !if(cnt == 6'h3b)
	   end // if (pdi_valid)	      	   
        end // case: storeadsf  
        storeadsp: begin
           case (cnt) 
             6'h01: begin
                if (seglen > 0) begin                   
                   if (pdi_valid) begin
                      pdi_ready <= 1;
                      swr <= 1;
                      cntn <= {cnt[4:0], cnt[5]^cnt[4]^1'b1};           
                   end                     
                end // if (seglen >= 0)
                else begin
                   pdi <= 0;               
                   swr <= 1;
                   cntn <= {cnt[4:0], cnt[5]^cnt[4]^1'b1};
                end // else: !if(seglen >= 0)
             end // case: 6'h01      
             6'h03: begin
                if (seglen > 0) begin                   
                   if (pdi_valid) begin
                      pdi_ready <= 1;
                      swr <= 
                      cntn <= {cnt[4:0], cnt[5]^cnt[4]^1'b1};           
                   end                     
                end // if (seglen >= 0)
                else begin
                   pdi <= 0;               
                   swr <= 1;
                   cntn <= {cnt[4:0], cnt[5]^cnt[4]^1'b1};
                end             
             end // case: 6'h03
             6'h07: begin
                if (seglen > 4) begin
                   if (pdi_valid) begin
		      pdi_ready <= 1;
		      swr <= 1;
		      cntn <= {cnt[4:0], cnt[5]^cnt[4]^1'b1};           
                   end                     
                end // if (seglen >= 0)
                else begin
		   pdi <= 0;               
		   swr <= 1;
		   cntn <= {cnt[4:0], cnt[5]^cnt[4]^1'b1};
		end // else: !if(seglen > 4)
	     end // case: 6'h07	     
             6'h0f: begin
		if (seglen > 4) begin
                   if (pdi_valid) begin
		      pdi_ready <= 1;
		      swr <= 1;
		      cntn <= {cnt[4:0], cnt[5]^cnt[4]^1'b1};           
                   end                     
                end // if (seglen >= 0)
                else begin
		   pdi <= 0;               
		   swr <= 1;
		   cntn <= {cnt[4:0], cnt[5]^cnt[4]^1'b1};
		end // else: !if(seglen > 4)
             end // case: 6'h0f      
             6'h1f: begin
                if (seglen > 8) begin
		   if (pdi_valid) begin
		      pdi_ready <= 1;
		      swr <= 1;
		      cntn <= {cnt[4:0], cnt[5]^cnt[4]^1'b1};           
                   end                 
                end // if (seglen >= 0)
                else begin
		   pdi <= 0;               
		   swr <= 1;
		   cntn <= {cnt[4:0], cnt[5]^cnt[4]^1'b1};
                end // else: !if(seglen > 8)		
             end // case: 6'h1f      
             6'h3e: begin
		if (seglen > 8) begin
		   if (pdi_valid) begin
		      pdi_ready <= 1;		      
		      swr <= 1;
		      cntn <= {cnt[4:0], cnt[5]^cnt[4]^1'b1};           
                   end                 
                end // if (seglen >= 0)
                else begin		   
		   pdi <= 0;               
		   swr <= 1;
		   cntn <= {cnt[4:0], cnt[5]^cnt[4]^1'b1};
                end // else: !if(seglen > 8)
             end // case: 6'h3e
             6'h3d: begin
                if (seglen > 12) begin
                   pdi_ready <= 1;                 
                   if (pdi_valid) begin                      
                      swr <= 1;
                      cntn <= {cnt[4:0], cnt[5]^cnt[4]^1'b1};           
                   end                     
                end // if (seglen >= 0)
                else begin
                   pdi <= 0;               
                   swr <= 1;
                   cntn <= {cnt[4:0], cnt[5]^cnt[4]^1'b1};                                 
                end // else: !if(seglen >= 0)
             end // case: 6'h3d                   
             6'h3b: begin
                seglenn <= 0;
                if (seglen > 12) begin
                   pdi_ready <= 1;
                   if (pdi_valid) begin
                      if (counter != INITCTR2) begin
                         kcrct <= 1;
                      end                       
                      pdi <= {pdi_data[31:4],seglen[3:0]};                                 
                      swr <= 1;
                      ccrct <= 1;
                      domain <= adpadded;
                      nonce_domainn <= adpadded;                      
                      cntn <= 6'h01;
                      fsmn <= nonceheader;                    
                   end                     
                end // if (seglen >= 0)
                else begin
                   if (counter != INITCTR2) begin
                      kcrct <= 1;
                   end 
                   pdi <= {28'h0,seglen[3:0]};                  
                   swr <= 1;
                   ccrct <= 1;             
                   domain <= nonce_domain;
                   nonce_domainn <= adpadded;                 
                   cntn <= 6'h01;
                   fsmn <= nonceheader;               
                end                             
             end // case: 6'h0F      
           endcase // case (cnt)              
        end // case: storeadsp
        storeadtf: begin
           if (pdi_valid) begin
              pdi_ready <= 1; 
              twr <= 1;       
              if (cnt == 5'h01) begin
                 seglenn <= seglen - 16;
              end                                 
              if (cnt == 6'h0f) begin
                 cntn <= 6'h01;
                 if (flags[1] == 1) begin
                    nonce_domainn <= adfinal;                 
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
                   pdi_ready <= 1;                 
                   if (pdi_valid) begin                      
                      twr <= 1;
                      cntn <= {cnt[4:0], cnt[5]^cnt[4]^1'b1};           
                   end                     
                end 
                else begin
                   pdi <= 0;
                   twr <= 1;
                   cntn <= {cnt[4:0], cnt[5]^cnt[4]^1'b1};                                 
                end 
             end // case: 6'h01      
             6'h03: begin
                if (seglen > 4) begin
                   pdi_ready <= 1;
                   if (pdi_valid) begin
                      twr <= 1;
                      cntn <= {cnt[4:0], cnt[5]^cnt[4]^1'b1};           
                   end                     
                end 
                else begin
                   pdi <= 0;
                   twr <= 1;
                   cntn <= {cnt[4:0], cnt[5]^cnt[4]^1'b1};
                end
             end // case: 6'h03      
             6'h07: begin
                if (seglen > 8) begin
                   pdi_ready <= 1;                 
                   if (pdi_valid) begin                      
                      twr <= 1;
                      cntn <= {cnt[4:0], cnt[5]^cnt[4]^1'b1};           
                   end                     
                end 
                else begin
                   pdi <= 0;
                   twr <= 1;
                   cntn <= {cnt[4:0], cnt[5]^cnt[4]^1'b1};
                end             
             end // case: 6'h07      
             6'h0F: begin
                seglenn <= 0;
                if (seglen > 12) begin
                   pdi_ready <= 1;
                   if (pdi_valid) begin                      
                      pdi <= {pdi_data[31:4],seglen[3:0]};
                      twr <= 1;
                      cntn <= 6'h01;
                      nonce_domainn <= adpadded;                      
                      fsmn <= encryptad;                      
                   end                     
                end
                else begin
                   pdi <= {28'h0,seglen[3:0]};  
                   twr <= 1;                
                   nonce_domainn <= adpadded;                 
                   cntn <= 6'h01;
                   fsmn <= encryptad;                 
                end                             
             end // case: 6'h0F      
           endcase // case (cnt)              
        end // case: storeadtp
        msgheader: begin           
           if (pdi_valid) begin
              if (dec) begin
                 if (cmd == Ctxt) begin
                    seglenn <= pdi_data[15:0];
                    flagsn <= pdi_data[27:24];
                    if ((pdi_data[25] == 1) && (pdi_data[15:0] < 16)) begin
                       if (pdo_ready) begin
                          fsmn <= storemp;
                          pdi_ready <= 1;
                          pdo_valid <= 1;
                          pdo_data <= {Ptxt,pdi_data[27],1'b0,pdi_data[25],pdi_data[25],pdi_data[23:0]};
                       end
                    end             
                    else begin
                       if (pdo_ready) begin
                          pdi_ready <= 1;
                          fsmn <= storemf;
                          pdo_valid <= 1;
                          pdo_data <= {Ptxt,pdi_data[27],1'b0,pdi_data[25],pdi_data[25],pdi_data[23:0]};
                       end
                    end
                 end // if (cmd == Ctxt)                 
              end // if (dec)         
              else begin
                 if (cmd == Ptxt) begin
                    seglenn <= pdi_data[15:0];
                    flagsn <= pdi_data[27:24];
                    if ((pdi_data[25] == 1) && (pdi_data[15:0] < 16)) begin
                       if (pdo_ready) begin
                          fsmn <= storemp;
                          pdi_ready <= 1;
                          pdo_valid <= 1;
                          pdo_data <= {Ctxt,pdi_data[27],1'b0,pdi_data[25],1'b0,pdi_data[23:0]};
                       end
                    end             
                    else begin
                       if (pdo_ready) begin
                          pdi_ready <= 1;
                          fsmn <= storemf;
                          pdo_valid <= 1;
                          pdo_data <= {Ctxt,pdi_data[27],1'b0,pdi_data[25],1'b0,pdi_data[23:0]};
                       end                  
                    end // else: !if((pdi_data[25] == 1) && (pdi_data[15:0] < 16))
                 end // if (cmd == Ptxt)                 
              end // else: !if(dec)           
           end // if (pdi_valid)
        end // case: msgheader
        storemf: begin
           if (pdi_valid) begin
	      if (pdo_ready) begin
                 decrypt <= {dec,dec,dec,dec};           
                 pdo_valid <= 1;
                 pdo_data <= pdo;                
                 pdi_ready <= 1;                 
                 swr <= 1;
                 if (cnt == 5'h01) begin
                    seglenn <= seglen - 16;
                 end
                 if (cnt == 5'h3b) begin
                    ccrct <= 1;
                    tcrct <= 1;
                    kcrct <= 1;
                    correct_cntn <= 1;        
                    if ((seglen == 0) && (flags[1] == 1)) begin
		       domain <= msgfinal;
		       nonce_domainn <= adpadded;                      
                    end
                    else begin
		       domain <= msgnormal;                    
                    end
                    cntn <= 6'h01;
                    fsmn <= encryptm;               
                 end // if (cnt == 5'h3b)                
                 else begin
                    cntn <= {cnt[4:0], cnt[5]^cnt[4]^1'b1};                
                 end // else: !if(cnt == 5'h3b)
	      end // if (pdo_ready)		 
           end // if (pdi_valid)
        end // case: storemf
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
                         swr <= 1;
                         cntn <= {cnt[4:0], cnt[5]^cnt[4]^1'b1};           
                      end                     
                   end             
                end             
                else begin
                   pdi <= 0;
		   swr <= 1;
		   cntn <= {cnt[4:0], cnt[5]^cnt[4]^1'b1};
		end // else: !if(seglen >= 0)
             end // case: 6'h01
             6'h03: begin               
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
                         swr <= 1;
                         cntn <= {cnt[4:0], cnt[5]^cnt[4]^1'b1};           
                      end                     
                   end             
                end             
                else begin
                   pdi <= 0;
		   swr <= 1;
                   cntn <= {cnt[4:0], cnt[5]^cnt[4]^1'b1};
                end // else: !if(seglen >= 0)
             end // case: 6'h03      
             6'h07: begin
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
                         swr <= 1;
                         cntn <= {cnt[4:0], cnt[5]^cnt[4]^1'b1};
                      end               
                   end      
                end // if (seglen >= 0)
                else begin
                   pdi <= 0;
		   swr <= 1;
                   cntn <= {cnt[4:0], cnt[5]^cnt[4]^1'b1};
                end             
             end // case: 6'h07      
             6'h0f: begin
                if (seglen > 4) begin
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
                         swr <= 1;
                         cntn <= {cnt[4:0], cnt[5]^cnt[4]^1'b1};
                      end               
                   end      
                end // if (seglen >= 0)
                else begin
                   pdi <= 0;   
                   swr <= 1;
		   cntn <= {cnt[4:0], cnt[5]^cnt[4]^1'b1};
                end             
             end // case: 6'h0f 
             6'h1f: begin
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
                         swr <= 1;
                         cntn <= {cnt[4:0], cnt[5]^cnt[4]^1'b1};
                      end               
                   end      
                end // if (seglen >= 0)
                else begin
                   pdi <= 0;
                   swr <= 1;
                   cntn <= {cnt[4:0], cnt[5]^cnt[4]^1'b1};
                end             
             end // case: 6'h1f
             6'h3e: begin
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
                         swr <= 1;
                         cntn <= {cnt[4:0], cnt[5]^cnt[4]^1'b1};
                      end               
                   end      
                end // if (seglen >= 0)
                else begin
                   pdi <= 0;
                   swr <= 1;
                   cntn <= {cnt[4:0], cnt[5]^cnt[4]^1'b1};
                end             
             end // case: 6'h3e
             6'h3d: begin
                if (seglen > 12) begin
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
                         swr <= 1;
                         cntn <= {cnt[4:0], cnt[5]^cnt[4]^1'b1};
                      end
                   end // if (pdo_ready)                   
                end // if (seglen >= 0)
                else begin
                   pdi <= 0;
                   swr <= 1;
                   cntn <= {cnt[4:0], cnt[5]^cnt[4]^1'b1};
                end             
             end // case: 6'h3d      
             6'h3b: begin
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
                         domain <= msgpadded;
                         kcrct <= 1;
                         correct_cntn <= 1;
                         tcrct <= 1;
                         kcrct <= 1;
                         pdi_ready <= 1;
                         pdi <= {pdi_data[31:4],seglen[3:0]};
                         swr <= 1;
                         cntn <= 6'h01;
                         fsmn <= encryptm;               
                      end            
                   end         
                end // if (seglen >= 0)
                else begin
                   domain <= msgpadded;
                   ccrct <= 1;
                   correct_cntn <= 1;
                   tcrct <= 1;
                   kcrct <= 1;
                   pdi <= {28'h0,seglen[3:0]};
                   swr <= 1;
                   cntn <= 6'h01;
                   fsmn <= encryptm;                  
                end                             
             end // case: 6'h3b      
           endcase // case (cnt)                   
        end // case: storemp
        encryptad: begin
           correct_cntn <= 0;
           tbcenn <= {tbcen[3:0],tbcen[4]};
	   rdi_ready <= 1;	      
           if (tbcen[4]) begin	      
              tk1sn <= ~tk1s;
              ken <= 1;
              ten <= 1;     
              cntn <= {cnt[4:0],cnt[5]^cnt[4]^1'b1};
              if (cnt == FINCONST) begin                 
                 cntn <= 6'h01;
                 if (seglen == 0) begin
                    if (flags[1] == 1) begin                
                       fsmn <= storeadsp;
                       seglenn <= 0;
                       st0n <= 1;
                       c2n <= 0;        
                    end
                    else begin
                       correct_cntn <= 1;
                       ccrct <= 1;
                       fsmn <= adheader;
                       c2n <= 1;                  
                    end // else: !if(flags[1] == 1)
                 end // if (seglen == 0)
                 else if (seglen < 16) begin
                    correct_cntn <= 1;
                    fsmn <= storeadsp;
                    ccrct <= 1;
                    c2n <= 1;
                 end                             
                 else begin
                    correct_cntn <= 1;
                    fsmn <= storeadsf;
                    ccrct <= 1;
                    c2n <= 1;
                 end // else: !if(seglen < 16)           
              end // if (cnt == FINCONST)             
           end // if (tbcen[4])    
        end // case: encryptad  
        encryptn: begin
	   rdi_ready <= 1;	      
           correct_cntn <= 0;
           tbcenn <= {tbcen[3:0],tbcen[4]};        
           if (tbcen[4]) begin	      
              tk1sn <= ~tk1s;
              ken <= 1;
              ten <= 1;       
              cntn <= {cnt[4:0],cnt[5]^cnt[4]^1'b1};
              if (cnt == FINCONST) begin
                 cntn <= 6'h01;
                 fsmn <= msgheader;
                 crst <= 1;
                 correct_cntn <= 1;
                 c2n <= 1;               
              end             
           end // if (tbcen[4])    
        end // case: encryptn
        encryptm: begin
           correct_cntn <= 0;
	   rdi_ready <= 1;	      
           tbcenn <= {tbcen[3:0],tbcen[4]};        
           if (tbcen[4]) begin	      
              tk1sn <= ~tk1s;
              ken <= 1;
              ten <= 1;       
              cntn <= {cnt[4:0],cnt[5]^cnt[4]^1'b1};
              if (cnt == FINCONST) begin
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
                 end // if (seglen == 0)                 
                 else if (seglen < 16) begin
                    fsmn <= storemp;
                    c2n <= 1;
                 end
                 else begin
                    fsmn <= storemf;
                    c2n <= 1;
                 end
              end // if (cnt == FINCONST)             
           end // if (tbcen[4])    
        end // case: encryptm
        outputtag0: begin
           if (pdo_ready) begin
              pdi <= 0;    
              pdo_valid <= 1;      
              pdo_data <= {Tg,4'h3,8'h0,16'h010};
              fsmn <= outputtag1;             
           end
        end // case: outputtag0
        outputtag1: begin
           if (pdo_ready) begin
              pdi <= 0; 
              swr <= 1;
              pdo_valid <= 1;      
              pdo_data <= pdo;
              cntn <= {cnt[4:0], cnt[5]^cnt[4]^1'b1};
              if (cnt == 6'h3b) begin
                 fsmn <= statuse;
                 cntn <= 6'h01;
              end
           end // if (pdo_ready)           
        end // case: outputtag1
        statuse: begin
           if (pdo_ready) begin
              pdo_valid <= 1;
              pdo_data <= {SUCCESS, 28'h0};
              do_last <= 1;
              fsmn <= idle;
              kcrct <= 1;
           end
        end // case: statuse
        verifytag0: begin
           pdi_ready <= 1;
           if (pdi_valid) begin
              if (cmd == Tg) begin
                 fsmn <= verifytag1;                 
              end             
           end     
        end // case: verifytag0
        verifytag1: begin
           if (pdi_valid) begin
              pdi_ready <= 1;
	      tag_accn <= final_tag_acc;	      
              if (cnt == 6'h3b) begin
                 cntn <= 6'h01;
                 if (final_tag_acc != 32'h0) begin
                    fsmn <= statusdf;
                 end
                 else begin
                    fsmn <= statusds;
                 end // else: !if((pdo != 32'h0) || (dec == 0))          
              end // if (cnt == 6'h0F)
              else begin
                 cntn <= {cnt[4:0], cnt[5]^cnt[4]^1'b1}; 
                 swr <= 1;               
              end // else: !if(cnt == 6'h0F)          
           end // if (pdi_valid)           
        end // case: verifytag1
        statusds: begin
           if (pdo_ready) begin
              pdo_valid <= 1;
              pdo_data <= {SUCCESS, 28'h0};
              do_last <= 1;
              fsmn <= idle;
              kcrct <= 1;
           end
        end // case: statusds   
        statusdf: begin
           if (pdo_ready) begin
              pdo_valid <= 1;
              pdo_data <= {FAILURE, 28'h0};
              do_last <= 1;
              fsmn <= idle;
              kcrct <= 1;
           end
        end // case: statusdf   
      endcase // case (fsm)      
   end // always @ (...   
      
endmodule // api
