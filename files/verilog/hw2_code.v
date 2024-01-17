// Homework 2 Verilog Solutions Spring 2021
//Sean Huang

// Problem 1: 4-bit Multiplexor
// =============================================================================
// mux
module mux(a, b, c, d, s, out);
    input a, b, c, d;
    input [1:0] s;
    output out;

    wire int_a, int_b;

    assign int_a = (a & ~s[0]) | (b & s[0]);
    assign int_b = (c & ~s[0]) | (d & s[0]);
    assign out = (int_a & ~s[1]) | (int_b & s[1]);
endmodule

// testbench
// testbench
module mux_tb;
  reg [3:0] in_vec;
  reg [1:0] s;
  reg expected;
  wire out;

  // loop variables
  integer i, j;

  // instantiate dut
  mux dut (.a(in_vec[3]),
           .b(in_vec[2]),
           .c(in_vec[1]),
           .d(in_vec[0]),
           .s(s),
           .out(out));

  // make golden LUT
  always @(*) begin
    case (s)
      2'b00:	expected <= in_vec[3];
      2'b01:	expected <= in_vec[2];
      2'b10:	expected <= in_vec[1];
      2'b11:	expected <= in_vec[0];
      default:expected <= 1'b0;
    endcase
  end

  // begin test
  initial begin
    $dumpfile("dump.vcd");
    $dumpvars;
    in_vec = 4'b0000;
   	s = 2'b00;
    for(i = 0; i < 16; i = i + 1) begin
      for (j = 0; j < 4; j = j + 1) begin
      	in_vec = i;
        s = j;
        $strobe("a: %b, b: %b, c: %b, d: %b, s: %b, out: %b",
                in_vec[3], in_vec[2], in_vec[1], in_vec[0], s, out);
        #1;
        // Break early if test failed
        if (out != expected) begin
          $display("FAILED, expected %b, got %b", expected, out);
          $finish();
        end
      end
    end
    $display("ALL TESTS PASSSED!");
    $finish();
  end
endmodule

// Problem 2: 6-bit Multiplexor
// =============================================================================
// Part a
// -----------------------------------------------------------------------------
module mux_2_hier(
  input [1:0] X,
  input sel,
  output y);

  assign y = sel ? X[1] : X[0];
endmodule

module mux_4_hier(
  input [3:0] X,
  input [1:0] sel,
  output y);

  wire int_AA, int_AB;

  mux_2_hier mux_AA(.X(X[3:2]), .sel(sel[0]), .y(int_AA));
  mux_2_hier mux_AB(.X(X[1:0]), .sel(sel[0]), .y(int_AB));
  mux_2_hier mux_B(.X({int_AA, int_AB}), .sel(sel[1]), .y(y));
endmodule

