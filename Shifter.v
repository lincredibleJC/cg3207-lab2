`timescale 1ns / 1ps
/*
----------------------------------------------------------------------------------
-- Company: NUS	
-- Engineer: (c) Shahzor Ahmad and Rajesh Panicker
-- 
-- Create Date: 09/23/2015 06:49:10 PM
-- Module Name: Shifter
-- Project Name: CG3207 Project
-- Target Devices: Nexys 4 (Artix 7 100T)
-- Tool Versions: Vivado 2015.2
-- Description: Shifter Module
-- 
-- Dependencies: NIL
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------

----------------------------------------------------------------------------------
--	License terms :
--	You are free to use this code as long as you
--		(i) DO NOT post it on any public repository;
--		(ii) use it only for educational purposes;
--		(iii) accept the responsibility to ensure that your implementation does not violate any intellectual property of ARM Holdings or other entities.
--		(iv) accept that the program is provided "as is" without warranty of any kind or assurance regarding its suitability for any particular purpose;
--		(v)	acknowledge that the program was written based on the microarchitecture described in the book Digital Design and Computer Architecture, ARM Edition by Harris and Harris;
--		(vi) send an email to rajesh.panicker@ieee.org briefly mentioning its use (except when used for the course CG3207 at the National University of Singapore);
--		(vii) retain this notice in this file or any files derived from this.
----------------------------------------------------------------------------------
*/

module Shifter(
    input [1:0] Sh,
    input [4:0] Shamt5,
    input [31:0] ShIn,
    output [31:0] ShOut
    );
      
    wire [31:0] ShTemp0 ;
    wire [31:0] ShTemp1 ;
    wire [31:0] ShTemp2 ;
    wire [31:0] ShTemp3 ;
    wire [31:0] ShTemp4 ;
                    
    assign ShTemp0 = ShIn ;
    shiftByNPowerOf2#(0) shiftBy0PowerOf2( Sh, Shamt5[0], ShTemp0, ShTemp1 ) ;
    shiftByNPowerOf2#(1) shiftBy1PowerOf2( Sh, Shamt5[1], ShTemp1, ShTemp2 ) ;
    shiftByNPowerOf2#(2) shiftBy2PowerOf2( Sh, Shamt5[2], ShTemp2, ShTemp3 ) ;
    shiftByNPowerOf2#(3) shiftBy3PowerOf2( Sh, Shamt5[3], ShTemp3, ShTemp4 ) ;
    shiftByNPowerOf2#(4) shiftBy4PowerOf2( Sh, Shamt5[4], ShTemp4, ShOut ) ;

	
endmodule


module shiftByNPowerOf2
//module Shifter
    #(parameter i = 0) // exponent
    (   
        input [1:0] Sh,
        input flagShift,
        input [31:0] ShTempIn,
        output reg [31:0] ShTempOut
    ) ;
    
    always@(Sh, ShTempIn, flagShift) begin
        if(flagShift)
            case(Sh)
                2'b00: ShTempOut <= { ShTempIn[31-2**i:0], {2**i{1'b0}} } ;      // LSL
                2'b01: ShTempOut <= { {2**i{1'b0}}, ShTempIn[31:2**i] } ;        // LSR    
                2'b10: ShTempOut <= { {2**i{ShTempIn[31]}}, ShTempIn[31:2**i] } ;   // ASR   
                2'b11: ShTempOut <= { ShTempIn[2**i-1:0], ShTempIn[31:2**i] } ;  // ROR
            endcase   
        else
            ShTempOut <= ShTempIn ;
    end
    
endmodule 
