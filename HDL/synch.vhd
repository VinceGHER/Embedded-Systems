library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity synch is
   port(
		clk					: in std_logic;
      nReset				: in std_logic;
		
		input					: in std_logic;
		enable				: in std_logic;
		output				: out std_logic
	);
end entity synch;

architecture synch of synch is

   signal synch_signal : std_logic := '0';

begin

	output <= synch_signal;
	
	process(clk, nReset, enable)
	begin
		if rising_edge(clk) then
			if (nReset = '0') then
				synch_signal <= '0';
			elsif (enable = '1') then
				synch_signal <= input;
			else
				synch_signal <= synch_signal;
			end if;
		end if;
	end process;

end;
