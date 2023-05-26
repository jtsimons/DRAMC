library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity DRAMC is
	port (
		-- Inputs
		R_CMD, W_CMD, RESET, CLK: in std_logic;
		-- Outputs
		MUX_SEL, CAS, RAS, W, CLK_OUT: out std_logic
	);
end DRAMC;

architecture BEHAVIORAL of DRAMC is

	-- State assignments
	type state is (
		idle_s, RAD_s, pre_w_s, pre_r_s, CASR_s, CASW_s, PR_s
	);
	
	-- Present/next state signals, counter signals, constants
	signal present_s, next_s: state := idle_s;
	signal tRAD_ctr, tPW_ctr, tPRR_ctr, tCASR_ctr, tCASW_ctr, tPR_ctr: integer := 1;
	constant tRAD: integer := 5;
	constant tPW, tPRR, tCASR, tCASW: integer := 2;
	constant tPR: integer := 5;
	
begin
	
	-- Finite state machine process
	FSM: process(present_s, W_CMD, R_CMD, tRAD_ctr, tPW_ctr, tPRR_ctr, tCASR_ctr, tCASW_ctr, tPR_ctr)
	begin
		-- Handle present/next state
		case present_s is
			-- Idle state
			when idle_s =>
				RAS <= '1';
				CAS <= '1';
				MUX_SEL <= '0';
				W <= '1';
				if (W_CMD = '0' or R_CMD = '0') then
					next_s <= RAD_s;
				else
					next_s <= idle_s;
				end if;
			-- RAD state
			when RAD_s =>
				RAS <= '0';
				CAS <= '1';
				MUX_SEL <= '0';
				W <= '1';
				if (tRAD_ctr = tRAD) then
					-- Go to read/write cycles
					if (W_CMD = '0' and R_CMD = '1') then
						next_s <= pre_w_s;
					elsif (W_CMD = '1' and R_CMD = '0') then
						next_s <= pre_r_s;
					else
						next_s <= pre_r_s;
					end if;
				else
					next_s <= RAD_s;
				end if;
			-- Pre-write state
			when pre_w_s =>
				RAS <= '0';
				CAS <= '1';
				MUX_SEL <= '1';
				W <= '0';
				if (tPW_ctr = tPW) then
					next_s <= CASW_s;
				else
					next_s <= pre_w_s;
				end if;
			-- Pre-read state
			when pre_r_s =>
				RAS <= '0';
				CAS <= '1';
				MUX_SEL <= '1';
				W <= '1';
				if (tPRR_ctr = tPRR) then
					next_s <= CASR_s;
				else
					next_s <= pre_r_s;
				end if;
			-- CASW state
			when CASW_s =>
				RAS <= '0';
				CAS <= '0';
				MUX_SEL <= '1';
				W <= '0';
				if (tCASW_ctr = tCASW) then
					next_s <= CASW_s;
				else
					next_s <= PR_s;
				end if;
			-- CASR state
			when CASR_s =>
				RAS <= '0';
				CAS <= '0';
				MUX_SEL <= '1';
				W <= '1';
				if (tCASR_ctr = tCASR) then
					next_s <= CASR_s;
				else
					next_s <= PR_s;
				end if;
			-- PR state
			when PR_s =>
				RAS <= '1';
				CAS <= '1';
				MUX_SEL <= '0';
				W <= '1';
				if (tPR_ctr = tPR) then
					next_s <= idle_s;
				else
					next_s <= PR_s;
				end if;
			-- Default
			when others =>
				RAS <= '1';
				CAS <= '1';
				MUX_SEL <= '0';
				W <= '1';
				next_s <= idle_s;
		end case;
	end process FSM;
	
	-- Counters process
	counters: process(tRAD_ctr, tPW_ctr, tPRR_ctr, tCASR_ctr, tCASW_ctr, tPR_ctr, CLK)
	begin
		-- Check present state and adjust counters accordingly
		if (rising_edge(CLK)) then
			if (present_s = RAD_s) then
				tRAD_ctr <= tRAD_ctr + 1;
			else
				tRAD_ctr <= 1;
			end if;
			if (present_s = pre_w_s) then
				tPW_ctr <= tPW_ctr + 1;
			else
				tPW_ctr <= 1;
			end if;
			if (present_s = CASW_s) then
				tCASW_ctr <= tCASW_ctr + 1;
			else
				tCASW_ctr <= 1;
			end if;
			if (present_s = CASR_s) then
				tCASR_ctr <= tCASR_ctr + 1;
			else
				tCASR_ctr <= 1;
			end if;
			if (present_s = PR_s) then
				tPR_ctr <= tPR_ctr + 1;
			else
				tPR_ctr <= 1;
			end if;
		end if;
	end process counters;
	
	-- Clock process
	clock: process(CLK, RESET)
	begin
		CLK_OUT <= CLK;
		-- Active low reset
		if (RESET = '0') then
			present_s <= idle_s;
		elsif (rising_edge(CLK)) then
			present_s <= next_s;
		end if;
	end process clock;
	
end BEHAVIORAL;
