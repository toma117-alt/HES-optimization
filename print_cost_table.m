function print_cost_table(costs)
% PRINT_COST_TABLE  Displays formatted cost breakdown in Command Window.
fprintf('\n  %-12s %10s %10s %10s %10s %10s\n','Component','YIC[$]','YRC[$]','YFC[$]','YOMC[$]','YCC[$]');
fprintf('  %s\n',repmat('-',1,65));
comps={'PV','BAT','INV','DG'}; names={'PV','Battery','Converter','DG'};
for k=1:4, c=comps{k};
    fprintf('  %-12s %10.2f %10.2f %10.2f %10.2f %10.2f\n',names{k},...
        costs.(['YIC_' c]),costs.(['YRC_' c]),costs.(['YFC_' c]),...
        costs.(['YOMC_' c]),costs.(['YCC_' c]));
end
fprintf('  %s\n',repmat('-',1,65));
fprintf('  %-12s %10.2f %10.2f %10.2f %10.2f %10.2f\n','TOTAL',...
    costs.YIC_tot,costs.YRC_tot,costs.YFC_tot,costs.YOMC_tot,costs.YSC);
fprintf('  %s\n',repmat('-',1,65));
fprintf('  COE = $%.4f/kWh  |  Renewable Fraction = %.1f%%\n',costs.COE,costs.RF);
end
