library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity tb_as is
end tb_as;

architecture test_v3 of tb_as is
	constant CLK_PERIOD : time := 20 ns;
	-- Signal used to end simulator when we finished submitting our test cases
	signal sim_finished : boolean := false;

	-- adder_sequential PORTS
	signal CLK, SLOW_CLK : std_logic;
	signal RST,RST_invert : std_logic;
 
	 signal AM_burst_count	:			std_logic_vector(31 downto 0);
	 signal AM_byteEnable :					std_logic_vector(3 downto 0);
	 signal AM_write_data	:				std_logic_vector(31 downto 0);
	 signal AM_write		:			 std_logic;
	 signal AM_wait_request	:				 std_logic;
	 signal AM_address	:				std_logic_vector(31 downto 0);
		

		-- Internal interface (i.e. Avalon slave).
	 signal AS_address : std_logic_vector(1 downto 0);
	 signal AS_write : std_logic;
	 signal AS_read : std_logic;
	 signal AS_writedata : std_logic_vector(31 downto 0);
	 signal AS_readdata : std_logic_vector(31 downto 0);


	signal CM_address : std_logic_vector(2 downto 0);
	signal CM_write : std_logic;
	signal CM_read : std_logic;
	signal CM_writedata : std_logic_vector(31 downto 0);
	signal CM_readdata : std_logic_vector(31 downto 0);
	

	 signal CM_FVAL : std_logic;
	 signal CM_LVAL : std_logic;
	 signal CM_CAM_DATA: std_logic_vector(11 downto 0);
	

begin
RST_invert <= not RST;
-- Instantiate DUT
Camera_Controller : entity work.Camera_Controller
	port map(
		clk => CLK,
		reset_n => RST,

	 AM_burst_count	=> AM_burst_count,
	 AM_byteEnable => AM_byteEnable,
	 AM_write_data	=> AM_write_data,
	 AM_write	=>AM_write,
	 AM_wait_request => AM_wait_request,
	 AM_address => AM_address,
		

		-- Internal interface (i.e. Avalon slave).
	 AS_address =>AS_address,
	 AS_write =>AS_write,
	 AS_read =>AS_read,
	 AS_writedata => AS_writedata,
	 AS_readdata =>AS_readdata,
	

	 CM_PIXCLK =>SLOW_CLK,
	 CM_FVAL =>CM_FVAL,
	 CM_LVAL =>CM_LVAL,
	 CM_CAM_DATA=>CM_CAM_DATA
	
	);



camera: entity work.cmos_sensor_output_generator 
	generic map (	
		PIX_DEPTH=>12, 
		MAX_WIDTH=>1000,
		MAX_HEIGHT=>1000
	)
	port map(
		clk => SLOW_CLK,
		reset => RST_invert,
		addr => CM_address,
		read => CM_read,
		write => CM_write,
		rddata => open,
		wrdata=> CM_writedata,
		frame_valid =>CM_FVAL,
		line_valid =>CM_LVAL,
		data => CM_CAM_DATA
	);

-- Generate CLK signal
clk_generation : process
begin
	if not sim_finished then
		
		SLOW_CLK <= '1';
		for i in 1 to 4 loop
			CLK <= '1';
			wait for CLK_PERIOD / 2;
			CLK <= '0';
			wait for CLK_PERIOD / 2;
		end loop;
		SLOW_CLK <= '0';
		for i in 1 to 4 loop
			CLK <= '1';
			wait for CLK_PERIOD / 2;
			CLK <= '0';
			wait for CLK_PERIOD / 2;
		end loop;
	else
		wait;
	end if;
end process clk_generation;


-- Test adder_sequential
simulation : process

procedure async_reset is
begin
	wait until rising_edge(CLK);
	AM_wait_request<='0';
	wait for CLK_PERIOD /2;
	RST <= '0';
	wait for CLK_PERIOD*10;
	RST <= '1';
	wait for CLK_PERIOD*5;
	
end procedure async_reset;


procedure CM_write_data(constant address2 : in std_logic_vector(2 downto 0); 
                     constant values : in natural) is 
begin
wait until rising_edge(SLOW_CLK);
CM_address <= address2;
CM_write <= '1';
CM_writedata <= std_logic_vector(to_unsigned(values, CM_writedata'length));
wait until rising_edge(SLOW_CLK);
CM_write <= '0';
end procedure CM_write_data;

procedure AS_write_data(constant address2 : in std_logic_vector(1 downto 0); 
                     constant values : in natural) is 
begin
wait until rising_edge(CLK);
AS_address <= address2;
AS_write <= '1';
AS_writedata <= std_logic_vector(to_unsigned(values, AS_writedata'length));
wait until rising_edge(CLK);
AS_write <= '0';
end procedure AS_write_data;


procedure test is
begin
-- Our circuit is sensitive to the rising edge of the CLK, so we
wait until rising_edge(CLK);

CM_write_data("110",0);
CM_write_data("000",64);
CM_write_data("001",12);


AS_write_data("00",0);
AS_write_data("01",10240);
AS_write_data("10",1);

wait for CLK_PERIOD*3;

CM_write_data("110",1);


wait;
end procedure test;

begin
wait for CLK_PERIOD;
-- Reset the circuit.
async_reset;
-- Check test vectors against expected outputs
test;
-- Instruct "clk_generation" process to halt execution.
sim_finished <= true;
-- Make this process wait indefinitely (it will never re-execute from
-- its beginning again).
wait;
end process simulation;
end architecture test_v3;
