///////////////////////////////////////////
// vlane.sv
//
// Written: eoinoconnell04@gmail.com
// Created: 30 October 2026
// Modified: 30 October 2026
//
// Purpose: vector integer execution unit lane. Currently just the valu adder.
//
// Documentation: RISC-V System on Chip Design Volume 2
//
// A component of the CORE-V-WALLY configurable RISC-V project.
// https://github.com/openhwgroup/cvw
//
// Copyright (C) 2021-26 Harvey Mudd College & Oklahoma State University & Skyworks Solutions Inc.
//
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
//
// Licensed under the Solderpad Hardware License v 2.1 (the “License”); you may not use this file
// except in compliance with the License, or, at your option, the Apache License version 2.0. You
// may obtain a copy of the License at
//
// https://solderpad.org/licenses/SHL-2.1/
//
// Unless required by applicable law or agreed to in writing, any work distributed under the
// License is distributed on an “AS IS” BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
// either express or implied. See the License for the specific language governing permissions
// and limitations under the License.
////////////////////////////////////////////////////////////////////////////////////////////////

module vlane import cvw::*;  #(parameter cvw_t P) (
  input  logic [P.ELEN-1:0] SrcA, SrcB,    // lane operands
  input  logic [5:0] Funct6E,
  input  logic [2:0] Funct3E,
  output logic [P.ELEN-1:0] LaneResult     // lane result
);

  logic [P.ELEN-1:0] SumE, ProductE, ShiftE;
  logic [P.ELEN-1:0] ArithResult; // arithmetic result
  logic mul, move, shift;  // whether the instruction is multiply, move or shift
  logic typeI; // whether the instrution is type I, this is used to differetiate between mul and shift
  logic shiftRight, shiftArith; // for vshifter

  assign typeI = (Funct3E == 3'b000) | (Funct3E == 3'b011) | (Funct3E == 3'b100);
  assign mul = (Funct6E == 6'b100101) & (Funct3E[1:0] == 2'b10);
  assign move = Funct6E == 6'b010111;
  assign shiftRight = (Funct6E[5:1] == 5'b10100);
  assign shift = typeI & (shiftRight | Funct6E == 6'b100101);
  assign shiftArith = Funct6E[0]; // the difference between logical and arithmetic is the LSB of Funct6E

  valu #(P) valu(.A(SrcA), .B(SrcB), .Funct6E(Funct6E), .Funct3E(Funct3E), .Sum(SumE));

  vmul #(P) vmul(.A(SrcA), .B(SrcB), .Product(ProductE));

  vshifter #(P) vshift(.A(SrcA), .B(SrcB), .Y(ShiftE), .dir(shiftRight), .arith(shiftArith));

  always_comb
    if (mul) ArithResult = ProductE;
    else if (shift) ArithResult = ShiftE;
    else ArithResult = SumE;

  //mux2 #(P.ELEN) resultmux(SumE, ProductE, mul, ArithResult);
  //mux2 #(P.ELEN) resultmux2(ArithResult, ShiftE, shift, ArithResult);
  mux2 #(P.ELEN) resultmux3(ArithResult, SrcA, move, LaneResult);

endmodule
