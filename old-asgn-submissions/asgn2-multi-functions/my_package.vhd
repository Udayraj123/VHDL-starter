library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- TODO: Rename the packagename
PACKAGE MY IS
-- Array for seven seg display. used in code as DISP_ARRAY(3 downto 0) to correspond to the 4 display hex-numbers
type DISP_ARRAY is array (integer range <>) of STD_LOGIC_VECTOR(7 downto 0);
type INT_ARRAY is array (integer range <>) of integer  RANGE 0 TO 9;--:=0

FUNCTION myMod (a,b:integer) RETURN INTEGER;
FUNCTION INT_TO7SEG (A:INTEGER) RETURN STD_LOGIC_VECTOR;
-- function "returns" a calculated value
FUNCTION SUM (N:integer;TenNums:INT_ARRAY(9 downto 0)) RETURN INTEGER;
FUNCTION AVG (N:integer;TenNums:INT_ARRAY(9 downto 0)) RETURN INTEGER;
--% PROCEDURE SEG_CTRL (SIGNAL NUMBER:IN INTEGER; SIGNAL DIGIT1,DIGIT2,DIGIT3,DIGIT4: OUT INTEGER RANGE 0 TO 9);
PROCEDURE SEG_CTRL (SIGNAL NUMBER:IN INTEGER; SIGNAL digits: OUT INT_ARRAY(3 downto 0));

END MY;


PACKAGE BODY MY IS

FUNCTION myMod (a,b:integer) RETURN INTEGER is
BEGIN
return (a - b*(a/b));
end myMod;

FUNCTION SUM (N:integer;TenNums:INT_ARRAY(9 downto 0)) RETURN INTEGER is
VARIABLE SumOfNums: integer range 0 to 320 := 0;
VARIABLE temp: integer range 0 to 10 := 0;
BEGIN
-- N can be max 9 here, can use more than 9, or a While loop here.
for i in 0 to 9 loop
if(temp < N)then
SumOfNums := (SumOfNums + TenNums(i));
temp := temp +1;
end if;
end loop ;
RETURN SumOfNums;
END SUM;

FUNCTION AVG (N:integer;TenNums:INT_ARRAY(9 downto 0)) RETURN INTEGER is
BEGIN
RETURN (SUM(N,TenNums)/N);
END AVG;

FUNCTION INT_TO7SEG (A:INTEGER) RETURN STD_LOGIC_VECTOR IS
VARIABLE RESULT: STD_LOGIC_VECTOR(7 downto 0); -- 8 bits including the dot '.'

BEGIN
case A is
when 0 => RESULT := "11000000";
when 1 => RESULT := "11111001";
when 2 => RESULT := "10100100";
when 3 => RESULT := "10110000";
when 4 => RESULT := "10011001";
when 5 => RESULT := "10010010";
when 6 => RESULT := "10000010";
when 7 => RESULT := "11111000";
when 8 => RESULT := "10000000";
when 9 => RESULT := "10010000";
when others => RESULT := "01111111";
end case;

RETURN RESULT;
END INT_TO7SEG;
--------------------------------------------------

-- Convert input integer into array of integer digits
-- 1234 --> [1,2,3,4]
PROCEDURE SEG_CTRL (SIGNAL NUMBER:IN INTEGER;SIGNAL digits: OUT INT_ARRAY(3 downto 0)) IS
VARIABLE TEMP: INTEGER RANGE 0 TO 9999;
VARIABLE D1: INTEGER RANGE 0 TO 9;
VARIABLE D2: INTEGER RANGE 0 TO 9;
VARIABLE D3: INTEGER RANGE 0 TO 9;
VARIABLE D4: INTEGER RANGE 0 TO 9;
BEGIN
-- TODO: Can make it shorter using the myMod function
-- myMod(TEMP,1000)
TEMP:=NUMBER;
IF(TEMP>999)THEN
D4:=TEMP/1000;
TEMP:=TEMP-D4*1000;
ELSE
D4:=0;
END IF;
IF(TEMP>99)THEN
D3:=TEMP/100;
TEMP:=TEMP-D3*100;
ELSE
D3:=0;
END IF;
IF(TEMP>9)THEN
D2:=TEMP/10;
TEMP:=TEMP-D2*10;
ELSE
D2:=0;
END IF;
D1:=TEMP;
digits(0)<=D1;
digits(1)<=D2;
digits(2)<=D3;
digits(3)<=D4;
END SEG_CTRL;
END MY;