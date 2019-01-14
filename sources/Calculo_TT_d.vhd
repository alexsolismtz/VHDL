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
--use IEEE.NUMERIC_STD.ALL;
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
-- se modifica el algorimto para calcular la diferencia entre una muestra y la anterior, si se detecta un máximo en la señal, se considera
-- cambio de alabe.. se usa parte de la infraestructura del anterior, pero en vez de detectar mínimos de V2, se busca máximos de difV2.
-- 01.07.16
-- A partir de de la señal de entrada V2 se detreminan los mínimos y se generan las señales de TipTiming (TT) y flanco de cambio del TipTiming (changeTT).
--
-- En primer lugar se selecciona un mínimo provisional de la señal de entrada (V2) y lo almacena en "minaux". 
-- Cuando la nueva señal de entrada V2 supera en más de "limiter" se verifica el valor mínimo almacenado y se convierte en mínimo real.
-- Además se produce "changeTTin" y en el siguiente pulso "changeTT".
-- Entre dos mínimos reales funciona un contador que determina el Tip Timinig.
-- El contador de TipTiming se forma con "counter" - "contaux". 
-- "Counter" cuenta desde el anterior mínimo real hasta el mínimo verificado.
-- "contaux" calcula el exceso de cuenta, desde el mínimo provisional hasta el mínimo verificado.
-- La diferncia de estos dos valores es el TipTiming real.
-- Si "contaux" es mayor de 1/2 del contador anterior real (ttaux) se produce una verificación de mínimo.
-- Después de un mínimo real durante 3/4 del counter real (decoun)no se pueden detectar mínimos para evitar falsos mínimos.

--				v2. Se elimina la posibilidad de un modo... se hará fuera del core.

entity CalculoTT is
    Port ( v2 : 		in  STD_LOGIC_VECTOR (15 downto 0);				-- Señal mayor del sensor óptico
           clk : 		in  STD_LOGIC;											-- Reloj del sistema
           reset : 	in  STD_LOGIC;			  								-- Reset general
			  limitem : in  STD_LOGIC_VECTOR (15 downto 0);				-- Mayor diferencia entre V2 y minimo acumulado para aceptar, modo entrada externa
           --modo : 	in  STD_LOGIC;											-- Modo = 1 => modo manual, Modo = 0 => modo automático 
			  tt : 		out  STD_LOGIC_VECTOR (15 downto 0) := (others => '0');			-- Pulsos entre mínimos
			  min : 		out  STD_LOGIC_VECTOR (15 downto 0):= (others => '1');			-- Valor del mínimo detectado
           changett : out  STD_LOGIC := '0');
end CalculoTT;

architecture Behavioral of CalculoTT is

signal limiter : STD_LOGIC_VECTOR (15 downto 0) := (others => '0'); 	-- Límite real
signal maxaux : signed (15 downto 0) := (others => '1'); 	-- MAximo auxiliar
signal counter : STD_LOGIC_VECTOR (15 downto 0) := (others => '0'); 	-- Contador de Tip-Timing
signal decoun : STD_LOGIC_VECTOR (15 downto 0) := (others => '0'); 	-- Decontador
signal contaux : STD_LOGIC_VECTOR (15 downto 0) := (others => '0'); 	-- Exceso de contador
signal contreal : STD_LOGIC_VECTOR (15 downto 0) := (others => '0'); -- Contador real
--signal estado : STD_LOGIC;																-- 0 detección de mínimo, 1 no detección de mínimo
--signal changeTTin : STD_LOGIC;	
signal tt_in: STD_LOGIC_VECTOR(15 downto 0) := (others => '0'); 
signal max_in: signed(15 downto 0) := (others => '0'); 
--signal ttin : STD_LOGIC_VECTOR (15 downto 0) := "0000000000000000"; 
signal ttaux : STD_LOGIC_VECTOR (15 downto 0) := (others => '0');				-- 

constant limitea : STD_LOGIC_VECTOR (15 downto 0) := x"1333"; 	-- Límite automático x"1D00" Para 16 bits x"03A0" para 13 bits
																					-- x"0064"
																					-- x"01F4" --500
																					-- x"03A0" --928  0.11V@1V
																					-- x"1333" --4915 0.6V@1V
																					-- x"1999"   0.8V@1V
---- FSM
TYPE stateTT_t IS (	stBuscarMaximo,			--
							stConfirmarMaximo,
							stAlabeDetectado,
							stEsperar3CuartosToA);

signal currTTSt: stateTT_t := stBuscarMaximo;
signal nextTTst: stateTT_t := stBuscarMaximo;

signal tt_i : STD_LOGIC_VECTOR(15 downto 0):= (OTHERS => '0');
signal max_i: STD_LOGIC_VECTOR(15 downto 0):= (OTHERS => '1');
signal changett_i: STD_LOGIC := '0';
signal dif, V2_1: signed(15 downto 0):=(OTHERS => '0');
signal V2Dif : signed (15 downto 0);
---- FSM
begin

Diferenciar:process(clk)
begin

	IF(rising_edge(clk)) THEN
		IF(reset = '1') THEN
	       	dif <= (OTHERS => '0');
		ELSE	
		  	dif <= signed(V2) - V2_1;
        	V2_1 <= signed(V2);
		END IF;
	END IF;    
end process;
V2Dif <= dif;

