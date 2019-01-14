----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 22.01.2015 16:35:00
-- Design Name: 
-- Module Name: red_pitaya_core_t3c - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
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
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity red_pitaya_t3c_core is
    Port ( adc_clk_i        : in STD_LOGIC;
           adc_rstn_i       : in STD_LOGIC;
           adc_V1_i     : in STD_LOGIC_VECTOR (13 downto 0);
           adc_v2_i     : in STD_LOGIC_VECTOR (13 downto 0);
           --system bus connections
           sys_clk_i    : in STD_LOGIC;
           sys_rstn_i   : in STD_LOGIC;
           sys_addr_i   : in STD_LOGIC_VECTOR (31 downto 0);
           sys_wdata_i  : in STD_LOGIC_VECTOR (31 downto 0);
           sys_sel_i    : in STD_LOGIC_VECTOR (3 downto 0);
           sys_wen_i    : in STD_LOGIC;
           sys_ren_i    : in STD_LOGIC;
           sys_rdata_o  : out STD_LOGIC_VECTOR (31 downto 0);
           sys_err_o    : out STD_LOGIC;
           sys_ack_o    : out STD_LOGIC);
end red_pitaya_t3c_core;

architecture Behavioral of red_pitaya_t3c_core is

constant cteCoreVersion :STD_LOGIC_VECTOR := x"0102000F";
--constant ctNumAlabes    :STD_LOGIC_VECTOR    := x"92";  --146
constant ctNumAlabes    :STD_LOGIC_VECTOR    := "000" & x"92";  --146
--constant A_cte: std_logic_vector (15 downto 0) := x"07A1"; -- 4 -> 32768
--constant B_cte: std_logic_vector (31 downto 0) := x"01FD2270"; --"1001000000000000"; -- 9 -> 36864
--constant ctCoefA        :STD_LOGIC_VECTOR    := x"000007A1";
--constant ctCoefB        :STD_LOGIC_VECTOR    := x"01FD2270";
constant ctCoefA        :STD_LOGIC_VECTOR    := x"00005949";
constant ctCoefB        :STD_LOGIC_VECTOR    := x"14F69249";


signal rdata_DPM: STD_LOGIC_VECTOR(31 downto 0);
signal regControl,regEstado,regCoef_A,regCoef_B,regAlabes,regDezimator,regLimite,regTimeOutAlabe: STD_LOGIC_VECTOR(31 downto 0);
--signal CoefA : std_logic_vector(15 downto 0);
signal CoefA : std_logic_vector(31 downto 0);
signal CoefB: std_logic_vector(31 downto 0);
--signal numalabes :std_logic_vector(7 downto 0) := x"92"; --146
signal numalabes :std_logic_vector(10 downto 0) := "000"&x"92"; --146
SIGNAL ADC_Data: STD_LOGIC_VECTOR(31 downto 0);
signal rst_DPM : STD_LOGIC; --reset memoria doble puerto
--constant ADD_MEMORIA_WITDH : integer := 11; --memoria de 2k 
constant ADD_MEMORIA_WITDH : integer := 14; --memoria de 16k

signal T3CReset :Std_logic := '0';
signal T3CEnable    :std_logic := '0'; -- --Seleccion de datos para el core. 0:ADC 1:ROM (BASE+0[2])
signal T3C_modoCoefs  :std_logic := '0'; -- --Seleccion de datos para el core. 0:ADC 1:ROM (BASE+0[5])
signal T3C_modoRecta:std_logic := '0'; -- --Seleccion de recta para el core. 0:direct prop  1:inve propor (BASE+0[4])
signal T3CDataSel   :std_logic := '0'; -- --Seleccion de datos para el core. 0:ADC 1:ROM (BASE+0[31])
signal T3CData : std_logic_vector(31 downto 0) :=x"00000000";
signal uB_we		:std_logic_vector(0 downto 0);
signal DPM_sel : std_logic := '0';
--constant ADD_TESTROM_WITDH : integer := 16; --memoria de 64k

constant ADD_TESTROM_WITDH : integer := 14; --memoria de 16k
signal ROMTestReset : std_logic := '0';
signal ROMTestEnable_i : std_logic := '0';
signal ROMTestEndOfAdd : std_logic := '0';
signal ROMTest_Data :STD_LOGIC_VECTOR(31 downto 0);
signal ROMTest_AdressBus: std_logic_vector(ADD_TESTROM_WITDH-1 downto 0);

--salidas del sincronizador
signal addr,wdata,rdata : Std_logic_vector(31 downto 0);
signal wen,ren,err,ack : std_logic;


