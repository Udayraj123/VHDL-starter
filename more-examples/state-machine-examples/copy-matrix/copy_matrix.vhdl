-------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
----------------------------------------------------------------------------------------------------
-- A demonstration of copying a matrix into another using a state machine.
-- This code can be used as a starting point for transferring an array/a matrix from PC to FPGA
-- Simulate this and see how the states change as the clock ticks
----------------------------------------------------------------------------------------------------

ENTITY copy_matrix IS
  PORT (
    reset_in : IN std_logic; 
    clk_in : IN std_logic; -- 08MHz clock from FX2
    data_out0 : OUT std_logic_vector(7 DOWNTO 0)
  );
END copy_matrix;

ARCHITECTURE behavioural OF copy_matrix IS
-- Define possible states
TYPE state_type IS (Reset, initSendA, sendA, endSendA, changeCol, readB, Halt);
-- Define state variables
SIGNAL state, next_state : state_type;
  BEGIN

------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Three processes will run parallely that do the following:
-- NEXT_STATE_DECODE: 'Decode next state' 
-- SYNC_PROC: 'Update current state to next or ResetState'
-- OUTPUT_DECODE: 'Decode output'
------------------------------------------------------------------------------------------------------------------------------------------------------------

---------------NEXT_STATE_DECODE-------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Decides the sequence in which our FSM should move.
-- Note: Ignore warnings like 'end_marker should be on the sensitivity list of the process'
------------------------------------------------------------------------------------------------------------------------------------------------------------
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
  -- Initial state is defined here.
  -- This code almost always stays the same
  ------------------------------------------------------------------------------------------------------------------------------------------------------------
  SYNC_PROC : PROCESS (clk_in)
  BEGIN
    IF (rising_edge(clk_in)) THEN
      IF (reset_in = '1') THEN
        state <= ResetState; -- Initial state is defined here.
      ELSE
        state <= next_state;
      END IF;
    END IF;
  END PROCESS;
  

 -----------OUTPUT_DECODE-----------------------------------------------------------------------------------------
  ------------------------------------------------------------------------------------------------------------------------------------------------------------
  -- This will contain the actual processing code for 
  -- Taking inputs,
  -- Modifying intermediate things other than states if any
  -- Displaying outputs
  ------------------------------------------------------------------------------------------------------------------------------------------------------------
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
  ----------------------------------------------------------------------------------------------------
END behavioural;
 