--------------------------------------------------------------------------------
--                                                                            --
--                          V H D L    F I L E                                --
--                          COPYRIGHT (C) 2006                                --
--                                                                            --
--------------------------------------------------------------------------------
--                                                                            --
-- Title       : DIVIDER                                                      --
-- Design      : Unsigned Pipelined Divider core                              --
-- Author      : Michal Krepa                                                 --
--                                                                            --
--------------------------------------------------------------------------------
--                                                                            --
-- File        : DIVIDER.VHD                                                  --
-- Created     : Sat Jun 25 2006                                              --
--                                                                            --
--------------------------------------------------------------------------------
--                                                                            --
--  Description : Unsigned Pipelined Divider                                  --
--                                                                            --
-- dividend allowable range of 0 to 2**SIZE_C-1                               --
-- divider allowable range of 0 to (2**SIZE_C)/2-1                            --
-- pipeline latency is 2*SIZE_C (time from latching input to result ready)    --
-- when pipeline is full new result is generated every clock cycle            --                                           --
-- Restoring division algorithm                                               --
-- Use SIZE_C constant in divider entity (not divpipe entity!) to adjust      --
-- bit width                                                                  --
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- divpipe unit 
-- (many divpipe units are connected in chain to create pipelined divider)
--------------------------------------------------------------------------------
library IEEE;
  use IEEE.STD_LOGIC_1164.All;
  use IEEE.NUMERIC_STD.all;
  
entity divpipe is
  generic ( SIZE_C : INTEGER := 16 );
  port
    (
      rst    : in  STD_LOGIC;
      clk    : in  STD_LOGIC;
      ri     : in  STD_LOGIC_VECTOR(2*SIZE_C-1 downto 0);
      di     : in  STD_LOGIC_VECTOR(SIZE_C-1 downto 0);
      qi     : in  STD_LOGIC_VECTOR(SIZE_C-1 downto 0);
      
      ro     : out STD_LOGIC_VECTOR(2*SIZE_C-1 downto 0);
      do     : out STD_LOGIC_VECTOR(SIZE_C-1 downto 0);
      qo     : out STD_LOGIC_VECTOR(SIZE_C-1 downto 0)
    );
end divpipe;

architecture rtl of divpipe is
   
  signal r2_reg      : UNSIGNED(2*SIZE_C-1 downto 0) ;
  signal r3_reg      : UNSIGNED(2*SIZE_C-1 downto 0) ;
  signal d2_reg      : UNSIGNED(SIZE_C-1 downto 0);
  signal d3_reg      : UNSIGNED(SIZE_C-1 downto 0);
  signal q2_reg      : UNSIGNED(SIZE_C-1 downto 0);
  signal q3_reg      : UNSIGNED(SIZE_C-1 downto 0);
  
