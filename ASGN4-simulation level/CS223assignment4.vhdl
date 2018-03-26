-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
----------------------------------------------------------------------------------------------------
-- Matrix multiplication in parallel
-- Two set of states used for this assignment.
-- These handle the sending data to board : (Reset,initSendA,sendA,sendA_2,initSendB,sendB,sendB_2,changeCol,readC,Halt,NextHalt)
-- These handle the calculation part (defined in rowmodule) : (Reset,firstStore,StoreAt_j,StoreAt_j_2, WaitCalc,WaitCalc_2,initCalc,CalcAt_i,CalcAt_i_2,changeCol,Halt,Finish); 
----------------------------------------------------------------------------------------------------

entity top_level is
port(
ResetMatrix     : in    std_logic;                  
clk_in        : in    std_logic;                    -- 08MHz clock from FX2
data_out0  : out std_logic_vector(7 downto 0);
data_out1  : out std_logic_vector(7 downto 0);
data_out2  : out std_logic_vector(7 downto 0);
data_out3  : out std_logic_vector(7 downto 0);
data_out4  : out std_logic_vector(7 downto 0);
data_out5  : out std_logic_vector(7 downto 0);
data_out6  : out std_logic_vector(7 downto 0);
data_out7  : out std_logic_vector(7 downto 0);
data_out8  : out std_logic_vector(7 downto 0);
data_out9  : out std_logic_vector(7 downto 0);
data_out10 : out std_logic_vector(7 downto 0);
data_out11 : out std_logic_vector(7 downto 0);
data_out12 : out std_logic_vector(7 downto 0);
data_out13 : out std_logic_vector(7 downto 0);
data_out14 : out std_logic_vector(7 downto 0);
data_out15 : out std_logic_vector(7 downto 0)
);
end top_level;

architecture behavioural of top_level is
----------------------------------------------------------------------------------------------------

type state_type is (Reset,initSendA,sendA,sendA_2,initSendB,sendB,sendB_2,changeCol,readC,Halt,NextHalt); 
signal state, next_state : state_type; 

type row is array(0 to 15) of std_logic_vector(7 downto 0);
type matrix is array(0 to 255) of std_logic_vector(7 downto 0);
type int_matrix is array(0 to 255) of integer;--std_logic_vector(7 downto 0)


signal matrix_A :  int_matrix:=(
  0=>2, 1=>4, 2=>8, 3=>16, 
  15=>2, 16=>4, 17=>8, 31=>16,
others=>1);--all remaining set to one
signal matrix_B_T :  int_matrix:=(
-- 0=>2,240=>2, -- End numbers of First Column (For testing different inputs)
-- 15=>2,255=>2,-- End numbers of Last Column
others=>1);--all ones
-- signal matrix_C :  matrix:=(others=>(others=>'0'));

signal rowNo : integer:= 0;
-- signal data_o_A : integer:= 0;
-- signal data_i_A : integer:= 0;
--------------rowHandler-------------------------------------------------------------------------------------
signal i: integer := 0;
signal j: integer := 0;
signal we_temp: std_logic := '0';
signal startB: std_logic := '0';
signal showC: std_logic := '0';
signal data_o_C: row := (others=>(others=>'0'));
signal A_elem: std_logic_vector(7 downto 0) := (others=>'0');
signal B_elem: std_logic_vector(7 downto 0) := (others=>'0');
signal resetModule: std_logic_vector(0 to 15):=(others=>'0');
----------------------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------------------
begin							

data_out0<=data_o_C(0);
data_out1<=data_o_C(1);
data_out2<=data_o_C(2);
data_out3  <=data_o_C(3 );
data_out4  <=data_o_C(4 );
data_out5  <=data_o_C(5 );
data_out6  <=data_o_C(6 );
data_out7  <=data_o_C(7 );
data_out8  <=data_o_C(8 );
data_out9  <=data_o_C(9 );
data_out10 <=data_o_C( 10);
data_out11 <=data_o_C( 11);
data_out12 <=data_o_C( 12);
data_out13 <=data_o_C( 13);
data_out14 <=data_o_C( 14);
data_out15 <=data_o_C( 15);

