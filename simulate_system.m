function out = simulate_system(sol, params, data)
% SIMULATE_SYSTEM
%   Hourly dispatch of hybrid PV-Battery-DG system.
%   Dispatch priority: PV -> Battery -> DG -> Unmet demand
%   Strategy: Load Following (Zhu et al. 2024, Section 4)
%   sol = [PV_kW, BAT_kWh, DG_kW]

PV_nom  = sol(1);
BAT_nom = sol(2);
DG_nom  = sol(3);
T       = data.T;

eta_inv = params.eta_inv;
eta_b   = params.eta_batt;
delta   = params.delta;
SOC_min = params.SOC_min;
SOC_max = params.SOC_max;
zeta    = params.zeta;
tau_dg  = params.tau_dg;
CCR     = params.CCR;
fc      = params.fc;
FPT     = params.FPT;
I_nom   = params.I_nom;
Tc_nom  = params.Tcell_nom;

E_PV    = zeros(T,1);
E_DG    = zeros(T,1);
F_DG    = zeros(T,1);
S_batt  = zeros(T+1,1);
E_sup   = zeros(T,1);
E_unmet = zeros(T,1);
E_dump  = zeros(T,1);

S_batt(1) = 0.50 * BAT_nom;   % start at 50% SOC

%% PV generation model (Eqs. 1-2)
for t = 1:T
    I_t    = data.irr(t);
    T_a    = data.T_amb(t);
    T_cell = T_a + (I_t/I_nom) * (Tc_nom-20) / 0.8;
    E_PV(t)= PV_nom * (I_t/I_nom) * fc * (1 + FPT*(T_cell-25));
    E_PV(t)= max(0, min(E_PV(t), PV_nom));
end

%% Hourly dispatch
for t = 1:T
    E_load   = data.load_kW(t);
    S_prev   = delta * S_batt(t);     % apply self-discharge first
    E_pv_ac  = E_PV(t) * eta_inv;    % PV output after inverter

    if E_pv_ac >= E_load
        %% CASE A: PV surplus
        E_sup(t)  = E_load;
        E_surplus = E_pv_ac - E_load;
        S_new = S_prev + E_surplus * eta_b;
        if S_new > SOC_max * BAT_nom
            E_dump(t) = (S_new - SOC_max*BAT_nom) / eta_b;
            S_new     = SOC_max * BAT_nom;
        end
        S_batt(t+1) = S_new;

    else
        %% CASE B: PV deficit
        E_deficit    = E_load - E_pv_ac;
        E_batt_avail = max(0, S_prev - SOC_min*BAT_nom);
        E_batt_ac    = E_batt_avail * eta_inv;

        if E_batt_ac >= E_deficit
            %% B1: Battery alone covers deficit
            S_batt(t+1) = max(S_prev - E_deficit/eta_inv, SOC_min*BAT_nom);
            E_sup(t)    = E_load;

        else
            %% B2: PV + Battery not enough, DG needed
            S_batt(t+1) = SOC_min * BAT_nom;
            E_pv_bat_ac = E_pv_ac + E_batt_ac;

            E_dg_needed = E_load - E_pv_bat_ac;
            % Enforce DG minimum loading ratio
            if E_dg_needed > 0 && E_dg_needed < params.DG_min_load * DG_nom
                E_dg_out = params.DG_min_load * DG_nom;
            else
                E_dg_out = min(max(E_dg_needed, 0), DG_nom);
            end

            E_DG(t)    = E_dg_out;
            E_sup(t)   = min(E_load, E_pv_bat_ac + E_dg_out);
            E_unmet(t) = max(0, E_load - E_sup(t));

            % Fuel consumption (Eq. 7)
            if E_dg_out > 0
                F_DG(t) = zeta * DG_nom + tau_dg * E_dg_out;
            end
        end
    end
end

%% Outputs
total_load  = sum(data.load_kW);
total_unmet = sum(E_unmet);

out.E_PV      = E_PV;
out.E_DG      = E_DG;
out.F_DG      = F_DG;
out.S_batt    = S_batt(1:T);
out.E_sup     = E_sup;
out.E_unmet   = E_unmet;
out.E_dump    = E_dump;

out.UD        = total_unmet / max(total_load, 1e-9);       % Eq. 19
out.CR_kg     = sum(F_DG) * CCR;                           % Eq. 17 [kg/yr]
out.CR        = out.CR_kg / 1000;                          % [t/yr]
out.fuel_L    = sum(F_DG);                                 % [L/yr]
out.E_PV_yr   = sum(E_PV);
out.E_DG_yr   = sum(E_DG);
out.E_load_yr = total_load;
out.E_dump_yr = sum(E_dump);
out.RF        = max(0, min(1, 1 - sum(E_DG)/max(sum(E_sup),1e-9)));
out.COE       = 0;   % filled by compute_cost_breakdown
end
