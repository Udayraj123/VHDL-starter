-- These need to be imported every time before declaring an entity
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity clock_div is
    Port (
        clk_in : in  STD_LOGIC;
        tick_at_count : in INTEGER;
        reset  : in  STD_LOGIC;
        clk_out: out STD_LOGIC
    );
end clock_div;

architecture Behavioral of clock_div is
    signal slow_clock: STD_LOGIC;
    signal counter : integer range 0 to 500000000 := 0;
begin
    
    -- update slow_clock
    frequency_divider: process (reset, clk_in) begin
        if (reset = '1') then
            slow_clock <= '0';
            counter <= 0;
        else 
            if rising_edge(clk_in) then
                if (counter = tick_at_count) then
                    slow_clock <= NOT(slow_clock);
                    counter <= 0;
                else
                    counter <= counter + 1;
                end if;
            end if;				
        end if;
    end process;
    
    -- constantly copy updated value(slow_clock) into clk_out
    outputClk: process (slow_clock) begin
    	clk_out <= slow_clock;
    end process;
end Behavioral;
