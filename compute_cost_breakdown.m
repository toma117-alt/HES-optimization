function costs = compute_cost_breakdown(sol, params, sim_out)
% COMPUTE_COST_BREAKDOWN
%   Full annualized cost breakdown per component.
%   Uses identical economic model as objective_function.m.

PV_kW   = sol(1);
BAT_kWh = sol(2);
DG_kW   = sol(3);

i     = params.i_real;
l_pr  = params.l_pr;
l_BAT = params.l_BAT;
l_INV = params.l_INV;

CRF  = i*(1+i)^l_pr / ((1+i)^l_pr - 1);
g    = params.i_infl;
if abs(i-g) < 1e-9, PVAF = l_pr/(1+i);
else, PVAF = (1-((1+g)/(1+i))^l_pr)/(i-g); end

costs.YIC_PV   = params.C_inv_PV  * PV_kW  * CRF;
costs.YRC_PV   = 0;
costs.YFC_PV   = 0;
costs.YOMC_PV  = params.YOMC1_PV  * PV_kW  * CRF * PVAF;
costs.YCC_PV   = costs.YIC_PV + costs.YOMC_PV;

costs.YIC_BAT  = params.C_inv_BAT * BAT_kWh * CRF;
costs.YRC_BAT  = params.C_rep_BAT * BAT_kWh * i / ((1+i)^l_BAT - 1);
costs.YFC_BAT  = 0;
costs.YOMC_BAT = params.YOMC1_BAT * BAT_kWh * CRF * PVAF;
costs.YCC_BAT  = costs.YIC_BAT + costs.YRC_BAT + costs.YOMC_BAT;

costs.YIC_INV  = params.C_inv_INV * PV_kW  * CRF;
costs.YRC_INV  = params.C_rep_INV * PV_kW  * i / ((1+i)^l_INV - 1);
costs.YFC_INV  = 0;
costs.YOMC_INV = params.YOMC1_INV * PV_kW  * CRF * PVAF;
costs.YCC_INV  = costs.YIC_INV + costs.YRC_INV + costs.YOMC_INV;

costs.YIC_DG   = params.C_inv_DG      * DG_kW       * CRF;
costs.YRC_DG   = 0;
costs.YFC_DG   = sim_out.fuel_L       * params.fuel_price;
costs.YOMC_DG  = (params.YOMC1_DG    * sim_out.E_DG_yr + ...
                  params.YOMC1_DG_fix * DG_kW) * CRF * PVAF;
costs.YCC_DG   = costs.YIC_DG + costs.YFC_DG + costs.YOMC_DG;

costs.YIC_tot  = costs.YIC_PV  + costs.YIC_BAT  + costs.YIC_INV  + costs.YIC_DG;
costs.YRC_tot  = costs.YRC_BAT + costs.YRC_INV;
costs.YFC_tot  = costs.YFC_DG;
costs.YOMC_tot = costs.YOMC_PV + costs.YOMC_BAT + costs.YOMC_INV + costs.YOMC_DG;
costs.YSC      = costs.YCC_PV  + costs.YCC_BAT  + costs.YCC_INV  + costs.YCC_DG;

costs.COE      = costs.YSC / max(sim_out.E_load_yr, 1);
costs.RF       = sim_out.RF * 100;
costs.labels   = {'PV','Battery','Converter','DG'};
costs.YCC_vec  = [costs.YCC_PV, costs.YCC_BAT, costs.YCC_INV, costs.YCC_DG];
end