signal i_changeTT :std_logic := '0';
signal i_TT : std_logic_vector(15 downto 0) := x"0000";
signal EndOfAddressGeneration :std_logic ;
--COMPONENT ROM_LUT_test64kx32 IS
--COMPONENT testROM64k IS
--COMPONENT testROM16k IS
--PORT (
--    --Port A
--  ENA           : IN STD_LOGIC;  --opt port
--  ADDRA         : IN STD_LOGIC_VECTOR(ADD_TESTROM_WITDH - 1 DOWNTO 0);
--  DOUTA         : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
--  CLKA          : IN STD_LOGIC
--);
--END COMPONENT;

--COMPONENT gen_dir_prog is
--	generic(NumBitsDireccion   :integer := ADD_TESTROM_WITDH; 	--16k);
--	       AddInicial          :integer := 0;
--	       AddFinal            :integer := 16331;
--	       NumVeces            :integer := 4);
--    Port ( clk_i : in  STD_LOGIC;
--           rst_i : in  STD_LOGIC;
--           en_i : in  STD_LOGIC;
--           EndOfAddressGeneration: out std_logic;
--           add_o : out  STD_LOGIC_VECTOR (NumBitsDireccion - 1 downto 0));
--end COMPONENT;

COMPONENT Procesador_T3C is	
	PORT ( clk : in  STD_LOGIC;
           rst : in  STD_LOGIC;
           Canal_A : in  STD_LOGIC_VECTOR (15 downto 0);
           Canal_B : in  STD_LOGIC_VECTOR (15 downto 0);
           --Coef_A : in  STD_LOGIC_VECTOR (15 downto 0);
           Coef_A : in  STD_LOGIC_VECTOR (31 downto 0);
           Coef_B : in  STD_LOGIC_VECTOR (31 downto 0);
           --numAlabes : in  STD_LOGIC_VECTOR (7 downto 0);
           numAlabes : in  STD_LOGIC_VECTOR (10 downto 0);
		   limitem : in STD_LOGIC_VECTOR(12 downto 0);
		   limitTimeOut: in STD_LOGIC_VECTOR(15 downto 0);
		   modoRecta: in STD_LOGIC; --0 direct proporc, 1 inv proporcional
		   rst_DPM: in STD_LOGIC;
           --dirAXI_i : in  STD_LOGIC_VECTOR (10 downto 0);
           dirAXI_i : in  STD_LOGIC_VECTOR (13 downto 0);
           datAXI_i : in  STD_LOGIC_VECTOR (31 downto 0);
		   datAXI_o : out  STD_LOGIC_VECTOR (31 downto 0);
           webAXI_i : in  STD_LOGIC_VECTOR (0 downto 0);
		   enAXI_i : in  STD_LOGIC;
           clkAXI_i : in  STD_LOGIC;
--	PARA COMPROBACIONES --
			TT : OUT STD_LOGIC_VECTOR(15 downto 0);
			ChangeTT: OUT STD_LOGIC);
END COMPONENT;

COMPONENT bus_clk_bridge IS
PORT (
   -- system bus
   sys_clk_i		: in std_logic;   					--,	 //!< bus clock
   sys_rstn_i    	: in std_logic;						--,  //!< bus reset - active low
   sys_addr_i    	: in  std_logic_vector(31 downto 0);--,  //!< bus address
   sys_wdata_i   	: in  std_logic_vector(31 downto 0);--,  //!< bus write data
   sys_sel_i     	: in  std_logic_vector(3 downto 0);	--,  //!< bus write byte select
   sys_wen_i     	: in std_logic;						--,  //!< bus write enable
   sys_ren_i     	: in std_logic;						--,  //!< bus read enable
   sys_rdata_o   	: out std_logic_vector(31 downto 0);--,  //!< bus read data
   sys_err_o     	: out std_logic;					--,  //!< bus error indicator
   sys_ack_o     	: out std_logic;					--,  //!< bus acknowledge signal
   -- Destination bus
   clk_i		: in std_logic; 					--,  //!< clock
   rstn_i     	: in std_logic; 					--,  //!< reset - active low
   addr_o     	: out std_logic_vector(31 downto 0);--,  //!< address
   wdata_o		: out std_logic_vector(31 downto 0);--,  //!< write data
   wen_o 		: out std_logic;        			--,  //!< write enable
   ren_o		: out std_logic;         			--,  //!< read enable
   rdata_i		: in  std_logic_vector(31 downto 0);--,  //!< read data
   err_i      	: in std_logic; 					--,  //!< error indicator
   ack_i      	: in std_logic	 					--,      //!< acknowledge signal
);
END COMPONENT;

SIGNAL bram_ack:std_logic_vector(3 downto 0)  := "0000";

begin
-- 

T3CReset <= (NOT sys_rstn_i) OR ROMTestEndOfAdd OR (NOT T3CEnable); --activo H

