`timescale 1ns/1ns
`define CLOCK_PERIOD 10

module bit_serial_receiver_tb();
  reg clk = 0;
  always #(`CLOCK_PERIOD/2) clk = ~clk;

  reg rst;
  reg bits_in;
  reg input_valid;
  wire input_ready;

  wire packet_match;
  wire packet_match_valid;
  wire check_match;
  wire check_match_valid;

  localparam MY_ADDR   = 10;

  localparam AWIDTH    = 32;
  localparam PLD_WIDTH = 512 * 8;
  localparam CHK_WIDTH = 8;
  localparam PKT_WIDTH = AWIDTH * 2 + PLD_WIDTH + CHK_WIDTH;

  localparam CHK_BITS_START = 0;
  localparam CHK_BITS_END   = CHK_BITS_START + CHK_WIDTH - 1;
  localparam PLD_BITS_START = CHK_BITS_END + 1;
  localparam PLD_BITS_END   = PLD_BITS_START + PLD_WIDTH - 1;
  localparam DST_BITS_START = PLD_BITS_END + 1;
  localparam DST_BITS_END   = DST_BITS_START + AWIDTH - 1;
  localparam SRC_BITS_START = DST_BITS_END + 1;
  localparam SRC_BITS_END   = SRC_BITS_START + AWIDTH - 1;

  bit_serial_receiver #(
    .MY_ADDR(MY_ADDR)
  ) DUT (
    .clk(clk),
    .rst(rst),

    .bits_in(bits_in),         // input
    .input_valid(input_valid), // input
    .input_ready(input_ready), // output

    .packet_match(packet_match),             // output
    .packet_match_valid(packet_match_valid), // output
    .check_match(check_match),               // output
    .check_match_valid(check_match_valid)    // output
  );

  wire input_fire = input_valid & input_ready;

  integer i, j;

  localparam NUM_TESTS = 3;

  reg [AWIDTH-1:0]    src_addr [0:NUM_TESTS-1];
  reg [AWIDTH-1:0]    dst_addr [0:NUM_TESTS-1];
  reg [PLD_WIDTH-1:0] payload  [0:NUM_TESTS-1];
  reg [CHK_WIDTH-1:0] checksum [0:NUM_TESTS-1];
  reg [PKT_WIDTH-1:0] pkt;

  task compute_checksum;
    input [AWIDTH-1:0] src_addr;
    input [AWIDTH-1:0] dst_addr;
    input [PLD_WIDTH-1:0] payload;
    output [7:0] checksum;
    reg [7:0] tmp;
    reg [AWIDTH*2+PLD_WIDTH-1:0] all_prev_bits;
    begin
      tmp = 8'd0;
      all_prev_bits = {src_addr, dst_addr, payload};
      #1;
      for (i = 0; i < AWIDTH * 2 + PLD_WIDTH; i = i + 8) begin
        tmp = tmp + ((all_prev_bits >> i) & 8'hFF);
      end

      checksum = ~tmp[7:0];
    end
  endtask

  task serial_interface;
    input [PKT_WIDTH-1:0] pkt;
    begin
      for (i = 0; i < PKT_WIDTH; i = i + 1) begin
        @(negedge clk);
        bits_in = pkt[PKT_WIDTH - 1 - i];
        input_valid = 1'b1;

        wait (input_fire === 1'b1);

        @(negedge clk);
        input_valid = 1'b0;
      end
    end
  endtask

  initial begin
    // Expect packet_match True, check_match True
    src_addr[0] = 8;
    dst_addr[0] = MY_ADDR;
    payload[0]  = 12345678;
    compute_checksum(src_addr[0], dst_addr[0], payload[0], checksum[0]);

    // Expect packet_match False (early termination)
    src_addr[1] = 8;
    dst_addr[1] = MY_ADDR + 1;
    payload[1]  = 12345678;
    compute_checksum(src_addr[1], dst_addr[1], payload[1], checksum[1]);

    // Expect packet_match True, check_match False
    src_addr[2] = 8;
    dst_addr[2] = MY_ADDR;
    payload[2]  = 12345678;
    compute_checksum(src_addr[2], dst_addr[2], payload[2], checksum[2]);
    #1;
    // corrupt payload
    payload[2]  = 12345676;
  end

  wire [AWIDTH-1:0] src_bits         = pkt[SRC_BITS_END:SRC_BITS_START];
  wire [AWIDTH-1:0] dst_bits         = pkt[DST_BITS_END:DST_BITS_START];
  wire [PLD_WIDTH-1:0] payload_bits  = pkt[PLD_BITS_END:PLD_BITS_START];
  wire [CHK_WIDTH-1:0] chksum_bits   = pkt[CHK_BITS_END:CHK_BITS_START];
  reg test_begin;

  initial begin
    $dumpfile("test.vcd");
    $dumpvars;

    rst = 1'b1;
    pkt = 0;
    //bits_in = 1'b0;
    input_valid = 1'b0;
    repeat (10) @(posedge clk);

    @(negedge clk);
    rst = 1'b0;

    for (j = 0; j < NUM_TESTS; j = j + 1) begin
      @(negedge clk);
      test_begin = 1'b1;
      pkt = {src_addr[j], dst_addr[j], payload[j], checksum[j]};

      @(negedge clk);
      test_begin = 1'b0;
      serial_interface(pkt);
    end

    #100;
    $display("Done! All tests passed!");
    $finish();
  end

  initial begin
    // Test 1
    wait (test_begin === 1'b1);
    wait (input_fire === 1'b1);

    wait (packet_match_valid === 1'b1);
    //#1;
    if (packet_match !== 1'b1) begin
      $display("[At %t, Test 1] Failed! packet_match should be HIGH!", $time);
      $finish();
    end

    wait (check_match_valid === 1'b1);
    //#1;
    if (check_match !== 1'b1) begin
      $display("[At %t, Test 1] Failed! check_match should be HIGH!", $time);
      $finish();
    end

    // Test 2
    wait (test_begin === 1'b1);
    wait (input_fire === 1'b1);

    wait (packet_match_valid === 1'b1);
    //#1;
    if (packet_match !== 1'b0) begin
      $display("[At %t, Test 2] Failed! packet_match should be LOW!", $time);
      $finish();
    end

    // Test 3
    wait (test_begin === 1'b1);
    wait (input_fire === 1'b1);

    wait (packet_match_valid === 1'b1);
    //#1;
    if (packet_match !== 1'b1) begin
      $display("[At %t, Test 3] Failed! packet_match should be HIGH!", $time);
      $finish();
    end

    wait (check_match_valid === 1'b1);
    //#1;
    if (check_match !== 1'b0) begin
      $display("[At %t, Test 3] Failed! check_match should be LOW!", $time);
      $finish();
    end
  end

  initial begin
    repeat (3 * NUM_TESTS * PKT_WIDTH) @(posedge clk);
    $display("Timeout!");
    $finish();
  end

endmodule
