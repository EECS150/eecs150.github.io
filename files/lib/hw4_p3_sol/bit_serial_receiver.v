
// Problem 3
module bit_serial_receiver #(
  parameter MY_ADDR = 10
) (
  input clk,
  input rst,

  input  bits_in,
  input  input_valid,
  output input_ready,

  output packet_match,
  output packet_match_valid,
  output check_match,
  output check_match_valid
);

  localparam PLD_WIDTH = 512 * 8;
  localparam AWIDTH    = 4 * 8;
  localparam CHK_WIDTH = 8;

  localparam PKT_WIDTH = AWIDTH * 2 + CHK_WIDTH + PLD_WIDTH;

  localparam CHK_BITS_START = 0;
  localparam CHK_BITS_END   = CHK_BITS_START + CHK_WIDTH - 1;
  localparam PLD_BITS_START = CHK_BITS_END + 1;
  localparam PLD_BITS_END   = PLD_BITS_START + PLD_WIDTH - 1;
  localparam DST_BITS_START = PLD_BITS_END + 1;
  localparam DST_BITS_END   = DST_BITS_START + AWIDTH - 1;
  localparam SRC_BITS_START = DST_BITS_END + 1;
  localparam SRC_BITS_END   = SRC_BITS_START + AWIDTH - 1;

  wire [PKT_WIDTH-1:0] pkt_value;

  wire [AWIDTH-1:0] my_addr;
  REGISTER #(.N(AWIDTH)) my_addr_reg (
    .clk(clk),
    .d(MY_ADDR),
    .q(my_addr)
  );

  wire [31:0] cnt_next, cnt_value;
  wire cnt_ce, cnt_rst;
  REGISTER_R_CE #(.N(32), .INIT(0)) cnt_reg (
    .clk(clk),
    .rst(cnt_rst),
    .ce(cnt_ce),
    .d(cnt_next),
    .q(cnt_value)
  );

  wire [7:0] sum_next, sum_value;
  wire sum_ce, sum_rst;
  REGISTER_R_CE #(.N(8), .INIT(0)) sum_reg (
    .clk(clk),
    .rst(sum_rst),
    .ce(sum_ce),
    .d(sum_next),
    .q(sum_value)
  );

  wire [PKT_WIDTH-1:0] sr_out;
  wire sr_ce;
  SHIFT_REG_CE #(.N(PKT_WIDTH)) shift_reg (
    .clk(clk),
    .ce(sr_ce),
    .bit_in(bits_in),
    .bit_out(),
    .Q(sr_out)
  );

  localparam STATE_IDLE          = 2'b00;
  localparam STATE_RECEIVE       = 2'b01;
  localparam STATE_VERIFY_DST    = 2'b10;
  localparam STATE_VERIFY_CHKSUM = 2'b11;

  reg [1:0]  state_next;
  wire [1:0] state_value;

  REGISTER_R #(.N(2), .INIT(STATE_IDLE)) state_reg (
    .clk(clk),
    .rst(rst),
    .d(state_next),
    .q(state_value)
  );

  assign input_ready = (state_value != STATE_VERIFY_CHKSUM);
  wire input_fire = input_valid & input_ready;

  always @(*) begin
    state_next = state_value;
    case (state_value)
      STATE_IDLE: begin
        if (input_fire && cnt_value == 0)
          state_next = STATE_RECEIVE;
      end

      STATE_RECEIVE: begin
        if (input_fire && cnt_value == PKT_WIDTH - 1 - DST_BITS_START)
          state_next = STATE_VERIFY_DST;
        else if (input_fire && cnt_value == PKT_WIDTH - 1)
          state_next = STATE_VERIFY_CHKSUM;
      end

      STATE_VERIFY_DST: begin
        if (~packet_match)
          state_next = STATE_IDLE;
        else
          state_next = STATE_RECEIVE;
      end

      STATE_VERIFY_CHKSUM: begin
        state_next = STATE_IDLE;
      end
    endcase
  end

  assign sr_ce = input_fire;

  assign cnt_next = cnt_value + 1;
  assign cnt_ce   = input_fire;
  assign cnt_rst  = (input_fire && cnt_value == PKT_WIDTH - 1) | rst;

  assign sum_next = sum_value + {sr_out[6:0], bits_in};
  assign sum_ce   = (cnt_value[2:0] == 3'b111) && input_fire;
  assign sum_rst  = (state_value == STATE_IDLE) | rst;

  assign packet_match       = (sr_out[AWIDTH-1:0] == my_addr);
  assign packet_match_valid = (state_value == STATE_VERIFY_DST);

  assign check_match        = (sum_value[7:0] == 8'hFF);
  assign check_match_valid  = (state_value == STATE_VERIFY_CHKSUM);

endmodule
