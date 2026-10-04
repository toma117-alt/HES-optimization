function save_all_figures(folder)
% SAVE_ALL_FIGURES
%   Saves all open figures as high-resolution PNG files.
%   Called automatically by main.m after all plots are generated.

if nargin < 1, folder = 'MATLAB_Results_Figures'; end
if ~exist(folder, 'dir'), mkdir(folder); end

figs = findall(0, 'Type', 'figure');
if isempty(figs)
    fprintf('  No figures to save.\n');
    return;
end

% Figure name mapping
name_map = {
    'Fig1 Load Profiles',           'Fig01_Load_Profiles_Sandwip';
    'Fig2 Solar & Temperature',     'Fig02_Solar_Temperature_NASA';
    'Fig3 EEFO Convergence',        'Fig03_EEFO_Convergence_Curve';
    'Fig4 Dispatch',                'Fig04_Energy_Dispatch_Summer_Winter';
    'Fig5 Battery SOC',             'Fig05_Battery_State_of_Charge';
    'Fig6 Monthly Energy',          'Fig06_Monthly_Energy_Balance';
    'Fig7 Cost Breakdown',          'Fig07_Cost_Breakdown_Pie';
    'Fig8 Sensitivity',             'Fig08_Sensitivity_Analysis';
    'EEFO vs iHOGA Comparison',     'Fig09_EEFO_vs_HOMER_Comparison';
    'EW1 Irradiance',               'Fig10_EW_Irradiance_Scenarios';
    'EW2 Battery SOC',              'Fig11_EW_Battery_SOC_Cyclone';
    'EW3 Unmet Demand',             'Fig12_EW_Unmet_Demand';
    'EW4 Sizing Comparison',        'Fig13_EW_Sizing_Comparison';
    'EW5 Energy Not Served',        'Fig14_EW_Energy_Not_Served';
};

saved = 0;
for k = 1:numel(figs)
    fig = figs(k);
    fig_name = get(fig, 'Name');

    % Find matching filename
    fname = sprintf('Figure_%d', k);
    for m = 1:size(name_map,1)
        if contains(fig_name, name_map{m,1})
            fname = name_map{m,2};
            break;
        end
    end

    % Save as high-resolution PNG
    out_path = fullfile(folder, [fname '.png']);
    try
        exportgraphics(fig, out_path, 'Resolution', 300);
        fprintf('  Saved: %s.png\n', fname);
        saved = saved + 1;
    catch
        % Fallback for older MATLAB versions
        saveas(fig, out_path);
        fprintf('  Saved: %s.png\n', fname);
        saved = saved + 1;
    end
end

fprintf('  Total: %d figures saved to %s/\n', saved, folder);
fprintf('  Ready for thesis — 300 DPI resolution\n');
end
