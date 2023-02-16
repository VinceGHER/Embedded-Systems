library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity counter is
   port(
		clk					: in std_logic;
      nReset				: in std_logic;
		
		increment			: in std_logic;
		count					: out std_logic_vector(31 downto 0)
	);
end entity counter;

architecture counter of counter is

   signal counter : unsigned(31 downto 0) := "11111111111111111111111111111111";

begin
	count <= std_logic_vector(counter);
	
	process(clk)
	begin
		if rising_edge(clk) then
			if (nReset = '0') then
				counter <= "11111111111111111111111111111111";
			elsif (increment = '1') then
				counter <= counter + 1;
			else 
				counter <= counter;
			end if;
		end if;
	end process;

end;
