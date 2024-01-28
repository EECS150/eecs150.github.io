`include "EECS151.v"

module SHIFT_REG_CE #(
  parameter N=1
  )(
  input clk,
  input ce,
  input bit_in,
  output bit_out,
  );

  wire [N-1:0] Q;
  wire [N-1:0] next_bit;
  genvar i;

  assign next_bit = {Q[N-2:0], bit_in};
  assign bit_out = Q[N-1];

  generate
    for (i=0; i<N; i=i+1) begin:bit
      REGISTER_CE #(.N(1)) shift_r(.d(next_bit[i]), .q(Q[i]), .clk(clk), .ce(ce));
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
    output count_done,
  )

  wire [N-1:0] nxt;
  assign nxt = val + 1;
  assign count_done = (nxt >= THRESHOLD) ? 1 : 0;

  REGISTER_R_CE #(.N(N), .INIT(INIT)) acc_reg (.clk(clk), .rst(rst), .ce(ce), .d(nxt), .q(val));
endmodule
