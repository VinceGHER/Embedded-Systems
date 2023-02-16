library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity state is
   port(
		clk					: in std_logic;
      nReset				: in std_logic;
		
		set					: in std_logic;
		reset					: in std_logic;
		state					: out std_logic
	);
end entity state;

architecture state of state is

   signal state_signal : std_logic := '0';

begin

	state <= state_signal;
	
	process(clk, nReset)
	begin
		if rising_edge(clk) then
			if (nReset = '0') then
				state_signal <= '0';
			elsif (set = '1' and state_signal = '0') then
				state_signal <= '1';
			elsif (reset = '1' and state_signal = '1') then
				state_signal <= '0';
			else
				state_signal <= state_signal;
			end if;
		end if;
	end process;

end;
