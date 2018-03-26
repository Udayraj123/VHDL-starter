library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity single_ram is
port (
 Clk : in std_logic;
       address : in integer;
       we : in std_logic;
       data_i_A : in std_logic_vector(7 downto 0);
       data_o_A : out std_logic_vector(7 downto 0)
    );
end single_ram;

architecture Behavioral of single_ram is

--Declaration of type and signal of a 256 element RAM =  [ -------256 x 8 bit blocks--------  ] 
-- type ram_t is array (0 to 255) of std_logic_vector(7 downto 0);
--Row here : 
type ram_t is array (0 to 15) of std_logic_vector(7 downto 0);
signal ram_A : ram_t := (others => (others => '0'));

begin

--process for read and write operation.
PROCESS(Clk)
BEGIN
   if(rising_edge(Clk)) then
       if(we='1') then
          ram_A(address) <= data_i_A;
       end if;
      data_o_A <= ram_A(address);
   end if;
END PROCESS;

end Behavioral;