--RegistrarLimit: process(clk) -- Para LIMIT variable
--begin
--	if(rising_edge(clk)) then
--		if(reset = '1') then
--			limiter <= limitea; -- constante 
--		else
--			limiter <= limitem; -- proviene del gestor de memoria
--		end if;
--	end if;
--end process;
 limiter <= limitem; --PARA LIMIT fijo 
SYNC_PROC: PROCESS (clk) --just clock
BEGIN
	IF(rising_edge(clk)) THEN
		IF(reset = '1') THEN
			currTTSt <= stBuscarMaximo;
			tt <= (OTHERS => '0');
			min <= (OTHERS => '0');
			changett <= '0';
		ELSE	
			currTTSt <= nextTTst;			
			tt <= tt_i;
			min <= max_i;
			changett <= changett_i;
		END IF;
	END IF;
END PROCESS;
DeteminarMaxAux: process(clk)
begin
	if(rising_edge(clk)) then
		if (reset = '1') then
			maxaux <= (others => '0'); 
			decoun <= (others => '0'); 
			contaux <= (others => '0'); 
			counter <= (others => '0'); 
		else
			if(currTTSt = stBuscarMaximo) then
				if(v2Dif > 0) then
					if (maxaux < v2Dif) then
						maxaux <= v2Dif;
					end if;
				end if;
                decoun <= (others => '0'); 
                contaux <= (others => '0');
                counter <= counter + '1';
                tt_in <= contreal + '1';

			end if;
			if(currTTSt = stConfirmarMaximo) then
--				if(v2 - minaux < limiter) AND (contaux  < "00" & ttaux (15 downto 2)) then		
						counter <= counter + '1';
						contaux <= contaux + '1';
--						decoun <= (others => '0'); 
						ttaux <= contreal;						
						maxaux <= maxaux ;	
						tt_in <= contreal + '1';
						max_in <= maxaux;
						decoun <= ttaux (15 downto 0) - ttaux (15 downto 2); -- - contaux (15 downto 0); --3tt/4			
--					else	--Demasiado tiempo OR Demaisado alto, asi que encontrado!
--						counter <= contaux; --No perder la cuenta
--						contaux <= (others => '0'); -- REsete contador en exceso
--						tt_in <= contreal + '1';
--						ttaux <= contreal;						
--						min_in <= minaux;
--						decoun <= ttaux (15 downto 0) - ttaux (15 downto 2) - contaux (15 downto 0); --3tt/4
--					end if;			
			end if;
			if( currTTSt = stAlabeDetectado) then
						counter <= contaux; --No perder la cuenta
						contaux <= (others => '0'); -- REsete contador en exceso
--						tt_in <= contreal + '1';
						
--						min_in <= minaux;
						
--				counter <= counter + '1';
--				decoun <= decoun - '1';	
--				contaux <= (others => '0');
--				minaux <= (others => '1');
			end if;
			if(currTTSt = stEsperar3CuartosToA) then
				counter <= counter + '1';
				decoun <= decoun - '1';	
				contaux <= (others => '0');
				maxaux <= (others => '0');
			end if;
		end if;
	end if;
end process;

NEXT_STATE_DECODE: PROCESS(currTTSt,v2Dif,maxaux,limiter,contaux,ttaux,decoun) --stCurrent+Inputs
BEGIN
	nextTTst <= currTTSt;	
	CASE currTTSt IS
		WHEN  stBuscarMaximo =>
			if(v2Dif > 0) then
				if(V2Dif < maxaux) then
					nextTTst <= stConfirmarMaximo;
				end if;
			end if;
		WHEN	stConfirmarMaximo =>
			if(v2Dif > maxaux) then
				nextTTst <= stBuscarMaximo;
			--elsif((maxaux - v2Dif  > limiter) OR (contaux > "00" & ttaux (15 downto 2))) then -- Si nos vamos por arriba o hay mas de 1/4ToA cambio de estado
			elsif(((maxaux - v2Dif  > limiter) AND (maxaux > 0))  OR (contaux > "00" & ttaux (15 downto 2))) then -- Debe ser mayor que limiter, pero sólo cuando sea positiva
			--elsif((v2 - minaux > limiter) OR (contaux > "000" & ttaux (15 downto 3))) then -- Si nos vamos por arriba o hay mas de 1/8ToA cambio de estado
				nextTTst <= stAlabeDetectado;
			end if;
		WHEN	stAlabeDetectado =>
				nextTTst <= stEsperar3CuartosToA;
		WHEN 	stEsperar3CuartosToA =>
			if(decoun = x"0000") then
				nextTTst <= stBuscarMaximo;
			end if;			
	END CASE;
END PROCESS;

OUTPUT_DECODE: process(currTTSt)
BEGIN
	CASE currTTSt IS
		WHEN  stBuscarMaximo =>
			tt_i <= x"AAAA";
			changett_i <= '0';
			max_i <=  x"AAAA";
		WHEN	stConfirmarMaximo =>
			tt_i <= x"BBBB";
			changett_i <= '0';
			max_i <= x"BBBB";
		WHEN	stAlabeDetectado =>
			tt_i <= tt_in;
			changett_i <= '1';
			max_i <= std_logic_vector(max_in);
		WHEN 	stEsperar3CuartosToA =>
			tt_i <= x"CCCC";
			changett_i <= '0';
			max_i <= x"CCCC";
	END CASE;
END PROCESS;
		
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


