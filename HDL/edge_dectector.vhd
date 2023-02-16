library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity front_edge_detector is
port (
  i_clk                       : in  std_logic;
  i_reset_n                      : in  std_logic;
  i_input                     : in  std_logic;
  o_pulse                     : out std_logic);
end front_edge_detector;
architecture rtl of front_edge_detector is
signal r0_input                           : std_logic;
signal r1_input                           : std_logic;
begin
p_rising_edge_detector : process(i_clk,i_reset_n)
begin
  if(i_reset_n='0') then
    r0_input           <= '0';
    r1_input           <= '0';
  elsif(rising_edge(i_clk)) then
    r0_input           <= i_input;
    r1_input           <= r0_input;
  end if;
end process p_rising_edge_detector;
o_pulse            <= not r1_input and r0_input;
end rtl;