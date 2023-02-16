
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity Camera_Controller is 
	port(
		clk : in std_logic;
		reset_n : in std_logic;

	 AM_burst_count	:out			std_logic_vector(31 downto 0);
	 AM_byteEnable :out					std_logic_vector(3 downto 0);
	 AM_write_data	:out				std_logic_vector(31 downto 0);
	 AM_write		:out			 std_logic;
	 AM_wait_request	:in				 std_logic;
	 AM_address	:out				std_logic_vector(31 downto 0);
		

		-- Internal interface (i.e. Avalon slave).
	 AS_address :in std_logic_vector(1 downto 0);
	 AS_write :in std_logic;
	 AS_read :in std_logic;
	 AS_writedata :in std_logic_vector(31 downto 0);
	 AS_readdata :out std_logic_vector(31 downto 0);
	

	 CM_PIXCLK :in std_logic;
	 CM_FVAL :in std_logic;
	 CM_LVAL :in std_logic;
	 CM_CAM_DATA:in std_logic_vector(11 downto 0)
	);
end Camera_Controller;

architecture comp of Camera_Controller is
	signal cam_addr : std_logic_vector(31 downto 0);
	signal cam_length : std_logic_vector(31 downto 0);
	signal cam_start : std_logic;
	signal cam_status: std_logic;

	signal rdData_camera					: std_logic_vector(31 downto 0);
	signal fifoEmpty_camera					: std_logic;
	signal rdFIFO_camera					: std_logic;
begin
-- AS camera controller
AS_camera_interface:  entity work.AS_camera_interface
	port map(
		clk => CLK,
		reset_n => cam_start,
		start => cam_start,
		rd_data => rdData_camera,
		rd_fifo => rdFIFO_camera,
		fifo_empty => fifoEmpty_camera,
		pixclk	=> CM_PIXCLK,
		fval => CM_FVAL,
		lval => CM_LVAL,
		cam_data => CM_CAM_DATA
	);

avalonMaster : entity work.avalonMaster
		port map (
			clk							=> clk,
      			nReset							=> reset_n,
		
			-- Avalon master interface
			burst_count						=> AM_burst_count,
			byteEnable						=> AM_byteEnable,
			write_data						=> AM_write_data,
			write							=> AM_write,
			wait_request						=> AM_wait_request,
			address							=> AM_address,
		
			-- Avalon Slave interface component
			start							=> cam_start,
			status							=> cam_status,
			length							=> cam_length,
			cam_address						=> cam_addr,
		
			-- Camera interface
			rdData_camera						=> rdData_camera,
			fifoEmpty_camera					=> fifoEmpty_camera,
			rdFIFO_camera						=> rdFIFO_camera
		);
-- Avalon slave write to registers.
process(clk, reset_n)
begin
	if reset_n = '0' then
		cam_addr <= (others => '0');
		cam_length <= (others => '0');
		cam_start <= '0';

	elsif rising_edge(clk) then
		if AS_write = '1' then
			case AS_address is

				when "00" => cam_addr <= (AS_writedata);
				when "01" => cam_length <= (AS_writedata);
				when "10" => cam_start <=  AS_writedata(0);			
				when others => null;
			end case;
		end if;
		if cam_status = '1' then
			cam_start <= '0';
		end if;
	end if;
end process;

-- Avalon slave read from registers.
process(clk)
begin
	if rising_edge(clk) then
		AS_readdata <= (others => '0');
		if AS_read = '1' then
			case AS_address is
				when "00" => AS_readdata <= (cam_addr);
				when "01" => AS_readdata <= (cam_length);
				when "10" => AS_readdata(0) <= cam_start;
				when "11" => AS_readdata(0) <= cam_status;
				when others => null;
			end case;
		end if;
	end if;
end process;
end comp;
	
