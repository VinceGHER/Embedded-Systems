library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity pixelCompressor is
   port(
		clk					: in std_logic;
      nReset				: in std_logic;
		
		rdData				: in std_logic_vector(31 downto 0);
		Fifo_empty			: in std_logic;
		rdFifo				: out std_logic;
		
		wrData				: out std_logic_vector(15 downto 0);
		Fifo_Almost_Full	: in std_logic;
		wrFifo				: out std_logic
	);
end entity pixelCompressor;

architecture compression of pixelCompressor is


	signal green			: std_logic_vector(8 downto 0);

begin
	
	wrData(15 downto 11) <= rdData(31 downto 27); 
	wrData(4 downto 0) 	<= rdData(7 downto 3); 
	green						<= std_logic_vector(unsigned('0' & rdData(23 downto 16)) + unsigned('0' & rdData(15 downto 8)));
	wrData(10 downto 5) 	<= green(8 downto 3);

	rdFifo <= not(Fifo_empty or Fifo_Almost_Full);
	wrFifo <= not(Fifo_empty or Fifo_Almost_Full);


end;
