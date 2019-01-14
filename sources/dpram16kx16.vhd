----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    18:34:02 02/26/2016 
-- Design Name: 
-- Module Name:    dpram16kx16 - Behavioral 
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
use IEEE. std_logic_arith.all;
use IEEE. std_logic_unsigned.all;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;
-- Para los cambios en la RAM
--https://danstrother.com/2010/09/11/inferring-rams-in-fpgas/

entity dpram16kx16 is
    Port ( clka : in  STD_LOGIC;
           ena : in  STD_LOGIC;
           wea : in  STD_LOGIC_VECTOR (0 downto 0);
           addra : in  STD_LOGIC_VECTOR (13 downto 0);
           dina : in  STD_LOGIC_VECTOR (15 downto 0);
           douta : out  STD_LOGIC_VECTOR (15 downto 0);
           clkb : in  STD_LOGIC;
           enb : in  STD_LOGIC;
           web : in  STD_LOGIC_VECTOR (0 downto 0);
           addrb : in  STD_LOGIC_VECTOR (13 downto 0);
           dinb : in  STD_LOGIC_VECTOR (15 downto 0);
           doutb : out  STD_LOGIC_VECTOR (15 downto 0));
end dpram16kx16;

architecture Behavioral of dpram16kx16 is
type ram_type is array (16383 downto 0) of std_logic_vector (15 downto 0);
    --signal RAM: ram_type;			--ok en implementacion
	 shared variable RAM : ram_type;	--Porque da error en la simulacion.
begin

process (clka)
begin
   if (clka'event and clka = '1') then
      if (ena = '1') then
         if (wea = "1") then
            --RAM(conv_integer(addra)) <= dina;	-- OK en implementcion
				RAM(conv_integer(addra)) := dina;	--para simulacion
         end if;
         douta <= RAM(conv_integer(addra));
      end if;
   end if;
end process;

process (clkb)
begin
   if (clkb'event and clkb = '1') then
      if (enb = '1') then
            if (web = "1") then
                --RAM(conv_integer(addrb)) <= dinb;	--OK en implementacon
					 RAM(conv_integer(addrb)) := dinb;	--Para simuilacion
            end if;
         doutb <= RAM(conv_integer(addrb));
      end if;
   end if;
end process;
end Behavioral;
