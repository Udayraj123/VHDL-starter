-- IN PROGRESS

entity top_level is
port(
resetRead     : in    std_logic;                  
Clk     : in    std_logic;                    -- 08MHz clock from FX2
data_out1 : out std_logic_vector(7 downto 0);
data_out2 : out std_logic_vector(7 downto 0)
);
end top_level;

architecture behavioural of top_level is
----------------------------------------------------------------------------------------------------
type rows_reader is array(0 to 3) of std_logic_vector(7 downto 0);--std_logic_vector(7 downto 0)
type matrix is array(0 to 3) of rows_reader;
type int_rows_reader is array(0 to 3) of integer;--std_logic_vector(7 downto 0)
type int_matrix is array(0 to 3) of int_rows_reader;
----------------------------------------------------------------------------------------------------
--Overloading the Operators 
-----------------------------------------^--Inside the architecture of entity.--------------------
 
function "/"(a, b : integer) return integer is
variable a_copy : integer:=0;
variable quo : integer:=0;
begin
a_copy:=a;
while (a_copy>b) loop
a_copy := a_copy - b;
quo := quo + 1;
end loop;

return quo;
end function;


 -- On product of binary numbers
 function "*"(a, b : std_logic_vector) return std_logic_vector is
 variable S : std_logic_vector(7 downto 0) :=(others=>'0');
 begin
 S:= std_logic_vector(to_unsigned(to_integer(unsigned(a))  *  to_integer(unsigned(b)) ,8));
 return S;
 end function;

 -- -- On assignment of integer to std_logic_vector
 -- std_logic_vector(to_unsigned(
 -- function "<="(a: std_logic_vector,b :integer) return std_logic_vector is
 -- variable S : std_logic_vector(7 downto 0) :=(others=>'0');
 -- begin
 -- S:= std_logic_vector(to_unsigned(to_integer(unsigned(a))  +  to_integer(unsigned(b)) ,8));
 -- return S;
 -- end function;

 -- On addition of binary numbers
 function "+"(a, b : std_logic_vector) return std_logic_vector is
 variable S : std_logic_vector(7 downto 0) :=(others=>'0');
 begin
 S:= std_logic_vector(to_unsigned(to_integer(unsigned(a))  +  to_integer(unsigned(b)) ,8));
 return S;
 end function;

-- On dot product of binary vectors
function "*"(a, b : rows_reader) return std_logic_vector is
variable result_v : rows_reader;
--  log(16)+(8+8) = 0+16 = 20
variable S : std_logic_vector(7 downto 0) :=(others=>'0');
begin
for idx in result_v'range loop --'
S := S + (a(idx) * b(idx)); 
end loop;--
return S;
end function;
---------------------------------------END OPERATOR OVERLOADING ----------------------------------------------

signal matrix_A :  int_matrix:=(
(1,7,7,3),
(4,3,1,9),
(6,8,9,2),
(4,3,8,7));

signal matrix_B :  int_matrix:=(
(1,2,9,8),
(7,6,5,4),
(3,4,7,9),
(4,8,9,3));
--Declare internal signals for all outputs of the state-machine
--other outputs
signal rowNo : integer:= 0;
----------------------------------------------------------------------------------------------------
begin					
SYNC_PROC: process (Clk)
begin
   if (rising_edge(Clk)) then
      if (resetRead = '1') then
         state <= StoreAt0;
      else
         state <= next_state;
      -- assign other outputs to internal signals
	    data_out1<=matrix_C(0)(0); --The index is the address(1)
	    data_out2 <= readOutA_Row(0);
	  end if;        
   end if;
end process;

--MOORE State-Machine - Outputs based on state only
OUTPUT_DECODE: process (state)--,address(1) in sensitivity list was causing it to run twice !
begin
	-- update in_row_A on state change
	--only the num at index (1) will matter. others won't [THINK !]
	-- in_row_A <= ("00000100","00000011","00000010","00000001","00000101");-- Note : INDICES ARE N DOWNTO 0

   case (state) is
      -- StoreAt1 to StoreAt0 depends on the sequence in type definition
      when StoreAt0 to StoreAt3=> 
		we<= (others=>'1');
	  when Halt1 | ReadAtNone=>
		we<= (others=>'0');--Disable write, But do not update C
	  when others =>
		we<= (others=>'0');

		--For second element of Row1 of C incremented by values at index 'address(1)' of First row of A & second Col of B :
		--This will actually run 4 times before the final answer. [THINK <- due to states readAt11,etc]
		--address(1)=  0 , 1 ,2 ,3 

--This loop has to be in different process
		for idx in matrix_C(rowNo)'range loop --'
			matrix_C(rowNo)(idx) <= matrix_C(rowNo)(idx) + (readOutA_Row(rowNo) * readOutB_Col(idx)); 
		end loop;--
		
   end case;      
end process;
NEXT_STATE_DECODE: process (state)
begin
   --declare default state for next_state to avoid latches
   next_state <= state;  --default is to stay in current state
   case (state) is

      --Touch all the memories to update on next cycle
        when StoreAt0 =>
           	address<=(others=>0);

           	for idx in in_row_A'range loop --'
           		in_row_A(idx) <= std_logic_vector(to_unsigned(matrix_A(idx)(0),8));
           	end loop;--

           	for idx in in_cols_B'range loop --'
           		in_cols_B(idx) <= std_logic_vector(to_unsigned(matrix_B(0)(idx),8));
           	end loop;--

           	next_state <= StoreAt1;
      when StoreAt1 =>
         	address<=(others=>1);
         	-- Take input matrix data

         	for idx in in_row_A'range loop --'
         		in_row_A(idx) <= std_logic_vector(to_unsigned(matrix_A(idx)(1),8));
         	end loop;--
         	
         	for idx in in_cols_B'range loop --'
         		in_cols_B(idx) <= std_logic_vector(to_unsigned(matrix_B(1)(idx),8));
         	end loop;--
            next_state <= StoreAt2;--ReadAt11;
      when StoreAt2 =>
         	address<=(others=>2);

         	for idx in in_row_A'range loop --'
         		in_row_A(idx) <= std_logic_vector(to_unsigned(matrix_A(idx)(2),8));
         	end loop;--
         	
         	for idx in in_cols_B'range loop --'
         		in_cols_B(idx) <= std_logic_vector(to_unsigned(matrix_B(2)(idx),8));
         	end loop;--
         	next_state <= StoreAt3;
      when StoreAt3 =>
         	address<=(others=>3);

         	for idx in in_row_A'range loop --'
         		in_row_A(idx) <= std_logic_vector(to_unsigned(matrix_A(idx)(3),8));
         	end loop;--

         	for idx in in_cols_B'range loop --'
         		in_cols_B(idx) <= std_logic_vector(to_unsigned(matrix_B(3)(idx),8));
         	end loop;--

         	next_state <= ReadAtNone;
      
--Above 0 states should read data from PC and stored them at different addresses
--The buffer
      when ReadAtNone =>
         	address <= (others=>0); 
         	--Done in OUTPUTDECODER-- Should turn off write enable. otherwise it would overwrite the values?!
            next_state <= ReadAt10;
            
--Below 0 states will be accessing them
	  when ReadAt10 =>
	  	-- OUTPUT DECODER WILL HAVE READ AT ADDRESS 0 (previous state's)
	   		address <= (others=>1);
	      	next_state <= ReadAt11;
	  when ReadAt11 =>
         	address <= (others=>2); 
            next_state <= ReadAt12;
	  when ReadAt12 =>
	   		address <= (others=>3);
	      	next_state <= ReadAt13;
	  when ReadAt13 =>
	   		address <= (others=>5);--Not read/written in halt
	      	next_state <= Halt1;
      when Halt1 =>
      		next_state<=Halt1;
      when others =>
         next_state <= StoreAt1;
   end case;   

end process;
