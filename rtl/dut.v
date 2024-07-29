
`include "defines.vh"
//---------------------------------------------------------------------------
// DUT 
//---------------------------------------------------------------------------
module MyDesign(
//---------------------------------------------------------------------------
//System signals
  input wire reset_n                      ,  
  input wire clk                          ,

//---------------------------------------------------------------------------
//Control signals
  input wire dut_valid                    , 
  output wire dut_ready                   ,

//---------------------------------------------------------------------------
//q_state_input SRAM interface
  output wire                                               q_state_input_sram_write_enable  ,
  output wire [`Q_STATE_INPUT_SRAM_ADDRESS_UPPER_BOUND-1:0] q_state_input_sram_write_address ,
  output wire [`Q_STATE_INPUT_SRAM_DATA_UPPER_BOUND-1:0]    q_state_input_sram_write_data    ,
  output wire [`Q_STATE_INPUT_SRAM_ADDRESS_UPPER_BOUND-1:0] q_state_input_sram_read_address  , 
  input  wire [`Q_STATE_INPUT_SRAM_DATA_UPPER_BOUND-1:0]    q_state_input_sram_read_data     ,

//---------------------------------------------------------------------------
//q_state_output SRAM interface
  output wire                                                q_state_output_sram_write_enable  ,
  output wire [`Q_STATE_OUTPUT_SRAM_ADDRESS_UPPER_BOUND-1:0] q_state_output_sram_write_address ,
  output wire [`Q_STATE_OUTPUT_SRAM_DATA_UPPER_BOUND-1:0]    q_state_output_sram_write_data    ,
  output wire [`Q_STATE_OUTPUT_SRAM_ADDRESS_UPPER_BOUND-1:0] q_state_output_sram_read_address  , 
  input  wire [`Q_STATE_OUTPUT_SRAM_DATA_UPPER_BOUND-1:0]    q_state_output_sram_read_data     ,

//---------------------------------------------------------------------------
//scratchpad SRAM interface                                                       
  output wire                                                scratchpad_sram_write_enable        ,
  output wire [`SCRATCHPAD_SRAM_ADDRESS_UPPER_BOUND-1:0]     scratchpad_sram_write_address       ,
  output wire [`SCRATCHPAD_SRAM_DATA_UPPER_BOUND-1:0]        scratchpad_sram_write_data          ,
  output wire [`SCRATCHPAD_SRAM_ADDRESS_UPPER_BOUND-1:0]     scratchpad_sram_read_address        , 
  input  wire [`SCRATCHPAD_SRAM_DATA_UPPER_BOUND-1:0]        scratchpad_sram_read_data           ,

//---------------------------------------------------------------------------
//q_gates SRAM interface                                                       
  output wire                                                q_gates_sram_write_enable           ,
  output wire [`Q_GATES_SRAM_ADDRESS_UPPER_BOUND-1:0]        q_gates_sram_write_address          ,
  output wire [`Q_GATES_SRAM_DATA_UPPER_BOUND-1:0]           q_gates_sram_write_data             ,
  output wire [`Q_GATES_SRAM_ADDRESS_UPPER_BOUND-1:0]        q_gates_sram_read_address           ,  
  input  wire [`Q_GATES_SRAM_DATA_UPPER_BOUND-1:0]           q_gates_sram_read_data              
);


	//Parameters
	localparam S0  = 5'b00000;
	localparam S1  = 5'b00001;
	localparam S2  = 5'b00010;
	localparam S3  = 5'b00011;
	localparam S4  = 5'b00100;
	localparam S5  = 5'b00101;
	localparam S6  = 5'b00110;
	localparam S7  = 5'b00111;
	localparam S8  = 5'b01000;
	localparam S9  = 5'b01001;
  localparam S10 = 5'b01010;
  localparam S11 = 5'b01011;
  localparam S12 = 5'b01100;
  localparam S13 = 5'b01101;
  localparam S14 = 5'b01110;
  localparam S15 = 5'b01111;
  localparam S16 = 5'b10000;
  localparam S17 = 5'b10001;
  localparam S18 = 5'b10010;
  localparam S19 = 5'b10011;
  localparam S20 = 5'b10100;
  localparam S21 = 5'b10101;
  localparam S22 = 5'b10110;
  localparam S23 = 5'b10111;
  localparam S24 = 5'b11000;
  localparam S25 = 5'b11001;
  localparam S26 = 5'b11010;


//Multiplication, MAC, adder unit------------------------------------------------------------------------
  localparam inst_sig_width = 52;
  localparam inst_exp_width = 11;
  localparam inst_ieee_compliance = 3; //0 or 1

  wire  [2 : 0] inst_rnd_0; //0
  wire  [2 : 0] inst_rnd_1; //0
  wire  [2 : 0] inst_rnd_2; //0
  wire  [2 : 0] inst_rnd_3; //0
  wire  [2 : 0] inst_rnd_4; //0
  wire  [2 : 0] inst_rnd_5; //0
  wire  [2 : 0] inst_rnd_6; //0
  wire  [2 : 0] inst_rnd_7; //0
  wire [7 : 0] status_inst1;
  wire [7 : 0] status_inst2;
  wire [7 : 0] status_inst3;
  wire [7 : 0] status_inst4;
  wire [7 : 0] status_inst5;
  wire [7 : 0] status_inst6;
  wire [7 : 0] status_inst7;
  wire [7 : 0] status_inst8;

//control Signals----------------------------------------------------------------------------------------

  reg [1:0] q_state_input_rd_adr_sel;
  reg [1:0] scratchpad_rd_adr_sel;
  reg [1:0] q_gates_sram_rd_adr_sel;
  reg [1:0] m_counter_sel;
  reg [1:0] a_counter_sel;
  reg [1:0] b_counter_sel;
  reg       b_select;
  reg       a_max_value_enable;
  reg [1:0] acc_sel;
  reg write_data_demux_sel;
  reg [1:0] sp_wr_adr_sel;
  reg [1:0] q_state_output_wr_adr_sel;

  reg dut_ready_r;

  reg [4:0]	current_state;	//FSM current state
  reg [4:0]	next_state;	    //FSM next state

//registers -----------------------------------------------------------------
  reg [63:0] m_counter;
  reg [63:0] a_counter;
  reg [63:0] b_counter;
  reg [7:0] a_max_value;
  reg [7:0] m_max_value;

  reg [63:0] accumulate_real;
  reg [63:0] accumulate_img;


//wires ---------------------------------------------------------------------

  wire [127:0] a_data;
  wire [127:0] b_data;

  wire [63:0] multiplier1_output; //mac_input1
  wire [63:0] multiplier2_output; //mac_input2
  wire [63:0] multiplier3_output; //adder_input1
  wire [63:0] multiplier4_output; //adder_input2

  wire[63:0] mac_input3;
  assign mac_input3 = 64'hbff0000000000000;

  wire [63:0] mac_output;
  wire [63:0] adder_output;

  wire [63:0] realAdderAccumOutput;
  wire [63:0] ImgAdderAccumOutput;

  wire [127:0] write_data;

//---------------------------------------------------------------------------
//q_state_input SRAM interface
  reg                                               q_state_input_sram_write_enable_r;
  reg [`Q_STATE_INPUT_SRAM_ADDRESS_UPPER_BOUND-1:0] q_state_input_sram_write_address_r;
  reg [`Q_STATE_INPUT_SRAM_DATA_UPPER_BOUND-1:0]    q_state_input_sram_write_data_r;
  reg [`Q_STATE_INPUT_SRAM_ADDRESS_UPPER_BOUND-1:0] q_state_input_sram_read_address_r; 

