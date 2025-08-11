`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/10/2025 02:52:02 PM
// Design Name: 
// Module Name: tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

`timescale 1ns / 1ps
`include "uvm_macros.svh"
 import uvm_pkg::*;

typedef enum bit [3:0] {rand_baud_1_stop =0, rand_length_2_stop =1,length5wp =2, length6wp=3,length7wp=4,length8wp=5,length5wop=6 ,length6wop=7,length7wop=8,length8wop=9}oper_mode;

class transaction extends uvm_sequence_item;
  `uvm_object_utils(transaction)
  
  oper_mode op;
  logic tx_start,rx_start;
  logic rst;
  rand logic [7:0]tx_data;
  rand logic[16:0] baud;
  rand logic[3:0]length;
  rand logic parity_type,parity_en;
  logic stop2;
  logic tx_done, rx_done,tx_err,rx_err;
  logic [7:0]rx_out;
  
  constraint baud_c {baud inside {4800,9600,14400,19200,38400,57600};}
  constraint length_c {length inside {5,6,7,8};}
  
  function new(input string inst="trans");
    super.new(inst);
  endfunction
endclass


//seq1 is responsible for generating random baud,fixed length,single stop and random parity
class seq1 extends uvm_sequence#(transaction);
  `uvm_object_utils(seq1)
  
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
       t.op=rand_baud_1_stop;
       t.length=8;
       t.rst=1'b0;
       t.stop2=1'b0;
       t.tx_start=1'b1;
       t.rx_start=1'b1;
       t.parity_en=1'b1;
       finish_item(t);
     end
  endtask
endclass


//seq2 is responsible for generating random baud,fixed length=8,double stop and random parity
class seq2 extends uvm_sequence#(transaction);
  `uvm_object_utils(seq2)
  
  function new(input string inst="seq2");
    super.new(inst);
  endfunction
  
  transaction t;
  
  virtual task body();
    repeat(5)
     begin
       t=transaction::type_id::create("t");
       start_item(t);
       t.randomize();
       t.op=rand_length_2_stop;
       t.length=8;
       t.rst=1'b0;
       t.stop2=1'b1;
       t.tx_start=1'b1;
       t.rx_start=1'b1;
       t.parity_en=1'b1;
       finish_item(t);
     end
  endtask
endclass

