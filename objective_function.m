function [YSC, UD, CR_kg] = objective_function(sol, params, data)
% OBJECTIVE_FUNCTION
%   Computes Yearly System Cost (YSC) with epsilon-constraint penalties.
%   Eqs. 10-22 from Zhu et al. (2024).
%   Main objective : Min YSC = YIC + YRC + YFC + YOMC  (Eq. 16)
%   Constraints    : CR <= eps_CR  (Eq. 18)
%                    UD <= eps_UD  (Eq. 20)

PV_kW   = sol(1);
BAT_kWh = sol(2);
DG_kW   = sol(3);

sim   = simulate_system(sol, params, data);
UD    = sim.UD;
CR_kg = sim.CR_kg;

i     = params.i_real;
l_pr  = params.l_pr;
l_BAT = params.l_BAT;
l_INV = params.l_INV;

% Capital Recovery Factor
CRF  = i*(1+i)^l_pr / ((1+i)^l_pr - 1);

% Present Value Annuity Factor (inflation-adjusted O&M)
g    = params.i_infl;
if abs(i-g) < 1e-9
    PVAF = l_pr / (1+i);
else
    PVAF = (1 - ((1+g)/(1+i))^l_pr) / (i-g);
end

% PV (no replacement, no salvage)
YIC_PV   = params.C_inv_PV  * PV_kW  * CRF;
YOMC_PV  = params.YOMC1_PV  * PV_kW  * CRF * PVAF;
YCC_PV   = YIC_PV + YOMC_PV;

% Battery (replaced every l_BAT years)
YIC_BAT  = params.C_inv_BAT * BAT_kWh * CRF;
YRC_BAT  = params.C_rep_BAT * BAT_kWh * i / ((1+i)^l_BAT - 1);
YOMC_BAT = params.YOMC1_BAT * BAT_kWh * CRF * PVAF;
YCC_BAT  = YIC_BAT + YRC_BAT + YOMC_BAT;

% Converter (replaced every l_INV years)
YIC_INV  = params.C_inv_INV * PV_kW  * CRF;
YRC_INV  = params.C_rep_INV * PV_kW  * i / ((1+i)^l_INV - 1);
YOMC_INV = params.YOMC1_INV * PV_kW  * CRF * PVAF;
YCC_INV  = YIC_INV + YRC_INV + YOMC_INV;

% DG (no replacement)
YIC_DG   = params.C_inv_DG      * DG_kW        * CRF;
YFC_DG   = sim.fuel_L           * params.fuel_price;
YOMC_DG  = (params.YOMC1_DG    * sim.E_DG_yr  + ...
             params.YOMC1_DG_fix * DG_kW) * CRF * PVAF;
YCC_DG   = YIC_DG + YFC_DG + YOMC_DG;

YSC_base = YCC_PV + YCC_BAT + YCC_INV + YCC_DG;

% Quadratic penalty for constraint violations
M       = 1e8;
penalty = 0;
if CR_kg > params.eps_CR
    penalty = penalty + M * ((CR_kg - params.eps_CR)/params.eps_CR)^2;
end
if UD > params.eps_UD
    penalty = penalty + M * ((UD - params.eps_UD)/params.eps_UD)^2;
end

YSC = YSC_base + penalty;
end
