LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

ENTITY single_ram IS
  PORT (
    Clk : IN std_logic;
    address : IN INTEGER;
    we : IN std_logic;
    data_i_A : IN std_logic_vector(7 DOWNTO 0);
    data_o_A : OUT std_logic_vector(7 DOWNTO 0)
  );
END single_ram;

ARCHITECTURE Behavioral OF single_ram IS

  --Declaration of type and signal of a 256 element RAM = [ -------256 x 8 bit blocks-------- ]
  -- type ram_t is array (0 to 255) of std_logic_vector(7 downto 0);
  --Row here :
  TYPE ram_t IS ARRAY (0 TO 15) OF std_logic_vector(7 DOWNTO 0);
  SIGNAL ram_A : ram_t := (OTHERS => (OTHERS => '0'));

BEGIN
  --process for read and write operation.
  PROCESS (Clk)
  BEGIN
    IF (rising_edge(Clk)) THEN
      IF (we = '1') THEN
        ram_A(address) <= data_i_A;
      END IF;
      data_o_A <= ram_A(address);
    END IF;
  END PROCESS;

END Behavioral;