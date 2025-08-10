`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/09/2025 05:58:56 PM
// Design Name: 
// Module Name: tb_uart_baud
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: Verification of a UART clock generator for different BAUD rate
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
module clk_gen(
input clk, rst,
input [16:0] baud,
output  tx_clk
);
  
  
reg  t_clk = 0;
int  tx_max = 0;
int  tx_count = 0;
//////////////////////////////////////////////
 
always@(posedge clk) begin 
		if(rst)begin
			tx_max <= 0;	
			end
		else begin 		
			case(baud)
				4800 :	begin
						  tx_max <=14'd10416;	//10418
			            end
				9600  : begin
						  tx_max <=14'd5208;
				    	end
				14400 : begin 
						  tx_max <=14'd3472;
						 end
				19200 : begin 
						  tx_max <=14'd2604;
						end
				38400: begin
						  tx_max <=14'd1302;
						end
				57600 : begin 
						  tx_max <=14'd868;	
						end 						
				 default: begin 
						  tx_max <=14'd5208;	
						 end
			endcase
		end
	end
 
///////////////////////////////////////////
 
 
always@(posedge clk)
begin
 if(rst) 
   begin
     tx_count <= 0;
     t_clk    <= 0;
   end
 else 
 begin
   if(tx_count < tx_max/2)
       begin
         tx_count <= tx_count + 1;
       end
    else 
       begin
        t_clk   <= ~t_clk;
        tx_count <= 0;
       end
 end
end

/////////////////////////////////////////////////////
  assign tx_clk = t_clk;
endmodule
 
 
////////////////////////////////////////////////////////////////////////
 
interface clk_if;
logic clk, rst;
logic [16:0] baud;
logic tx_clk;
endinterface
 
 //UVM TESTBENCH
 
 `include "uvm_macros.svh"
import uvm_pkg::*;

typedef enum bit [1:0] {reset_assert =0 , random_baud =1}oper_mode;

class transaction extends uvm_sequence_item;
  `uvm_object_utils(transaction)
  
  oper_mode oper;
  rand logic[16:0]baud;
  logic tx_clk;
  real period;
  
  constraint baud_c {baud inside {4800,9600,14400,19200,38400,57600};}
  
  function new(input string inst="trans");
    super.new(inst);
  endfunction
endclass


//making sequences

class reset_func extends uvm_sequence#(transaction);
  `uvm_object_utils(reset_func)
  
  transaction t;
  
  function new(input string inst="seq1");
    super.new(inst);
    endfunction
    
  virtual task body();//sequence checks the reset functionality
    repeat(5)
      begin
        t=transaction::type_id::create("t");
        start_item(t);
        t.randomize();
        t.oper =reset_assert;
        finish_item(t);
      end
  endtask
endclass

