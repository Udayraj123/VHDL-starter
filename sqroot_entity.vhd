--------------- SQROOT ENTITIY ------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
-- use IEEE.STD_LOGIC_unsigned.ALL;
-- use IEEE.STD_LOGIC_arith.ALL;

ENTITY sqroot IS
	PORT (
		clock : IN std_logic; 
		data_in : IN std_logic_vector(7 DOWNTO 0);
		data_out : OUT std_logic_vector(3 DOWNTO 0);
		reset : IN std_logic
	);
END sqroot;

ARCHITECTURE behaviour OF sqroot IS
	SIGNAL sq_done : std_logic := '0';
	SIGNAL sq_counter : INTEGER := 0;

BEGIN
	-- architecture

	PROCESS (clock, data_in, sq_done)--, CLK_50kHZ, reset)
	VARIABLE reset_prev : std_logic := '0';
	BEGIN
		-- division comparision is used to floor down sqroot of data_in < 1.
		IF rising_edge(clock) THEN
 
			IF (reset_prev = '1' AND reset = '0') THEN
				sq_done <= '0';
				sq_counter <= 0;
				data_out <= std_logic_vector(to_unsigned(0, 4));
			ELSE
				IF (sq_done = '0') THEN
					IF (sq_counter * sq_counter > to_integer(unsigned(data_in)))
					 THEN
					 sq_done <= '1';
					 data_out <= std_logic_vector(to_unsigned(sq_counter - 1, 4));
					 ELSE
						 sq_counter <= sq_counter + 1;
					 END IF;
				 END IF;
			 END IF;

			 reset_prev := reset;
		 END IF;

	 END PROCESS; 
 END behaviour;