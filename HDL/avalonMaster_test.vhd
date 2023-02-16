library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity avalonMaster_test is

end entity avalonMaster_test;

architecture simulation1 of avalonMaster_test is

	signal clk 						: std_logic := '1';
	signal nReset						: std_logic;

	signal burst_count					: std_logic_vector(31 downto 0);
	signal byteEnable					: std_logic_vector(3 downto 0);
	signal write_data					: std_logic_vector(31 downto 0);
	signal write						: std_logic;
	signal wait_request					: std_logic;
	signal address						: std_logic_vector(31 downto 0);
		
	-- Avalon Slave interface component
	signal start						: std_logic;
	signal status						: std_logic;
	signal length						: std_logic_vector(31 downto 0);
	signal cam_address					: std_logic_vector(31 downto 0);
		
	-- Camera interface
	signal rdData_camera					: std_logic_vector(31 downto 0);
	signal fifoEmpty_camera					: std_logic;
	signal rdFIFO_camera					: std_logic;
	
	component avalonMaster 
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
	end component avalonMaster;

	
	
begin

	clk <= not clk after 20 ns;
	nReset <= '0', '1' after 50 ns;


	u0 : component avalonMaster
		port map (
			clk							=> clk,
      			nReset							=> nReset,
		
			-- Avalon master interface
			burst_count						=> burst_count,
			byteEnable						=> byteEnable,
			write_data						=> write_data,
			write							=> write,
			wait_request						=> wait_request,
			address							=> address,
		
			-- Avalon Slave interface component
			start							=> start,
			status							=> status,
			length							=> length,
			cam_address						=> cam_address,
		
			-- Camera interface
			rdData_camera						=> rdData_camera,
			fifoEmpty_camera					=> fifoEmpty_camera,
			rdFIFO_camera						=> rdFIFO_camera
		);
		
	
	FIFO : process is
	begin
		start <= '0';
		fifoEmpty_camera <= '1';
		wait_request <= '0';
		wait for 50 ns;
		wait_request <= '0';
		start <= '1';
		length <= "00000000000000000000000100000000";
		cam_address <= "00000000001100000000000001000000";
		fifoEmpty_camera <= '0';
		wait for 5 ns;
		while fifoEmpty_camera = '0' loop
			rdData_camera <= "11110000111100001111000000001111";
			wait until clk'event and clk = '1' and rdFIFO_camera = '1';
			rdData_camera <= "11110000111100001111000000001111";
			wait for 5 ns;
			if write = '1' then
				wait_request <= '1';
				wait for 50 ns;
				wait_request <= '0';
			end if;
		end loop;
	end process;



end architecture simulation1;
