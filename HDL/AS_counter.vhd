library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity AS_counter is 
	port(
		clk : in std_logic;
		reset_n : in std_logic;

		-- Internal interface (i.e. Avalon slave).
		

		enable : in std_logic;
		output: out std_logic
	);
end AS_counter;

architecture comp of AS_counter is
	signal counter: std_logic;
begin

process(clk, enable, counter,reset_n)
begin
	if reset_n = '0' then
		output <= '0';
		counter <= '0';
	elsif falling_edge(clk) and enable = '1' then
		counter <= counter xor '1'; 
	end if;
	output <= counter;
end process;

end comp;
		