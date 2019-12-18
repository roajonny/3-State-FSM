--This arbiter grants 3 processors - A, B, and C access to SRAM for a maximum of 64 clock cycles
--A has higher priority than B, and B has higher priority than C
--FSM implemented with a MOD-64 counter
--Three-process FSM separating Next-State, Current-State, and Output logic

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity Controller is
    Port ( clock, reset : in STD_LOGIC;
           ReA : in STD_LOGIC;
           ReB : in STD_LOGIC;
           ReC : in STD_LOGIC;
           AckA : out STD_LOGIC;
           AckB : out STD_LOGIC;
           AckC : out STD_LOGIC;
           EnA1 : out STD_LOGIC;
           EnB1 : out STD_LOGIC;
           EnC1 : out STD_LOGIC;
           EnA2 : out STD_LOGIC;
           EnB2 : out STD_LOGIC;
           EnC2 : out STD_LOGIC);
end Controller;

architecture Behavioral of Controller is

component ctr_mod is 
    Port ( clk : in STD_LOGIC;
           rst : in STD_LOGIC;
           en : in STD_LOGIC;
           output : out STD_LOGIC_VECTOR (6 downto 0);
           max_pulse : out STD_LOGIC);
end component;

type StateType is (IDLE, procA, procB, procC);
signal CurrentState, NextState : StateType;
signal times_up : STD_LOGIC;
signal counter_rst : STD_LOGIC;
signal s_transfer_ind : integer := 0;
signal ctr_en : STD_LOGIC := '1';
begin
ctr : ctr_mod port map (clk => clock, rst => counter_rst, max_pulse => times_up, en => ctr_en); 

--next-state logic
COMB: process(clock, reset, times_up, CurrentState) 
begin
    case CurrentState is
        when IDLE => --prioritizes processor A when in IDLE
            if (ReA = '1') then 
                NextState <= procA;
            elsif (ReA= '0' and ReB = '1') then 
                NextState <= procB;
            elsif (ReA = '0' and ReB = '0' and ReC = '1') then 
                NextState <= procC;
            end if;
            
        when procA => 
            if (times_up = '1') then --first checks if time is up
                if (reA = '1' and reB = '0' and reC = '0') then 
                    NextState <= procA; --loops back if no other requests
                elsif (reB = '1') then  
                    NextState <= procB;
                elsif (reB = '0' and reC = '1') then --otherwise goes to other processors if requesting
                    NextState <= procC;
                end if;
            else 
                if (reA = '0') then
                    if (reB = '1') then
                        NextState <= procB;
                    elsif (reB = '0' and reC = '1') then 
                        NextState <= procC;
                    else
                        NextState <= IDLE;
                    end if;
                 end if;
             end if;
        
        when procB => 
            if (times_up = '1') then
                if (ReA = '0' and ReB = '1' and ReC = '0') then
                    NextState <= procB;
                elsif (ReC = '1') then 
                    NextState <= procC;
                end if;
            else
                if (ReB = '0') then 
                    if (ReA = '1') then
                        NextState <= procA;
                    elsif (ReC = '1') then
                        NextState <= procC;
                    else
                        NextState <= IDLE;
                    end if;
                end if;
            end if;
            
        when procC =>
            if (times_up = '1') then
                if (reA = '1') then
                    NextState <= procA;
                elsif (reA = '0' and reB = '1') then
                    NextState <= procB;
                end if;
             else
                if (reC = '0') then
                    if (reA = '1') then 
                        NextState <= procA;
                    elsif (reA = '0' and reB = '1') then
                        NextState <= procB;
                    else
                        NextState <= IDLE;
                    end if;
                end if;
             end if;
             
         when others => 
            NextState <= IDLE;
         end case;
                 
end process COMB;

--counter reset process     
process (clock) 
begin 
 if (CurrentState /= NextState ) then
            counter_rst <= '1';
          else 
            counter_rst <= '0';
         end if;
         end process; 

--current-state logic             
SEQ : process (clock, reset, NextState) 
begin
        if (reset = '1') then
            CurrentState <= IDLE;
        elsif (clock'event and clock = '1') then
            CurrentState <= NextState;       
        end if;
end process SEQ;

--output logic
output_logic : process (CurrentState)
begin
    case CurrentState is --enables and acknowledges go high at the same time
        when procA =>
            EnA1 <= '1';
            EnA2 <= '1';
                AckA <= '1';
            EnB1 <= '0';
            EnB2 <= '0';
                AckB <= '0';
            EnC1 <= '0';
            EnC2 <= '0';
                AckC <= '0';
        when procB => 
            EnA1 <= '0';
            EnA2 <= '0';
                AckA <= '0'; 
            EnB1 <= '1';
            EnB2 <= '1';
                AckB <= '1';
            EnC1 <= '0';
            EnC2 <= '0';
                AckC <= '0';
        when procC => 
            EnA1 <= '0';
            EnA2 <= '0';
                AckA <= '0';
            EnB1 <= '0';
            EnB2 <= '0';
                AckB <= '0';
            EnC1 <= '1';
            EnC2 <= '1';
                AckC <= '1';
        when others => 
            EnA1 <= '0';
            EnA2 <= '0';
                AckA <= '0';
            EnB1 <= '0';
            EnB2 <= '0';
                AckB <= '0';
            EnC1 <= '0';
            EnC2 <= '0';
                AckC <= '0'; 
     end case;
  end process;   
end Behavioral;
