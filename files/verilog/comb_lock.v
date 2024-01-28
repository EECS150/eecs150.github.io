/*** DO NOT EDIT FROM HERE ***/
`include "EECS151.v"

module comb_lock_binary(
                        input       CLK, ENTER, RESET,
                        input [1:0] CODE, 
                        output reg  OPEN, ERROR
                        );
   
   localparam START = 3'b000;
   localparam OK1   = 3'b001;
   localparam OK2   = 3'b010;
   localparam BAD1  = 3'b011;
   localparam BAD2  = 3'b100;
   
   localparam CODE1 = 2'b11;
   localparam CODE2 = 2'b10;
/********* TO HERE **********/

// Implement binary-encoded combinational lock here


   
/*** DO NOT EDIT FROM HERE ***/
endmodule

module comb_lock_onehot(
                        input       CLK, ENTER, RESET,
                        input [1:0] CODE, 
                        output      OPEN, ERROR
                        );
/********* TO HERE **********/

// Implement onehot-encoded combinational lock here


   
/*** DO NOT EDIT FROM HERE ***/
endmodule
/********* TO HERE **********/
