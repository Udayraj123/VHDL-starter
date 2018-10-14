-------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
----------------------------------------------------------------------------------------------------
-- Matrix multiplication in parallel
-- Two set of states used for this assignment.
-- These handle the sending data to board : (Reset,initSendA,sendA,sendA_2,initSendB,sendB,sendB_2,changeCol,readC,Halt,NextHalt)
-- These handle the calculation part (defined in rowmodule) : (Reset,firstStore,StoreAt_j,StoreAt_j_2, WaitCalc,WaitCalc_2,initCalc,CalcAt_i,CalcAt_i_2,changeCol,Halt,Finish);
----------------------------------------------------------------------------------------------------

ENTITY top_level IS
  PORT (
    ResetMatrix : IN std_logic; 
    clk_in : IN std_logic; -- 08MHz clock from FX2
    data_out0 : OUT std_logic_vector(7 DOWNTO 0);
    data_out1 : OUT std_logic_vector(7 DOWNTO 0);
    data_out2 : OUT std_logic_vector(7 DOWNTO 0);
    data_out3 : OUT std_logic_vector(7 DOWNTO 0);
    data_out4 : OUT std_logic_vector(7 DOWNTO 0);
    data_out5 : OUT std_logic_vector(7 DOWNTO 0);
    data_out6 : OUT std_logic_vector(7 DOWNTO 0);
    data_out7 : OUT std_logic_vector(7 DOWNTO 0);
    data_out8 : OUT std_logic_vector(7 DOWNTO 0);
    data_out9 : OUT std_logic_vector(7 DOWNTO 0);
    data_out10 : OUT std_logic_vector(7 DOWNTO 0);
    data_out11 : OUT std_logic_vector(7 DOWNTO 0);
    data_out12 : OUT std_logic_vector(7 DOWNTO 0);
    data_out13 : OUT std_logic_vector(7 DOWNTO 0);
    data_out14 : OUT std_logic_vector(7 DOWNTO 0);
    data_out15 : OUT std_logic_vector(7 DOWNTO 0)
  );
END top_level;

ARCHITECTURE behavioural OF top_level IS
  ----------------------------------------------------------------------------------------------------

  TYPE state_type IS (Reset, initSendA, sendA, sendA_2, initSendB, sendB, sendB_2, changeCol, readC, Halt, NextHalt);
  SIGNAL state, next_state : state_type;

  TYPE row IS ARRAY(0 TO 15) OF std_logic_vector(7 DOWNTO 0);
  TYPE matrix IS ARRAY(0 TO 255) OF std_logic_vector(7 DOWNTO 0);
  TYPE int_matrix IS ARRAY(0 TO 255) OF INTEGER;--std_logic_vector(7 downto 0)
  SIGNAL matrix_A : int_matrix := (
    0 => 2, 1 => 4, 2 => 8, 3 => 16, 15 => 2, 16 => 4, 17 => 8, 31 => 16, 
    OTHERS => 1
  );--all remaining set to one
  SIGNAL matrix_B_T : int_matrix := (
    -- 0=>2,240=>2, -- End numbers of First Column (For testing different inputs)
    -- 15=>2,255=>2,-- End numbers of Last Column
    OTHERS => 1
  );--all ones
  -- signal matrix_C : matrix:=(others=>(others=>'0'));

  SIGNAL rowNo : INTEGER := 0;
  -- signal data_o_A : integer:= 0;
  -- signal data_i_A : integer:= 0;
  --------------rowHandler-------------------------------------------------------------------------------------
  SIGNAL i : INTEGER := 0;
  SIGNAL j : INTEGER := 0;
  SIGNAL we_temp : std_logic := '0';
  SIGNAL startB : std_logic := '0';
  SIGNAL showC : std_logic := '0';
  SIGNAL data_o_C : row := (OTHERS => (OTHERS => '0'));
  SIGNAL A_elem : std_logic_vector(7 DOWNTO 0) := (OTHERS => '0');
  SIGNAL B_elem : std_logic_vector(7 DOWNTO 0) := (OTHERS => '0');
  SIGNAL resetModule : std_logic_vector(0 TO 15) := (OTHERS => '0');
  ----------------------------------------------------------------------------------------------------

  ----------------------------------------------------------------------------------------------------
