----------------------------------------------------------------------------------
-- Company: NUS
-- Engineer: (c) Rajesh Panicker
-- 
-- Create Date:   21:06:18 24/09/2015
-- Design Name: 	TOP
-- Target Devices: Nexys 4 (Artix 7 100T)
-- Tool versions: Vivado 2015.2
-- Description: Top level module for Synthesis. Not meant to be simulated
--
-- Dependencies: Uses uart.vhd by (c) Peter A Bennett
--
-- Revision: 
-- Revision 0.02
-- Additional Comments: See the notes below. The interface (entity) as well as implementation (architecture) can be modified
----------------------------------------------------------------------------------
--	License terms :
--	You are free to use this code as long as you
--		(i) DO NOT post it on any public repository;
--		(ii) use it only for educational purposes;
--		(iii) accept the responsibility to ensure that your implementation does not violate any intellectual property of ARM Holdings or other entities.
--		(iv) accept that the program is provided "as is" without warranty of any kind or assurance regarding its suitability for any particular purpose;
--		(v) send an email to rajesh.panicker@ieee.org briefly mentioning its use (except when used for the course CG3207 at the National University of Singapore);
--		(vi) retain this notice in this file or any files derived from this.
----------------------------------------------------------------------------------

-->>>>>>>>>>>>>>>>>>>>>>>>>>> ******* FOR SYNTHESIS ONLY. DO NOT SIMULATE THIS ******* <<<<<<<<<<<<<<<<<<<<<<<<<<<

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_unsigned.ALL;
use IEEE.NUMERIC_STD.ALL;
use ieee.math_real.exp;

----------------------------------------------------------------
-- TOP level module interface
----------------------------------------------------------------
entity TOP is
		Generic 
		(
			constant N_LEDs_OUT	: integer := 8; -- Number of LEDs displaying Result. LED(15 downto 15-N_LEDs_OUT+1). 8 by default
			-- LED(15-N_LEDs_OUT) showing the divided clock. 
			-- LED(15-N_LEDs_OUT-1 downto 0) showing the PC.
			constant N_DIPs		: integer := 16;  -- Number of DIPs. 16 by default
			constant N_PBs		: integer := 4  -- Number of PushButtons. 4 by default
			-- Order (3 downto 0) -> BTNU, BTNL, BTNR, BTND.
			-- Note that BTNC is used as PAUSE
		);
		Port 
		(
			DIP 			: in  STD_LOGIC_VECTOR (N_DIPs-1 downto 0);  -- DIP switch inputs. Not debounced.
			PB    			: in  STD_LOGIC_VECTOR (N_PBs-1 downto 0);  -- PB switch inputs. Not debounced.
			LED 			: out  STD_LOGIC_VECTOR (15 downto 0); -- LEDs.
			-- (15 downto 8) mapped to the address 0x00000C00
			-- (7) showing the divided clock
			-- (6 downto 0) showing PC(8 downto 2)
			SevenSegAn		: out  STD_LOGIC_VECTOR (7 downto 0); -- 7 Seg anodes. Common anode
			SevenSegCat		: out  STD_LOGIC_VECTOR (6 downto 0); -- 7 Seg cathodes
			TX 				: out STD_LOGIC;	-- UART Tx
			RX 				: in  STD_LOGIC;	-- UART Rx
			PAUSE			: in  STD_LOGIC;  	-- Pause -> BTNC (Centre push button)
			RESET			: in  STD_LOGIC; 	-- Reset -> CPU_RESET (Red push button). ACTIVE LOW.
			CLK_undiv		: in  STD_LOGIC 	-- 100MHz clock. Converted to a lower frequency using CLK_DIV_PROCESS before being fed to the Wrapper.
		);
end TOP;


architecture arch_TOP of TOP is

----------------------------------------------------------------
-- TOP Constants
----------------------------------------------------------------
constant CLK_DIV_BITS : integer := 5; 	-- Set this to 26 for a ~1Hz clock. 0 for a 100MHz clock. Should not exceed 26. 
										-- There is no need to change it for simulation, as this entity/module should not be simulated
										-- If this is set to less than 17, you might need a software delay loop between successive reads / writes to/from UART.

