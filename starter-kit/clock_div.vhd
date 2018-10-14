-- These need to be imported every time before declaring an entity
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY clock_div IS
    PORT (
        clk_in : IN STD_LOGIC;
        tick_at_count : IN INTEGER;
        reset : IN STD_LOGIC;
        clk_out : OUT STD_LOGIC
    );
END clock_div;

ARCHITECTURE Behavioral OF clock_div IS
    SIGNAL slow_clock : STD_LOGIC;
    SIGNAL counter : INTEGER RANGE 0 TO 500000000 := 0;
BEGIN
    -- update slow_clock
    frequency_divider : PROCESS (reset, clk_in) BEGIN
        IF (reset = '1') THEN
            slow_clock <= '0';
            counter <= 0;
        ELSE
            IF rising_edge(clk_in) THEN
                IF (counter = tick_at_count) THEN
                    slow_clock <= NOT(slow_clock);
                    counter <= 0;
                ELSE
                    counter <= counter + 1;
                END IF;
            END IF; 
        END IF;
    END PROCESS;
 
    -- constantly copy updated value(slow_clock) into clk_out
    outputClk : PROCESS (slow_clock) BEGIN
        clk_out <= slow_clock;
    END PROCESS;
END Behavioral;