module mux_6_hier(
  input [5:0] X,
  input [2:0] sel,
  output y);

  wire int_AA, int_AB;

  mux_4_hier mux_AA(.X({2'bxx,X[5:4]}), .sel(sel[1:0]), .y(int_AA));
  mux_4_hier mux_AB(.X(X[3:0]), .sel(sel[1:0]), .y(int_AB));
  mux_2_hier mux_B(.X({int_AA, int_AB}), .sel(sel[2]), .y(y));
endmodule
// Part b
// -----------------------------------------------------------------------------
module mux_6_flat(
  input [5:0] X,
  input [2:0] sel,
  output reg y
  );

  always @ ( * ) begin
    case (sel)
      3'b000:   y = X[0];
      3'b001:   y = X[1];
      3'b010:   y = X[2];
      3'b011:   y = X[3];
      3'b100:   y = X[4];
      3'b101:   y = X[5];
      default:  y = 1'bx;
    endcase
  end
endmodule

// testbench
module mux_6_tb;
  reg [5:0] in_vec;
  reg [2:0] s;
  reg expected;
  wire out_hier;
  wire out_flat;

  // loop variables
  integer i, j;

  // instantiate duts
  mux_6_hier dut_hier (.X(in_vec),
                  .sel(s),
                  .y(out_hier));

  mux_6_flat dut_flat (.X(in_vec),
                  .sel(s),
                  .y(out_flat));

  // make golden LUT
  always @(*) begin
    case (s)
      3'b000:   expected = in_vec[0];
      3'b001:   expected = in_vec[1];
      3'b010:   expected = in_vec[2];
      3'b011:   expected = in_vec[3];
      3'b100:   expected = in_vec[4];
      3'b101:   expected = in_vec[5];
      default:  expected = 1'bx;
    endcase
  end

  // begin test
  initial begin
    $dumpfile("dump.vcd");
    $dumpvars;
    in_vec = 4'b0000;
   	s = 2'b00;
    for(i = 0; i < 256; i = i + 1) begin
      for (j = 0; j < 8; j = j + 1) begin
      	in_vec = i;
        s = j;
        $strobe("in_vec: %b, s: %b, out_flat: %b, out_hier: %b, expected: %b",
                in_vec, s, out_flat, out_hier, expected);
        #1;
        // Break early if failed; Using case equivalence to check for x
        if (out_hier !== expected) begin
          $display("HIERARCHICAL FAILED, expected %b, got %b", expected, out_hier);
          $finish();
        end
        if (out_flat !== expected) begin
          $display("FLAT FAILED, expected %b, got %b", expected, out_flat);
          $finish();
        end
      end
    end
    $display("ALL TESTS PASSED FOR ALL DESIGNS!");
    $finish();
  end
endmodule

// Problem 3: 2-bit Decoder Both Ways
// =============================================================================
// Part a
// -----------------------------------------------------------------------------
module decoder_2_cond(
  input [1:0] in,
  output reg [3:0] out
  );

  always @ ( * ) begin
    if (in == 2'b00) out = 4'b0001;
    if (in == 2'b01) out = 4'b0010;
    if (in == 2'b10) out = 4'b0100;
    if (in == 2'b11) out = 4'b1000;
  end
endmodule
// Part b
// -----------------------------------------------------------------------------
module decoder_2_bool(
  input [1:0] in,
  output [3:0] out
  );

  assign out[0] = ~in[0] & ~in[1];
  assign out[1] = in[0] & ~in[1];
  assign out[2] = ~in[0] & in[1];
  assign out[3] = in[0] & in[1];
endmodule
// Testbench
// -----------------------------------------------------------------------------
module decoder_2_tb;
  reg [1:0] in_vec;
  reg [3:0] expected;
  wire [3:0] out_cond;
  wire [3:0] out_bool;

  // loop variables
  integer i;

  // instantiate duts
  decoder_2_cond dut_cond (.in(in_vec), .out(out_cond));
  decoder_2_bool dut_bool (.in(in_vec), .out(out_bool));

  // make golden LUT
  always @(*) begin
    case (in_vec)
      2'b00:   expected = 4'b0001;
      2'b01:   expected = 4'b0010;
      2'b10:   expected = 4'b0100;
      2'b11:   expected = 4'b1000;
      default:  expected = 4'bx;
    endcase
  end

  // begin test
  initial begin
    $dumpfile("dump.vcd");
    $dumpvars;
    in_vec = 2'b00;
    for(i = 0; i < 4; i = i + 1) begin
    	in_vec = i;
      $strobe("in_vec: %b, out_cond: %b, out_bool: %b, expected: %b",
              in_vec, out_cond, out_bool, expected);
      #1;
      // Break early if failed; Using case equivalence to check for x
      if (out_cond !== expected) begin
        $display("CONDITIONAL FAILED, expected %b, got %b", expected, out_cond);
        $finish();
      end
      if (out_bool !== expected) begin
        $display("BOOLEAN FAILED, expected %b, got %b", expected, out_bool);
        $finish();
      end
    end
    $display("ALL TESTS PASSED FOR ALL DESIGNS!");
    $finish();
  end
endmodule

// Problem 4: Serializer
// =============================================================================
// Part a - using generate
// -----------------------------------------------------------------------------
// Don't forget to include the register library!
`include "EECS151.v"

module serializer_generate#(
  parameter N = 1
  )(
  input load,
  input clk,
  input rst,
  input [N-1:0] in,
  output out
  );

  wire [N-1:0] Q;
  wire [N-1:0] NS;
  genvar i;

  // Shift in 0 from the left
  assign NS = load ? in : {1'b0, Q[N-1:1]};
  assign out = Q[0];

  generate
    for (i=N-1; i>= 0; i=i-1) begin:stage
      REGISTER_R shift_r (.d(NS[i]), .q(Q[i]), .rst(rst), .clk(clk));
    end
  endgenerate
endmodule
// Part a - using parametrized register
// -----------------------------------------------------------------------------
// Don't forget to include the register library!
`include "EECS151.v"

module serializer_param#(
  parameter N = 1
  )(
  input load,
  input clk,
  input rst,
  input [N-1:0] in,
  output out
  );

  wire [N-1:0] Q;
  wire [N-1:0] NS;

  // Shift in 0 from the left
  assign NS = load ? in : {1'b0, Q[N-1:1]};
  assign out = Q[0];

  REGISTER_R #(.N(N), .INIT(0)) shift_r (.d(NS), .q(Q), .rst(rst), .clk(clk));
endmodule
// Testbenches
// -----------------------------------------------------------------------------
`timescale 1ns / 1ns

module serializer_tb;
  parameter N = 4;

  reg [N-1:0] in;
  reg load, clk, rst;
  reg [9:0] out_trace_g, out_trace_p;
  wire q_gen, q_param;
  // 10-bit golden vector
  wire [9:0] expected = {6'h0, in};

  integer i = 0;

  // define clock
  initial clk = 0;
  always #(1) clk = ~clk;

  // instantiate designs
  serializer_generate #(.N(N)) dut_gen (.load(load), .clk(clk), .rst(rst), .in(in), .out(q_gen));
  serializer_param #(.N(N)) dut_param (.load(load), .clk(clk), .rst(rst), .in(in), .out(q_param));

  initial begin
    $dumpfile("dump.vcd");
    $dumpvars;
    // Reset registers
    rst = 1'b1;
    #2;
    // Begin test vector
    rst = 1'b0;
    in = 4'b0110;
    load = 1'b1;
    #2;
    load = 1'b0;
    // Run for 10 cycles
    for (i = 0; i < 10; i = i + 1) begin
      out_trace_g[i] = q_gen; out_trace_p[i] = q_param;
      if (expected[i] !== q_gen) begin
        $display("GENERATED SERIALIZER FAILED, expected %b, got %b", expected[i], q_gen);
        $display("gen output trace: %b", out_trace_g);
        $finish();
      end
      if (expected[i] !== q_param) begin
        $display("PARAMETRIZED SERIALIZER FAILED, expected %b, got %b", expected[i], q_param);
        $display("param output trace: %b", out_trace_p);
        $finish();
      end
      #2;
    end
    $display("TEST PASSED FOR ALL DESIGNS!");
    $display("gen output trace: %b", out_trace_g);
    $display("param output trace: %b", out_trace_p);
    $finish();
  end
endmodule

// Problem 5: Serializer
// =============================================================================
// Don't forget to include the register library!
`include "EECS151.v"

module diff_ctrl_counter#(
  parameter N=1
  )(
  input clk,
  input rst,
  input up,
  input down,
  output [N-1:0] val);

  wire [N-1:0] next = up ? val + 1: val - 1;
  wire ce = up | down;

  REGISTER_R_CE #(.N(N), .INIT({N{1'b0}})) counter_reg (.d(next),
                                                        .q(val),
                                                        .rst(rst),
                                                        .ce(ce),
                                                        .clk(clk));
endmodule

// Testbenches
// -----------------------------------------------------------------------------
`timescale 1ns / 1ns

module diff_counter_tb;
  parameter N = 3;

  reg up, down, clk, rst;
  wire [N-1:0] val;
  reg [N-1:0] expected;

  integer i = 0;

  // define clock
  initial clk = 0;
  always #(1) clk = ~clk;

  diff_ctrl_counter #(.N(N)) dut (.clk(clk), .rst(rst), .up(up), .down(down), .val(val));

  // defining reset task since this is used a lot
  task reset;
    begin
    up = 1'b0;
    down = 1'b0;
    expected = 3'b000;
    rst = 1'b1;
    #2;
    rst = 1'b0;
    end
  endtask

  // begin test
  initial begin
    $dumpfile("counter_rb.vcd");
    $dumpvars;
    // reset counter
    reset;
    // count up, pick something arbitrarily >8
    $display("TESTING COUNT UP");
    for(i=0; i<10; i=i+1) begin
      up = 1'b1;
      if (val !== expected) begin
        $display("FAILED COUNT UP NORMAL expected %b, got %b", expected, val);
        $finish();
      end
      expected = expected + 1;
      #2;
    end
    // reset for next test
    reset;
    // count down from maximum, can test wrap immediately
    $display("TESTING COUNT DOWN");
    for(i=0; i<10; i=i+1) begin
      down = 1'b1;
      if (val !== expected) begin
        $display("FAILED COUNT DOWN expected %b, got %b", expected, val);
        $finish();
      end
      expected = expected - 1;
      #2;
    end
    // reset for next test
    reset;
    // count up, both up and down high
    $display("TESTING COUNT UP OVERCTRL");
    for(i=0; i<10; i=i+1) begin
      up = 1'b1;
      down = 1'b1;
      if (val !== expected) begin
        $display("FAILED COUNT UP OVERCTRL expected %b, got %b", expected, val);
        $finish();
      end
      expected = expected + 1;
      #2;
    end
    // reset for next test
    reset;
    // stop count, arbitrarily use same number of cycles
    $display("TESTING COUNT STOP");
    for(i=0; i<10; i=i+1) begin
      if (val !== expected) begin
        $display("FAILED COUNT STOP expected %b, got %b", expected, val);
        $finish();
      end
      expected = expected;
      #2;
    end
    // reset for next test
    reset;
    // count up then down from 4
    $display("TESTING COUNT AROUND");
    // count up to 4
    for(i=0; i<4; i=i+1) begin
      up = 1'b1;
      if (val !== expected) begin
        $display("FAILED COUNT AROUND AT COUNT UP expected %b, got %b", expected, val);
        $finish();
      end
      expected = expected + 1;
      #2;
    end
    // pause for 2 cycles
    for(i=0; i<1; i=i+1) begin
      up = 1'b0;
      down = 1'b0;
      if (val !== expected) begin
        $display("FAILED COUNT AROUND AT COUNT STOP expected %b, got %b", expected, val);
        $finish();
      end
      expected = expected;
      #2;
    end
    // count down to 0
    for(i=0; i<4; i=i+1) begin
      up = 1'b0;
      down = 1'b1;
      if (val !== expected) begin
        $display("FAILED COUNT AROUND AT COUNT DOWN expected %b, got %b", expected, val);
        $finish();
      end
      expected = expected - 1;
      #2;
    end
    $display("ALL TESTS PASSED!");
    $finish();
  end
endmodule
// Problem 6: Accumulator
// =============================================================================
// Don't forget to include the register library!
`include "EECS151.v"

module accumulator#(
  parameter N=1
  )(
  input clk,
  input rst,
  input signed [N-1:0] in,
  output signed [N-1:0] val);

  wire signed [N-1:0] last;
  assign val = last + in;


  REGISTER_R #(.N(N)) acc (.d(val), .q(last), .rst(rst), .clk(clk));
endmodule
// Testbenches
// -----------------------------------------------------------------------------
`timescale 1ns / 10ps

module accumulator_tb;
  parameter N = 4;

  reg clk, rst;
  wire signed [N-1:0] val;
  reg signed [N-1:0] in, expected;

  integer i;
  integer j;

  // define clock
  initial clk = 0;
  always #(1) clk = ~clk;

  accumulator #(.N(N)) dut (.clk(clk), .rst(rst), .in(in), .val(val));

  // defining reset task since this is used a lot
  task reset;
    begin
    in = 4'b0000;
    expected = 4'b0000;
    rst = 1'b1;
    wait(~clk);
    wait(clk);
    wait(~clk);
    rst = 1'b0;
    end
  endtask

  task preload;
  input [N-1:0] preload_val;
  begin
    in = preload_val;
    #2;
  end
  endtask

  initial begin
    $dumpfile("acc.vcd");
    $dumpvars;
    i = 0;
    j = 0;
    // exhaustively test adding
    // loop over all possible stored values of register
    for(i=-8; i<7; i=i+1) begin
      reset;
      preload(i);
      // loop over all possible input values for acc
      for(j=-8; j<7; j=j+1) begin
        in = j;
        expected = i + j;
        #0; // Hack to pause a bit b/c checks on same time step as change fail (on some sims)
        if (val != expected) begin
          $display("ACCUMULATION FAILED expected %b, got %b", expected, val);
          $display("i: %4.b, j: %4.b", i, j);
          $finish();
        end
      end
    end
    $display("ALL TESTS PASSED!");
    $finish();
  end
endmodule
// Problem 7: Accumulator with Saturation
// =============================================================================
// Don't forget to include the register library!
`include "EECS151.v"

module sat_accumulator#(
  parameter N=1,
  parameter signed SAT_HI={1'b0,{(N-1){1'b1}}},
  parameter signed SAT_LO={1'b1,{(N-1){1'b0}}}
  )(
  input clk,
  input rst,
  input signed [N-1:0] in,
  output signed [N-1:0] val);

  reg signed [N-1:0] diff;
  wire signed [N-1:0] last, addend;
  // To properly compare values, need N+1 bit wide result
  wire signed [N:0] int_sum = last + in;
  wire in_range = (int_sum >= $signed(SAT_LO)) && (int_sum <= $signed(SAT_HI));
  assign addend = (in_range) ? last : diff;
  assign val = addend + in;

  // make sure output always within saturation bounds
  always @(*) begin
    if (int_sum < SAT_LO) begin
      diff = SAT_LO - in;
    end else if (int_sum > SAT_HI) begin
      diff = SAT_HI - in;
    end
  end

  REGISTER_R #(.N(N)) acc (.d(val), .q(last), .rst(rst), .clk(clk));
