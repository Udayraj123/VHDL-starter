library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity top_level is
port(
Clk     : in    std_logic;                    -- 48MHz clock from FX2
data_out1 : out std_logic_vector(7 downto 0);
data_out2 : out std_logic_vector(7 downto 0)
);
end top_level;

architecture behavioural of top_level is
---------------BRAM-------------------------------------------------------------------------------------
signal address :  integer:=0;
signal we :  std_logic:='1';
signal data_i_x : std_logic_vector(7 downto 0):=(others=>'0');
signal data_i_y : std_logic_vector(7 downto 0):=(others=>'0');
signal data_o_x : std_logic_vector(7 downto 0):=(3=>'1',others=>'0');
signal data_o_y : std_logic_vector(7 downto 0):=(3=>'1',others=>'0');
----------------------------------------------------------------------------------------------------
begin													-- BEGIN_SNIPPET(registers)


----------------------------------------------------------------------------------------------------
--Attach BRAM
----------------------------------------------------------------------------------------------------
mybram : entity work.ram_example port map(
	Clk => Clk ,
	address => address ,
	we => we ,
	data_i_x => data_i_x ,
	data_i_y => data_i_y ,
	data_o_x => data_o_x ,
	data_o_y => data_o_y 
);
end behavioural;

----------------------------------------------------------------------------------------------------
-- Test BRAM
----------------------------------------------------------------------------------------------------
process(Clk) begin
if ( rising_edge(Clk) ) then
-- On each clock edge, data_i_x is written on data_o_x
	address <= 0;
	data_i_x <= std_logic_vector(to_unsigned(to_integer(unsigned( data_i_x )) + 1, 8));
	data_out1 <=data_o_x;
end if;
end process;

----------------------------------------------------------------------------------------------------
--Parallely update at a different location = WORKS.
----------------------------------------------------------------------------------------------------
process(Clk) begin
if ( rising_edge(Clk) ) then
	data_i_y <= std_logic_vector(to_unsigned(to_integer(unsigned( data_i_y )) + 1, 8));
	data_out2 <=data_o_y;
end if;
end process;