BEGIN
  data_out0 <= data_o_C(0);
  data_out1 <= data_o_C(1);
  data_out2 <= data_o_C(2);
  data_out3 <= data_o_C(3);
  data_out4 <= data_o_C(4);
  data_out5 <= data_o_C(5);
  data_out6 <= data_o_C(6);
  data_out7 <= data_o_C(7);
  data_out8 <= data_o_C(8);
  data_out9 <= data_o_C(9);
  data_out10 <= data_o_C(10);
  data_out11 <= data_o_C(11);
  data_out12 <= data_o_C(12);
  data_out13 <= data_o_C(13);
  data_out14 <= data_o_C(14);
  data_out15 <= data_o_C(15);

  ----------------------------------------------------------------------------------------------------
  -- FSM to read 255 elements of A, then B.
  ----------------------------------------------------------------------------------------------------
  -- This process should take inputs to the board from PC (currently taken from initialized matrix values only) at TODO.
  -- It handles the input/output of the board.
  ------------------------------------------------------------------------------------------------------------------------------------------------------------
  -- STATE MACHINE REFERENCE : VHDL->Synthesis Construct->Coding Examples->State-Machines

  OUTPUT_DECODE : PROCESS (state)
  BEGIN
    CASE (state) IS
      WHEN Reset => 
        resetModule <= (OTHERS => '1');
        j <= 0;
        i <= 0;
        startB <= '0';
 
      WHEN initSendA => 
        -- Run the rows one by one here
        resetModule <= (0 => '0', OTHERS => '1');
 
      WHEN sendA | sendA_2 => 
        -- -- -- -- -- 
        -- Here we can read data from PC using the h2fData_out register
        -- A_elem <= h2fData_out;
        A_elem <= std_logic_vector(to_unsigned(matrix_A(j), 8));
        -- -- -- -- -- 
        -- adjust rowNo & writeEn here.
        IF (j MOD 16 = 15) THEN
          rowNo <= rowNo + 1;
          resetModule(rowNo + 1) <= '0';

        END IF;

        IF (j = 254) THEN -- it should be 254 (and not 255) as it will take one clock cycle to reflect the change.
          --Run the rows together
          startB <= '1'; -- this will trigger the row_module
        END IF;
        j <= j + 1;

      WHEN initSendB => 
        j <= 0;
        i <= 0;
        --Note : initsendB will not update B_elem 

      WHEN sendB | sendB_2 => 
        -- here first i will be shown as 1, but index will 1-1 = 0;
        -- first time in sendB, the element will be B[0];
        B_elem <= std_logic_vector(to_unsigned(matrix_B_T(i), 8));
        -- Here no 1 cycle gap coz we_temp don't access by bram
        IF (i = 255) THEN
          showC <= '1';
        END IF;
        i <= i + 1;

      WHEN changeCol => 
        -- do not increment for 1 cycle
        B_elem <= std_logic_vector(to_unsigned(matrix_B_T(i), 8));

        -- when Halt=>
      WHEN OTHERS => 
        we_temp <= '0';
    END CASE; 

  END PROCESS;
  ------------------------------------------------------------------------------------------------------------------------------------------------------------
  -- Decides the sequence in which our FSM should move.
  -- First it will send A row by row, then send B column by column & calculate the column of C concurrently as B is coming (without storing it).
  ------------------------------------------------------------------------------------------------------------------------------------------------------------
  ---------------NEXT_STATE_DECODE-------------------------------------------------------------------------------------
  NEXT_STATE_DECODE : PROCESS (state)
  BEGIN
    next_state <= state; --default is to stay in current state
    CASE (state) IS
      WHEN Reset => 
        next_state <= initSendA;
      WHEN initSendA => 
        next_state <= sendA;

      WHEN sendA => 
        IF (j = 254) THEN
          next_state <= sendB;
        ELSE
          next_state <= sendA_2;
        END IF;

      WHEN sendA_2 => 
        IF (j = 254) THEN
          next_state <= sendB;
        ELSE
          next_state <= sendA;
        END IF;

      WHEN changeCol => 
        next_state <= sendB;
      WHEN Halt => 
        next_state <= Halt;

      WHEN sendB => 
        IF (i = 255) THEN
          next_state <= Halt;
        ELSE

          IF (i MOD 16 = 15) THEN
            next_state <= changeCol;
          ELSE
            next_state <= sendB_2;
          END IF;
        END IF;
      WHEN sendB_2 => 
        IF (i = 255) THEN
          next_state <= Halt;
        ELSE
          IF (i MOD 16 = 15) THEN
            next_state <= changeCol;
          ELSE
            next_state <= sendB;
          END IF;
        END IF;
      WHEN OTHERS => 
        next_state <= Reset; --Stay in the same state & wait for debug
    END CASE; 
  END PROCESS;

  -----------SYNC_PROC-----------------------------------------------------------------------------------------
  ------------------------------------------------------------------------------------------------------------------------------------------------------------
  -- This wrapper will push the FSM to next state, and handle the resetbutton.
  ------------------------------------------------------------------------------------------------------------------------------------------------------------
  SYNC_PROC : PROCESS (clk_in)
  BEGIN
    IF (rising_edge(clk_in)) THEN
      IF (ResetMatrix = '1') THEN
        state <= Reset;
      ELSE
        state <= next_state;
      END IF;
    END IF;
  END PROCESS;
  ----------------------------------------------------------------------------------------------------

  ------------------------------------------------------------------------------------------------------------------------------------------------------------
  -- Mapping the 16 Modules
  ------------------------------------------------------------------------------------------------------------------------------------------------------------
  -- The row_module will take care of storing itself, multiplying itself with B, and waiting for other rows to store/calculate.
  ----------------------------------------------------------------------------------------------------

  multiply_and_store : FOR i IN 16 DOWNTO 0 GENERATE
    row_i: work.row_module PORT MAP(
        clk_in => clk_in, 
        resetModule => resetModule(i), 
        startB => startB, 
        A_elem => A_elem, 
        B_elem => B_elem, 
        data_o_C => data_o_C(i)
      );
    END GENERATE;

END behavioural;