begin
  
  process(clk)
  begin
    if clk = '1' and clk'event then
      if rst = '1' then
        r2_reg <= (others => '0');
        r3_reg <= (others => '0');
        d2_reg <= (others => '0');
        d3_reg <= (others => '0');
        q2_reg <= (others => '1'); -- Era 0... lo cambio a '1' para que empiece dando un valor muy alto que corresponde a una distancia muy grande
        q3_reg <= (others => '1'); -- Era 0... lo cambio a '1' para que empiece dando un valor muy alto que corresponde a una distancia muy grande
      else
        
        -- stage 1 (shift left partial remainder and subtract divisior from partial remainder)
        r2_reg(2*SIZE_C-1 downto SIZE_C) <= UNSIGNED(ri(2*SIZE_C-2 downto SIZE_C-1)) - UNSIGNED(di);
        r2_reg(SIZE_C-1 downto 0)        <= UNSIGNED(ri(SIZE_C-2 downto 0)) & '0';
        d2_reg                           <= UNSIGNED(di);
        q2_reg                           <= UNSIGNED(qi);
        
        -- stage 2 (check if partial remainder is greater or equal than 0 after subtract
        if r2_reg(2*SIZE_C-1) = '0' then
          q3_reg                        <= q2_reg(SIZE_C-2 downto 0) & '1';
          r3_reg                        <= r2_reg;
        else
          q3_reg                            <= q2_reg(SIZE_C-2 downto 0) & '0';  
          r3_reg(2*SIZE_C-1 downto SIZE_C)  <= r2_reg(2*SIZE_C-1 downto SIZE_C) + d2_reg;
          r3_reg(SIZE_C-1 downto 0)         <= r2_reg(SIZE_C-1 downto 0);     
        end if;
        d3_reg                          <= d2_reg;
      end if; 
    end if;
  end process;
  
  ro <= STD_LOGIC_VECTOR( r3_reg );
  do <= STD_LOGIC_VECTOR( d3_reg );
  qo <= STD_LOGIC_VECTOR( q3_reg );
   
end rtl;
   
--------------------------------------------------------------------------------
-- MAIN DIVIDER top level
--------------------------------------------------------------------------------
library IEEE;
  use IEEE.STD_LOGIC_1164.All;

entity dividerNXN is
  generic ( SIZE_C : integer := 32 ) ;            -- SIZE_C: Number of bits
  port 
  (
       rst   : in  STD_LOGIC;
       clk   : in  STD_LOGIC;
       a     : in  STD_LOGIC_VECTOR(SIZE_C-1 downto 0) ;     
       d     : in  STD_LOGIC_VECTOR(SIZE_C-1 downto 0) ;     
       
       q     : out STD_LOGIC_VECTOR(SIZE_C-1 downto 0) ;     
       r     : out STD_LOGIC_VECTOR(SIZE_C-1 downto 0)
  ) ;   
end dividerNXN ;

architecture str of dividerNXN is
  
  type S_ARRAY  is array(0 to SIZE_C) of STD_LOGIC_VECTOR(SIZE_C-1 downto 0);
  type S2_ARRAY is array(0 to SIZE_C) of STD_LOGIC_VECTOR(2*SIZE_C-1 downto 0);
  
  signal d_s       : S_ARRAY;
  signal q_s       : S_ARRAY;
  signal r_s       : S2_ARRAY;
  
  component divpipe
  generic ( SIZE_C : INTEGER := SIZE_C );
  port
    (
      rst    : in  STD_LOGIC;
      clk    : in  STD_LOGIC;
      ri     : in  STD_LOGIC_VECTOR(2*SIZE_C-1 downto 0);
      di     : in  STD_LOGIC_VECTOR(SIZE_C-1 downto 0);
      qi     : in  STD_LOGIC_VECTOR(SIZE_C-1 downto 0);
      
      ro     : out STD_LOGIC_VECTOR(2*SIZE_C-1 downto 0);
      do     : out STD_LOGIC_VECTOR(SIZE_C-1 downto 0);
      qo     : out STD_LOGIC_VECTOR(SIZE_C-1 downto 0)
    );
  end component;
 
begin
  
 r_s(0)(SIZE_C-1 downto 0) <= a;
 r_s(0)(2*SIZE_C-1 downto SIZE_C) <= (others => '0');
 d_s(0)  <= d;
 q_s(0)  <= (others => '0');

 -----------------------------
 -- G1
 -----------------------------
 G1 : for n in 0 to SIZE_C-1 generate
   udivpipe : divpipe
   generic map
   (
     SIZE_C => SIZE_C   
   )
   port map
   (
      rst   => rst,  
      clk   => clk,
      ri    => r_s(n),
      di    => d_s(n),
      qi    => q_s(n),
          
      ro    => r_s(n+1),
      do    => d_s(n+1),
      qo    => q_s(n+1)   
   ); 
 end generate G1;
 
 -- remainder
 r <= STD_LOGIC_VECTOR( r_s(SIZE_C)(2*SIZE_C-1 downto SIZE_C) );
 
 -- quotient
 q <= STD_LOGIC_VECTOR( q_s(SIZE_C) );
 
end str;