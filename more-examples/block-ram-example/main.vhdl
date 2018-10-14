--------------- HOW TO USE -------------------------------------------------------------------------------------
--  Simulate this program and see that it takes a memory cycle for data_i to reflect into data_o
----------------------------------------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
ENTITY top_level IS

GENERIC (
    -- generic can be used for declarations(usually only integers) that can be used inside `port ()` as well as arichitecture of the entity. 
    -- Also, Generics are a means of passing specific information into an entity. They do not have a mode (direction). Ref: http://www.ics.uci.edu/~jmoorkan/vhdlref/generics.html
        -- 1024 data items of 2 bytes each
        CONSTANT ADDR_WIDTH : INTEGER := 10;
        CONSTANT DATA_WIDTH : INTEGER := 16 
        
        -- Minimum requirement examples for BRAM allocation-
        -- 64x26, 128x5, 256x3, 512x2, 1024x1 bits

        -- Note: Somehow 128x5 bits memory(ADDR_WIDTH=7,DATA_WIDTH=5) is allocated 1 BRAM,
        -- But the 64x10 bits memory(ADDR_WIDTH=6,DATA_WIDTH=10) is not! (Can someone point me to an explanation?)
        -- constant ADDR_WIDTH : integer := 7;
        -- constant DATA_WIDTH : integer := 4

        );
PORT (
		Clk : IN std_logic; -- 48MHz clock from FX2
		data_out : OUT std_logic_vector(DATA_WIDTH-1 DOWNTO 0)
		);
END top_level;

ARCHITECTURE behavioural OF top_level IS
	---------------BRAM-------------------------------------------------------------------------------------
	SIGNAL ADDR : std_logic_vector(ADDR_WIDTH - 1 DOWNTO 0);
	SIGNAL we : std_logic := '1';
	SIGNAL EN : std_logic := '1';
	SIGNAL data_i : std_logic_vector(DATA_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
	SIGNAL data_o : std_logic_vector(DATA_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
	----------------------------------------------------------------------------------------------------

	COMPONENT block_ram is
	GENERIC (
		-- Here it will obtain the value from it's parent entity
		CONSTANT EN_ADDR_WIDTH : INTEGER := ADDR_WIDTH;
		CONSTANT EN_DATA_WIDTH : INTEGER := DATA_WIDTH
		);
	PORT (
		EN : IN std_logic;
		CLK : IN std_logic;
		ADDR : IN std_logic_vector(ADDR_WIDTH - 1 DOWNTO 0);
		WE : IN std_logic;
		data_i : IN std_logic_vector(DATA_WIDTH - 1 DOWNTO 0);
		data_o : OUT std_logic_vector(DATA_WIDTH - 1 DOWNTO 0)
		);
	END COMPONENT;

	BEGIN
	-- BEGIN_SNIPPET(registers)
	----------------------------------------------------------------------------------------------------
	--Attach BRAM
	----------------------------------------------------------------------------------------------------
	mybram : block_ram
	PORT MAP(
		EN => EN,
		Clk => Clk, 
		ADDR => ADDR, 
		we => we, 
		data_i => data_i, 
		data_o => data_o
		);

	----------------------------------------------------------------------------------------------------
	-- Test BRAM
	----------------------------------------------------------------------------------------------------
	PROCESS (Clk) BEGIN
	IF (rising_edge(Clk)) THEN
	-- On each clock edge, data_i is written on data_o
	ADDR <= std_logic_vector( to_unsigned(0,ADDR_WIDTH) );
	data_i <= std_logic_vector( to_unsigned( to_integer(unsigned(data_i)) + 1, DATA_WIDTH) );
	data_out <= data_o;
	END IF;
	END PROCESS;


	END behavioural;