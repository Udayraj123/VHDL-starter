-------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

----------------------------------------------------------------------------------------------------
-- A demonstration of parsing the regular expression (01)* using a state machine.
-- This code is just for understanding how the state machine works here
-- First see the DFA image in the current directory(generated using http://www.webgraphviz.com/)
-- The following code shows how to translate that DFA into VHDL code.
-- The testbench has the string and current_bit_in will update accordingly at each clock tick 
-- Simulate this and see how the states change as input gets processed bit by bit
----------------------------------------------------------------------------------------------------

ENTITY simple_dfa IS
  PORT (
    reset_in : IN std_logic; 
    -- input will come bit by bit in sync with the clock
    clk_in : IN std_logic; 
    current_bit_in : IN std_logic;
    -- when end_marker is zero, the input starts in. when it is one, the input stops
    end_marker : IN std_logic; 
    -- Output boolean 'accepted'
    accepted : OUT std_logic
  );
END simple_dfa;

ARCHITECTURE behavioural OF simple_dfa IS
-- Define possible states
TYPE state_type IS (ResetState, Start, Got0, Got1, Trap, Halt);
-- Define state variables
SIGNAL state, next_state : state_type;

-- Some variables Just for debugging and verifying input in simulation
SIGNAL input_length : INTEGER := 0;
SIGNAL finished : std_logic := '0';
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

      -- Initialize
      WHEN ResetState => 
        if (end_marker = '0') then next_state <= Start; else next_state <= ResetState;end if;

      -- Make the 6 edges
      WHEN Start => 
          if (end_marker = '1') then next_state <= Halt;      else 
             if (current_bit_in = '0') then next_state <= Got0; else next_state <= Trap; end if;
          end if;

      WHEN Got0 => 
          if (end_marker = '1') then next_state <= Halt;      else 
             if (current_bit_in = '0') then next_state <= Trap; else next_state <= Got1; end if;
          end if;

      WHEN Got1 => -- Accept and Halt if end of input else continue to other states
          if (end_marker = '1') then  next_state <= Halt;      else 
             if (current_bit_in = '0') then next_state <= Got0; else next_state <= Trap; end if;
          end if;

      -- On End of input
      WHEN Halt => 
        next_state <= Halt;

      WHEN OTHERS => 
        next_state <= ResetState; --Stay in the same state & wait for debug
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
      WHEN ResetState => 
        accepted <= '0';     
      
      WHEN Start => 
        input_length <= 0; 
        finished <= '0';
 
      WHEN Got0  | Trap => 
        accepted <= '0';     
        input_length <= input_length + 1;

      WHEN Got1 => -- FINAL STATE
        accepted <= '1';     
        input_length <= input_length + 1;
      
      WHEN Halt =>
        finished <= '1';

--    WHEN OTHERS => -- Should never reach here

    END CASE; 

  END PROCESS;
  ----------------------------------------------------------------------------------------------------
END behavioural;
 