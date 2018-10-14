LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.ALL;

ENTITY block_ram IS
   GENERIC (
        -- Here it will obtain the value from it's parent entity
        CONSTANT EN_ADDR_WIDTH : INTEGER;
        CONSTANT EN_DATA_WIDTH : INTEGER 
        );
    PORT (
        EN : IN std_logic;
        CLK : IN std_logic;
        ADDR : IN std_logic_vector(EN_ADDR_WIDTH - 1 DOWNTO 0);
        WE : IN std_logic;
        data_i : IN std_logic_vector(EN_DATA_WIDTH - 1 DOWNTO 0);
        data_o : OUT std_logic_vector(EN_DATA_WIDTH - 1 DOWNTO 0)
    );
END block_ram;

ARCHITECTURE syn OF block_ram IS
    TYPE ram_type IS ARRAY (2 ** EN_ADDR_WIDTH - 1 DOWNTO 0) OF std_logic_vector (EN_DATA_WIDTH - 1 DOWNTO 0);
 
    -- CREATE A BLOCK RAM
    SIGNAL BRAM : ram_type;
BEGIN
    PROCESS (CLK)
    BEGIN
        IF CLK'EVENT AND CLK = '1' THEN
            IF EN = '1' THEN
                IF WE = '1' THEN
                    BRAM(conv_integer(ADDR)) <= data_i;
                END IF;
                data_o <= BRAM(conv_integer(ADDR));
            END IF;
        END IF;
    END PROCESS;

END syn;