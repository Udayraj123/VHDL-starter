--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   20:49:39 03/27/2018
-- Design Name:   
-- Module Name:   /home/udayraj/Desktop/DFA_test/test_DFA.vhd
-- Project Name:  DFA_test
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: simple_dfa
-- 
-- Dependencies:
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
-- Notes: 
-- This testbench has been automatically generated using types std_logic and
-- std_logic_vector for the ports of the unit under test.  Xilinx recommends
-- that these types always be used for the top-level I/O of a design in order
-- to guarantee that the testbench will bind correctly to the post-implementation 
-- simulation model.
--------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
 
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--USE ieee.numeric_std.ALL;
 
ENTITY test_DFA IS
END test_DFA;
 
ARCHITECTURE behavior OF test_DFA IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT simple_dfa
    PORT(
         reset_in : IN  std_logic;
         end_marker : IN  std_logic;
         clk_in : IN  std_logic;
         current_bit_in : IN  std_logic;
         accepted : OUT  std_logic
        );
    END COMPONENT;
    

   --Inputs
   signal reset_in : std_logic := '0';
   signal end_marker : std_logic := '0';
   signal clk_in : std_logic := '1';
   signal current_bit_in : std_logic := '0';

 	--Outputs
   signal accepted : std_logic;

   -- Clock period definitions
   constant clk_in_period : time := 10 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: simple_dfa PORT MAP (
          reset_in => reset_in,
          end_marker => end_marker,
          clk_in => clk_in,
          current_bit_in => current_bit_in,
          accepted => accepted
        );

   -- Clock process : merged with stimulus process
   -- Stimulus process : Loops infinitely
   stim_proc: process
    variable mode_temp, i,t : integer;
	 constant num_clock_ticks : integer := 100; --some large number
	 -- Assign your input here	 	 
	 constant input_length : integer := 10;
	 constant input_bits : std_logic_vector(input_length-1 downto 0) := "1010101010";
    begin      
		-- hold reset state for a few clock periods.
		end_marker <= '0';		
		current_bit_in <= input_bits(input_length-1); --first bit to send 
		Reset_in <= '1'; 
		clk_in <= not clk_in ; -- First clock tick to trigger	state 
		wait for clk_in_period;
		Reset_in <= '0'; -- now the DFA is triggered and gone to Start state.		
		i := input_length-1; -- Start from MSB of input
-- stimulate for num_clock_ticks in one run
	for t in 0 to num_clock_ticks loop
		IF ( i < 0) then
			 end_marker <= '1';
		else
			current_bit_in <= input_bits(i);			 
		end if;
		i := i - 1;
		-- One time period
		clk_in <= not clk_in ;
		wait for clk_in_period/2;
		clk_in <= not clk_in ;		
		wait for clk_in_period/2;
		end loop;
   end process;

END;
