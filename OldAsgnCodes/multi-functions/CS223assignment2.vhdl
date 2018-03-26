--------------- SQROOT ENTITIY ------------------
library ieee; 
use ieee.std_logic_1164.all; 
use ieee.numeric_std.all;
-- use IEEE.STD_LOGIC_unsigned.ALL;
-- use IEEE.STD_LOGIC_arith.ALL;

entity sqroot is port( 
	clock      : in std_logic;  
	data_in    : in std_logic_vector(7 downto 0); 
	data_out   : out std_logic_vector(3 downto 0);
	reset : in std_logic); 
	end sqroot;

architecture behaviour of sqroot is
signal sq_done  : std_logic := '0';
signal sq_counter : integer := 0; 

begin -- architecture

process(clock, data_in, sq_done)--, CLK_50kHZ, reset)
VARIABLE reset_prev: std_logic :='0';
begin
		-- division comparision is used to floor down sqroot of  data_in < 1.
		if rising_edge(clock) then
		
		if(reset_prev='1' and reset='0') then
		sq_done <='0';
		sq_counter <=0;
		data_out <= std_logic_vector(to_unsigned(0,4));
		else
		if(sq_done='0')then
		if(  sq_counter*sq_counter > to_integer(unsigned(data_in)) ) 
		then
		sq_done <= '1';
		data_out <= std_logic_vector(to_unsigned(sq_counter-1,4));
		else
		sq_counter <= sq_counter + 1;
		end if;
		end if;
		end if;

		reset_prev:=reset;
		end if;

		end process;   
		end behaviour;

-- These need to be imported every time before declaring an entity
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity clock_div is
Port (
	clk_in : in  STD_LOGIC;
	reset  : in  STD_LOGIC;
	clk_out: out STD_LOGIC
	);
end clock_div;

architecture Behavioral of clock_div is
signal temporal: STD_LOGIC;
signal counter : integer range 0 to 500000000 := 0;
begin
frequency_divider: process (reset, clk_in) begin
if (reset = '1') then
temporal <= '0';
counter <= 0;
elsif rising_edge(clk_in) then
if (counter = 124999) then
temporal <= NOT(temporal);
counter <= 0;
else
counter <= counter + 1;
end if;
end if;
end process;

outputClk: process (temporal) begin
clk_out <= temporal;
end process;
end Behavioral;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
-- which MODE to USE :
use work.my.all; -- declared inside sum_package.vhd file
-- use work.MY_RTL.all;


-- TOP LEVEL entity - The main()
-- Basys sevenseg
-- TODO: Rename the entity & it's arguments intuitively here-
ENTITY TOP_LEVEL IS
PORT(
---------------------- Onboard peripherals --------------------------------
en : out STD_LOGIC_VECTOR(3 downto 0);
seg : out STD_LOGIC_VECTOR (7 downto 0);
SW: IN STD_LOGIC_VECTOR(9 downto 0); -- THe input Switches
USER_MODE : in STD_LOGIC_VECTOR(1 downto 0);
btn,reset,clk: IN STD_LOGIC
----------------------------------------------------------------------
);
END TOP_LEVEL;

ARCHITECTURE MAIN OF TOP_LEVEL IS
SIGNAL PRESCALER :INTEGER RANGE 0 TO 50000000:=0;

SIGNAL digits: INT_ARRAY(3 downto 0);
SIGNAL digs: DISP_ARRAY(3 downto 0);
-- Clock configuration
SIGNAL CLK_50HZ : STD_LOGIC :='0';
SIGNAL fact_100MHz_50Hz:	INTEGER :=2000000; 
-- Current input in integer
signal currInp: INTEGER  := 0;
-- Array for converting & storing input binary numbers as integers
SIGNAL inpNums: INT_ARRAY(9 downto 0);
-- The digit in a single 7-seg display
SIGNAL dispNum:	INTEGER  := 0;
signal N:		INTEGER  := 0;
signal counter: INTEGER  := -1;

----- Clock Divider PART ----
component clock_div is
port(clk_in : in  STD_LOGIC; reset : in  STD_LOGIC; clk_out: out STD_LOGIC );
END component;

