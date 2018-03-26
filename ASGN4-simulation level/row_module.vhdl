library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all; --contains to_integer
------------------------------------------------------------------
-- row_module will take care of storing itself, multiplying itself with B, and waiting for other rows to store/calculate.
------------------------------------------------------------------
  entity row_module is
  port (
     Clk : in std_logic;
     startB : in std_logic;
     resetModule : in std_logic;
     A_elem : in std_logic_vector(7 downto 0);
     B_elem : in std_logic_vector(7 downto 0);
     data_o_C : out std_logic_vector(7 downto 0)
     );
  end row_module;

  architecture Behavioral of row_module is
signal i: integer := 0;
signal j: integer := 0;
signal col: integer := 0;
signal col_prev: integer := 0;

signal data_i_C: std_logic_vector(7 downto 0) := (others=>'0');
signal A_j: std_logic_vector(7 downto 0) := (others=>'0');
signal we : std_logic:='1';
signal weC : std_logic:='1';

signal S: integer := 0;

 type state_type is (Reset,firstStore,StoreAt_j,StoreAt_j_2, WaitCalc,WaitCalc_2,initCalc,CalcAt_i,CalcAt_i_2,changeCol,Halt,Finish); 
 signal state, next_state : state_type; 


 --- archi begin
 begin

OUTPUT_DECODE: process (state)
begin
    case (state) is
    when Reset=>
        we<= '1';
        j<=0;
    when firstStore=>
        j<=0; --do not increment, but store


    when StoreAt_j | StoreAt_j_2=>
          j<=j+1;

    when WaitCalc | WaitCalc_2=>
        i<=0;j<=0;
        col<=0;
        weC<='1';
        we<='0';

    when initCalc=>
        --calc here also if j is starting from 1. -- YUP
        --in init, do not increment, but only calc
        S <= S + to_integer(unsigned(B_elem)) * to_integer(unsigned(A_j)); 
        --Check : This should be visible in the simulation

    when CalcAt_i |CalcAt_i_2 =>
        -- i is the counter for B_elem
        S <= (S + to_integer(unsigned(B_elem)) * to_integer(unsigned(A_j)));

        if(j < 15)then
            j<=j+1;
        end if;
          i<=i+1;

    when changeCol=>
      if(j = 15)then
          data_i_C <= std_logic_vector(to_unsigned(S,8));
          S<=0; j<=0;
          col_prev<=col; -- or col - 1
          col<=col+1;
      end if;

    when Halt=>
    if(j = 15)then
        data_i_C <= std_logic_vector(to_unsigned(S,8));
        S<=0; j<=0;
        col_prev<=col; -- or col - 1
        col<=col+1;
    end if;
        -- weC<='0'; -- Will stop writing from last one also !
        we<='0';
    when Finish=>
        weC<='0';

     when others =>
        we<='0';
    end case;   

end process;

NEXT_STATE_DECODE: process (state,startB) --This reduced the cycle delay by 1 !
begin
   next_state <= state;  --default is to stay in current state
   case (state) is
        when Reset =>
             next_state <= firstStore ;

        when firstStore =>
             next_state <= StoreAt_j ;

        when StoreAt_j =>
            --Here j is till 14 only coz its incremented in the same state.
            --j=0 is done by init store
            if(j=14)then
             next_state <= WaitCalc;
            else
             next_state <= StoreAt_j_2 ;
            end if;
        when StoreAt_j_2 =>
            if(j=14)then
             next_state <= WaitCalc;
            else
             next_state <= StoreAt_j ;
            end if;

          when WaitCalc =>
            if(startB='1')then
             next_state <= initCalc;
            else
             next_state <= WaitCalc_2;
            end if;


          when WaitCalc_2 =>
            if(startB='1')then
             next_state <= initCalc;
            else
             next_state <= WaitCalc;
            end if;

        when initCalc =>
             next_state <= CalcAt_i ;

        when changeCol =>
             next_state <= CalcAt_i ;

         when CalcAt_i =>
             if(i=255)then
              next_state <= Halt;
             else
               if(j mod 16 = 15)then
                next_state <= changeCol;
               else
                next_state <= CalcAt_i_2 ;
               end if;
             end if;

         when CalcAt_i_2 =>
             if(i=255)then
              next_state <= Halt;
             else
               if(j mod 16 = 15)then
                next_state <= changeCol;
               else
                next_state <= CalcAt_i ;
               end if;
             end if;
             
         when Halt =>
             next_state <= Finish;

        when others =>
             next_state <= state; --Stay in the same state & wait for debug
       end case;   

end process;
----------------------------------------------------------------------------------
 A_row : entity work.single_ram port map(
    Clk => Clk , 
    we => we,
    address => j ,
    data_i_A => A_elem ,
    data_o_A => A_j
 );
 C_row : entity work.single_ram port map(
    Clk => Clk , 
    we => weC,
    address => col_prev,
    data_i_A => data_i_C ,
    data_o_A => data_o_C
 );

 ----------------------------------------------------------------------------------------------------
 SYNC_PROC: process (Clk)
 begin
    if (rising_edge(Clk)) then
       if (resetModule = '1') then state <= Reset;
       else state <= next_state; end if;
    end if;
 end process;

 ----------------------------------------------------------------------------------------------------
 end Behavioral;