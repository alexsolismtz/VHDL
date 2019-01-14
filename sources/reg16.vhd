----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    22:51:15 02/04/2017 
-- Design Name: 
-- Module Name:    reg16 - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity reg16 is
    Port ( clk : in  STD_LOGIC;
           d_i : in  STD_LOGIC_VECTOR (15 downto 0);
           d_o : out  STD_LOGIC_VECTOR (15 downto 0));
end reg16;

architecture Behavioral of reg16 is

begin
process (clk)
begin
	if(rising_edge(clk)) then
		d_o <= d_i;
	end if;
end process;

end Behavioral;