assign q_state_input_sram_write_enable  =    1'b0;
assign q_state_input_sram_write_address =    32'b0;
assign q_state_input_sram_write_data    =    128'b0;
assign q_state_input_sram_read_address  =    q_state_input_sram_read_address_r;
// assign q_state_input_sram_read_data_r     =    q_state_input_sram_read_data;

//---------------------------------------------------------------------------
//q_state_output SRAM interface
  reg                                                q_state_output_sram_write_enable_r;
  reg [`Q_STATE_OUTPUT_SRAM_ADDRESS_UPPER_BOUND-1:0] q_state_output_sram_write_address_r;
  reg [`Q_STATE_OUTPUT_SRAM_DATA_UPPER_BOUND-1:0]    q_state_output_sram_write_data_r;
  reg [`Q_STATE_OUTPUT_SRAM_ADDRESS_UPPER_BOUND-1:0] q_state_output_sram_read_address_r; 

assign q_state_output_sram_write_enable  =    q_state_output_sram_write_enable_r;
assign q_state_output_sram_write_address =    q_state_output_sram_write_address_r;
assign q_state_output_sram_write_data    =    q_state_output_sram_write_data_r;
assign q_state_output_sram_read_address  =    q_state_output_sram_read_address_r;

//---------------------------------------------------------------------------
//scratchpad SRAM interface                                                       
  reg                                                scratchpad_sram_write_enable_r;
  reg [`SCRATCHPAD_SRAM_ADDRESS_UPPER_BOUND-1:0]     scratchpad_sram_write_address_r;
  reg [`SCRATCHPAD_SRAM_DATA_UPPER_BOUND-1:0]        scratchpad_sram_write_data_r;
  reg [`SCRATCHPAD_SRAM_ADDRESS_UPPER_BOUND-1:0]     scratchpad_sram_read_address_r; 


assign scratchpad_sram_write_enable  =    scratchpad_sram_write_enable_r;
assign scratchpad_sram_write_address =    scratchpad_sram_write_address_r;
assign scratchpad_sram_write_data    =    scratchpad_sram_write_data_r;
assign scratchpad_sram_read_address  =    scratchpad_sram_read_address_r;

