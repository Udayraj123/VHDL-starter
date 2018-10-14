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

	----- Comm FPGA entity ----
	COMPONENT comm_fpga_fx2
	-- As usual, The 'Port' part below is same as the one in comm_fpga_fx2.vhdl 
	PORT (
		-- FX2 interface -----------------------------------------------------------------------------
		fx2Clk_in : IN std_logic; -- 48MHz clock from FX2
		fx2FifoSel_out : OUT std_logic; -- select FIFO: '0' for EP6OUT, '1' for EP8IN
		fx2Data_io : INOUT std_logic_vector(7 DOWNTO 0); -- 8-bit data to/from FX2

		-- When EP6OUT selected:
		fx2Read_out : OUT std_logic; -- asserted (active-low) when reading from FX2
		fx2GotData_in : IN std_logic; -- asserted (active-high) when FX2 has data for us

		-- When EP8IN selected:
		fx2Write_out : OUT std_logic; -- asserted (active-low) when writing to FX2
		fx2GotRoom_in : IN std_logic; -- asserted (active-high) when FX2 has room for more data from us
		fx2PktEnd_out : OUT std_logic; -- asserted (active-low) when a host read needs to be committed early

		-- Channel read/write interface --------------------------------------------------------------
		chanAddr_out : OUT std_logic_vector(6 DOWNTO 0); -- the selected channel (0-127)

		-- THE PORTS WE ACTUALLY CARE ABOUT ----------------------------------------------------------
		-- Host >> FPGA pipe:
		h2fData_out : OUT std_logic_vector(7 DOWNTO 0); -- data lines used when the host writes to a channel
		h2fValid_out : OUT std_logic; -- '1' means "on the next clock rising edge, please accept the data on h2fData_out"
		h2fReady_in : IN std_logic; -- channel logic can drive this low to say "I'm not ready for more data yet"

		-- Host << FPGA pipe:
		f2hData_in : IN std_logic_vector(7 DOWNTO 0); -- data lines used when the host reads from a channel
		f2hValid_in : IN std_logic; -- channel logic can drive this low to say "I don't have data ready for you"
		f2hReady_out : OUT std_logic -- '1' means "on the next clock rising edge, put your next byte of data on f2hData_in"
	);
	END COMPONENT;


	---- Input/Intermediate variables : Currently assigned dummy values.
	SIGNAL currInp : INTEGER := 0; 


BEGIN
	------------ ALL TOP_LEVEL CALLS HERE ------------
	-- Port mapping the entities:
	divide_clock : clock_div PORT MAP(clk_in, clk_50Hz_tick_count, reset, CLK_50HZ); -- clk_in ==//==> CLK_50HZ
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
				WHEN "00" => OUT_INT <= 1;
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