`timescale 1ns / 1ps
/*
----------------------------------------------------------------------------------
-- Company: NUS	
-- Engineer: (c) Shahzor Ahmad and Rajesh Panicker
-- 
-- Create Date: 09/23/2015 06:49:10 PM
-- Module Name: Extend
-- Project Name: CG3207 Project
-- Target Devices: Nexys 4 (Artix 7 100T)
-- Tool Versions: Vivado 2015.2
-- Description: Extend Module
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

module Extend(
    input [1:0] ImmSrc,
    input [23:0] InstrImm,
    output reg [31:0] ExtImm
    );
    
    always@(ImmSrc, InstrImm)
        case(ImmSrc)
            2'b00: ExtImm <= {24'b0, InstrImm[7:0]} ;   // DP instructions   
            2'b01: ExtImm <= {20'b0, InstrImm[11:0]} ;  // LDR/STR    
            2'b10: ExtImm <= {{6{InstrImm[23]}}, InstrImm[23:0], 2'b00} ;   // B   
            default: ExtImm <= 32'bx ;  // undefined     
        endcase   
    
endmodule





