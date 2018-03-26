LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
ENTITY top_level IS
	PORT (
		Clk : IN std_logic; -- 48MHz clock from FX2
		data_out1 : OUT std_logic_vector(7 DOWNTO 0);
		data_out2 : OUT std_logic_vector(7 DOWNTO 0)
	);
END top_level;

ARCHITECTURE behavioural OF top_level IS
	---------------BRAM-------------------------------------------------------------------------------------
	SIGNAL address : INTEGER := 0;
	SIGNAL we : std_logic := '1';
	SIGNAL data_i_x : std_logic_vector(7 DOWNTO 0) := (OTHERS => '0');
	SIGNAL data_i_y : std_logic_vector(7 DOWNTO 0) := (OTHERS => '0');
	SIGNAL data_o_x : std_logic_vector(7 DOWNTO 0) := (3 => '1', OTHERS => '0');
	SIGNAL data_o_y : std_logic_vector(7 DOWNTO 0) := (3 => '1', OTHERS => '0');
	----------------------------------------------------------------------------------------------------
BEGIN
	-- BEGIN_SNIPPET(registers)
	----------------------------------------------------------------------------------------------------
	--Attach BRAM
	----------------------------------------------------------------------------------------------------
	mybram : ENTITY work.ram_example
		PORT MAP(
			Clk => Clk, 
			address => address, 
			we => we, 
			data_i_x => data_i_x, 
			data_i_y => data_i_y, 
			data_o_x => data_o_x, 
			data_o_y => data_o_y
		);
END behavioural;

----------------------------------------------------------------------------------------------------
-- Test BRAM
----------------------------------------------------------------------------------------------------
PROCESS (Clk) BEGIN
IF (rising_edge(Clk)) THEN
	-- On each clock edge, data_i_x is written on data_o_x
	address <= 0;
	data_i_x <= std_logic_vector(to_unsigned(to_integer(unsigned(data_i_x)) + 1, 8));
	data_out1 <= data_o_x;
END IF;
END PROCESS;

----------------------------------------------------------------------------------------------------
--Parallely update at a different location = WORKS.
----------------------------------------------------------------------------------------------------
PROCESS (Clk) BEGIN
IF (rising_edge(Clk)) THEN
	data_i_y <= std_logic_vector(to_unsigned(to_integer(unsigned(data_i_y)) + 1, 8));
	data_out2 <= data_o_y;
END IF;
END PROCESS;