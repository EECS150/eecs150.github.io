//`include "EECS151.v"

module SHIFT_REG_CE #(
  parameter N=1
  )(
  input clk,
  input ce,
  input bit_in,
  output bit_out,
  output [N-1:0] Q
  );

  //wire [N-1:0] Q;
  wire [N-1:0] next_bit;
  genvar i;

  assign next_bit = {Q[N-2:0], bit_in};
  assign bit_out = Q[N-1];

  generate
    for (i=0; i<N; i=i+1) begin:_bit
      REGISTER_CE #(.N(1)) shift_r (.d(next_bit[i]), .q(Q[i]), .clk(clk), .ce(ce));
    end
  endgenerate
endmodule

module COUNTER_R_CE #(
  parameter N=1,
  parameter INIT={N{1'b0}},
  parameter THRESHOLD={N{1'b1}}
  )(
    input clk,
    input rst,
    input ce,
    output [N-1:0] val,
    output count_done
);

  wire [N-1:0] nxt;
  assign nxt = val + 1;
  assign count_done = (nxt >= THRESHOLD) ? 1 : 0;

  REGISTER_R_CE #(.N(N), .INIT(INIT)) acc_reg (.clk(clk), .rst(rst), .ce(ce), .d(nxt), .q(val));
endmodule

// Testbenches
// ============================================================================
module counter_r_tb;

  parameter N=5;
  parameter THRESH=10;

  reg clk, ce, rst;
  wire [N-1:0] val;
  wire count_done;
  integer i;

  COUNTER_R_CE #(.N(N), .THRESHOLD(THRESH)) dut (.clk(clk), .ce(ce), .rst(rst), .val(val), .count_done(count_done));

  always #(1) clk = ~clk;

  initial clk = 0;

  initial begin
    $dumpfile("sds.vcd");
    $dumpvars;
   	// reset counter
    @(negedge clk) rst = 1'b0;
    @(negedge clk) ce = 1'b1;
    #10;
    // test CE
    @(negedge clk) ce = 1'b0;
    #10;
    if (val > 0) begin
      $display("CE FAILED");
      $finish();
    end
    // test count and threshold
    @(negedge clk) ce = 1'b1;
    for(i=0; i<32; i=i+1) begin
      if (val != i) begin
        $display("COUNT FAILED, expected %2.d, got %2.d", i, val);
        $finish();
      end
      if (i > THRESH && ~count_done) begin
        $display("THRESHOLD FAILED, reached count %2.d and no flag", i);
        $finish();
      end
    end
    $display("ALL TESTS PASSED");
    $finish();
  end
endmodule

module shift_r_tb;

  parameter N=256;

  reg clk, ce, bit_in;
  reg [N-1:0] test_vec;
  wire bit_out;
  integer i;

  wire [2*N:0] golden = {{test_vec},{N{1'b0}}};

  SHIFT_REG_CE #(.N(N)) dut (.clk(clk), .ce(ce), .bit_in(bit_in), .bit_out(bit_out));

  always #(1) clk = ~clk;

  initial clk = 0;

  initial begin
    $dumpfile("sds.vcd");
    $dumpvars;
    #1;
    // clear shift reg
    @(negedge clk) bit_in = 1'b0;
    @(negedge clk) ce = 1'b1;
    #1000;
    // load test vec
    test_vec = 256'hdeadbeef;
    ce = 1'b1;
    // test shifting
    for(i=0; i<2*N; i=i+1) begin
      @(negedge clk) bit_in = test_vec[i];
      if(golden[i] !== bit_out) begin
        $display("%dns FAILED at cycle %2.d, expected %b, got %b", $time, i, golden[i], bit_out);
        #2;
        $finish();
      end
      #2;
    end
    $display("SHIFTING PASSED");
    // test clock enable
    // clear shift reg
    @(negedge clk) bit_in = 1'b0;
    #1000;
    @(negedge clk) bit_in = 1'b1;
    @(negedge clk) ce = 1'b0;
    if(bit_out == 1'b1) begin
      $display("%d CE FAILED", $time);
      $finish();
    end
    $display("ALL TESTS PASSED");
    $finish();
  end
endmodule