endmodule
// Testbenches
// -----------------------------------------------------------------------------

// Testbenches
// -----------------------------------------------------------------------------
`timescale 1ns / 10ps

module accumulator_tb;
  parameter N = 4;
  parameter signed SAT_HI = 4'b0101;
  parameter signed SAT_LO = 4'b1010;

  reg clk, rst;
  wire signed [N-1:0] val;
  reg signed [N-1:0] in, raw_sum, expected;

  integer i;
  integer j;
  integer true_sum;

  // define clock
  initial clk = 0;
  always #(1) clk = ~clk;

  // Picking SAT_HI = 5 and SAT_LO = -6 arbitrarily
  sat_accumulator #(.N(N), .SAT_HI(SAT_HI), .SAT_LO(SAT_LO)) dut (.clk(clk), .rst(rst), .in(in), .val(val));

  // defining reset task since this is used a lot
  task reset;
    begin
    in = 4'b0000;
    expected = 4'b0000;
    rst = 1'b1;
    wait(~clk);
    wait(clk);
    wait(~clk);
    rst = 1'b0;
    end
  endtask

  // preload first value into accumulator
  task preload;
  input signed [N-1:0] preload_val;
  begin
    in = preload_val;
    #2;
  end
  endtask

  // emulate saturation behavior to check against
  task sat_check;
    input integer i;
    input integer j;
    begin
      expected = i;
      if (i < SAT_LO) expected = SAT_LO;
      if (i > SAT_HI) expected = SAT_HI;
      // Check true sum without bit width truncation
      true_sum = expected + j;
      if (true_sum > SAT_HI) begin
          expected = SAT_HI;
      end else if (true_sum < SAT_LO) begin
          expected = SAT_LO;
      end else begin
        expected = expected + j;
      end
    end
  endtask

  initial begin
    $dumpfile("acc.vcd");
    $dumpvars;
    i = 0;
    j = 0;
    // exhaustively test adding
    // loop over all possible stored values of register
    for(i=-8; i<7; i=i+1) begin
      reset;
      preload(i);
      // loop over all possible input values for acc
      for(j=-8; j<7; j=j+1) begin
        in = j;
        sat_check(i, j);
        #0; // Hack to pause a bit b/c checks on same time step as change fail (on some sims)
        // Check saturation behavior
        if (!(val >= SAT_LO && val <= SAT_HI)) begin
          if (val > SAT_HI) $display("SATURATION FAILED should clip at %b, got %b", SAT_HI, val);
          if (val < SAT_LO) $display("SATURATION FAILED should clip at %b, got %b", SAT_LO, val);
          $finish();
        end
        // Check for correct output value
        if (val !== expected) begin
          $display("ACCUMULATION FAILED expected %b, got %b", expected, val);
          $display("i: %4.b , j: %4.b", i, j);
          #2;
          $finish();
        end
      end
    end
    $display("ALL TESTS PASSED!");
    $finish();
  end
endmodule
