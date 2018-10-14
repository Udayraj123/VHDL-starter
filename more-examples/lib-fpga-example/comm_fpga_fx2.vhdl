--
-- Copyright (C) 2009-2012 Chris McClelland
--
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU Lesser General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
-- GNU Lesser General Public License for more details.
--
-- You should have received a copy of the GNU Lesser General Public License
-- along with this program. If not, see .
--
-- Additional changes/comments by Cristinel Ababei, 2012
-- This entity is responsible with facillitating communication between your
-- application on the FPGA and the host computer connected to your Atlys board
-- via the Cypress USB controller (referred to as FX2 in the comments).
-- This must be instantiated as a component in each of your designs that require
-- communication with the host.
--
LIBRARY ieee;

USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

-- CommFPGA module
ENTITY comm_fpga_fx2 IS
	PORT (
		-- FX2 interface -----------------------------------------------------------------------------
		fx2Clk_in : IN std_logic; -- 48MHz clock from FX2
		fx2FifoSel_out : OUT std_logic; -- select FIFO: '0' for EP6OUT, '1' for EP8IN
		fx2Data_io : INOUT std_logic_vector(7 DOWNTO 0); -- 8-bit data to/from FX2

		-- When EP6OUT selected:
		fx2Read_out : OUT std_logic; -- asserted (active-low) when reading from FX2
		fx2GotData_in : IN std_logic; -- asserted (active-high) when FX2 has data for us

		-- When EP8IN selected:
		fx2Write_out : OUT std_logic; -- asserted (active-low) when writing to FX2
		fx2GotRoom_in : IN std_logic; -- asserted (active-high) when FX2 has room for more data from us
		fx2PktEnd_out : OUT std_logic; -- asserted (active-low) when a host read needs to be committed early

		-- Channel read/write interface --------------------------------------------------------------
		chanAddr_out : OUT std_logic_vector(6 DOWNTO 0); -- the selected channel (0-127)

		-- Host >> FPGA pipe:
		h2fData_out : OUT std_logic_vector(7 DOWNTO 0); -- data lines used when the host writes to a channel
		h2fValid_out : OUT std_logic; -- '1' means "on the next clock rising edge, please accept the data on h2fData_out"
		h2fReady_in : IN std_logic; -- channel logic can drive this low to say "I'm not ready for more data yet"

		-- Host << FPGA pipe:
		f2hData_in : IN std_logic_vector(7 DOWNTO 0); -- data lines used when the host reads from a channel
		f2hValid_in : IN std_logic; -- channel logic can drive this low to say "I don't have data ready for you"
		f2hReady_out : OUT std_logic -- '1' means "on the next clock rising edge, put your next byte of data on f2hData_in"
	);
END comm_fpga_fx2;