//---------------------------------------------------------------------------
//q_gates SRAM interface                                                       
  reg                                                q_gates_sram_write_enable_r;
  reg [`Q_GATES_SRAM_ADDRESS_UPPER_BOUND-1:0]        q_gates_sram_write_address_r;
  reg [`Q_GATES_SRAM_DATA_UPPER_BOUND-1:0]           q_gates_sram_write_data_r;
  reg [`Q_GATES_SRAM_ADDRESS_UPPER_BOUND-1:0]        q_gates_sram_read_address_r;


assign q_gates_sram_write_enable  =    1'b0;
assign q_gates_sram_write_address =    32'b00;
assign q_gates_sram_write_data    =    128'b00;
assign q_gates_sram_read_address  =    q_gates_sram_read_address_r;

assign dut_ready = dut_ready_r;
assign a_data = q_gates_sram_read_data;


assign inst_rnd_0 = 3'b000; //0
assign inst_rnd_1 = 3'b000; //0
assign inst_rnd_2 = 3'b000; //0
assign inst_rnd_3 = 3'b000; //0
assign inst_rnd_4 = 3'b000; //0
assign inst_rnd_5 = 3'b000; //0
assign inst_rnd_6 = 3'b000; //0
assign inst_rnd_7 = 3'b000; //0

always@(posedge clk)
  begin
    if (!reset_n) begin 
      current_state <= 5'b00000;
    end
    else begin 
    current_state <= next_state;
    end
  end

always@(*)
	begin
next_state = S0;
		casex (current_state)
			S0 : begin
        q_state_input_rd_adr_sel = 2'b11;
        scratchpad_rd_adr_sel = 2'b10;
        q_gates_sram_rd_adr_sel= 2'b10;
        m_counter_sel= 2'b10;
        a_counter_sel= 2'b10;
        b_counter_sel= 2'b10;
        b_select = 1'b0;
        a_max_value_enable = 1'b0;
        acc_sel = 2'b10;
        write_data_demux_sel = 1'b0;
        sp_wr_adr_sel = 2'b10;
        q_state_output_wr_adr_sel = 2'b10;
        dut_ready_r = 1'b1;
				if (dut_valid == 1'b1)
					next_state = S1;
				else
					next_state = S0;
      end
      S1 : begin // read input SRAM 0th address to fetch Q|M value
        q_state_input_rd_adr_sel = 2'b00;
        scratchpad_rd_adr_sel = 2'b10;
        q_gates_sram_rd_adr_sel= 2'b10;
        m_counter_sel= 2'b10;
        a_counter_sel= 2'b10;
        b_counter_sel= 2'b10;
        b_select = 1'b0;
        a_max_value_enable = 1'b0;
        acc_sel = 2'b10;
        write_data_demux_sel = 1'b0;
        sp_wr_adr_sel = 2'b10;
        q_state_output_wr_adr_sel = 2'b10;
        dut_ready_r = 1'b0;
        next_state = S26;
      end
      S26 : begin
        q_state_input_rd_adr_sel = 2'b11;
        scratchpad_rd_adr_sel = 2'b10;
        q_gates_sram_rd_adr_sel= 2'b10;
        m_counter_sel= 2'b10;
        a_counter_sel= 2'b10;
        b_counter_sel= 2'b10;
        b_select = 1'b0;
        a_max_value_enable = 1'b0;
        acc_sel = 2'b10;
        write_data_demux_sel = 1'b0;
        sp_wr_adr_sel = 2'b10;
        q_state_output_wr_adr_sel = 2'b10;
        dut_ready_r = 1'b0;
        next_state = S22;
      end
      S22: begin // q_gate SRAM 0th address to fetch 1st element of operator matrix & 1st data of input matrix
        q_state_input_rd_adr_sel = 2'b01;
        scratchpad_rd_adr_sel = 2'b10;
        q_gates_sram_rd_adr_sel= 2'b00;
        m_counter_sel= 2'b10;
        a_counter_sel= 2'b10;
        b_counter_sel= 2'b10;
        b_select = 1'b0;
        a_max_value_enable = 1'b1;
        acc_sel = 2'b10;
        write_data_demux_sel = 1'b0;
        sp_wr_adr_sel = 2'b10;
        q_state_output_wr_adr_sel = 2'b10;
        dut_ready_r = 1'b0;
        next_state = S2;    
      end
      S2 : begin
        q_state_input_rd_adr_sel = 2'b10;
        scratchpad_rd_adr_sel = 2'b10;
        q_gates_sram_rd_adr_sel= 2'b01;
        m_counter_sel= 2'b00;
        a_counter_sel= 2'b00;
        b_counter_sel= 2'b00;
        b_select = 1'b0;
        a_max_value_enable = 1'b0;
        acc_sel = 2'b11;
        write_data_demux_sel = 1'b0;
        sp_wr_adr_sel = 2'b10;
        q_state_output_wr_adr_sel = 2'b10;
        dut_ready_r = 1'b0;
        if(m_max_value == 64'b01)
          next_state = S15;
        else if(a_max_value > 64'b10)
          next_state = S4;
        else
          next_state = S3;
      end
      S3: begin //1st computation here
        q_state_input_rd_adr_sel = 2'b11;
        scratchpad_rd_adr_sel = 2'b10;
        q_gates_sram_rd_adr_sel= 2'b10;
        m_counter_sel= 2'b10;
        a_counter_sel= 2'b10;
        b_counter_sel= 2'b01;
        b_select = 1'b0;
        a_max_value_enable = 1'b0;
        acc_sel = 2'b01;
        write_data_demux_sel = 1'b0;
        sp_wr_adr_sel = 2'b10;
        q_state_output_wr_adr_sel = 2'b10;
        dut_ready_r = 1'b0;

          if(a_counter == a_max_value)
            next_state = S5;
          else
            next_state = S8;

      end
      S4 : begin
        q_state_input_rd_adr_sel = 2'b10;
        scratchpad_rd_adr_sel = 2'b10;
        q_gates_sram_rd_adr_sel= 2'b01;
        m_counter_sel= 2'b10;
        a_counter_sel= 2'b10;
        b_counter_sel= 2'b01;
        b_select = 1'b0;
        a_max_value_enable = 1'b0;
        acc_sel = 2'b01;
        write_data_demux_sel = 1'b0;
        sp_wr_adr_sel = 2'b10;
        q_state_output_wr_adr_sel = 2'b10;
        dut_ready_r = 1'b0;

        if(b_counter > 64'b11)
          next_state = S4;
        else
          next_state = S3;
      end
      S5 : begin
        q_state_input_rd_adr_sel = 2'b01;
        scratchpad_rd_adr_sel = 2'b10;
        q_gates_sram_rd_adr_sel= 2'b01;
        m_counter_sel= 2'b10;
        a_counter_sel= 2'b10;
        b_counter_sel= 2'b01;
        b_select = 1'b0;
        a_max_value_enable = 1'b0;
        acc_sel = 2'b01;
        write_data_demux_sel = 1'b0;
        sp_wr_adr_sel = 2'b00;
        q_state_output_wr_adr_sel = 2'b10;
        dut_ready_r = 1'b0;
        next_state = S6;
        
      end
      S6 : begin //1st write to scratchpad
        q_state_input_rd_adr_sel = 2'b10;
        scratchpad_rd_adr_sel = 2'b10;
        q_gates_sram_rd_adr_sel= 2'b01;
        m_counter_sel= 2'b10;
        a_counter_sel= 2'b01;
        b_counter_sel= 2'b00;
        b_select = 1'b0;
        a_max_value_enable = 1'b0;
        acc_sel = 2'b11;
        write_data_demux_sel = 1'b0;
        sp_wr_adr_sel = 2'b10;
        q_state_output_wr_adr_sel = 2'b10;
        dut_ready_r = 1'b0;
        if(a_max_value > 64'b10)
          next_state = S4;
        else
          next_state = S3;
      end
      S7 : begin //1st Matrix computation completed and write data given to scratchpad
        q_state_input_rd_adr_sel = 2'b11;
        scratchpad_rd_adr_sel = 2'b00;
        q_gates_sram_rd_adr_sel= 2'b01;
        m_counter_sel= 2'b01;
        a_counter_sel= 2'b00;
        b_counter_sel= 2'b00;
        b_select = 1'b0;
        a_max_value_enable = 1'b0;
        acc_sel = 2'b11;
        write_data_demux_sel = 1'b0;
        sp_wr_adr_sel = 2'b10;
        q_state_output_wr_adr_sel = 2'b10;
        dut_ready_r = 1'b0;
        next_state = S21;
      end
      S8 : begin
        q_state_input_rd_adr_sel = 2'b11;
        scratchpad_rd_adr_sel = 2'b10;
        q_gates_sram_rd_adr_sel= 2'b10;
        m_counter_sel= 2'b10;
        a_counter_sel= 2'b10;
        b_counter_sel= 2'b01;
        b_select = 1'b0;
        a_max_value_enable = 1'b0;
        acc_sel = 2'b01;
        write_data_demux_sel = 1'b0;
        sp_wr_adr_sel = 2'b01;
        q_state_output_wr_adr_sel = 2'b10;
        dut_ready_r = 1'b0;
        if(a_counter != 64'b01 && a_max_value > 64'b10)
          next_state = S23;
        else if(a_counter == 64'b01)
          next_state = S7;
      end
      S9 : begin
        q_state_input_rd_adr_sel = 2'b11;
        scratchpad_rd_adr_sel = 2'b10;
        q_gates_sram_rd_adr_sel= 2'b10;
        m_counter_sel= 2'b10;
        a_counter_sel= 2'b10;
        b_counter_sel= 2'b01;
        b_select = 1'b1;
        a_max_value_enable = 1'b0;
        acc_sel = 2'b01;
        write_data_demux_sel = 1'b0;
        sp_wr_adr_sel = 2'b10;
        q_state_output_wr_adr_sel = 2'b10;
        dut_ready_r = 1'b0;
        if(a_counter == a_max_value)
            next_state = S11;
        else
            next_state = S14;
      end
      S10 : begin
        q_state_input_rd_adr_sel = 2'b11;
        scratchpad_rd_adr_sel = 2'b01;
        q_gates_sram_rd_adr_sel= 2'b01;
        m_counter_sel= 2'b10;
        a_counter_sel= 2'b10;
        b_counter_sel= 2'b01;
        b_select = 1'b1;
        a_max_value_enable = 1'b0;
        acc_sel = 2'b01;
        write_data_demux_sel = 1'b0;
        sp_wr_adr_sel = 2'b10;
        q_state_output_wr_adr_sel = 2'b10;
        dut_ready_r = 1'b0;

        if(b_counter > 64'b11)
          next_state = S10;
        else if(b_counter == 64'b11)
          next_state = S9;
      end
      S11 : begin
        q_state_input_rd_adr_sel = 2'b11;
        scratchpad_rd_adr_sel = 2'b11;
        q_gates_sram_rd_adr_sel= 2'b01;
        m_counter_sel= 2'b10;
        a_counter_sel= 2'b10;
        b_counter_sel= 2'b01;
        b_select = 1'b1;
        a_max_value_enable = 1'b0;
        acc_sel = 2'b01;
        write_data_demux_sel = 1'b0;
        sp_wr_adr_sel = 2'b01;
        q_state_output_wr_adr_sel = 2'b10;
        dut_ready_r = 1'b0;
        next_state = S12;
      end
      S12 : begin
        q_state_input_rd_adr_sel = 2'b11;
        scratchpad_rd_adr_sel = 2'b01;
        q_gates_sram_rd_adr_sel = 2'b01;
        m_counter_sel = 2'b10;
        a_counter_sel = 2'b01;
        b_counter_sel = 2'b00;
        b_select = 1'b1;
        a_max_value_enable = 1'b0;
        acc_sel = 2'b11;
        write_data_demux_sel = 1'b0;
        sp_wr_adr_sel = 2'b10;
        q_state_output_wr_adr_sel = 2'b10;
        dut_ready_r = 1'b0;

        if(a_max_value > 64'b10)
          next_state = S10;
        else 
          next_state = S9;
      end
      S13 : begin
        q_state_input_rd_adr_sel = 2'b11;
        scratchpad_rd_adr_sel = 2'b01;
        q_gates_sram_rd_adr_sel= 2'b01;
        m_counter_sel= 2'b01;
        a_counter_sel= 2'b00;
        b_counter_sel= 2'b00;
        b_select = 1'b1;
        a_max_value_enable = 1'b0;
        acc_sel = 2'b11;
        write_data_demux_sel = 1'b0;
        sp_wr_adr_sel = 2'b10;
        q_state_output_wr_adr_sel = 2'b10;
        dut_ready_r = 1'b0;
        next_state = S21;
      end
      S14 : begin
        q_state_input_rd_adr_sel = 2'b11;
        scratchpad_rd_adr_sel = 2'b10;
        q_gates_sram_rd_adr_sel= 2'b10;
        m_counter_sel= 2'b10;
        a_counter_sel= 2'b10;
        b_counter_sel= 2'b01;
        b_select = 1'b1;
        a_max_value_enable = 1'b0;
        acc_sel = 2'b01;
        write_data_demux_sel = 1'b0;
        sp_wr_adr_sel = 2'b01;
        q_state_output_wr_adr_sel = 2'b10;
        dut_ready_r = 1'b0;
        if(a_counter == 64'b01)
          next_state = S13;
        else if(a_counter != 64'b01)
          next_state = S24;
      end
      S15 : begin //final cycle start here 
        q_state_input_rd_adr_sel = 2'b11;
        scratchpad_rd_adr_sel = 2'b10;
        q_gates_sram_rd_adr_sel= 2'b10;
        m_counter_sel= 2'b10;
        a_counter_sel= 2'b10;
        b_counter_sel= 2'b01;
        if(m_max_value == 8'b01) begin
          b_select = 1'b0;
        end
        else begin
          b_select = 1'b1;
        end
        a_max_value_enable = 1'b0;
        acc_sel = 2'b01;
        write_data_demux_sel = 1'b1;
        sp_wr_adr_sel = 2'b10;
        q_state_output_wr_adr_sel = 2'b10;
        dut_ready_r = 1'b0;
        if(a_counter == a_max_value)
          next_state = S17;
        else
          next_state = S20;
      end
      S16 : begin //final cycle start here
        q_state_input_rd_adr_sel = 2'b11;
        scratchpad_rd_adr_sel = 2'b01;
        q_gates_sram_rd_adr_sel= 2'b01;
        m_counter_sel= 2'b10;
        a_counter_sel= 2'b10;
        b_counter_sel= 2'b01;
        if(m_max_value == 8'b01)
          b_select = 1'b0;
        else
          b_select = 1'b1;
        a_max_value_enable = 1'b0;
        acc_sel = 2'b01;
        write_data_demux_sel = 1'b1;
        sp_wr_adr_sel = 2'b10;
        q_state_output_wr_adr_sel = 2'b10;
        dut_ready_r = 1'b0;

        if(b_counter > 64'b11)
          next_state = S16;
        else if(b_counter == 64'b11)
          next_state = S15;
      end
      S17 : begin
        scratchpad_rd_adr_sel = 2'b11;
        q_gates_sram_rd_adr_sel= 2'b01;
        m_counter_sel= 2'b10;
        a_counter_sel= 2'b10;
        b_counter_sel= 2'b01;
        if(m_max_value == 8'b01) begin
          b_select = 1'b0;
          q_state_input_rd_adr_sel = 2'b01;
        end
        else begin
          b_select = 1'b1;
          q_state_input_rd_adr_sel = 2'b11;
        end
        a_max_value_enable = 1'b0;
        acc_sel = 2'b01;
        write_data_demux_sel = 1'b1;
        sp_wr_adr_sel = 2'b10;
        q_state_output_wr_adr_sel = 2'b00;
        dut_ready_r = 1'b0;
        next_state = S18;
      end
      S18 : begin
        scratchpad_rd_adr_sel = 2'b01;
        q_gates_sram_rd_adr_sel = 2'b01;
        m_counter_sel = 2'b10;
        a_counter_sel = 2'b01;
        b_counter_sel = 2'b00;
        if(m_max_value == 8'b01) begin
          b_select = 1'b0;
          q_state_input_rd_adr_sel = 2'b10;
        end
        else begin
          b_select = 1'b1;
          q_state_input_rd_adr_sel = 2'b11;
        end
        a_max_value_enable = 1'b0;
        acc_sel = 2'b11;
        write_data_demux_sel = 1'b1;
        sp_wr_adr_sel = 2'b10;
        q_state_output_wr_adr_sel = 2'b10;
        dut_ready_r = 1'b0;
        if(a_max_value > 64'b10)
          next_state = S16;
        else 
          next_state = S15;
      end
      S19 : begin //final state
        q_state_input_rd_adr_sel = 2'b11;
        scratchpad_rd_adr_sel = 2'b10;
        q_gates_sram_rd_adr_sel= 2'b10;
        m_counter_sel= 2'b10;
        a_counter_sel= 2'b10;
        b_counter_sel= 2'b10;
        if(m_max_value == 8'b01)
          b_select = 1'b0;
        else
          b_select = 1'b1;
        a_max_value_enable = 1'b0;
        acc_sel = 2'b10;
        write_data_demux_sel = 1'b1;
        sp_wr_adr_sel = 2'b10;
        q_state_output_wr_adr_sel = 2'b10;
        dut_ready_r = 1'b0;
        next_state = S0;
      end
      S20 : begin
        q_state_input_rd_adr_sel = 2'b11;
        scratchpad_rd_adr_sel = 2'b10;
        q_gates_sram_rd_adr_sel= 2'b10;
        m_counter_sel= 2'b10;
        a_counter_sel= 2'b10;
        b_counter_sel= 2'b01;
        if(m_max_value == 8'b01)
          b_select = 1'b0;
        else
          b_select = 1'b1;
        a_max_value_enable = 1'b0;
        acc_sel = 2'b01;
        write_data_demux_sel = 1'b1;
        sp_wr_adr_sel = 2'b10;
        q_state_output_wr_adr_sel = 2'b01;
        dut_ready_r = 1'b0;
        if(a_counter == 64'b01)
          next_state = S19;
        else if(a_counter != 64'b01)
          next_state = S25;
      end
      S21 : begin
        q_state_input_rd_adr_sel = 2'b11;
        scratchpad_rd_adr_sel = 2'b01;
        q_gates_sram_rd_adr_sel= 2'b01;
        m_counter_sel= 2'b10;
        a_counter_sel= 2'b10;
        b_counter_sel= 2'b10;
        b_select = 1'b1;
        a_max_value_enable = 1'b0;
        acc_sel = 2'b10;
        write_data_demux_sel = 1'b0;
        sp_wr_adr_sel = 2'b10;
        q_state_output_wr_adr_sel = 2'b10;
        dut_ready_r = 1'b0;
        if(m_counter != 64'b01 && a_max_value > 64'b10)
          next_state = S10;
        else if(m_counter != 64'b01 && a_max_value == 64'b10)
          next_state = S9;
        else if(m_counter == 64'b01 && a_max_value > 64'b10)
          next_state = S16;
        else if(m_counter == 64'b01 && a_max_value == 64'b10)
          next_state = S15;  
      end
      S23 : begin
        q_state_input_rd_adr_sel = 2'b01;
        scratchpad_rd_adr_sel = 2'b10;
        q_gates_sram_rd_adr_sel= 2'b01;
        m_counter_sel= 2'b10;
        a_counter_sel= 2'b10;
        b_counter_sel= 2'b10;
        b_select = 1'b0;
        a_max_value_enable = 1'b0;
        acc_sel = 2'b11;
        write_data_demux_sel = 1'b0;
        sp_wr_adr_sel = 2'b10;
        q_state_output_wr_adr_sel = 2'b10;
        dut_ready_r = 1'b0;
        next_state = S6;
      end
      S24 : begin
        q_state_input_rd_adr_sel = 2'b11;
        scratchpad_rd_adr_sel = 2'b11;
        q_gates_sram_rd_adr_sel= 2'b01;
        m_counter_sel= 2'b10;
        a_counter_sel= 2'b10;
        b_counter_sel= 2'b10;
        b_select = 1'b0;
        a_max_value_enable = 1'b0;
        acc_sel = 2'b11;
        write_data_demux_sel = 1'b0;
        sp_wr_adr_sel = 2'b10;
        q_state_output_wr_adr_sel = 2'b10;
        dut_ready_r = 1'b0;
        next_state = S12;
      end
      S25 : begin
        q_state_input_rd_adr_sel = 2'b11;
        scratchpad_rd_adr_sel = 2'b11;
        q_gates_sram_rd_adr_sel= 2'b01;
        m_counter_sel= 2'b10;
        a_counter_sel= 2'b10;
        b_counter_sel= 2'b10;
        if(m_max_value == 8'b01)
          b_select = 1'b0;
        else
          b_select = 1'b1;
        a_max_value_enable = 1'b0;
        acc_sel = 2'b11;
        write_data_demux_sel = 1'b1;
        sp_wr_adr_sel = 2'b10;
        q_state_output_wr_adr_sel = 2'b10;
        dut_ready_r = 1'b0;
        next_state = S18;
      end
      default : begin
        q_state_input_rd_adr_sel = 2'b11;
        scratchpad_rd_adr_sel = 2'b10;
        q_gates_sram_rd_adr_sel= 2'b10;
        m_counter_sel= 2'b10;
        a_counter_sel= 2'b10;
        b_counter_sel= 2'b10;
        b_select = 1'b0;
        a_max_value_enable = 1'b0;
        acc_sel = 2'b10;
        write_data_demux_sel = 1'b0;
        sp_wr_adr_sel = 2'b10;
        q_state_output_wr_adr_sel = 2'b10;
        dut_ready_r = 1'b0;
				next_state = S0;
			end
		endcase
  end

// Adder, multiplier, MAC units ------------------------------------------------------------------
  DW_fp_mac_inst FP_MAC1 (
    mac_input3,
    multiplier2_output, //img(A*B)
    multiplier1_output,
    inst_rnd_0,
    mac_output,
    status_inst1
  );

  DW_fp_mult_inst FP_Multiplier1 (
    a_data[127:64], //a_real
    b_data[127:64], //b_real
    inst_rnd_1,
    multiplier1_output,
    status_inst2
  );

  DW_fp_mult_inst FP_Multiplier2 (
    a_data[63:0], //a_img
    b_data[63:0], //b_img
    inst_rnd_2,
    multiplier2_output,
    status_inst3
  );

  DW_fp_mult_inst FP_Multiplier3 (
    a_data[127:64], //a_real
    b_data[63:0], //b_img
    inst_rnd_3,
    multiplier3_output,
    status_inst4
  ); 

  DW_fp_mult_inst FP_Multiplier4 (
    a_data[63:0], //a_img
    b_data[127:64],//b_real
    inst_rnd_4,
    multiplier4_output,
    status_inst5
  );
  
  DW_fp_add_inst FP_Adder1 (
    multiplier3_output,
    multiplier4_output,
    inst_rnd_5,
    adder_output,
    status_inst6
  );

// Data path---------------------------------------------------------------------------

//q_state_input SRAM read address register----------------------------------------------
	always @(posedge clk) begin
     if(!reset_n) begin
     q_state_input_sram_read_address_r <= 32'b0;
     end
     else begin
      if(q_state_input_rd_adr_sel == 2'b00)
        q_state_input_sram_read_address_r <= 32'b00;
      else if(q_state_input_rd_adr_sel == 2'b01)
        q_state_input_sram_read_address_r <= 32'b01;
      else if(q_state_input_rd_adr_sel == 2'b10)
        q_state_input_sram_read_address_r <= q_state_input_sram_read_address_r + 32'b01;
      else if(q_state_input_rd_adr_sel == 2'b11)
        q_state_input_sram_read_address_r <= q_state_input_sram_read_address_r;
     end
  end

 //-------------------------------------------------------------------------------------------- 

//Scratchpad SRAM read address register --------------------------------------------------------
	always @(posedge clk) begin
    if(!reset_n) begin
      scratchpad_sram_read_address_r <= 32'b00;
    end
    else begin
      if(scratchpad_rd_adr_sel == 2'b00)
        scratchpad_sram_read_address_r <= 32'b00;
      else if(scratchpad_rd_adr_sel == 2'b01)
      scratchpad_sram_read_address_r <= scratchpad_sram_read_address_r + 32'b01;
      else if(scratchpad_rd_adr_sel == 2'b10)
        scratchpad_sram_read_address_r <= scratchpad_sram_read_address_r;
      else if(scratchpad_rd_adr_sel == 2'b11)
        scratchpad_sram_read_address_r <= (scratchpad_sram_read_address_r - a_max_value + 1); 
    end 
  end
 //--------------------------------------------------------------------------------------------

//q_gate SRAM read address register -----------------------------------------------------------
	always @(posedge clk) begin
    if(q_gates_sram_rd_adr_sel == 2'b00)
      q_gates_sram_read_address_r <= 32'b00;
    else if(q_gates_sram_rd_adr_sel == 2'b01)
     q_gates_sram_read_address_r <= q_gates_sram_read_address_r + 32'b01;
    else if(q_gates_sram_rd_adr_sel == 2'b10)
      q_gates_sram_read_address_r <= q_gates_sram_read_address_r;
  end
 //--------------------------------------------------------------------------------------------

//m_counter -----------------------------------------------------------------------------------
	always @(posedge clk) begin
    if(m_counter_sel == 2'b00)
      m_counter <= q_state_input_sram_read_data[63:0];
    else if(m_counter_sel == 2'b01)
     m_counter <= m_counter - 32'b01;
    else if(m_counter_sel == 2'b10)
      m_counter <= m_counter;
  end
 //--------------------------------------------------------------------------------------------

//a_counter -----------------------------------------------------------------------------------
	always @(posedge clk) begin
    if(a_counter_sel == 2'b00)
      a_counter <= a_max_value;
    else if(a_counter_sel == 2'b01)
     a_counter <= a_counter - 32'b01;
    else if(a_counter_sel == 2'b10)
      a_counter <= a_counter;
  end
 //--------------------------------------------------------------------------------------------

//b_counter ----------------------------------------------------------------------------------
	always @(posedge clk) begin
    if(b_counter_sel == 2'b00)
      b_counter <= a_max_value;
    else if(b_counter_sel == 2'b01)
     b_counter <= b_counter - 32'b01;
    else if(b_counter_sel == 2'b10)
      b_counter <= b_counter;
  end
 //--------------------------------------------------------------------------------------------

  //a_max_value register ----------------------------------------------------------------------
  always @(posedge clk) begin
    if(a_max_value_enable == 1'b1) begin
      a_max_value <= (1 << q_state_input_sram_read_data[127:64]); //2^q
      m_max_value <= (q_state_input_sram_read_data[63:0]);
    end
  end
 //--------------------------------------------------------------------------------------------

  //scratchPad SRAM write address register ----------------------------------------------------
	always @(posedge clk) begin
     if(!reset_n) begin
     scratchpad_sram_write_address_r <= 32'b00; 
     end
     else begin
      if(sp_wr_adr_sel == 2'b00)
        scratchpad_sram_write_address_r <= 32'b00;
      else if(sp_wr_adr_sel == 2'b01)
      scratchpad_sram_write_address_r <= scratchpad_sram_write_address_r + 32'b01;
      else if(sp_wr_adr_sel == 2'b10)
        scratchpad_sram_write_address_r <= scratchpad_sram_write_address_r;
     end
  end
 //--------------------------------------------------------------------------------------------

  //q_state_output SRAM write address register ------------------------------------------------
	always @(posedge clk) begin
    if(q_state_output_wr_adr_sel == 2'b00)
      q_state_output_sram_write_address_r <= 32'b00;
    else if(q_state_output_wr_adr_sel == 2'b01)
     q_state_output_sram_write_address_r <= q_state_output_sram_write_address_r + 32'b01;
    else if(q_state_output_wr_adr_sel == 2'b10)
      q_state_output_sram_write_address_r <= q_state_output_sram_write_address_r;
  end
 //--------------------------------------------------------------------------------------------

//Mux for switch inputData between q_state_input & Q_gate SRAM --------------------------------
assign b_data = (b_select) ? scratchpad_sram_read_data : q_state_input_sram_read_data;
 //--------------------------------------------------------------------------------------------

//Scratchpad Sram Write Enable Register -------------------------------------------------------
 always@(posedge clk)
  begin
    if(sp_wr_adr_sel == 2'b00 || sp_wr_adr_sel == 2'b01)
      scratchpad_sram_write_enable_r <= 1'b1;
    else if(sp_wr_adr_sel == 2'b10)
      scratchpad_sram_write_enable_r <= 1'b0;
  end
 //--------------------------------------------------------------------------------------------

//q_state_output Sram Write Enable Register ----------------------------------------------------
 always@(posedge clk)
  begin
    if(q_state_output_wr_adr_sel == 2'b00 || q_state_output_wr_adr_sel == 2'b01)
      q_state_output_sram_write_enable_r <= 1'b1;
    else if(q_state_output_wr_adr_sel == 2'b10)
      q_state_output_sram_write_enable_r <= 1'b0;
  end
 //--------------------------------------------------------------------------------------------

//demux for switch writing between scratchpad & q_gate_output SRAM ----------------------------
  always @(*) begin
    casex(write_data_demux_sel)
     1'b0 : begin
      scratchpad_sram_write_data_r <= write_data;
      q_state_output_sram_write_data_r <= 128'b00;
    end
    1'b1 : begin
      scratchpad_sram_write_data_r <= 128'b00;
      q_state_output_sram_write_data_r <= write_data;
    end
    endcase
  end
 //--------------------------------------------------------------------------------------------

    DW_fp_add_inst FP_Adder_AccumReal (
    accumulate_real,
    mac_output,
    inst_rnd_6,
    realAdderAccumOutput,
    status_inst7
  );

//realAccumulate register ------------------------------------------------------------------------
	always @(posedge clk) begin
    if(acc_sel == 2'b00)
      accumulate_real <= mac_output;
    else if(acc_sel == 2'b01) begin
    //  accumulate_real <= accumulate_real + mac_output;
    accumulate_real <= realAdderAccumOutput;
    end
    else if(acc_sel == 2'b10)
      accumulate_real <= accumulate_real;
    else if(acc_sel == 2'b11)
      accumulate_real <= 64'b0;
  end
 //--------------------------------------------------------------------------------------------

    DW_fp_add_inst FP_Adder_AccumImg (
    accumulate_img,
    adder_output,
    inst_rnd_7,
    ImgAdderAccumOutput,
    status_inst8
  );

//ImgAccumulate register ------------------------------------------------------------------------
	always @(posedge clk) begin
    if(acc_sel == 2'b00)
      accumulate_img <= adder_output;
    else if(acc_sel == 2'b01)
     accumulate_img <= ImgAdderAccumOutput;
    else if(acc_sel == 2'b10)
      accumulate_img <= accumulate_img;
    else if(acc_sel == 2'b11)
      accumulate_img <= 64'b0;
  end
 //--------------------------------------------------------------------------------------------

//wire for output sel ------------------------------------------------------------------------
assign write_data = {accumulate_real, accumulate_img};
 //--------------------------------------------------------------------------------------------

endmodule


module DW_fp_mac_inst #(
  parameter inst_sig_width = 52,
  parameter inst_exp_width = 11,
  parameter inst_ieee_compliance = 1 // These need to be fixed to decrease error
) ( 
  input wire [inst_sig_width+inst_exp_width : 0] inst_a,
  input wire [inst_sig_width+inst_exp_width : 0] inst_b,
  input wire [inst_sig_width+inst_exp_width : 0] inst_c,
  input wire [2 : 0] inst_rnd,
  output wire [inst_sig_width+inst_exp_width : 0] z_inst,
  output wire [7 : 0] status_inst
);

  // Instance of DW_fp_mac
  DW_fp_mac #(inst_sig_width, inst_exp_width, inst_ieee_compliance) U1 (
    .a(inst_a),
    .b(inst_b),
    .c(inst_c),
    .rnd(inst_rnd),
    .z(z_inst),
    .status(status_inst) 
  );

endmodule

module DW_fp_mult_inst( inst_a, inst_b, inst_rnd, z_inst, status_inst );
  parameter sig_width = 52;
  parameter exp_width = 11;
  parameter ieee_compliance = 3;
  parameter en_ubr_flag = 0;
  input [sig_width+exp_width : 0] inst_a;
  input [sig_width+exp_width : 0] inst_b;
  input [2 : 0] inst_rnd;
  output [sig_width+exp_width : 0] z_inst;
  output [7 : 0] status_inst;
  // Instance of DW_fp_mult
  DW_fp_mult #(sig_width, exp_width, ieee_compliance, en_ubr_flag) U1 ( 
    .a(inst_a), 
    .b(inst_b), 
    .rnd(inst_rnd), 
    .z(z_inst), 
    .status(status_inst) 
    );

endmodule


module DW_fp_add_inst( inst_a, inst_b, inst_rnd, z_inst, status_inst );
  parameter sig_width = 52;
  parameter exp_width = 11;
  parameter ieee_compliance = 3;
  input [sig_width+exp_width : 0] inst_a;
  input [sig_width+exp_width : 0] inst_b;
  input [2 : 0] inst_rnd;
  output [sig_width+exp_width : 0] z_inst;
  output [7 : 0] status_inst;
  // Instance of DW_fp_add
  DW_fp_add #(sig_width, exp_width, ieee_compliance) U1 ( 
    .a(inst_a),
    .b(inst_b),
    .rnd(inst_rnd),
    .z(z_inst),
    .status(status_inst) 
    );

endmodule
