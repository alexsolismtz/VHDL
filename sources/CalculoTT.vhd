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
		   limitTime : in STD_LOGIC_VECTOR (15 downto 0);             --Tiempo sin buscar alabe
           --modo : 	in  STD_LOGIC;											-- Modo = 1 => modo manual, Modo = 0 => modo automático 
			  tt : 		out  STD_LOGIC_VECTOR (15 downto 0) := (others => '0');			-- Pulsos entre mínimos
			  
			  min : 		out  STD_LOGIC_VECTOR (15 downto 0):= (others => '1');			-- Valor del mínimo detectado
           change_tt_V: out	STD_LOGIC := '0';			--Detecci�n por cambio por tensi�n muy por encima del �ltimo minimo
			  change_tt_T: out STD_LOGIC := '0';				--Detecci�n por tiempo por debajo del 1/4 tt
			  start_of_Detection: out STD_LOGIC := '0';				--Comienzo de detecci�n
			  changett : out  STD_LOGIC := '0');
end CalculoTT;

architecture Behavioral of CalculoTT is

constant DecountInicial : STD_LOGIC_VECTOR(15 downto 0) := x"003f";	--Tiempo sin busqueda por defecto.
signal limiter : STD_LOGIC_VECTOR (15 downto 0) := (others => '0'); 	-- Límite real
signal minaux : STD_LOGIC_VECTOR (15 downto 0) := (others => '1'); 	-- Mínimo auxiliar
signal counter : STD_LOGIC_VECTOR (15 downto 0) := (others => '0'); 	-- Contador de Tip-Timing
signal decoun : STD_LOGIC_VECTOR (15 downto 0) := DecountInicial; --(others => '0'); 	-- Decontador
signal contaux : STD_LOGIC_VECTOR (15 downto 0) := (others => '0'); 	-- Exceso de contador
signal contreal : STD_LOGIC_VECTOR (15 downto 0) := (others => '0'); -- Contador real
--signal estado : STD_LOGIC;																-- 0 detección de mínimo, 1 no detección de mínimo
--signal changeTTin : STD_LOGIC;	
signal tt_in: STD_LOGIC_VECTOR(15 downto 0) := (others => '0'); 
signal min_in: STD_LOGIC_VECTOR(15 downto 0) := (others => '0'); 
--signal ttin : STD_LOGIC_VECTOR (15 downto 0) := "0000000000000000"; 
signal ttaux : STD_LOGIC_VECTOR (15 downto 0) := DecountInicial;	--(others => '0');				-- 

constant limitea : STD_LOGIC_VECTOR (15 downto 0) := x"1333"; 	-- Límite automático x"1D00" Para 16 bits x"03A0" para 13 bits
																					-- x"0064"
																					-- x"01F4" --500
																					-- x"03A0" --928  0.11V@1V
																					-- x"1333" --4915 0.6V@1V
																					-- x"1999"   0.8V@1V
---- FSM
TYPE stateTT_t IS (	stBuscarMinimo,			--
							stConfirmarMinimo,
							stAlabeDetectadoV,
							stAlabeDetectadoT,
							stEsperar3CuartosToA);

signal currTTSt: stateTT_t := stEsperar3CuartosToA;
signal nextTTst: stateTT_t := stEsperar3CuartosToA;

signal tt_i : STD_LOGIC_VECTOR(15 downto 0):= (OTHERS => '0');
signal min_i: STD_LOGIC_VECTOR(15 downto 0):= (OTHERS => '0');
signal changett_i: STD_LOGIC := '0';
signal change_tt_Tin : STD_LOGIC := '0';	
signal change_tt_Vin : STD_LOGIC := '0';
signal start_of_Detection_in : STD_LOGIC := '0';
---- FSM
signal resta:std_logic_vector(15 downto 0) := x"0000";
signal lastDetectionIsV: std_logic := '0';
begin


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
resta <= v2 - minaux ;
 limiter <= limitem; --PARA LIMIT fijo 
SYNC_PROC: PROCESS (clk) --just clock
BEGIN
	IF(rising_edge(clk)) THEN
		IF(reset = '1') THEN
			currTTSt <= stEsperar3CuartosToA;
			tt <= (OTHERS => '0');
			min <= (OTHERS => '0');
			changett <= '0';
		ELSE	
			currTTSt <= nextTTst;			
			tt <= tt_i;
			min <= min_i;
			changett <= changett_i;
			change_tt_T <= change_tt_Tin;
			change_tt_V <= change_tt_Vin;
			start_of_Detection <= start_of_Detection_in;
			
		END IF;
	END IF;
END PROCESS;
DeteminarMinAux: process(clk)
begin
	if(rising_edge(clk)) then
		if (reset = '1') then
			minaux <= (others => '1'); 
			decoun <= DecountInicial; --(others => '0'); 
			contaux <= (others => '0'); 
			counter <= (others => '0'); 
		else
			if(currTTSt = stBuscarMinimo) then
				if (minaux > v2) then
					minaux <= v2;
				end if;
                --decoun <= (others => '0'); 
                contaux <= (others => '0');
                counter <= counter + '1';
                tt_in <= contreal + '1';

			
			elsif(currTTSt = stConfirmarMinimo) then
--				if(v2 - minaux < limiter) AND (contaux  < "00" & ttaux (15 downto 2)) then		
						counter <= counter + '1';
						contaux <= contaux + '1';	
						
						if lastDetectionIsV = '1' then
							ttaux <= contreal + 1;	--Para que se use en el siguiente alabe el del anterior...
						else
							ttaux <= ttaux + '1';
						end if;						
						tt_in <= contreal + '1';		--Preparar salida de tiempo si se confirmara
						min_in <= minaux;
						
