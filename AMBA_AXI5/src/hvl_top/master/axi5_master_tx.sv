`ifndef AXI5_MASTER_TX_INCLUDED_
`define AXI5_MASTER_TX_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi5_master_tx
// This class holds the data items required to drive the stimulus to dut
// and also holds methods that manipulate those data items.
//--------------------------------------------------------------------------------------------
class axi5_master_tx extends axi5_base_tx;
  
  `uvm_object_utils(axi5_master_tx)

  axi5_master_agent_config axi5_master_agent_cfg_h; 
  //-------------------------------------------------------
  // WRITE ADDRESS Constraints
  //-------------------------------------------------------
	constraint awregion_c0 {soft awregion inside {[0:3]};}
  //Constraint : awaddr
  //Used to generate the alligned address with respect to size
  constraint awaddr_c0 {soft awaddr%(2**awsize) == 0;}

  //Constraint : awburst_c1
  //Restricting write burst to select only FIXED, INCR and WRAP types
  constraint awburst_c1 {awburst != WRITE_RESERVED;}

  //Constraint : awlength_c2
  //Adding constraint for restricting write trasnfers
  constraint awlength_c2 {if(awburst==WRITE_FIXED ||awburst == WRITE_WRAP) //!!!!
                              awlen inside {[0:15]};
                          else if(awburst == WRITE_INCR) 
                              awlen inside {[0:255]};}

  //Constraint : awlength_c3
  //Adding constraint for restricting to get multiples of 2 in wrap burst
  constraint awlength_c3 {if(awburst == WRITE_WRAP)
                          awlen + 1 inside {2,4,8,16};}
  
  //Constraint : awlock_c4
  //Adding constraint to select the lock transfer type
  constraint awlock_c4 {soft awlock == WRITE_NORMAL_ACCESS;}

  //Constraint : awburst_c5
  //Adding a soft constraint to detrmine the burst type
  constraint awburst_c5 {soft awburst == WRITE_INCR;}

  //Constraint : awsize_c6
  //Adding a soft constraint to detrmine the awsize
  constraint awsize_c6 {soft awsize inside {[0:2]};}

  //-------------------------------------------------------
  // WRITE DATA Constraints
  //-------------------------------------------------------
  //Constraint : wdata_c1
  //Adding constraint to restrict the write data based on awlength
  constraint wdata_c1 {wdata.size() == awlen + 1;} 

  //Constraint : wstrb_c2
  //Adding constraint to restrict the write strobe based on awlength
  constraint wstrb_c2 {wstrb.size() == awlen + 1;}

  //Constraint : wstrb_c3
  //wstrb shouldn't be zero
  constraint wstrb_c3 {foreach(wstrb[i]) wstrb[i]!=0; }

  //Constraint: wstrb_c4
  //based on size setting the strobe values
  constraint wstrb_c4 {foreach(wstrb[i]) $countones(wstrb[i]) == 2**awsize;}

  //Constraint : no_of_wait_states_c3
  //Adding constraint to restrict the number of wait states for response
  constraint no_of_wait_states_c3 {no_of_wait_states inside {[0:3]};}
  
  //-------------------------------------------------------
  // READ ADDRESS Constraints
  //-------------------------------------------------------
  
  //Constraint : araddr
  //Used to generate the alligned address with respect to size
  constraint araddr_c0 {soft araddr == (araddr%(2**arsize)) == 0;}
  
  //Constraint : arburst_c1
  //Restricting read burst to select only FIXED, INCR and WRAP types
  constraint arburst_c1 { arburst != READ_RESERVED;}

  //Constraint : arlength_c2
  //Adding constraint for restricting read trasnfers
  constraint arlength_c2 { if(arburst==READ_FIXED || READ_WRAP)
                            arlen inside {[0:15]};
                           else if(arburst == READ_INCR) 
                            arlen inside {[0:255]};
                         }
  
  //Constraint : arlength_c3
  //Adding constraint for restricting to get multiples of 2 in wrap burst
  constraint arlength_c3 { if(arburst == READ_WRAP)
                            arlen + 1 inside {2,4,8,16};
                         }

  //Constraint : arlock_c9
  //Adding constraint to select the lock transfer type
  constraint arlock_c4 { soft arlock == READ_NORMAL_ACCESS;}

  //Constraint : arburst_c5
  //Adding a soft constraint to detrmine the burst type
  constraint arburst_c5 { soft arburst == READ_INCR;}

  //Constraint : arsize_c6
  //Adding a soft constraint to detrmine the arsize
  constraint arsize_c6 { soft arsize inside {[0:2]};}

  //-------------------------------------------------------
  // Memory Constraints
  //-------------------------------------------------------
  //Constraint : endian_c1
  //Adding constraint to select the endianess
  constraint endian_c1 { soft endian == LITTLE_ENDIAN;}

  //-------------------------------------------------------
  // Externally defined Tasks and Functions
  //-------------------------------------------------------
  extern function new (string name = "axi5_master_tx");
  extern function void post_randomize();
endclass : axi5_master_tx

//--------------------------------------------------------------------------------------------
// Construct: new
// initializes the class object
//
// Parameters:
// name - axi5_master_tx
//--------------------------------------------------------------------------------------------
function axi5_master_tx::new(string name = "axi5_master_tx");
  super.new(name);
endfunction : new

//--------------------------------------------------------------------------------------------
// Function : post_randomize 
// Implements the narrow transfers and unalligned transfers
//--------------------------------------------------------------------------------------------
function void axi5_master_tx::post_randomize();
  bit[3:0] wstrb_local;
  bit[3:0] wstrb_size_0_local;
  bit[3:0] awsize_0;
  bit[3:0] awsize_1;

  bit[3:0] unallignd_wstrb0;
  bit[3:0] unallignd_wstrb1;
  bit[3:0] unallignd_wstrb2;
  bit[1:0] unallignd_wstrb0_cnt;
  bit[3:0] alligned_wstrb0_cnt;
  int index;
  int quotient_check;
  int quotient_check_1;
  int remainder_check;

  //-------------------------------------------------------
  // Step-1: for awsize == 0
  // Calculate the remainder by dividing awaddr and 2**awsize
  // that gives the nearest alligned address based on the 
  // remainder assert that particular strobe bit.
  //
  // Step-2: for awsize == 1
  // Calculate the quotient by dividing awaddr and 2**awsize
  // if quotient is alligned assert first 2 bits of strobes
  // else assert next 2 bits of strobes
  //
  //Step-3: for awsize == 2
  //Here you can assert all 4bits of strobes since it is a 
  //alligned address and all 4bits needs to pass
  //(addr ex: 0,4,8..)
  //-------------------------------------------------------
  //-------------------------------------------------------
  // Narrow Transfers for alligned address
  //-------------------------------------------------------
  if(awaddr % 2**awsize == 0) begin
    awsize_0 = 4'b0001;
    awsize_1 = 4'b1111;
    remainder_check = awaddr % 4;
    `uvm_info("rem_check",$sformatf("remainder_check = %0d",remainder_check),UVM_HIGH)
    
    // Assigning the initial strobe values based on the size and address issued
    if(awsize == 0) begin
      if(remainder_check == 0) wstrb_local = 4'b0001; 
      if(remainder_check == 1) wstrb_local = 4'b0010; 
      if(remainder_check == 2) wstrb_local = 4'b0100; 
      if(remainder_check == 3) wstrb_local = 4'b1000; 
    end
   
    if(awsize == 1) begin 
      quotient_check_1 = awaddr / 2**awsize;
      if(quotient_check_1 % 2 == 0) begin
      wstrb_local = 4'b0011;
    end
    else begin
      wstrb_local = 4'b1100;
    end
  end
  
  if(awsize == 2) wstrb_local = 4'b1111;
  `uvm_info(get_type_name(), $sformatf("DEBUG_LOCAL :: wstrb_local =  %0b",wstrb_local), UVM_HIGH); 
  `uvm_info(get_type_name(), $sformatf("DEBUG_LOCL :: awsize =  %0d",awsize), UVM_HIGH); 
  
  wstrb_size_0_local = wstrb_local;

  //for loop to generate the strobe values based on strobe size
  for(int i=0;i<wstrb.size();i++) begin
    `uvm_info(get_type_name(),$sformatf("inside for loop of post randomize"),UVM_HIGH)
    
    if(awsize == 0) begin
      if(remainder_check == 0)begin
        if(i==0) begin
          wstrb[0] = wstrb_local;
          `uvm_info(get_type_name(), $sformatf("DEBUG_IN_LOOP :: wstrb[0] =  %0b",wstrb[0]), UVM_HIGH); 
        end 
        else begin
          // since remainder is 0 it will be in 1st(0) lane
          // so after every 4 transfers u need to assign wstrb(0)
          if(i%4 == 0) begin
            this.wstrb[i] = awsize_0;
            wstrb_size_0_local = awsize_0;
          end
          else begin
            wstrb_size_0_local = (wstrb_size_0_local << 2**awsize);
            this.wstrb[i] = wstrb_size_0_local;
          end
          `uvm_info(get_type_name(), $sformatf("DEBUG_IN_LOOP :: wstrb[%0d] =  %0b",i,this.wstrb[i]), UVM_HIGH); 
          `uvm_info(get_type_name(),$sformatf("outside for loop of post randomize"),UVM_HIGH)
        end
      end
      
      // since remainder is 1 it will be in 2nd(1) lane
      else if (remainder_check == 1) begin
        if(i==0) begin
          wstrb[0] = wstrb_local;
          `uvm_info(get_type_name(), $sformatf("DEBUG_IN_LOOP :: wstrb[0] =  %0b",wstrb[0]), UVM_HIGH); 
        end 
        else if(i == 1) begin
          wstrb[1] = wstrb[0] << i;
        end
        else if(i == 2) begin
          wstrb[2] = wstrb[0] << i;
          wstrb_size_0_local = awsize_0;
        end
        else begin 
          this.wstrb[i] = wstrb_size_0_local;
          wstrb_size_0_local = (wstrb_size_0_local << 2**awsize);
          alligned_wstrb0_cnt++;
          if(alligned_wstrb0_cnt == 4) begin
            // so after every 4 transfers u need to assign awsize_0
            wstrb_size_0_local = awsize_0;
            alligned_wstrb0_cnt = 0;
          end
        end
      end  
      
      else if (remainder_check == 2) begin
        if(i==0) begin
          wstrb[0] = wstrb_local;
          `uvm_info(get_type_name(), $sformatf("DEBUG_IN_LOOP :: wstrb[0] =  %0b",wstrb[0]), UVM_HIGH); 
        end 
        else if(i == 1) begin
          wstrb[1] = wstrb[0] << i;
          wstrb_size_0_local = awsize_0;
        end
        
        else begin 
          this.wstrb[i] = wstrb_size_0_local;
          wstrb_size_0_local = (wstrb_size_0_local << 2**awsize);
          alligned_wstrb0_cnt++;
          if(alligned_wstrb0_cnt == 4) begin
            wstrb_size_0_local = awsize_0;
            alligned_wstrb0_cnt = 0;
          end
        end
      end
      
      else if (remainder_check == 3) begin
        if(i==0) begin
          wstrb[0] = wstrb_local;
          wstrb_size_0_local = awsize_0;
          `uvm_info(get_type_name(), $sformatf("DEBUG_IN_LOOP :: wstrb[0] =  %0b",wstrb[0]), UVM_HIGH); 
        end 
        
        else begin 
          this.wstrb[i] = wstrb_size_0_local;
          wstrb_size_0_local = (wstrb_size_0_local << 2**awsize);
          alligned_wstrb0_cnt++;
          if(alligned_wstrb0_cnt == 4) begin
            wstrb_size_0_local = awsize_0;
            alligned_wstrb0_cnt = 0;
          end
        end
      end
    end
    
    else if(awsize == 1) begin
      if(quotient_check_1 % 2**awsize == 0) begin 
        if(i==0) begin
          wstrb[0] = wstrb_local;
          `uvm_info(get_type_name(), $sformatf("DEBUG_IN_LOOP :: wstrb[0] =  %0b",wstrb[0]), UVM_HIGH); 
        end 
        else begin
          if(i%2 == 0) begin
            this.wstrb[i] = {(wstrb_local << 2**awsize)^awsize_1};
          end
          else begin
            this.wstrb[i] = (wstrb_local << 2**awsize);
          end
        end
      end
      
      else begin
        if(i==0) begin
          wstrb[0] = wstrb_local;
          `uvm_info(get_type_name(), $sformatf("DEBUG_IN_LOOP :: wstrb[0] =  %0b",wstrb[0]), UVM_HIGH); 
        end 
        else begin
          if(i%2 == 0) begin
            this.wstrb[i] = wstrb_local;
          end
          else begin
            this.wstrb[i] = (wstrb_local >> 2**awsize);
          end
        end
      end
    end
    
    else if(awsize == 2) begin
      wstrb[i] = wstrb_local;
    end
  end
end


//-------------------------------------------------------
// Strobes for Unalligned transfers
//-------------------------------------------------------
if(awaddr % 2**awsize != 0) begin
  
  unallignd_wstrb0 = 4'b0001;
  unallignd_wstrb1 = 4'b0011;
  unallignd_wstrb2 = 4'b1111;
  
  quotient_check = awaddr / 2**awsize;
  
  if(awsize == 0) begin
    wstrb_local = 4'b0001;
  end
  if(awsize == 1) begin
    if(quotient_check%2 == 0) begin
      wstrb_local = 4'b0010;
    end
    else begin
      wstrb_local = 4'b1000;
    end
  end
  //in the 1st case why 3 bits made 1 becoz 
  //since addr is 1 if you pass only that address as high 
  //then in nxt lane it will start from addr 2 which is unalligned for size
  //so if u pass all 3 bits nxt transfer will strat from 4 which is alligned.
  if(awsize == 2) begin
    if(awaddr % 2**awsize == 1) wstrb_local = 4'b1110; 
    if(awaddr % 2**awsize == 2) wstrb_local = 4'b1100; 
    if(awaddr % 2**awsize == 3) wstrb_local = 4'b1000;
  end
  
  for(int i=0;i<wstrb.size();i++) begin
    if(awsize == 0) begin
      if(i == 0) begin
        wstrb[0] = wstrb_local;
      end
      else begin
        wstrb[i] = wstrb_local << 1;
        unallignd_wstrb0_cnt++;
        if(unallignd_wstrb0_cnt == 'd3) begin
          wstrb[i] = wstrb_local;
          unallignd_wstrb0_cnt = 0;
        end
      end
    end
    
    if(awsize == 1) begin
      if(i == 0) begin
        wstrb[0] = wstrb_local;
      end
      else if(i == 1) begin
        wstrb[i] = unallignd_wstrb1;
      end
      else begin
        if(i%2 == 0) begin
        wstrb[i] = unallignd_wstrb1 << 2;
      end
      else if(i%2 != 0) begin
        wstrb[i] = unallignd_wstrb1;
      end
    end
  end
  
  if(awsize == 2) begin
    if(i==0) begin
      wstrb[0] = wstrb_local;
    end
    else begin
      wstrb[i] = unallignd_wstrb2;
    end
   end
  end
end

endfunction : post_randomize
`endif