----------------------------------------------------------------------------
-- Wrapper component
----------------------------------------------------------------------------
component Wrapper is
		Generic 
		(
			constant N_LEDs_OUT	: integer := 8;
			constant N_DIPs		: integer := 16;
			constant N_PBs		: integer := 4
		);
		Port 
		(
			DIP 				: in  STD_LOGIC_VECTOR (N_DIPs-1 downto 0); 
			PB    				: in  STD_LOGIC_VECTOR (N_PBs-1 downto 0);
			LED_OUT				: out  STD_LOGIC_VECTOR (N_LEDs_OUT-1 downto 0);
			LED_PC 				: out  STD_LOGIC_VECTOR (6 downto 0);
			SEVENSEGHEX 		: out STD_LOGIC_VECTOR (31 downto 0);
			CONSOLE_OUT 		: out STD_LOGIC_VECTOR (7 downto 0);
			CONSOLE_OUT_ready	: in STD_LOGIC;
			CONSOLE_OUT_valid 	: out STD_LOGIC;
			CONSOLE_IN 			: in STD_LOGIC_VECTOR (7 downto 0);
			CONSOLE_IN_valid 	: in STD_LOGIC;
			CONSOLE_IN_ack 		: out STD_LOGIC;
			RESET				: in  STD_LOGIC;
			CLK					: in  STD_LOGIC
		);
end component Wrapper;

----------------------------------------------------------------------------
-- Wrapper signals
----------------------------------------------------------------------------  
signal	LED_OUT				: STD_LOGIC_VECTOR (N_LEDs_OUT-1 downto 0);
signal	LED_PC 				: STD_LOGIC_VECTOR (6 downto 0); 		
signal	SEVENSEGHEX 		: STD_LOGIC_VECTOR (31 downto 0); 		
signal	CONSOLE_OUT 		: STD_LOGIC_VECTOR (7 downto 0);
signal  CONSOLE_OUT_ready	: STD_LOGIC := '1';
signal	CONSOLE_OUT_valid 	: STD_LOGIC;
signal	CONSOLE_IN 			: STD_LOGIC_VECTOR (7 downto 0);
signal	CONSOLE_IN_valid 	: STD_LOGIC;
signal	CONSOLE_IN_ack 		: STD_LOGIC;	
signal	CLK					: STD_LOGIC;


