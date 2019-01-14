----------------------------------------------------------------------------------
-- Company: 
-- Engineer: Gerardo Aranguren
-- 
-- Create Date:   14/marz/2014 
-- Design Name: 
-- Module Name:    CalculoTT - Behavioral 
-- Project Name:  Turbosens
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
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.std_logic_arith.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

-- Algoritmo
--
-- A partir de de la seÃ±al de entrada V2 se detreminan los mÃ­nimos y se generan las seÃ±ales de TipTiming (TT) y flanco de cambio del TipTiming (changeTT).
--
-- En primer lugar se selecciona un mÃ­nimo provisional de la seÃ±al de entrada (V2) y lo almacena en "minaux". 
-- Cuando la nueva seÃ±al de entrada V2 supera en mÃ¡s de "limiter" se verifica el valor mÃ­nimo almacenado y se convierte en mÃ­nimo real.
-- AdemÃ¡s se produce "changeTTin" y en el siguiente pulso "changeTT".
-- Entre dos mÃ­nimos reales funciona un contador que determina el Tip Timinig.
-- El contador de TipTiming se forma con "counter" - "contaux". 
-- "Counter" cuenta desde el anterior mÃ­nimo real hasta el mÃ­nimo verificado.
-- "contaux" calcula el exceso de cuenta, desde el mÃ­nimo provisional hasta el mÃ­nimo verificado.
-- La diferncia de estos dos valores es el TipTiming real.
-- Si "contaux" es mayor de 1/2 del contador anterior real (ttaux) se produce una verificaciÃ³n de mÃ­nimo.
-- DespuÃ©s de un mÃ­nimo real durante 3/4 del counter real (decoun)no se pueden detectar mÃ­nimos para evitar falsos mÃ­nimos.

--				v2. Se elimina la posibilidad de un modo... se harÃ¡ fuera del core.

entity CalculoTT is
    Port ( v2 : 		in  STD_LOGIC_VECTOR (15 downto 0);				-- SeÃ±al mayor del sensor Ã³ptico
           clk : 		in  STD_LOGIC;											-- Reloj del sistema
           reset : 	in  STD_LOGIC;			  								-- Reset general
		   limitem : in  STD_LOGIC_VECTOR (15 downto 0);				-- Mayor diferencia entre V2 y minimo acumulado para aceptar, modo entrada externa
		   limitTime : in STD_LOGIC_VECTOR (15 downto 0);             --Tiempo sin buscar alabe
           --modo : 	in  STD_LOGIC;											-- Modo = 1 => modo manual, Modo = 0 => modo automÃ¡tico 
			  tt : 		out  STD_LOGIC_VECTOR (15 downto 0) := (others => '0');			-- Pulsos entre mÃ­nimos
			  
			  min : 		out  STD_LOGIC_VECTOR (15 downto 0):= (others => '1');			-- Valor del mÃ­nimo detectado
           change_tt_V: out	STD_LOGIC := '0';			--Detección por cambio por tensión muy por encima del último minimo
			  change_tt_T: out STD_LOGIC := '0';				--Detección por tiempo por debajo del 1/4 tt
			  changett : out  STD_LOGIC := '0');
end CalculoTT;

architecture Behavioral of CalculoTT is

signal limiter : STD_LOGIC_VECTOR (15 downto 0) := "0000000000000000"; 	-- Límite real
signal minaux : STD_LOGIC_VECTOR (15 downto 0) := "0000000000000000"; 	-- Mínimo auxiliar
signal counter : STD_LOGIC_VECTOR (15 downto 0) := "0000000000000000"; 	-- Contador de Tip-Timing
signal decoun : STD_LOGIC_VECTOR (15 downto 0) := "0000000000000000"; 	-- Decontador
signal contaux : STD_LOGIC_VECTOR (15 downto 0) := "0000000000000000"; 	-- Exceso de contador
signal contreal : STD_LOGIC_VECTOR (15 downto 0) := "0000000000000000"; -- Contador real
signal estado : STD_LOGIC;																-- 0 detección de mínimo, 1 no detección de mínimo
signal changeTTin : STD_LOGIC;	
signal change_tt_Tin : STD_LOGIC;	
signal change_tt_Vin : STD_LOGIC;	
--signal ttin : STD_LOGIC_VECTOR (15 downto 0) := "0000000000000000"; 
signal ttaux : STD_LOGIC_VECTOR (15 downto 0) := "0000000000000000"; 				-- 

--constant limitea : STD_LOGIC_VECTOR (15 downto 0) := x"1D00"; 	-- Límite automático 1D00 
constant limitea : STD_LOGIC_VECTOR (15 downto 0) := x"01F4"; 	-- Límite automático 1D00 


constant incioIdle: STD_LOGIC_VECTOR (15 downto 0) := x"017F";
signal resta:std_logic_vector(15 downto 0) := x"0000";
begin

detection:process(clk, v2, reset)

begin

	

--	if	modo = '0' then
		limiter <= limitea;
--	else
--		limiter <= limitem;	
--	end if;

