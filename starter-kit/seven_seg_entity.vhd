LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
-- import functions and custom types declared inside utils_package.vhd file
USE work.utils_package.ALL;

ENTITY seven_segment IS
	PORT (
		---------------------- Onboard peripherals --------------------------------
		-- The integer to display (max 4 digits)
		OUT_INT : IN INTEGER;
		-- 7seg digit selector
		DISP_SELECTOR : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
		-- 7seg current digit
		SEVEN_SEG_OUT : OUT STD_LOGIC_VECTOR (7 DOWNTO 0);
		clk_in : IN STD_LOGIC
		----------------------------------------------------------------------
	);
END seven_segment;
ARCHITECTURE MAIN OF seven_segment IS

	----- Seven Segment Display Parameters ----
	SIGNAL CLOCK_SLOWER : INTEGER RANGE 0 TO 50000000 := 0;
	CONSTANT SLOW_FACTOR : 	   INTEGER := 50000000;
	CONSTANT SEG_SLOW_FACTOR : INTEGER := 4000;
	SIGNAL SEG_INT_ARRAY : INT_ARRAY(3 DOWNTO 0);
	SIGNAL DISP_DIGITS : BYTE_ARRAY(3 DOWNTO 0);

BEGIN
	------------------ UPDATE SELECTOR IN CYCLIC MANNER -----------------
	PROCESS (clk_in,CLOCK_SLOWER,OUT_INT,DISP_DIGITS,SEG_INT_ARRAY)
	BEGIN
		
		-- Convert the integer OUT_INT into array of digits, and puts it into SEG_INT_ARRAY
		TO_INT_ARRAY(OUT_INT, SEG_INT_ARRAY);
		-- Convert digits in SEG_INT_ARRAY to 7seg representation
		DISP_DIGITS(0) <= INT_TO7SEG_BITS(SEG_INT_ARRAY(0));
		DISP_DIGITS(1) <= INT_TO7SEG_BITS(SEG_INT_ARRAY(1));
		DISP_DIGITS(2) <= INT_TO7SEG_BITS(SEG_INT_ARRAY(2));
		DISP_DIGITS(3) <= INT_TO7SEG_BITS(SEG_INT_ARRAY(3));
		
		--^ One can wrap the above code into another function and call it like this:
		-- printIntOn7Seg(OUT_INT);

		IF (clk_in'EVENT AND clk_in = '1') THEN -- '
			-- Updates selector about 20 times a second
			CLOCK_SLOWER <= (CLOCK_SLOWER + 1) MOD SLOW_FACTOR;
			-- ^ Another alternative for above is using refresh_counter(20 downto 19) Refer: http://www.fpga4student.com/2017/09/vhdl-code-for-seven-segment-display.html

			DISP_SELECTOR <= "1111"; 
			DISP_SELECTOR((CLOCK_SLOWER/SEG_SLOW_FACTOR) MOD 4) <= '0';
		END IF;
		-- LHS and RHS are both STD_LOGIC_VECTOR(7 downto 0) here
		SEVEN_SEG_OUT <= DISP_DIGITS((CLOCK_SLOWER/SEG_SLOW_FACTOR) MOD 4);
	END PROCESS;

END MAIN; -- architecture