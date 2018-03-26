library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity rams_01 is
generic(


    -- 1024 data items of 2 bytes each
    constant ADDR_WIDTH : integer := 10;
    constant DATA_WIDTH : integer := 16

    -- Minimum requirement for BRAM allocation-
    -- constant ADDR_WIDTH : integer := 5;
    -- constant DATA_WIDTH : integer := 16

    -- -- 2^16 data items of 1 byte each
    -- constant ADDR_WIDTH : integer := 16;
    -- constant DATA_WIDTH : integer := 8 
);
    port (CLK  : in std_logic;
          WE   : in std_logic;
          EN   : in std_logic;
          ADDR : in std_logic_vector(ADDR_WIDTH-1 downto 0);
          DI   : in std_logic_vector(DATA_WIDTH-1 downto 0);
          DO   : out std_logic_vector(DATA_WIDTH-1 downto 0));
end rams_01;

architecture syn of rams_01 is
    type ram_type is array (2**ADDR_WIDTH-1 downto 0) of std_logic_vector (DATA_WIDTH-1 downto 0);
      -- CREATE A BLOCK RAM
    signal BRAM: ram_type;

begin

    process (CLK)
    begin
        if CLK'event and CLK = '1' then
            if EN = '1' then
                if WE = '1' then
                    BRAM(conv_integer(ADDR)) <= DI;
                end if;
                DO <= BRAM(conv_integer(ADDR)) ;
            end if;
        end if;
    end process;

end syn;

					