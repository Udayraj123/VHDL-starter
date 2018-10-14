-- This is the main file that demonstrates the use of all entities enlisted in this directory
-- Note: Since our main concern here is not whether to use integers or std_logic_vectors,
--  	 I've used integers at many places to make the code look more intuitive and easy to debug
-- Code formatter used: https://g2384.github.io/VHDLFormatter
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
-- import functions and custom types declared inside utils_package.vhd file
USE work.utils_package.ALL;

ENTITY TOP_LEVEL IS
	PORT (
		---------------------- Onboard peripherals --------------------------------
		-- 7seg digit selector
		DISP_SELECTOR : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
		-- 7seg current digit
		SEVEN_SEG_OUT : OUT STD_LOGIC_VECTOR (7 DOWNTO 0);
		-- The inputs
		INP_SWITCHES : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
		USER_MODE : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
		btn, reset, clk_in : IN STD_LOGIC
		----------------------------------------------------------------------
	);
END TOP_LEVEL;

ARCHITECTURE MAIN OF TOP_LEVEL IS
	-- Clock configuration
	constant clk_50Hz_tick_count : INTEGER := 2000000;
	SIGNAL CLK_50HZ : STD_LOGIC := '0';
	
	-- The Answer to be outputed will be stored in OUT_INT
	SIGNAL OUT_INT : INTEGER := 0;

	----- Clock Divider ----
	COMPONENT clock_div IS
		PORT (
			clk_in : IN STD_LOGIC;
			tick_at_count : IN INTEGER;
			reset : IN STD_LOGIC;
			clk_out : OUT STD_LOGIC
		);
	END COMPONENT;

	----- The sqroot Entity added for stddeviation part ----
	COMPONENT sqroot
		PORT (
			clock : IN std_logic; 
			data_in : IN std_logic_vector(7 DOWNTO 0);
			data_out : OUT std_logic_vector(3 DOWNTO 0);
			reset : IN std_logic
		);
	END COMPONENT;

	COMPONENT seven_segment
		PORT (
			---------------------- Onboard peripherals --------------------------------
			-- The integer to display (max 4 digits)
			OUT_INT : IN INTEGER; -- 
			-- 7seg digit selector
			DISP_SELECTOR : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
			-- 7seg current digit
			SEVEN_SEG_OUT : OUT STD_LOGIC_VECTOR (7 DOWNTO 0);
			clk_in : IN STD_LOGIC
			----------------------------------------------------------------------
		);
	END COMPONENT;

	---- Input/Intermediate variables : Currently assigned dummy values.
	SIGNAL currInp : INTEGER := 0; 
	SIGNAL sum_squares : std_logic_vector (7 DOWNTO 0) := "01000000"; -- 64
	-- You can read currInp from switches as integer by doing: currInp <= to_integer(unsigned(INP_SWITCHES));
	
	-- Temporary display variables
	SIGNAL std_deviation : std_logic_vector (3 DOWNTO 0);


BEGIN
	------------ ALL TOP_LEVEL CALLS HERE ------------
	-- Port mapping the entities:
	divide_clock : clock_div PORT MAP(clk_in, clk_50Hz_tick_count, reset, CLK_50HZ); -- clk_in ==//==> CLK_50HZ
	calc_sqroot : sqroot PORT MAP(CLK_50HZ, sum_squares, std_deviation, reset); -- std_deviation = sqroot(sum_squares)  
	display_handler : seven_segment PORT MAP(OUT_INT, DISP_SELECTOR, SEVEN_SEG_OUT, clk_in); 

mainProcess: PROCESS (btn, reset, CLK_50HZ)
VARIABLE btn_prev : std_logic := '0';
VARIABLE reset_prev : std_logic := '0';
BEGIN
	--
	IF rising_edge(CLK_50HZ) THEN
		IF (reset_prev = '1' AND reset = '0') THEN
			OUT_INT <= 0; 
		ELSE 
			-- currInp <= to_integer(unsigned(INP_SWITCHES)); -- Convert and store switches input
			CASE (USER_MODE) IS
				-- Call your calculation functions here from the package
				WHEN "00" => OUT_INT <= 1; -- OUT_INT <= SUM(N,INPUT_NUMS)
				WHEN "01" => OUT_INT <= 2;
				WHEN "10" => OUT_INT <= 3;
				WHEN OTHERS => 
					-- std_deviation is already calculated by the sqroot entity. 
					-- So just assign it to the displaying variable to get current value
					OUT_INT <= to_integer(unsigned(std_deviation)); --From ENTITY
			END CASE;
	    END IF;
		reset_prev := reset;
		btn_prev := btn;
	END IF;
END PROCESS;

END MAIN; -- architecture