----------------------------------------------------------------
-- Memory type declaration (Character map for 7-Seg
----------------------------------------------------------------
type MEM_16x7 is array (0 to 15) of std_logic_vector (6 downto 0);
constant SevenSegHexMap : MEM_16x7 := ("0111111", "0000110", "1011011", "1001111", "1100110", "1101101", "1111101", "0000111", "1111111", "1100111", "1110111", "1111100", "0111001", "1011110", "1111001", "1110001"); 
-- SevenSeg display cathode bits (active low)
--      0
--     ---  
--  5 |   | 1
--     ---   <- 6
--  4 |   | 2
--     ---
--      3
--  Decimal Point = 7

----------------------------------------------------------------------------
-- UART Constants
----------------------------------------------------------------------------
constant BAUD_RATE				: positive 	:= 9600;
constant CLOCK_FREQUENCY		: positive 	:= 100000000;

----------------------------------------------------------------------------
-- UART component
----------------------------------------------------------------------------
component UART is
    generic (
            BAUD_RATE           : positive;
            CLOCK_FREQUENCY     : positive
        );
    port (  -- General
            CLOCK		        : in      std_logic;
            RESET               : in      std_logic;    
            DATA_STREAM_IN      : in      std_logic_vector(7 downto 0);
            DATA_STREAM_IN_STB  : in      std_logic;
            DATA_STREAM_IN_ACK  : out     std_logic;
            DATA_STREAM_OUT     : out     std_logic_vector(7 downto 0);
            DATA_STREAM_OUT_STB : out     std_logic;
            DATA_STREAM_OUT_ACK : in      std_logic;
            TX                  : out     std_logic;
            RX                  : in      std_logic
         );
end component UART;
 
----------------------------------------------------------------------------
-- UART signals
----------------------------------------------------------------------------
signal uart_data_in             : std_logic_vector(7 downto 0);
signal uart_data_out            : std_logic_vector(7 downto 0);
signal uart_data_in_stb         : std_logic;
signal uart_data_in_ack         : std_logic;
signal uart_data_out_stb        : std_logic;
signal uart_data_out_ack        : std_logic;	 

----------------------------------------------------------------------------
-- Other UART signals
-----------------------------------------------------------------------------
-- UART related
type states is (WAITING, CONSOLE);
signal recv_state : states := WAITING;
signal CLK_uart : std_logic;
signal RX_MSF1, RX_MSF2 : std_logic := '1'; -- metastable filter		

-- UART console related
signal CONSOLE_OUT_valid_prev : std_logic := '0';
signal CONSOLE_IN_ack_prev : std_logic := '0';
signal uart_data_out_stb_prev: std_logic := '0'; 

signal RESET_INT, RESET_EFF : STD_LOGIC; 	-- internal and effective reset, for future use.
signal RESET_EXT	: std_logic; 			-- internal reset
----------------------------------------------------------------	
----------------------------------------------------------------
-- <TOP architecture>
----------------------------------------------------------------
----------------------------------------------------------------	
		
begin

----------------------------------------------------------------
-- LEDs
----------------------------------------------------------------			
LED(15-N_LEDs_OUT-1 downto 0) <= LED_PC; 	-- PC on LED(6 downto 0)
LED(15-N_LEDs_OUT) <= CLK; 					-- clock on LED(7)
LED(15 downto N_LEDs_OUT) <= LED_OUT;		-- Written by the processor

----------------------------------------------------------------
-- Debug LEDs
----------------------------------------------------------------	
RESET_EXT <= not RESET; 				-- CPU_RESET is active low. 
RESET_EFF <= RESET_INT or RESET_EXT; 	-- Reset sent to the Wrapper
RESET_INT <= '0'; 						-- internal reset, for future use.	

----------------------------------------------------------------------------
-- Wrapper port map
----------------------------------------------------------------------------			
Wrapper1 : Wrapper
port map (			
		DIP 			 	=> 		DIP 			,
		PB    			 	=>   	PB    			,
		LED_OUT			 	=>   	LED_OUT			,
		LED_PC 			 	=>   	LED_PC 			,
		SEVENSEGHEX 	 	=>   	SEVENSEGHEX 	,
		CONSOLE_OUT 	 	=>   	CONSOLE_OUT 	,
		CONSOLE_OUT_ready	=>		CONSOLE_OUT_ready,
		CONSOLE_OUT_valid  	=>   	CONSOLE_OUT_valid,
		CONSOLE_IN 		 	=>     	CONSOLE_IN 		,
		CONSOLE_IN_valid  	=>    	CONSOLE_IN_valid,
		CONSOLE_IN_ack 	 	=>     	CONSOLE_IN_ack 	,
		RESET			 	=>     	RESET_EFF		,
		CLK				 	=>     	CLK	
);

----------------------------------------------------------------------------
-- UART port map
----------------------------------------------------------------------------
UART1 : UART
generic map (
		BAUD_RATE           => BAUD_RATE,
		CLOCK_FREQUENCY     => CLOCK_FREQUENCY
)
port map (  
		CLOCK		        => CLK_uart,
		RESET               => RESET_EXT,
		DATA_STREAM_IN      => uart_data_in,
		DATA_STREAM_IN_STB  => uart_data_in_stb,
		DATA_STREAM_IN_ACK  => uart_data_in_ack,
		DATA_STREAM_OUT     => uart_data_out,
		DATA_STREAM_OUT_STB => uart_data_out_stb,
		DATA_STREAM_OUT_ACK => uart_data_out_ack,
		TX                  => TX,
		RX                  => RX_MSF2
);
	
----------------------------------------------------------------
-- UART
----------------------------------------------------------------
UART_Process: process (CLK_uart)
begin
if CLK_uart'event and CLK_uart = '1' then

   if RESET_EXT = '1' then
		uart_data_in_stb        <= '0';
		uart_data_out_ack       <= '0';
		uart_data_in            <= (others => '0');
		recv_state			  	<= WAITING;
		uart_data_out_stb_prev 	<= '0';
		RX_MSF1					<= '1';
		RX_MSF2					<= '1';
		CONSOLE_OUT_ready		<= '1';
		CONSOLE_IN_valid 		<= '0';
		CONSOLE_IN				<= (others => '0'); -- not really required, as the valid flag will be 0 on reset. 
   else
   		RX_MSF1					<= RX; -- metastable filter
   		RX_MSF2					<= RX_MSF1; -- metastable filter
		---------------------
		-- Sending
		---------------------
		uart_data_out_ack <= '0';
		if CONSOLE_OUT_valid = '1' and CONSOLE_OUT_valid_prev = '0' then-- CONSOLE_OUT_ready = '1' is checked in the Wrapper, which ensures that the next character is sent only if the previous character has been sent. Hence, there is no need to check it here
			uart_data_in <= CONSOLE_OUT;
			uart_data_in_stb <= '1';
			CONSOLE_OUT_ready 	<= '0';
		end if;
		if uart_data_in_ack = '1' then
			uart_data_in_stb    <= '0';
			CONSOLE_OUT_ready 	<= '1';
		end if;
		---------------------
		-- Receiving
		---------------------
		case recv_state is 
		when WAITING =>
			if uart_data_out_stb = '1' and uart_data_out_stb_prev = '0' then
				uart_data_out_ack   <= '1';
				recv_state <= CONSOLE;	
				CONSOLE_IN <= uart_data_out;
				CONSOLE_IN_valid <= '1';
			end if;
			
		when CONSOLE =>	
			if uart_data_out_stb = '1' and uart_data_out_stb_prev = '0' then -- just read and ignore further characters before the current valid character is read. To prevent this, do not send it from PC at a rate faster than your processor reads it.
				uart_data_out_ack   <= '1';
			end if;
			if CONSOLE_IN_ack = '1' and CONSOLE_IN_ack_prev = '0' then
				recv_state <= WAITING;
				CONSOLE_IN_valid <= '0';
			end if;	
			
		end case; 			
		uart_data_out_stb_prev <= uart_data_out_stb;
		CONSOLE_OUT_valid_prev <= CONSOLE_OUT_valid; -- No successive STRs
		CONSOLE_IN_ack_prev <= CONSOLE_IN_ack;  -- No successive LDRs
	end if;
end if;
end process;				

----------------------------------------------------------------
-- Seven Segment Display
----------------------------------------------------------------
SEVENSEG_DISPLAY_PROCESS : process(CLK_undiv)					-- Counter driving 7-Seg LED display
variable sevenseg_counter : std_logic_vector(18 downto 0) := (others => '0');
variable indices : integer := 0;
begin
	if CLK_undiv'event and CLK_undiv = '1' then
		sevenseg_counter := sevenseg_counter+1;
		indices := 4*conv_integer(sevenseg_counter(18 downto 16));
		SevenSegCat <= not(SevenSegHexMap(conv_integer(SevenSegHex(indices+3 downto indices))));
		SevenSegAN 	<= (others=>'1'); -- ~200Hz refresh
		SevenSegAN(conv_integer(sevenseg_counter(18 downto 16))) <= '0';
	end if;
end process;

----------------------------------------------------------------
-- Clock divider
----------------------------------------------------------------
CLK_uart <= CLK_undiv;	-- CLOCK_FREQUENCY should be set to 100000000 if this line is uncommented. 
CLK_DIVIDER_OFF_SET: if CLK_DIV_BITS = 0 generate 
	CLK <= CLK_undiv;
end generate;
CLK_DIVIDER_ON_SET: if CLK_DIV_BITS > 0 generate
CLK_COUNTER_PROCESS : process(CLK_undiv)						-- Counter for clock division
variable clk_counter : std_logic_vector(CLK_DIV_BITS downto 0) := (others => '0');
begin
	if CLK_undiv'event and CLK_undiv = '1' then
		if PAUSE = '0' then
			clk_counter := clk_counter+1;
			CLK <= clk_counter(CLK_DIV_BITS);
			--CLK_uart <= clk_counter(0); -- CLOCK_FREQUENCY should be set appropriately if this line is uncommented. 
		end if;
	end if;
end process;
end generate;

end arch_TOP;

----------------------------------------------------------------	
----------------------------------------------------------------
-- </TOP architecture>
----------------------------------------------------------------
----------------------------------------------------------------