--					else	--Demasiado tiempo OR Demaisado alto, asi que encontrado!
--						counter <= contaux; --No perder la cuenta
--						contaux <= (others => '0'); -- REsete contador en exceso
--						tt_in <= contreal + '1';
--						ttaux <= contreal;						
--						min_in <= minaux;
--						decoun <= ttaux (15 downto 0) - ttaux (15 downto 2) - contaux (15 downto 0); --3tt/4
--					end if;			

			elsif( currTTSt = stAlabeDetectadoV ) then
						counter <= contaux + 1; --No perder la cuenta
						
						
						--decoun <= limitTime;  -- Para entrada esterna del tiempo en que estarmos sin mirar
						--decoun <= ttaux (15 downto 0) - ttaux (15 downto 2) - contaux (15 downto 0); --3tt/4			
						decoun <= ttaux (15 downto 0) - ttaux (15 downto 3)  - contaux (15 downto 0); --7tt/8
						--decoun <= ttaux (15 downto 0) - ttaux(15 downto 1) - contaux (15 downto 0); --1tt/2
						contaux <= (others => '0'); -- REsete contador en exceso
						ttaux <= contreal + 1;		--Fijo tiempo para el siguiente alabe
						lastDetectionIsV <= '1';
			elsif(currTTSt = stAlabeDetectadoT) then
						counter <= contaux + 1; --No perder la cuenta												
						--decoun <= limitTime;  -- Para entrada esterna del tiempo en que estarmos sin mirar
						--decoun <= ttaux (15 downto 0) - ttaux (15 downto 2) - contaux (15 downto 0); --3tt/4			
						decoun <= ttaux (15 downto 0) - ttaux (15 downto 3)  - contaux (15 downto 0); --7tt/8
						--decoun <= ttaux (15 downto 0) - ttaux(15 downto 1) - contaux (15 downto 0); --1tt/2			
						contaux <= (others => '0'); -- REsete contador en exceso
						ttaux <= contreal + 1;		--Fijo tiempo para el siguiente alabe
						lastDetectionIsV <= '0';
			elsif(currTTSt = stEsperar3CuartosToA) then
				counter <= counter + '1';
				decoun <= decoun - '1';	
				contaux <= (others => '0');
				minaux <= (others => '1');
			end if;
		end if;
	end if;
end process;

NEXT_STATE_DECODE: PROCESS(currTTSt,v2,minaux,limiter,contaux,ttaux,decoun) --stCurrent+Inputs
BEGIN
	nextTTst <= currTTSt;	
	CASE currTTSt IS
		WHEN  stBuscarMinimo =>
			if(v2 > minaux) then
				nextTTst <= stConfirmarMinimo;
			end if;
		WHEN	stConfirmarMinimo =>
			if(v2 < minaux) then
				nextTTst <= stBuscarMinimo;
			--elsif((v2 - minaux > limiter) OR (contaux > "00" & ttaux (15 downto 2))) then -- Si nos vamos por arriba o hay mas de 1/4ToA cambio de estado
			elsif(v2 - minaux > limiter) then
				nextTTst <= stAlabeDetectadoV;
			elsif(contaux > "00" & ttaux (15 downto 2)) then -- Si nos vamos por arriba o hay mas de 1/4ToA cambio de estado
			--elsif(contaux > "000" & ttaux (15 downto 3)) then -- Si nos vamos por arriba o hay mas de 1/8ToA cambio de estado
				nextTTst <= stAlabeDetectadoT;
			end if;
		WHEN	stAlabeDetectadoV =>
				nextTTst <= stEsperar3CuartosToA;
		WHEN	stAlabeDetectadoT =>
				nextTTst <= stEsperar3CuartosToA;
		WHEN 	stEsperar3CuartosToA =>
			if(decoun = x"0000") then
				nextTTst <= stBuscarMinimo;
			end if;			
	END CASE;
END PROCESS;

OUTPUT_DECODE: process(currTTSt)
BEGIN
	CASE currTTSt IS
		WHEN  stBuscarMinimo =>
			tt_i <= x"AAAA";
			changett_i <= '0';
			min_i <=  x"AAAA";
			change_tt_Vin <= '0';
			change_tt_Tin <= '0';
			start_of_Detection_in <= '0';
		WHEN	stConfirmarMinimo =>
			tt_i <= x"BBBB";
			changett_i <= '0';
			min_i <= x"BBBB";
			change_tt_Vin <= '0';
			change_tt_Tin <= '0';
			start_of_Detection_in <= '1';
		WHEN	stAlabeDetectadoV =>
			tt_i <= tt_in;
			changett_i <= '1';
			min_i <= min_in;
			change_tt_Vin <= '1';
			change_tt_Tin <= '0';
			start_of_Detection_in <= '0';
		WHEN	stAlabeDetectadoT =>
			tt_i <= tt_in;
			--changett_i <= '1';
			changett_i <= '0';
			min_i <= min_in;
			change_tt_Vin <= '0';
			change_tt_Tin <= '1';
			start_of_Detection_in <= '0';
		WHEN 	stEsperar3CuartosToA =>
			tt_i <= x"CCCC";
			changett_i <= '0';
			min_i <= x"CCCC";
			change_tt_Vin <= '0';
			change_tt_Tin <= '0';
			start_of_Detection_in <= '0';
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


