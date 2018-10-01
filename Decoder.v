`timescale 1ns / 1ps
/*
----------------------------------------------------------------------------------
-- Company: NUS	
-- Engineer: (c) Shahzor Ahmad and Rajesh Panicker  
-- 
-- Create Date: 09/23/2015 06:49:10 PM
-- Module Name: Decoder
-- Project Name: CG3207 Project
-- Target Devices: Nexys 4 (Artix 7 100T)
-- Tool Versions: Vivado 2015.2
-- Description: Decoder Module
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

module Decoder(
    input [3:0] Rd,
    input [1:0] Op,
    input [5:0] Funct,
    output PCS,
    output reg RegW,
    output reg MemW,
    output reg MemtoReg,
    output reg ALUSrc,
    output reg [1:0] ImmSrc,
    output reg [1:0] RegSrc,
    output reg NoWrite,
    output reg [1:0] ALUControl,
    output reg [1:0] FlagW
    );
    
    reg [1:0] ALUOp ;
    //<extra signals, if any>
    
    assign PCS = (Rd[0] & Rd[1] & Rd[2] & Rd[3]) | (Op[1] & ~Op[0]);
    
    always @ (*) begin
        case(Op)
            2'b00: begin
                case(Funct[5])
                    1'b0: begin
                        MemtoReg = 0;
                        MemW = 0;
                        ALUSrc = 0;
                        ImmSrc = 2'bXX;
                        RegW = 1;
                        RegSrc = 2'b00;
                        ALUOp = 2'b10;
                    end
                    1'b1: begin
                        MemtoReg = 0;
                        MemW = 0;
                        ALUSrc = 1;
                        ImmSrc = 2'b00;
                        RegW = 1;
                        RegSrc = 2'bX0;
                        ALUOp = 2'b10;
                    end
                endcase
            end
            2'b01: begin
                case(Funct[0])
                    1'b0: begin
                        MemtoReg = 1'bX;
                        MemW = 1;
                        ALUSrc = 1;
                        ImmSrc = 2'b01;
                        RegW = 0;
                        RegSrc = 2'b10;
                        ALUOp = 2'b01;                        
                    end
                        
                    1'b1: begin
                        MemtoReg = 1;
                        MemW = 0;
                        ALUSrc = 1;
                        ImmSrc = 2'b01;
                        RegW = 1;
                        RegSrc = 2'bX0;
                        ALUOp = 2'b01;
                    end                
                endcase
            end
            2'b10: begin
                MemtoReg = 0;
                MemW = 0;
                ALUSrc = 1;
                ImmSrc = 2'b10;
                RegW = 0;
                RegSrc = 2'bX1;
                ALUOp = 2'b00;                
            end
            default: begin
                            MemtoReg = 1'bX;
                            MemW = 1'bX;
                            ALUSrc = 1'bX;
                            ImmSrc = 2'bXX;
                            RegW = 1'bX;
                            RegSrc = 2'bXX;
                            ALUOp = 2'bXX;                
                     end        
        endcase
        
        case(ALUOp)
            2'b00: begin
                ALUControl = 2'b00;
                FlagW = 2'b00;
                NoWrite = 0;
            end
            2'b10: begin
                case(Funct[4:0])
                    5'b01000: begin
                                    ALUControl = 2'b00;
                                    FlagW = 2'b00;
                                    NoWrite = 0;
                              end
                    5'b01001: begin
                                    ALUControl = 2'b00;
                                    FlagW = 2'b11;
                                    NoWrite = 0;
                              end
                    5'b00100: begin
                                    ALUControl = 2'b01;
                                    FlagW = 2'b00;
                                    NoWrite = 0;
                              end
                    5'b00101: begin
                                    ALUControl = 2'b01;
                                    FlagW = 2'b11;
                                    NoWrite = 0;
                              end
                    5'b00000: begin
                                    ALUControl = 2'b10;
                                    FlagW = 2'b00;
                                    NoWrite = 0;
                              end
                    5'b00001: begin
                                    ALUControl = 2'b10;
                                    FlagW = 2'b10;
                                    NoWrite = 0;
                              end
                    5'b11000: begin
                                    ALUControl = 2'b11;
                                    FlagW = 2'b00;
                                    NoWrite = 0;
                              end
                    5'b11001: begin
                                    ALUControl = 2'b11;
                                    FlagW = 2'b10;
                                    NoWrite = 0;
                              end
                    5'b10101: begin
                                    ALUControl = 2'b01;
                                    FlagW = 2'b11;
                                    NoWrite = 1;
                              end
                    5'b10111: begin
                                    ALUControl = 2'b00;
                                    FlagW = 2'b11;
                                    NoWrite = 1;
                              end
                    default:  begin
                                    ALUControl = 2'bXX;
                                    FlagW = 2'bXX;
                                    NoWrite = 1'bX;
                              end
                endcase
            end
            2'b01: begin
                case(Funct[3])
                    0: begin
                        ALUControl = 2'b01;
                        FlagW = 2'b00;
                        NoWrite = 0;
                       end
                    1: begin
                        ALUControl = 2'b00;
                        FlagW = 2'b00;
                        NoWrite = 0;
                       end
                endcase
            end
            default:begin
                        ALUControl = 2'bXX;
                        FlagW = 2'bXX;
                        NoWrite = 1'bX;
                    end
        endcase
    end
    
endmodule