ARCHITECTURE behavioural OF comm_fpga_fx2 IS
	-- The read/write nomenclature here refers to the FPGA reading and writing the FX2 FIFOs, and is therefore
	-- of the opposite sense to the host's read and write. So host reads are fulfilled in the S_WRITE state, and
	-- vice-versa. Apologies for the confusion.
	TYPE StateType IS (
	S_IDLE, -- wait for requst from host & register chanAddr & isWrite
	S_GET_COUNT0, -- register most significant byte of message length
	S_GET_COUNT1, -- register next byte of message length
	S_GET_COUNT2, -- register next byte of message length
	S_GET_COUNT3, -- register least significant byte of message length
	S_BEGIN_WRITE, -- switch direction of FX2 data bus
	S_WRITE, -- write data to FX2 EP8IN FIFO, one byte at a time
	S_END_WRITE_ALIGNED, -- end an aligned write (do not assert fx2PktEnd_out)
	S_END_WRITE_NONALIGNED, -- end a nonaligned write (assert fx2PktEnd_out)
	S_READ -- read data from FX2 EP6OUT FIFO, one byte at a time
	);
	CONSTANT FIFO_READ : std_logic_vector(1 DOWNTO 0) := "10"; -- assert fx2Read_out (active-low)
	CONSTANT FIFO_WRITE : std_logic_vector(1 DOWNTO 0) := "01"; -- assert fx2Write_out (active-low)
	CONSTANT FIFO_NOP : std_logic_vector(1 DOWNTO 0) := "11"; -- assert nothing
	CONSTANT OUT_FIFO : std_logic := '0'; -- EP6OUT
	CONSTANT IN_FIFO : std_logic := '1'; -- EP8IN
	SIGNAL state, state_next : StateType := S_IDLE;
	SIGNAL fifoOp : std_logic_vector(1 DOWNTO 0) := FIFO_NOP;
	SIGNAL count, count_next : unsigned(31 DOWNTO 0) := (OTHERS => '0'); -- read/write count
		SIGNAL chanAddr, chanAddr_next : std_logic_vector(6 DOWNTO 0) := (OTHERS => '0'); -- channel being accessed (0-127)
			SIGNAL isWrite, isWrite_next : std_logic := '0'; -- is this access is an FX2 FIFO write or a read?
			SIGNAL isAligned, isAligned_next : std_logic := '0'; -- is this FX2 FIFO write block-aligned?
			SIGNAL dataOut : std_logic_vector(7 DOWNTO 0); -- data to be driven on fx2Data_io
			SIGNAL driveBus : std_logic; -- whether or not to drive fx2Data_io
		BEGIN
			-- Infer registers
			PROCESS (fx2Clk_in)
			BEGIN
				IF (rising_edge(fx2Clk_in)) THEN
					state <= state_next;
					count <= count_next;
					chanAddr <= chanAddr_next;
					isWrite <= isWrite_next;
					isAligned <= isAligned_next;
				END IF;
			END PROCESS;

			-- Next state logic
			PROCESS (
			state, fx2Data_io, fx2GotData_in, fx2GotRoom_in, count, isAligned, isWrite, chanAddr, 
			f2hData_in, f2hValid_in, h2fReady_in)
				BEGIN
					state_next <= state;
					count_next <= count;
					chanAddr_next <= chanAddr;
					isWrite_next <= isWrite; -- is the FPGA writing to the FX2?
					isAligned_next <= isAligned; -- does this FIFO write end on a block (512-byte) boundary?
					dataOut <= (OTHERS => '0');
					driveBus <= '0'; -- don't drive fx2Data_io by default
					fifoOp <= FIFO_READ; -- read the FX2 FIFO by default
					fx2PktEnd_out <= '1'; -- inactive: FPGA does not commit a short packet.
					f2hReady_out <= '0';
					h2fValid_out <= '0';

					CASE state IS
						WHEN S_GET_COUNT0 => 
							fx2FifoSel_out <= OUT_FIFO; -- Reading from FX2
							IF (fx2GotData_in = '1') THEN
								-- The count high word high byte will be available on the next clock edge.
								count_next(31 DOWNTO 24) <= unsigned(fx2Data_io);
								state_next <= S_GET_COUNT1;
							END IF;

						WHEN S_GET_COUNT1 => 
							fx2FifoSel_out <= OUT_FIFO; -- Reading from FX2
							IF (fx2GotData_in = '1') THEN
								-- The count high word low byte will be available on the next clock edge.
								count_next(23 DOWNTO 16) <= unsigned(fx2Data_io);
								state_next <= S_GET_COUNT2;
							END IF;

						WHEN S_GET_COUNT2 => 
							fx2FifoSel_out <= OUT_FIFO; -- Reading from FX2
							IF (fx2GotData_in = '1') THEN
								-- The count low word high byte will be available on the next clock edge.
								count_next(15 DOWNTO 8) <= unsigned(fx2Data_io);
								state_next <= S_GET_COUNT3;
							END IF;

						WHEN S_GET_COUNT3 => 
							fx2FifoSel_out <= OUT_FIFO; -- Reading from FX2
							IF (fx2GotData_in = '1') THEN
								-- The count low word low byte will be available on the next clock edge.
								count_next(7 DOWNTO 0) <= unsigned(fx2Data_io);
								IF (isWrite = '1') THEN
									state_next <= S_BEGIN_WRITE;
								ELSE
									state_next <= S_READ;
								END IF;
							END IF;

						WHEN S_BEGIN_WRITE => 
							fx2FifoSel_out <= IN_FIFO; -- Writing to FX2
							fifoOp <= FIFO_NOP;
							IF (count(8 DOWNTO 0) = "000000000") THEN
								isAligned_next <= '1';
							ELSE
								isAligned_next <= '0';
							END IF;
							state_next <= S_WRITE;

						WHEN S_WRITE => 
							fx2FifoSel_out <= IN_FIFO; -- Writing to FX2
							IF (fx2GotRoom_in = '1') THEN
								f2hReady_out <= '1';
							END IF;
							IF (fx2GotRoom_in = '1' AND f2hValid_in = '1') THEN
								fifoOp <= FIFO_WRITE;
								dataOut <= f2hData_in;
								driveBus <= '1';
								count_next <= count - 1;
								IF (count = 1) THEN
									IF (isAligned = '1') THEN
										state_next <= S_END_WRITE_ALIGNED; -- don't assert fx2PktEnd
									ELSE
										state_next <= S_END_WRITE_NONALIGNED; -- assert fx2PktEnd to commit small packet
									END IF;
								END IF;
							ELSE
								fifoOp <= FIFO_NOP;
							END IF;

						WHEN S_END_WRITE_ALIGNED => 
							fx2FifoSel_out <= IN_FIFO; -- Writing to FX2
							fifoOp <= FIFO_NOP;
							state_next <= S_IDLE;

						WHEN S_END_WRITE_NONALIGNED => 
							fx2FifoSel_out <= IN_FIFO; -- Writing to FX2
							fifoOp <= FIFO_NOP;
							fx2PktEnd_out <= '0'; -- Active: FPGA commits the packet early.
							state_next <= S_IDLE;

						WHEN S_READ => 
							fx2FifoSel_out <= OUT_FIFO; -- Reading from FX2
							IF (fx2GotData_in = '1' AND h2fReady_in = '1') THEN
								-- A data byte will be available on the next clock edge
								h2fValid_out <= '1';
								count_next <= count - 1;
								IF (count = 1) THEN
									state_next <= S_IDLE;
								END IF;
							ELSE
								fifoOp <= FIFO_NOP;
							END IF;

							-- S_IDLE and others
						WHEN OTHERS => 
							fx2FifoSel_out <= OUT_FIFO; -- Reading from FX2
							IF (fx2GotData_in = '1') THEN
								-- The read/write flag and a seven-bit channel address will be available on the
								-- next clock edge.
								chanAddr_next <= fx2Data_io(6 DOWNTO 0);
								isWrite_next <= fx2Data_io(7);
								state_next <= S_GET_COUNT0;
							END IF;
					END CASE;
				END PROCESS;

				-- Drive stateless signals
				fx2Read_out <= fifoOp(0);
				fx2Write_out <= fifoOp(1);
				chanAddr_out <= chanAddr;
				h2fData_out <= fx2Data_io;
				fx2Data_io <= dataOut WHEN driveBus = '1' ELSE (OTHERS => 'Z');
END behavioural;