--	contreal <= counter - contaux;
	resta <= v2 - minaux ;
	if clk'event and clk = '1' then
		if	reset = '1' then
				estado <= '1';
				minaux <= "1111111111111111";
				counter <= "0000000000000000";
				
				decoun <= incioIdle; 	--"0000000000111111"; 
				contaux <= "0000000000000000";
	--			ttin <= "1111111111111111";
				ttaux <= incioIdle;	--"0000000000111111";
				tt <= "0000000000000000";
				change_tt_Vin <= '0';
				change_tt_Tin <= '0';

		else
			if estado = '0' then							-- Si estado = 0
				if minaux > v2 then						-- ESTADO A, cambio de mínimo
					estado <= '0';
					minaux <= v2;							-- El nuevo dato es el nuevo mínimo
					counter <= counter + '1';				-- Continuar counter TT
					changettin <= '0';						-- No se confirma el mínimo
					decoun <= "0000000000000000";    -- 
					contaux <= "0000000000000000";
	--				ttin <= counter + '1';					-- Valor de Tip timing provisional
	--				min <= V2;								-- Valor del mínimo detectado provisional
					change_tt_Vin <= '0';
					change_tt_Tin <= '0';				
				elsif v2 - minaux < limiter then		-- ESTADO B, sin cambio de mínimo y sin llegar al límite
						if contaux (15 downto 0) < "00" & ttaux (15 downto 2) then
							estado <= '0';
							minaux <= minaux;						-- No hay variación
							counter <= counter + '1';			-- Se incrementa el TT			
							changettin <= '0';						-- No se confirma el mínimo
							decoun <= "0000000000000000";
							contaux <= contaux + '1';
							change_tt_Vin <= '0';
							change_tt_Tin <= '0';
						else										-- ESTADO C, sin cambio de mínimo pero llegada al límite de contador
							estado <= '1';
							minaux <= "1111111111111111";		-- Preset para búsqueda de nuevo mínimo
							counter <= contaux;					-- Reset contador		
							changettin <= '1';						-- Detección de cambio en TipTiming
							decoun (15 downto 0) <= ttaux (15 downto 0) - ttaux (15 downto 2) - contaux (15 downto 0); 
							contaux <= "0000000000000000";	-- Reset contador en exceso
							tt <= contreal + '1';
							ttaux <= contreal;
							min <= minaux;
							change_tt_Vin <= '0';
							change_tt_Tin <= '1';
						end if;
				else										-- ESTADO D, sin cambio de mínimo pero llegada al límite y confirmación del mímino anterior
						estado <= '1';
						minaux <= "1111111111111111";		-- Preset para búsqueda de nuevo mínimo
						counter <= contaux;					-- Reset contador		
						changettin <= '1';					-- Detección de cambio en TipTiming
						decoun (15 downto 0) <= ttaux (15 downto 0) - ttaux (15 downto 2) - contaux (15 downto 0); 
						contaux <= "0000000000000000";	-- Reset contador en exceso
						tt <= contreal + '1';
						ttaux <= contreal;
						min <= minaux;
						change_tt_Vin <= '1';
						change_tt_Tin <= '0';
				end if;
			else												-- Si estado = 1
				if decoun = "0000000000000000" then	-- ESTADO F, fin de cuenta de espera
					estado <= '0';							-- Vuelve a buscar mínimo				
					minaux <= "1111111111111111";		-- Preset para búsqueda de nuevo mínimo
					changettin <= '0';						-- No mínimo
					decoun <= "0000000000000000";
					counter <= counter + '1';			-- Se incrementa el TT
					contaux <= "0000000000000000";
					change_tt_Vin <= '0';
					change_tt_Tin <= '0';
				else											-- ESTADO E, contando espera
					estado <= '1';							-- Continua esperando subida 
					minaux <= "1111111111111111";		-- Preset para búsqueda de nuevo mínimo
					counter <= counter + '1';			-- Se incrementa el TT		
					changettin <= '0';						-- No mínimo
					decoun <= decoun - '1';				-- Descuenta tiempo para cambio de estado
					contaux <= "0000000000000000";
					change_tt_Vin <= '0';
					change_tt_Tin <= '0';
				end if;
			end if;
		end if;	
	-- Salida
	end if;

end process;

Salida: process(clk)
begin
if(rising_edge(clk)) then
	if reset = '1' then
		changett <= '0';
	else
		if changettin = '1' then
			changett <= '1';
		else
			changett <= '0';
		end if;
	end if;
end if;
end process;

SalidaT: process(clk)
begin
if(rising_edge(clk)) then
	if reset = '1' then
		change_tt_T <= '0';
	else
		if change_tt_Tin = '1' then
			change_tt_T <= '1';
		else
			change_tt_T <= '0';
		end if;
	end if;
end if;
end process;
SalidaV: process(clk)
begin
if(rising_edge(clk)) then
	if reset = '1' then
		change_tt_V <= '0';
	else
		if change_tt_Vin = '1' then
			change_tt_V <= '1';
		else
			change_tt_V <= '0';
		end if;
	end if;
end if;
end process;

DeterminarcontadorReal: process(clk)
begin
	if(rising_edge(clk)) then
		if (reset = '1') then
			contreal <= (others => '0');
		else
			contreal <= counter - contaux;
		end if;
	end if;
end process;

end Behavioral;


