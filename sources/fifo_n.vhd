----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    21:52:48 02/04/2017 
-- Design Name: 
-- Module Name:    fifo_n - Behavioral 
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

entity fifo_n is
	generic (
		N:Integer := 60); --Etpas de la FIFO
    Port ( d_i : in  STD_LOGIC_VECTOR (15 downto 0);
           d_o : out  STD_LOGIC_VECTOR (15 downto 0);
           clk : in  STD_LOGIC);
end fifo_n;

architecture Behavioral of fifo_n is

COMPONENT reg16 is
    Port ( clk : in  STD_LOGIC;
           d_i : in  STD_LOGIC_VECTOR (15 downto 0);
           d_o : out  STD_LOGIC_VECTOR (15 downto 0));
end COMPONENT;
type FIFO_Mem is array (0 to N-1) of STD_LOGIC_VECTOR (15 downto 0);
signal Memory : FIFO_Mem;
begin
X0: reg16 PORT MAP(clk => clk, d_i => d_i, d_o => Memory(0));

Xi: for I in 1 to N-1 generate
      REGX : reg16 port map
        (clk => clk, d_i => Memory(I-1), d_o => Memory(I));
   end generate Xi;
XN: reg16 PORT MAP(clk => clk, d_i => Memory(N-1), d_o => d_o);
--process(clk)
--type FIFO_Mem is array (0 to N-1) of STD_LOGIC_VECTOR (15 downto 0);
--variable Memory : FIFO_Mem;
--begin	
--	d_o <= Memory(N-1);
--	for I in N-2 to 0 loop
--		Memory(I+1) := Memory(I);
--	end loop;
--	Memory(0) := d_i;
--end process;

end Behavioral;

