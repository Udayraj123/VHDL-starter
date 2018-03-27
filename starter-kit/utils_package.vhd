library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

PACKAGE utils_package IS
-- Array for seven seg display. used in code as BYTE_ARRAY(3 downto 0) to correspond to the 4 display hex-numbers
type BYTE_ARRAY is array (integer range <>) of STD_LOGIC_VECTOR(7 downto 0);
type INT_ARRAY is array (integer range <>) of integer  RANGE 0 TO 9;--:=0

-- function "returns" a calculated value
FUNCTION INT_TO7SEG_BITS (DISP_INT:INTEGER) RETURN STD_LOGIC_VECTOR;
FUNCTION SUM (N:integer;MaxTenNums:INT_ARRAY(9 downto 0)) RETURN INTEGER;
FUNCTION AVG (N:integer;MaxTenNums:INT_ARRAY(9 downto 0)) RETURN INTEGER;

PROCEDURE TO_INT_ARRAY (SIGNAL NUMBER:IN INTEGER; SIGNAL digits: OUT INT_ARRAY(3 downto 0));
-- Note: Procedure 'connects' its Multiple INs and Multiple OUTs
-- while A function may return only one output

END utils_package;


PACKAGE BODY utils_package IS

FUNCTION SUM (N:integer;MaxTenNums:INT_ARRAY(9 downto 0)) RETURN INTEGER is
VARIABLE SumOfNums: integer range 0 to 320 := 0;
VARIABLE temp: integer range 0 to 10 := 0;
BEGIN
-- N can be max 9 here, can use more than 9, or a While loop here.
	for i in 0 to 9 loop
		if(temp < N)then
			SumOfNums := (SumOfNums + MaxTenNums(i));
			temp := temp +1;
		end if;
	end loop ;
RETURN SumOfNums;
END SUM;

FUNCTION AVG (N:integer;MaxTenNums:INT_ARRAY(9 downto 0)) RETURN INTEGER is
BEGIN
	RETURN (SUM(N,MaxTenNums)/N);
END AVG;

FUNCTION INT_TO7SEG_BITS (DISP_INT:INTEGER) RETURN STD_LOGIC_VECTOR IS
VARIABLE RESULT: STD_LOGIC_VECTOR(7 downto 0); -- 8 bits including the dot '.'

BEGIN
case DISP_INT is
-- NOTE: Check the pin order for your board's display (Common Anode or Cathode). Ref: http://fpga-tutorials.blogspot.in/2011/11/7-segment-displays.html 

--		 The constant '1' at the left end is for the decimal point on the display
-- Common anode display
	-- when 0 => RESULT := "11000000"; 
	-- when 1 => RESULT := "11111001";
	-- when 2 => RESULT := "10100100";
	-- when 3 => RESULT := "10110000";
	-- when 4 => RESULT := "10011001";
	-- when 5 => RESULT := "10010010";
	-- when 6 => RESULT := "10000010";
	-- when 7 => RESULT := "11111000";
	-- when 8 => RESULT := "10000000";
	-- when 9 => RESULT := "10010000";
	-- when others => RESULT := "01111111";

-- Common cathode display
    when 0 => RESULT := "10000001"; -- "0"     
    when 1 => RESULT := "11001111"; -- "1" 
    when 2 => RESULT := "10010010"; -- "2" 
    when 3 => RESULT := "10000110"; -- "3" 
    when 4 => RESULT := "11001100"; -- "4" 
    when 5 => RESULT := "10100100"; -- "5" 
    when 6 => RESULT := "10100000"; -- "6" 
    when 7 => RESULT := "10001111"; -- "7" 
    when 8 => RESULT := "10000000"; -- "8"     
    when 9 => RESULT := "10000100"; -- "9" 
    when 10 => RESULT := "10000010"; -- a
    when 11 => RESULT := "11100000"; -- b
    when 12 => RESULT := "10110001"; -- C
    when 13 => RESULT := "11000010"; -- d
    when 14 => RESULT := "10110000"; -- E
    when 15 => RESULT := "10111000"; -- F
	when others => RESULT := "11111111";

end case;

RETURN RESULT;
END INT_TO7SEG_BITS;
--------------------------------------------------

-- Convert input integer into array of integer digits(which shall later be converted to 7seg pin bits using INT_TO7SEG_BITS)
-- 1234 --> [1,2,3,4]
PROCEDURE TO_INT_ARRAY (SIGNAL NUMBER:IN INTEGER;SIGNAL digits: OUT INT_ARRAY(3 downto 0)) IS
VARIABLE TEMP: INTEGER RANGE 0 TO 9999;
BEGIN
digits(0) <= NUMBER / 10;
digits(1) <= NUMBER / 100;
digits(2) <= NUMBER / 1000;
digits(3) <= NUMBER / 10000;
-- Or can use a loop : 
-- TEMP:=1;
-- for i in 0 to 4 loop
-- 	digits(i)<=NUMBER mod TEMP;
-- 	TEMP:=TEMP*10;
-- end loop;
END TO_INT_ARRAY;
END utils_package;