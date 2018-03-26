LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE ieee.numeric_std.ALL; --contains to_integer
------------------------------------------------------------------
-- row_module will take care of storing itself, multiplying itself with B, and waiting for other rows to store/calculate.
------------------------------------------------------------------
ENTITY row_module IS
  PORT (
    Clk : IN std_logic;
    startB : IN std_logic;
    resetModule : IN std_logic;
    A_elem : IN std_logic_vector(7 DOWNTO 0);
    B_elem : IN std_logic_vector(7 DOWNTO 0);
    data_o_C : OUT std_logic_vector(7 DOWNTO 0)
  );
END row_module;

ARCHITECTURE Behavioral OF row_module IS
  SIGNAL i : INTEGER := 0;
  SIGNAL j : INTEGER := 0;
  SIGNAL col : INTEGER := 0;
  SIGNAL col_prev : INTEGER := 0;

  SIGNAL data_i_C : std_logic_vector(7 DOWNTO 0) := (OTHERS => '0');
  SIGNAL A_j : std_logic_vector(7 DOWNTO 0) := (OTHERS => '0');
  SIGNAL we : std_logic := '1';
  SIGNAL weC : std_logic := '1';

  SIGNAL S : INTEGER := 0;

  TYPE state_type IS (Reset, firstStore, StoreAt_j, StoreAt_j_2, WaitCalc, WaitCalc_2, initCalc, CalcAt_i, CalcAt_i_2, changeCol, Halt, Finish);
  SIGNAL state, next_state : state_type;
  --- archi begin
BEGIN
  OUTPUT_DECODE : PROCESS (state)
  BEGIN
    CASE (state) IS
      WHEN Reset => 
        we <= '1';
        j <= 0;
      WHEN firstStore => 
        j <= 0; --do not increment, but store
      WHEN StoreAt_j | StoreAt_j_2 => 
        j <= j + 1;

      WHEN WaitCalc | WaitCalc_2 => 
        i <= 0;
        j <= 0;
        col <= 0;
        weC <= '1';
        we <= '0';

      WHEN initCalc => 
        --calc here also if j is starting from 1. -- YUP
        --in init, do not increment, but only calc
        S <= S + to_integer(unsigned(B_elem)) * to_integer(unsigned(A_j));
        --Check : This should be visible in the simulation

      WHEN CalcAt_i | CalcAt_i_2 => 
        -- i is the counter for B_elem
        S <= (S + to_integer(unsigned(B_elem)) * to_integer(unsigned(A_j)));

        IF (j < 15) THEN
          j <= j + 1;
        END IF;
        i <= i + 1;

      WHEN changeCol => 
        IF (j = 15) THEN
          data_i_C <= std_logic_vector(to_unsigned(S, 8));
          S <= 0;
          j <= 0;
          col_prev <= col; -- or col - 1
          col <= col + 1;
        END IF;

      WHEN Halt => 
        IF (j = 15) THEN
          data_i_C <= std_logic_vector(to_unsigned(S, 8));
          S <= 0;
          j <= 0;
          col_prev <= col; -- or col - 1
          col <= col + 1;
        END IF;
        -- weC<='0'; -- Will stop writing from last one also !
        we <= '0';
      WHEN Finish => 
        weC <= '0';

      WHEN OTHERS => 
        we <= '0';
    END CASE; 

  END PROCESS;

  NEXT_STATE_DECODE : PROCESS (state, startB) --This reduced the cycle delay by 1 !
  BEGIN
    next_state <= state; --default is to stay in current state
    CASE (state) IS
      WHEN Reset => 
        next_state <= firstStore;

      WHEN firstStore => 
        next_state <= StoreAt_j;

      WHEN StoreAt_j => 
        --Here j is till 14 only coz its incremented in the same state.
        --j=0 is done by init store
        IF (j = 14) THEN
          next_state <= WaitCalc;
        ELSE
          next_state <= StoreAt_j_2;
        END IF;
      WHEN StoreAt_j_2 => 
        IF (j = 14) THEN
          next_state <= WaitCalc;
        ELSE
          next_state <= StoreAt_j;
        END IF;

      WHEN WaitCalc => 
        IF (startB = '1') THEN
          next_state <= initCalc;
        ELSE
          next_state <= WaitCalc_2;
        END IF;
      WHEN WaitCalc_2 => 
        IF (startB = '1') THEN
          next_state <= initCalc;
        ELSE
          next_state <= WaitCalc;
        END IF;

      WHEN initCalc => 
        next_state <= CalcAt_i;

      WHEN changeCol => 
        next_state <= CalcAt_i;

      WHEN CalcAt_i => 
        IF (i = 255) THEN
          next_state <= Halt;
        ELSE
          IF (j MOD 16 = 15) THEN
            next_state <= changeCol;
          ELSE
            next_state <= CalcAt_i_2;
          END IF;
        END IF;

      WHEN CalcAt_i_2 => 
        IF (i = 255) THEN
          next_state <= Halt;
        ELSE
          IF (j MOD 16 = 15) THEN
            next_state <= changeCol;
          ELSE
            next_state <= CalcAt_i;
          END IF;
        END IF;
 
      WHEN Halt => 
        next_state <= Finish;

      WHEN OTHERS => 
        next_state <= state; --Stay in the same state & wait for debug
    END CASE; 

  END PROCESS;
  ----------------------------------------------------------------------------------
  A_row : ENTITY work.single_ram
    PORT MAP(
      Clk => Clk, 
      we => we, 
      address => j, 
      data_i_A => A_elem, 
      data_o_A => A_j
    );
      C_row : ENTITY work.single_ram
        PORT MAP(
          Clk => Clk, 
          we => weC, 
          address => col_prev, 
          data_i_A => data_i_C, 
          data_o_A => data_o_C
        );

          ----------------------------------------------------------------------------------------------------
          SYNC_PROC : PROCESS (Clk)
          BEGIN
            IF (rising_edge(Clk)) THEN
              IF (resetModule = '1') THEN
                state <= Reset;
              ELSE
                state <= next_state;
              END IF;
            END IF;
          END PROCESS;

          ----------------------------------------------------------------------------------------------------
END Behavioral;