----- THE SQROOT Entity added for STDDEVIATION PART ----
component sqroot
port (
	clock      : in std_logic;  
	data_in    : in std_logic_vector(7 downto 0); 
	data_out   : out std_logic_vector(3 downto 0);
	reset      : in std_logic 
);
end component;

SIGNAL stdDevResult: std_logic_vector (7 downto 0);
SIGNAL tempDisp:	 std_logic_vector (3 downto 0);

BEGIN



-- Port map the entities:
clock: clock_div port map (clk, reset, CLK_50HZ);
-- ^entity for divide isn't here?
sq1: sqroot port map (CLK_50HZ,stdDevResult,tempDisp,reset);

-- 1234 --> [1,2,3,4]
SEG_CTRL(dispNum,digits); -- Procedure 'connects' its Multiple INs and Multiple OUTs

-- Note: I've used integers everywhere to make the code look more intuitive
-- Only below call is converting int to sevenseg representation
-- when 9 => RESULT := "10010000";
digs(0)<=INT_TO7SEG(digits(0));
digs(1)<=INT_TO7SEG(digits(1));
digs(2)<=INT_TO7SEG(digits(2));
digs(3)<=INT_TO7SEG(digits(3));
currInp <= to_integer(unsigned(sw)); -- Convert and store switches input

-- takes N=10 input numbers (into currInp), stores it into array (inpNums) and shows computed output (like SUM(N,inpNums))
PROCESS(btn,reset,CLK_50HZ)
VARIABLE btn_prev: std_logic :='0';
VARIABLE reset_prev: std_logic :='0';
		BEGIN --
		if rising_edge(CLK_50HZ) then
		if(reset_prev='1' and reset='0') then
		counter <= -1;--reset
		else --
		if(counter < 0) then
			dispNum <= 0; --display current Input
			else
			if(counter<1) then
				dispNum <= N; --display current Input
			else --
			dispNum <= inpNums(counter-1);	
			end if;
			end if;

		if (counter <= N) then -- <- '=' For an Extra Confirmation Click
		if(btn_prev='1' and btn='0') then
		if(counter=-1) then
		N <= currInp;
		elsif(counter<N) then
		inpNums(counter) <= currInp;
		end if;

		counter <= (counter+1);
		end if;
		else

			-- stdDevResult <= std_logic_vector(to_unsigned(stdDev(N,inpNums), 8));
			stdDevResult <= (others => '0');
			case USER_MODE is
			when "00" => dispNum<= SUM(N,inpNums);
			when "01" => dispNum<= AVG(N,inpNums);
			-- when "10" => dispNum<= sqSUM(N,inpNums); -- Code this function byself
			when "10" => dispNum<= SUM(N,inpNums);
			--OTHER FUNCTIONS GO HERE
			when others => 
			--tempDisp is already calculated. So just connect
				dispNum <= to_integer(unsigned(tempDisp)); --From ENTITY
			--dispNum <= sqRoot(stdDev(N,inpNums)); -- From FUNCTION
			end case;
			end if;
			end if;

			reset_prev:=reset;
			btn_prev:=btn;
			end if;
			END PROCESS;
 ------------------ SETTING ENABLER BY CLOCK FREQUENCY -----------------
 -- TODO: use your own implementation
 -- enabler + PRESCALER = refresh_counter + LED_activating_counter
 PROCESS(CLK)
 BEGIN
 IF(CLK'EVENT AND CLK='1')THEN -- '
-- Pace of calculation : 2 times a second 
PRESCALER<=(PRESCALER+1) MOD 50000000;
   -- ^Better alternative for above is using refresh_counter(20 downto 19)

   IF(PRESCALER=0) THEN
				--Normal paced operations 
				--if Any
				END IF;

	-- Clock paced operations
	en <= "1111";	--update enabler 20 times a second
	en((PRESCALER/4000) mod 4) <= '0'; 
	END IF;
	-- LHS and RHS are both STD_LOGIC_VECTOR(7 downto 0)
	-- digs(index = (PRESCALER/4000) mod 4)
	seg <= digs((PRESCALER/4000) mod 4);

	END PROCESS;
	END MAIN;