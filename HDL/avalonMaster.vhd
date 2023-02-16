library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity avalonMaster is
   port(
		clk							: in std_logic;
      		nReset							: in std_logic;
		
		-- Avalon master interface
		burst_count						: out std_logic_vector(31 downto 0);
		byteEnable						: out std_logic_vector(3 downto 0);
		write_data						: out std_logic_vector(31 downto 0);
		write							: out std_logic;
		wait_request						: in std_logic;
		address							: out std_logic_vector(31 downto 0);
		
		-- Avalon Slave interface component
		start							: in std_logic;
		status							: out std_logic;
		length							: in std_logic_vector(31 downto 0);
		cam_address						: in std_logic_vector(31 downto 0);
		
		-- Camera interface
		rdData_camera						: in std_logic_vector(31 downto 0);
		fifoEmpty_camera					: in std_logic;
		rdFIFO_camera						: out std_logic
		
	);
end entity avalonMaster;

architecture master of avalonMaster is
	
	component counter
		port(
			clk							: in std_logic;
			nReset						: in std_logic;
			increment					: in std_logic;
			count							: out std_logic_vector(31 downto 0)
		);
	end component counter;
	
	component state
		port(
			clk					: in std_logic;
			nReset				: in std_logic;
			
			set					: in std_logic;
			reset					: in std_logic;
			state					: out std_logic
		);
	end component state;
	
	component synch 
		port(
			clk					: in std_logic;
			nReset				: in std_logic;
			
			input					: in std_logic;
			enable				: in std_logic;
			output				: out std_logic
		);
	end component synch;
	
	component compressedPixel_FIFO
		port
		(
			aclr						: IN STD_LOGIC;
			data						: IN STD_LOGIC_VECTOR (15 DOWNTO 0);
			rdclk						: IN STD_LOGIC;
			rdreq						: IN STD_LOGIC;
			wrclk						: IN STD_LOGIC;
			wrreq						: IN STD_LOGIC;
			q						: OUT STD_LOGIC_VECTOR (31 DOWNTO 0);
			rdempty						: OUT STD_LOGIC;
			rdusedw						: OUT STD_LOGIC_VECTOR (6 DOWNTO 0);
			wrfull						: OUT STD_LOGIC;
			wrusedw						: OUT STD_LOGIC_VECTOR (7 DOWNTO 0)
		);
	end component compressedPixel_FIFO;
	
	component pixelCompressor
		port(
			clk							: in std_logic;
			nReset						: in std_logic;
			
			rdData						: in std_logic_vector(31 downto 0);
			Fifo_empty					: in std_logic;
			rdFifo						: out std_logic;
			
			wrData						: out std_logic_vector(15 downto 0);
			Fifo_Almost_Full			: in std_logic;
			wrFifo						: out std_logic
		);
	end component pixelCompressor;

	-- State of the component (1 during a burst write)
	signal state_signal				: std_logic;
	
	-- Signals for master logic
   	signal write_signal 		: std_logic := '0';
	
	-- Useful signal
	signal canStart_signal			: std_logic;
	signal waitForWrite_signal		: std_logic;
	signal reset_signal 			: std_logic;
	signal stateSet_signal			: std_logic;
	signal stateReset_signal			: std_logic;
	
	signal status_signal 			: std_logic := '0';
	signal increment_signal 		: std_logic := '0';
	signal burstDone_signal 		: std_logic := '0';
	signal count_signal 			: std_logic_vector(31 downto 0);
	
	
	-- Signals to obtain FIFO read almost empty signal
	signal fifoPixelMin_signal	: std_logic_vector(6 downto 0);
	signal fifoAlmostEmpty_signal	: std_logic;
	
	-- Signals for interfacing between pixel compressor and internal FIFO
	signal compressed_signal		: std_logic_vector(15 downto 0);
	signal writeFIFO_signal 		: std_logic;
	signal fifoPixelMax_signal		: std_logic_vector(7 downto 0);
	signal fifoAlmostFull_signal	: std_logic;
	
begin

	compressor : pixelCompressor port map(
		clk 							=> clk,
		nReset 							=> nReset,
		
		-- Connected directly to the camera interface
		rdData							=> rdData_camera,
		Fifo_empty						=> fifoEmpty_camera,
		rdFifo							=> rdFIFO_camera,
		
		-- Connected to the internal FIFO
		wrData							=> compressed_signal,
		Fifo_Almost_Full					=> fifoAlmostFull_signal,
		wrFifo							=> writeFIFO_signal
	);

	pixel_FIFO : compressedPixel_FIFO port map(
		aclr								=> "not"(nReset),
		wrclk								=> clk,
		rdclk								=> clk,
		
		-- Signals to interface with Avalon Master
		q								=> write_data,
		rdreq								=> increment_signal,
		rdusedw								=> fifoPixelMin_signal,
		
		-- Signals to interface with pixel compressor
		data								=> compressed_signal,
		wrreq								=> writeFIFO_signal,
		wrusedw								=> fifoPixelMax_signal
	);

	internal_counter : counter port map(
		clk 								=> clk,
		nReset		 						=> reset_signal,
		
		increment 							=> increment_signal,
		count 								=> count_signal
	);
	
	internal_state : state port map(
		clk 								=> clk,
		nReset		 						=> reset_signal,
		
		-- Signals for setting and resetting the state
		set								=> stateSet_signal,
		reset								=> stateReset_signal,
		state								=> state_signal
	);
	
	internal_synch : synch port map(
		clk 								=> clk,
		nReset		 						=> reset_signal,
			
		input								=> state_signal,
		enable								=> "not"(waitForWrite_signal),
		output								=> write_signal
	);
	
	-- Transforming the fifoPixelLeft into a almost empty signal
	fifoAlmostEmpty_signal 				<= '1' when fifoPixelMin_signal(6 downto 5) = "00" else '0';
	fifoAlmostFull_signal				<= '1' when fifoPixelMax_signal(7 downto 2) = "111111" else '0';

	-- Some signals used multiple times
	canStart_signal					<= start and not status_signal;
	waitForWrite_signal				<= write_signal and wait_request;
	reset_signal					<= nReset and start and not status_signal;
	
	-- Set and Reset signal 
	stateSet_signal					<= canStart_signal and not fifoAlmostEmpty_signal and not write_signal;
	stateReset_signal					<= burstDone_signal and increment_signal;
	-- Signal to output for incrementing counter and reading from FIFO
	increment_signal					<= not waitForWrite_signal and state_signal;
	
	
	-- Logic to control write 
	write 								<= write_signal;
	burst_count							<= "00000000000000000000000000100000";
	byteEnable							<= "1111";
	
	-- Comparator for end of burst count cycle
	burstDone_signal					<= '1' when (count_signal and "00000000000000000000000000011111") = "00000000000000000000000000011110" else '0';
	
	-- Adder logic for computing write address
	address								<= std_logic_vector(shift_left(unsigned(count_signal and "11111111111111111111111111100000"), 2) + unsigned(cam_address));
	
	-- Comparator logic for stop condition
	status_signal						<= '1' when shift_right(unsigned(length), 2) - unsigned(count_signal) = "00000000000000000000000000000000" else '0';
	status 							<= status_signal;
end;