//seq3 is responsible for generating random baud,fixed length=5,single stop and random parity
class seq3 extends uvm_sequence#(transaction);
  `uvm_object_utils(seq3)
  
  function new(input string inst="seq3");
    super.new(inst);
  endfunction
  
  transaction t;
  
  virtual task body();
    repeat(5)
     begin
       t=transaction::type_id::create("t");
       start_item(t);
       t.randomize();
       t.op=length5wp;
       t.length=5;
       t.rst=1'b0;
       t.tx_data= {3'b000,t.tx_data[7:3]};
       t.stop2=1'b0;
       t.tx_start=1'b1;
       t.rx_start=1'b1;
       t.parity_en=1'b1;
       finish_item(t);
     end
  endtask
endclass

//seq4 is responsible for generating random baud,fixed length=6,single stop and random parity
class seq4 extends uvm_sequence#(transaction);
  `uvm_object_utils(seq4)
  
  function new(input string inst="seq4");
    super.new(inst);
  endfunction
  
  transaction t;
  
  virtual task body();
    repeat(5)
     begin
       t=transaction::type_id::create("t");
       start_item(t);
       t.randomize();
       t.op=length6wp;
       t.length=6;
       t.rst=1'b0;
       t.tx_data= {2'b00,t.tx_data[7:2]};
       t.stop2=1'b0;
       t.tx_start=1'b1;
       t.rx_start=1'b1;
       t.parity_en=1'b1;
       finish_item(t);
     end
  endtask
endclass  
  
//seq5 is responsible for generating random baud,fixed length=7,single stop and random parity
class seq5 extends uvm_sequence#(transaction);
  `uvm_object_utils(seq5)
  
  function new(input string inst="seq5");
    super.new(inst);
  endfunction
  
  transaction t;
  
  virtual task body();
    repeat(5)
     begin
       t=transaction::type_id::create("t");
       start_item(t);
       t.randomize();
       t.op=length7wp;
       t.length=7;
       t.rst=1'b0;
       t.tx_data= {1'b0,t.tx_data[7:1]};
       t.stop2=1'b0;
       t.tx_start=1'b1;
       t.rx_start=1'b1;
       t.parity_en=1'b1;
       finish_item(t);
     end
  endtask
endclass   
  
//seq6 is responsible for generating random baud,fixed length=8,single stop and random parity
class seq6 extends uvm_sequence#(transaction);
  `uvm_object_utils(seq6)
  
  function new(input string inst="seq6");
    super.new(inst);
  endfunction
  
  transaction t;
  
  virtual task body();
    repeat(5)
     begin
       t=transaction::type_id::create("t");
       start_item(t);
       t.randomize();
       t.op=length8wp;
       t.length=8;
       t.rst=1'b0;
       t.stop2=1'b0;
       t.tx_start=1'b1;
       t.rx_start=1'b1;
       t.parity_en=1'b1;
       finish_item(t);
     end
  endtask
endclass   
  
  
class driver extends uvm_driver#(transaction);
  `uvm_component_utils(driver)
  
  transaction dc; //data container to store transation from sequencer
  virtual uart_if uif; //getting handle of the virtual interface
  
  function new(input string path="driver",uvm_component parent=null);
    super.new(path,parent);
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    dc=transaction::type_id::create("dc",this);
    if(!uvm_config_db#(virtual uart_if)::get(this,"","uif",uif))
      `uvm_error("DRV","Unable to get interface handle");
  endfunction
  
  //Reset task resets the DUT
  task reset_dut();
    repeat(5)
    begin
    uif.rst<=1'b1; //assert reset pin high
    uif.tx_start<=1'b0;
    uif.rx_start<=1'b0;
    uif.tx_data<=8'h00;
    uif.stop2<=1'b0;
    uif.parity_en=1'b0;
    uif.parity_type=1'b0;
    uif.baud=16'h0;
    uif.length<=4'h0;
      `uvm_info("DRV","Reset has been asserted",UVM_NONE);
      @(posedge uif.clk);
    end
  endtask
      
  //After system has been reset, drive sequences to DUT
  
  task drive();
    reset_dut(); //Reset the system
    forever begin //always ready to receive transaction from sequencer
      seq_item_port.get_next_item(dc); // ask sequencer for the next item
      uif.rst<=1'b0; //remove reset
      uif.baud<=dc.baud;
      uif.length<=dc.length;
      uif.parity_en<=dc.parity_en;
      uif.parity_type<=dc.parity_type;
      uif.stop2<=dc.stop2;
      uif.tx_start<=dc.tx_start;
      uif.rx_start<=dc.rx_start;
      uif.tx_data<=dc.tx_data;
      `uvm_info("DRV",$sformatf("BAUD:%0d , Length:%0d, Parity_type:%0b,Partity_en:%0b, Tx_Data:%0d",dc.baud,dc.length,dc.parity_type,dc.parity_en,dc.tx_data),UVM_NONE);
                @(posedge uif.clk); //to match the delay of reset
                @(posedge uif.tx_done); //transmission is complete
                @(posedge uif.rx_done); //reception is complete
                seq_item_port.item_done(); //communicates to sequencer that done driving the first transaction to DUT
                end
                endtask
                
                virtual task run_phase(uvm_phase phase);
                  drive();
                endtask
                endclass
 
class monitor extends uvm_monitor;
  `uvm_component_utils(monitor)
  
  function new(input string path="mon",uvm_component parent=null);
    super.new(path,parent);
  endfunction
  
  virtual uart_if uif; //handle to the interface
  transaction t; //to store response collected from DUT
  uvm_analysis_port#(transaction) send; //analysis port to send the response collected from DUT to scoreboard 
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    t=transaction::type_id::create("t");
    send=new("send",this);
    if(!uvm_config_db#(virtual uart_if)::get(this,"","uif",uif))
      `uvm_error("MON","Unable to get access to the interface");
  endfunction
      
  virtual task run_phase(uvm_phase phase);
   forever begin
     @(posedge uif.clk);
     if(uif.rst)
      begin
        t.rst=1'b1; //only sending reset value , not picking up any other response
     `uvm_info("MON","System RESET has been detected",UVM_NONE);
     send.write(t);
   end
   else
     begin
       @(posedge uif.tx_done); //wait for transmission to complete
       t.rst=1'b0;
       t.tx_start=uif.tx_start;
       t.rx_start=uif.rx_start;
       t.tx_data=uif.tx_data;
       t.baud=uif.baud;
       t.length=uif.length;
       t.parity_en=uif.parity_en;
       t.parity_type=uif.parity_type;
       t.stop2=uif.stop2;
       @(negedge uif.rx_done);
       t.rx_out = uif.rx_out;
       `uvm_info ("MON",$sformatf("Baud:%0d , Length:%0d, Parity_type:%0b, Parity_en:%0b, Stop2:%0d, Tx_data:%0d , Rx_data:%0d",t.baud,t.length,t.parity_type,t.parity_en,t.stop2,t.tx_data,t.rx_out),UVM_NONE);
       send.write(t);
     end
   end
  endtask
endclass
                
    class scoreboard extends uvm_scoreboard;
      `uvm_component_utils(scoreboard)
      
      function new(input string path="sco",uvm_component parent=null);
        super.new(path,parent);
      endfunction
      
      uvm_analysis_imp#(transaction,scoreboard) rcv;
      
      virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        rcv=new("rcv",this);
      endfunction
      
      virtual function void write(transaction t);
        if(t.rst == 1'b1)
          `uvm_info("SCO","SYSTEM RESET",UVM_NONE)
        else if (t.tx_data == t.rx_out)
          `uvm_info ("SCO","TEST PASSED",UVM_NONE)
        else
          `uvm_info("SCO","TEST FAILED",UVM_NONE);
      endfunction
    endclass
                
class agent extends uvm_agent;
  `uvm_component_utils(agent)
  
  function new(input string path="agent",uvm_component parent=null);
    super.new(path,parent);
  endfunction
  
 monitor m;
 driver d;
  uvm_sequencer#(transaction) seqr;
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    m=monitor::type_id::create("m",this);
    d=driver::type_id::create("d",this);
    seqr=uvm_sequencer#(transaction)::type_id::create("seqr",this);
  endfunction
  
  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    d.seq_item_port.connect(seqr.seq_item_export);
  endfunction
endclass
                
  class env extends uvm_env;
    `uvm_component_utils(env)
    
    function new(input string path="env",uvm_component c);
      super.new(path,c);
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
                  
    function new(input string path="test",uvm_component c);
      super.new(path,c);
    endfunction
 
    env e;
    seq1 s1;
    seq2 s2;
    seq3 s3;
    seq4 s4;
    seq5 s5;
    seq6 s6;
    
    virtual function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      e=env::type_id::create("e",this);
      s1=seq1::type_id::create("s1");
      s2=seq2::type_id::create("s2");
      s3=seq3::type_id::create("s3");
      s4=seq4::type_id::create("s4");
      s5=seq5::type_id::create("s5");
      s6=seq6::type_id::create("s6");
    endfunction
   
    virtual task run_phase(uvm_phase phase);
      phase.raise_objection(this);
      s1.start(e.a.seqr);
      #20; //drain time -> allows last transaction to be processed bu DUT
      s2.start(e.a.seqr);
      #20;
      s6.start(e.a.seqr);
      #20;
      phase.drop_objection(this);
    endtask
    
  endclass
                
  module tb;
    
    uart_if uif();
    
    uart_top dut(.clk(uif.clk),.rst(uif.rst),.tx_start(uif.tx_start), .rx_start(uif.rx_start), .tx_data(uif.tx_data), .baud(uif.baud), .length(uif.length), .parity_type(uif.parity_type), .parity_en(uif.parity_en),.stop2(uif.stop2),.tx_done(uif.tx_done), .rx_done(uif.rx_done), .tx_err(uif.tx_err), .rx_err(uif.rx_err), .rx_out(uif.rx_out));
  
    initial begin
     uif.clk<=0;
    end
    
  always #10 uif.clk<=~uif.clk;  
    
    initial begin
      uvm_config_db#(virtual uart_if)::set(null,"*","uif",uif);
    end
    
       
    initial begin
      run_test("test");
      $dumpfile("dump.vcd");
      $dumpvars;
    end
    
  endmodule
                
      