class baud_func extends uvm_sequence#(transaction);
  `uvm_object_utils(baud_func)
  
  function new(input string inst="seq1");
    super.new(inst);
    endfunction
  transaction t;
  
  virtual task body();
    repeat(5)
      begin
        t=transaction::type_id::create("t");
        start_item(t);
        t.randomize();
        t.oper=random_baud;
        finish_item(t);
      end
  endtask
endclass

//Driver checks the operation mode and drives DUT accordingly
//If reset mode is on, Driver drives the reset pin of the DUT
//If baud_rate mode is on, Driver pulls the reset low and drives the baud rate pin of the DUT
//Idetify type of mode and drive the signals accordingly

class driver extends uvm_driver#(transaction);
  `uvm_component_utils(driver)
  
 virtual interface clk_if cif;
  transaction dc;//to store transaction from sequencer and store it in a data container
   
   function new(input string inst="driver",uvm_component parent=null);
     super.new(inst,parent);
   endfunction
   
   function void build_phase(uvm_phase phase);
     super.build_phase(phase);
     dc=transaction::type_id::create("dc",this);
     if(!uvm_config_db#(virtual clk_if)::get(this,"","cif",cif))
       `uvm_error("DRV","Unable to get handle to interface");
   endfunction
   
   virtual task run_phase(uvm_phase phase);
    forever begin
      seq_item_port.get_next_item(dc);
      if(dc.oper == reset_assert)
        begin
        cif.rst<= 1'b1;
          @(posedge cif.clk);
        end
      else if(dc.oper == random_baud)
        begin
         cif.rst<=1'b0;
         cif.baud<=dc.baud;
          @(posedge cif.clk);
          @(posedge cif.tx_clk);
          @(posedge cif.tx_clk);
        end
      seq_item_port.item_done();
    end
      endtask
      endclass
      
      class monitor extends uvm_monitor;
        `uvm_component_utils(monitor)
        
         uvm_analysis_port#(transaction) send; //to send data to scoreboard using analysis_port
        
        function new(input string path="monitor",uvm_component parent=null);
          super.new(path,parent);
          send=new("send",this);
        endfunction
        
        real ton;
        real toff;
                
     virtual clk_if cif; //handle to interface
     transaction t; //collect data from DUT and store it in a transaction
        
      
        virtual function void build_phase(uvm_phase phase);
          super.build_phase(phase);
          t=transaction::type_id::create("t");
          if(!uvm_config_db#(virtual clk_if)::get(this,"","cif",cif))
            `uvm_error("MON","Unable to get handle of interface");
        endfunction
        
        virtual task run_phase(uvm_phase phase);
         forever begin
           @(posedge cif.clk);
           if(cif.rst)
            begin
           t.oper=reset_assert;
           ton=0;
           toff=0;
              `uvm_info("MON","SYSTEM RESET DETECTED",UVM_NONE);
              send.write(t);
              end
           else
           begin
           t.baud = cif.baud;
           t.oper = random_baud;
             @(posedge cif.tx_clk);
           ton=$realtime;
             @(posedge cif.tx_clk);
            toff=$realtime;
            t.period = toff-ton;
             send.write(t);
           end
         end
        endtask
      endclass
      
      class scoreboard extends uvm_scoreboard;
        `uvm_component_utils(scoreboard)
        
        function new(input string inst="sco",uvm_component parent=null);
          super.new(inst,parent);
        endfunction
        
        uvm_analysis_imp#(transaction,scoreboard) rcv; //analysis implementation port
        real count =0;
        real baudcount =0;
       
        function void build_phase(uvm_phase phase);
          super.build_phase(phase);
          rcv=new("rcv",this);
        endfunction
        
        virtual function void write(transaction tr);
         count = tr.period/20;
         baudcount = count;
          `uvm_info("SCO",$sformatf(" BAUD :%0d ,count:%0f , Baudcount:%0f",tr.baud,count,baudcount),UVM_NONE);
          
          case(tr.baud)
          
         
            4800:begin
              if(baudcount == 10418) //10416 = 50Mhz /4800
                `uvm_info("SCO","TEST PASSED" ,UVM_NONE)
             else 
               `uvm_error ("SCO","TEST FAILED");
            end
            
           9600: begin
             if(baudcount == 5210) //5208 + 2
               `uvm_info("SCO","TEST PASSED",UVM_NONE)
             else
               `uvm_error("SCO","TEST FAILED");
           end
           
         14400: begin
        if(baudcount == 3474)
          `uvm_info("SCO", "TEST PASSED", UVM_NONE)
        else
          `uvm_error("SCO" , "TEST FAILED")
      end
        
      19200: begin
        if(baudcount == 2606)
          `uvm_info("SCO", "TEST PASSED", UVM_NONE)
        else
          `uvm_error("SCO" , "TEST FAILED")
        
      end
        
      38400: begin
        if(baudcount == 1304)
          `uvm_info("SCO", "TEST PASSED", UVM_NONE)
        else
          `uvm_error("SCO" , "TEST FAILED")
        
      end
        
      57600: begin
        if(baudcount == 870)
          `uvm_info("SCO", "TEST PASSED", UVM_NONE)
        else
          `uvm_error("SCO" , "TEST FAILED")
      end
          
          endcase     
  endfunction
 
endclass
        
        
          class agent extends uvm_agent;
            `uvm_component_utils(agent)
            
            function new(input string inst="agent",uvm_component parent=null);
              super.new(inst,parent);
            endfunction
            
        monitor m;
        driver d;
            uvm_sequencer#(transaction) seqr;
            
            virtual function void build_phase(uvm_phase phase);
              super.build_phase(phase);
              d=driver::type_id::create("d",this);
              m=monitor::type_id::create("m",this);
              seqr=uvm_sequencer#(transaction)::type_id::create("seqr",this);
            endfunction
            
            virtual function void connect_phase(uvm_phase phase);
              super.connect_phase(phase);
              d.seq_item_port.connect(seqr.seq_item_export);
            endfunction
          endclass
        
        class env extends uvm_env;
          `uvm_component_utils(env)
          
          function new(input string inst="env",uvm_component c);
            super.new(inst,c);
          endfunction
          
       agent a;
       scoreboard s;
          
          virtual function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            a=agent::type_id::create("a",this);
            s=scoreboard::type_id::create("s",this);
          endfunction
          
          virtual function void connect_phase(uvm_phase phase);
            super.connect_phase(phase);
            a.m.send.connect(s.rcv);
          endfunction
        endclass
        
        class test extends uvm_test;
          `uvm_component_utils(test)
          
      env e;
      reset_func rf;
      baud_func bf;
          
          function new(input string inst="env",uvm_component c);
            super.new(inst,c);
          endfunction
          
          virtual function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            e=env::type_id::create("e",this);
            rf= reset_func::type_id::create("rf");
            bf = baud_func::type_id::create("bf");
          endfunction
          
          virtual task run_phase(uvm_phase phase);
            phase.raise_objection(this);
            bf.start(e.a.seqr);
            #20;  //drain time
            phase.drop_objection(this);
          endtask
        endclass
        
      module tb_uart_baud;
        
        clk_if cif();
        
        clk_gen dut(.clk(cif.clk),.rst(cif.rst), .baud(cif.baud), .tx_clk(cif.tx_clk));
            
        initial begin
          cif.clk <=0;
        end
        
        always #10 cif.clk <= ~cif.clk;
        
        initial begin
          uvm_config_db#(virtual clk_if)::set(null,"*","cif",cif);
			run_test("test");
        end
      
        initial begin
    $dumpfile("dump.vcd");
    $dumpvars;
  end
 
  
endmodule
            
 


