library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity AS_camera_interface is 
	port(
		clk : in std_logic;
		reset_n : in std_logic;
		
		-- slave interface
		start : in std_logic;
	
		-- Fifo interface
		rd_data : out std_logic_vector(31 downto 0);
		rd_fifo: in std_logic;
		fifo_empty: out std_logic;

		-- Camera inputs
		pixclk: in std_logic;
		fval: in std_logic;
		lval: in std_logic;
		cam_data : in std_logic_vector(11 downto 0)
	);
end AS_camera_interface;

architecture comp of AS_camera_interface is
	signal output_counter_row : std_logic;
	signal condition_column : std_logic;
	signal output_counter_column : std_logic;
	signal condition_row : std_logic;
	signal pixel_clk_invert :std_logic;
	signal pixel_clk_down : std_logic;
	
	signal write_fifo_green : std_logic;
	signal write_fifo_red : std_logic;
	signal write_fifo_blue : std_logic;
	signal write_fifo_global : std_logic;
	signal row_edge_detect: std_logic;
	signal colum_edge_detect: std_logic;
	signal merge_data: std_logic_vector(31 downto 0);
	signal reset : std_logic;
	signal reset_column : std_logic;
	signal wait_for_new_frame: std_logic;
	signal shutdown : std_logic;
	signal start_getting:std_logic;
	
begin
start_getting <= start and wait_for_new_frame and not shutdown;
reset <= not reset_n or not fval;
reset_column <= reset_n and ( fval and lval );
pixel_clk_invert <= not pixclk;
condition_row <= start_getting and lval;
condition_column <= start_getting and lval and pixclk;
write_fifo_green <= start_getting and pixel_clk_down and lval and output_counter_column and output_counter_row;
write_fifo_red <= start_getting and pixel_clk_down and lval and not output_counter_column and output_counter_row;
write_fifo_blue <= start_getting and pixel_clk_down and lval and output_counter_column and not output_counter_row;
write_fifo_global <= start_getting and pixel_clk_down and lval and not output_counter_column and not output_counter_row;

process(clk,reset_n, fval)
begin 
	if reset_n = '0' then
		shutdown <= '0';
		wait_for_new_frame <= '0';
	elsif rising_edge(fval) then
		if wait_for_new_frame = '0' then
			wait_for_new_frame <= '1';
		end if;
		if wait_for_new_frame = '1' then
			shutdown <= '1';
		end if;
	end if;
end process;
fifo_green : entity work.fifo_color port map (
		aclr	 => reset,
		clock	 => clk,
		data	 => cam_data(11 downto 4),
		rdreq	 => write_fifo_global,
		wrreq	 => write_fifo_green,
		empty	 => open,
		full	 => open,
		q	 => merge_data(15 downto 8),
		usedw	 => open
	);




fifo_red : entity work.fifo_color port map (
		aclr	 => reset,
		clock	 => clk,
		data	 => cam_data(11 downto 4),
		rdreq	 => write_fifo_global,
		wrreq	 => write_fifo_red,
		empty	 => open,
		full	 => open,
		q	 => merge_data(31 downto 24),
		usedw	 => open
	);
fifo_blue : entity work.fifo_color port map (
		aclr	 => reset,
		clock	 => clk,
		data	 => cam_data(11 downto 4),
		rdreq	 => write_fifo_global,
		wrreq	 => write_fifo_blue,
		empty	 => open,
		full	 => open,
		q	 => merge_data(7 downto 0),
		usedw	 => open
	);
merge_data(23 downto 16) <= cam_data(11 downto 4);
fifo_global:  entity work.fifo5 port map (
		aclr	 => reset,
		clock	 => clk,
		data	 => merge_data,
		rdreq	 => rd_fifo,
		wrreq	 => write_fifo_global,
		almost_empty	 => open,
		empty	 => fifo_empty,
		full	 => open,
		q	 => rd_data,
		usedw	 => open
	);

pixel_edge_dector : entity work.front_edge_detector
	port map(
		i_clk => clk,
		i_reset_n => reset_n,
		i_input => pixel_clk_invert,
		o_pulse => pixel_clk_down
	);

row_edge_dector : entity work.front_edge_detector
	port map(
		i_clk => clk,
		i_reset_n => reset_n,
		i_input => condition_row,
		o_pulse => row_edge_detect
	);
column_edge_dector : entity work.front_edge_detector
	port map(
		i_clk => clk,
		i_reset_n => reset_n,
		i_input => condition_column,
		o_pulse => colum_edge_detect
	);
row_counter : entity work.AS_counter
	port map(
		clk => clk,
		reset_n => reset_n,
		enable => row_edge_detect,
		output => output_counter_row
	);
column_counter : entity work.AS_counter
	port map(
		clk => clk,
		reset_n => reset_column,
		enable => colum_edge_detect,
		output => output_counter_column
	);
end comp;