PrcT3C: Procesador_T3C PORT MAP(
		clk           => adc_clk_i,
		rst           => T3CReset,        --activo H
		Canal_A       => T3CData(15 downto 0),
        Canal_B       => T3CData(31 downto 16),
        Coef_A        => CoefA,
        Coef_B        => CoefB,
        numAlabes     => numalabes,
		limitem       => regLimite(12 downto 0), -- valor en tt_cal.vhd
		limitTimeOut  => regTimeOutAlabe(15 downto 0),
		modoRecta     => T3C_modoRecta,
		rst_DPM       => rst_DPM,    
        dirAXI_i      => addr (ADD_MEMORIA_WITDH + 1 downto 2),
		datAXI_i      => wdata ,		
		datAXI_o      => rdata_DPM ,
		webAXI_i      => uB_we,
		enAXI_i       => DPM_sel, --sys_addr_i(16),	-- DPM mapeada en 4061XXXX (y en 4063, y 4065...
		clkAXI_i      => adc_clk_i,
		TT            => i_TT,
		ChangeTT      => i_ChangeTT);

DPM_sel <= '1' when addr (19 downto 16) = x"1" else '0';
uB_we(0) <= wen;

--ROM64k: testROM64k
--ROM64K: ROM_LUT_test64kx32
--ROM16K: testROM16K    
--  PORT MAP (
--    clka    => adc_clk_i,
--    ena     => T3CDataSel,
--    addra   => ROMTest_AdressBus,
--    douta   => ROMTest_Data);

--TestROM_GenDireccions: gen_dir_prog
--   GENERIC MAP(
--        NumBitsDireccion    => ADD_TESTROM_WITDH, --14 para 16kB
--        AddInicial          => 0,      -- desde esta
--        AddFinal            => 16331, --esta incluida
--        NumVeces            => 8
--        )
--    PORT MAP(
--        clk_i                  => adc_clk_i, 
--    	rst_i                  => ROMTestReset,
--    	en_i                   => ROMTestEnable_i,
--    	EndOfAddressGeneration => ROMTestEndOfAdd,
--    	add_o                  => ROMTest_AdressBus
--    );

ROMTestEnable_i <= T3CDataSel AND T3CEnable ;
ROMTestReset <= (NOT sys_rstn_i) OR (NOT T3CEnable) ;

T3CDataSelProcess: process(adc_clk_i) begin
    if(rising_edge(adc_clk_i)) then
        if(sys_rstn_i='0') then
    	   T3CData <= x"00000000";
    	elsif(T3CDataSel = '0') then
    	   T3CData <= ADC_Data;
    	else
    	   -- T3CData <= "0" & ROMTest_Data(31 downto 17) & "0" & ROMTest_Data(15 downto 1);
    	   --T3CData <= "00" & ROMTest_Data(31 downto 18) & "00" & ROMTest_Data(15 downto 2);
            T3CData <= ROMTest_Data;
    	end if;
    end if;
 end process;
 
 
 
 -- Bits de control a partir de los registros.
ADC_Data <= "00" & adc_v2_i & "00" & adc_v1_i;
--T3CEnable      <= regControl(2);
--T3C_modoCoefs  <= regControl(3);
--rst_DPM        <= regControl(4); --activo H
--T3CDataSel     <= regControl(31);
--CoefA          <= regCoef_A(15 downto 0);
CoefA          <= regCoef_A;
CoefB          <= regCoef_B;
 
numalabes      <= regAlabes(numalabes'LEFT downto 0);

---------------------------------------------------------------------------------
--
--  System bus connection
-- MAPA DE MEMORIA
-- 00000 :CONTROL   .0->SOC
--                  .2->Enable Core T3C
--                  .3->Modo coeficientes: 0 automatico, 1 manual
--                  .4->Reset de la DPM
--                  .31->Fuente de datos para el core, 0 ADC, 1 ROM con muestras
-- 00004 :ESTADO 
-- 00008 :COEFICIENTES A [16 bits] 
-- 0000C : Coeficiente B [32 bits]
-- 00010 :NUMERO DE ALABES [146d]
-- 10000
-- 10800 : 2k DPM con datos

err <= '0'; --no hay errores, hala!
ack <= '1' when  addr(19 downto 16) = x"0"  else
                  bram_ack(1) when  (addr(19 downto 16) = x"1");


-- ACK para el bus
ACK_PROC: process(adc_clk_i) is
  begin
      if (rising_edge(adc_clk_i)) then
        if ( sys_rstn_i = '0' ) then
            bram_ack <= "0000";
        else
            bram_ack <= bram_ack(2 downto 0) & (ren or wen) ; -- or  sys_wen_i);
        end if;
       end if;
 end process;
 
   
-- Multiplexor de lectura estado
regEstado_Process:process(adc_clk_i)
begin
    if(rising_edge(adc_clk_i)) then
        if(adc_rstn_i = '0') then
            regEstado       <= (others => '0');
         else
            regEstado <= "00" & adc_v2_i & x"55"& '0' & '1' & NOT T3CEnable & EndOfAddressGeneration & ROMTestEndOfAdd & T3CReset & ROMTestReset & ROMTestEnable_i;
         end if;
    end if;
end process;

-- Multiplexor de lectura
rdata        <= regControl      when (addr(19 downto 0) = x"00000")  else 
                regEstado       when (addr(19 downto 0) = x"00004")  else 
                regCoef_A       when (addr(19 downto 0) = x"00008") else
                regCoef_B       when (addr(19 downto 0) = x"0000C") else 
                regAlabes       when (addr(19 downto 0) = x"00010") else 
                regDezimator    when (addr(19 downto 0) = x"00014") else 
                ADC_Data        when (addr(19 downto 0) = x"00018") else 
                cteCoreVersion  when (addr(19 downto 0) = x"0001C") else
                regLimite       when (addr(19 downto 0) = x"00020") else
                regTimeOutAlabe when (addr(19 downto 0) = x"00024") else
                rdata_DPM       when (addr(19 downto 16) = x"1")  else
                (others => '0');
               
-- Multiplexor de escritura
SysWrProcess:process(adc_clk_i)
begin
    if(rising_edge(adc_clk_i)) then
        if(adc_rstn_i = '0') then
            regControl      <= (others => '0');
            regCoef_A      <=  ctCoefA;
            regCoef_B      <= ctCoefB; 
            regAlabes       <= x"00000" & "0" & ctNumAlabes;
            regLimite       <= x"00001333"; --Por defecto 0.6V@1V
            regTimeOutAlabe <= (others => '0');
            T3CEnable      <= '0';
            T3C_modoCoefs  <= '0';
            T3C_modoRecta  <= '0';
            rst_DPM        <= '0'; --activo H
            T3CDataSel     <= '0';
        else
            if(wen = '1') then
                if(addr(19 downto 0) = x"00000" ) then
                    regControl <= wdata;
                    T3CEnable      <= wdata(2);
                    T3C_modoCoefs  <= wdata(3);
                    rst_DPM        <= wdata(4); --activo H
                    T3C_modoRecta  <= wdata(5);
                    T3CDataSel     <= wdata(31);
                end if;
                if(addr(19 downto 0) = x"00004") then
                    --regEstado <= wdata; -- No escribimos en regEstado ya que es RO
                end if;
                if(addr(19 downto 0) = x"00008")then
                    if(T3C_modoCoefs = '0') then --automatico
                        regCoef_A <= ctCoefA;
                    else
                        regCoef_A <= wdata;
                     end if;
                end if;
                if(addr(19 downto 0) = x"0000C")then
                    if(T3C_modoCoefs = '0') then
                       regCoef_B <= ctCoefB;        --automatico
                    else
                        regCoef_B <= wdata;
                    end if;
                end if;
                if(addr(19 downto 0) = x"00010")then
                    if(T3C_modoCoefs = '0') then --automatico
                        regAlabes <=  x"00000" & "0" & ctNumAlabes;            
                        --regAlabes <=  x"000000" & ctNumAlabes;
                    else
                        regAlabes <= wdata;
                    end if;
                end if;
                if(addr(19 downto 0) = x"00014") then
                    regDezimator <= wdata;
                end if;
                -- 00018 ADC Data RO
                -- 0001C Core Version RO
                if(addr(19 downto 0) = x"00020") then
                    regLimite <= wdata;
                end if;
                if(addr(19 downto 0) = x"00024") then
                    regTimeOutAlabe <= wdata;
                end if;

             end if;
        end if;
    end if;
end process;

-- Sincronizador de bus... no tengo muy claro que haga falta al final 
i_bridge: bus_clk_bridge  PORT MAP(
  sys_clk_i     => sys_clk_i	,
  sys_rstn_i    => sys_rstn_i	,
  sys_addr_i    => sys_addr_i	,
  sys_wdata_i   => sys_wdata_i	,
  sys_sel_i     => sys_sel_i	,
  sys_wen_i     => sys_wen_i	,
  sys_ren_i     => sys_ren_i	,
  sys_rdata_o   => sys_rdata_o	,
  sys_err_o     => sys_err_o	,
  sys_ack_o     => sys_ack_o	,

  clk_i         =>  adc_clk_i   ,
  rstn_i        =>  adc_rstn_i  ,
  addr_o        =>  addr		,
  wdata_o       =>  wdata		,
  wen_o         =>  wen			,
  ren_o         =>  ren			,
  rdata_i       =>  rdata		,
  err_i         =>  err			,
  ack_i         =>  ack);

end Behavioral;