----------------------------------------------------------------------------------------------------
-- FSM to read 255 elements of A, then B.
----------------------------------------------------------------------------------------------------
-- This process should take inputs to the board from PC (currently taken from initialized matrix values only) at TODO.
-- It handles the input/output of the board.
------------------------------------------------------------------------------------------------------------------------------------------------------------
--  STATE MACHINE REFERENCE : VHDL->Synthesis Construct->Coding Examples->State-Machines

OUTPUT_DECODE: process (state)
begin

    case (state) is
    when Reset=>
        resetModule<=(others=>'1');
       j<=0; i<=0;
        startB<='0';
    
    when initSendA=>
        -- Run the rows one by one here
        resetModule<=(0=>'0',others=>'1');
        
    when sendA | sendA_2=>
    --TODO :  Connect here from register of h2fData

        -- Convert int to std here
        A_elem <= std_logic_vector(to_unsigned(matrix_A(j),8));
        -- adjust rowNo & writeEn here.
         if(j mod 16 = 15)then 
          rowNo<=rowNo+1;
          resetModule(rowNo+1)<='0';

        end if;

         if(j=254)then -- it should be 254 (and not 255) as it will take one clock cycle to reflect the change.
          --Run the rows together
           startB<='1'; -- this will trigger the row_module
        end if;
        j<=j+1;

    when initSendB=>
        j<=0;
        i<=0;
        --Note : initsendB will not update B_elem  

    when sendB | sendB_2=>
        -- here first i will be shown as 1, but index will 1-1 = 0;
        -- first time in sendB, the element will be B[0];
        B_elem <= std_logic_vector(to_unsigned(matrix_B_T(i),8));
        -- Here no 1 cycle gap coz we_temp don't access by bram
         if(i=255)then
           showC<='1';
        end if;
        i<=i+1;

     when changeCol =>
      -- do not increment for 1 cycle
        B_elem <= std_logic_vector(to_unsigned(matrix_B_T(i),8));

    -- when Halt=>
     when others =>
        we_temp<='0';
    end case;   

end process;
------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Decides the sequence in which our FSM should move.
-- First it will send A row by row, then send B column by column & calculate the column of C concurrently as B is coming (without storing it).
------------------------------------------------------------------------------------------------------------------------------------------------------------
---------------NEXT_STATE_DECODE-------------------------------------------------------------------------------------
NEXT_STATE_DECODE: process (state)
begin
   next_state <= state;  --default is to stay in current state
   case (state) is
        when Reset =>
             next_state <= initSendA ;
        when initSendA =>
             next_state <= sendA;

         when sendA =>
             if(j=254)then
                next_state <= sendB;
             else
                next_state <= sendA_2 ;
             end if;

         when sendA_2 =>
             if(j=254)then
                next_state <= sendB;
             else
                next_state <= sendA ;
             end if;

         when changeCol =>
              next_state <= sendB;
         when Halt =>
              next_state <= Halt;

         when sendB =>
             if(i=255)then
                next_state <= Halt;
             else

               if(i mod 16 = 15)then
                next_state <= changeCol;
               else
                next_state <= sendB_2 ;
               end if;
             end if;
         when sendB_2 =>
             if(i=255)then
                next_state <= Halt;
             else
               if(i mod 16 = 15)then
                next_state <= changeCol;
               else
                  next_state <= sendB ;
               end if;
             end if;
        when others =>
             next_state <= Reset; --Stay in the same state & wait for debug
       end case;   
end process;

-----------SYNC_PROC-----------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------
-- This wrapper will push the FSM to next state, and handle the resetbutton.
------------------------------------------------------------------------------------------------------------------------------------------------------------
SYNC_PROC: process (clk_in)
begin
   if (rising_edge(clk_in)) then
      if (ResetMatrix = '1') then state <= Reset;
      else state <= next_state; end if;
   end if;
end process;
----------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Mapping the 16 Modules
------------------------------------------------------------------------------------------------------------------------------------------------------------
-- The row_module will take care of storing itself, multiplying itself with B, and waiting for other rows to store/calculate.
----------------------------------------------------------------------------------------------------

bram_rows: for i in 16 downto 0 generate
  entity work.row_module port map(
     clk_in => clk_in ,
     resetModule => resetModule(i),
     startB => startB,
     A_elem => A_elem,
     B_elem => B_elem,
     data_o_C => data_o_C(i)
  );
end generate;

end behavioural;