function plot_all_results(data, sim_out, history, costs, sens, params)
% PLOT_ALL_RESULTS  8 publication-quality figures for thesis.
c_pv=[0.93,0.69,0.13]; c_dg=[0.17,0.45,0.70];
c_batt=[0.30,0.65,0.30]; c_load=[0.85,0.20,0.10];
set(0,'DefaultAxesFontSize',13,'DefaultAxesLineWidth',1.5,'DefaultLineLineWidth',2.2);
% Fig1: Load profiles
figure('Name','Fig1 Load Profiles','Position',[50 650 700 280]);
h_sum=(172-1)*24+1:172*24; h_win=(355-1)*24+1:355*24;
plot(1:24,data.load_kW(h_sum),'-','Color',c_load,'DisplayName','Summer'); hold on;
plot(1:24,data.load_kW(h_win),'--','Color',c_dg,'DisplayName','Winter');
yline(params.peak_load,'k:',sprintf('Peak %.0f kW',params.peak_load),'HandleVisibility','off','LineWidth',1.8);
xlabel('Hour of Day','FontSize',14,'FontWeight','bold'); ylabel('Load (kW)','FontSize',14,'FontWeight','bold');
legend('Location','northwest','Box','off'); xlim([1 24]);
% Fig2a: Ambient Temperature
figure('Name','Fig2a Ambient Temperature','Position',[50 330 700 280]);
days=(1:8760)/24;
plot(days,data.T_amb,'Color',[0.8 0.2 0.2],'LineWidth',2.2);
ylabel('Temperature (°C)','FontSize',14,'FontWeight','bold'); xlabel('Day of Year','FontSize',14,'FontWeight','bold'); xlim([1 365]);
% Fig2b: Solar Irradiance (GHI)
figure('Name','Fig2b Solar Irradiance','Position',[780 330 700 280]);
plot(days,data.irr,'Color',c_pv,'LineWidth',2.2);
ylabel('GHI (kW/m²)','FontSize',14,'FontWeight','bold'); xlabel('Day of Year','FontSize',14,'FontWeight','bold'); xlim([1 365]);
% Fig3: EEFO convergence
figure('Name','EEFO Convergence','Position',[780 650 580 280]);
plot(1:numel(history),history/1000,'Color',c_dg);
xlabel('Number of Iteration','FontSize',14,'FontWeight','bold'); ylabel('Best YSC (k$/yr)','FontSize',14,'FontWeight','bold');
% Fig4: Energy dispatch
figure('Name','Fig4 Dispatch','Position',[780 330 800 480]);
subplot(2,1,1);
plot(1:24,data.load_kW(h_sum),'-','Color',c_load,'DisplayName','Load'); hold on;
plot(1:24,sim_out.E_PV(h_sum)*params.eta_inv,'-','Color',c_pv,'DisplayName','PV');
plot(1:24,sim_out.E_DG(h_sum),'--','Color',c_dg,'DisplayName','DG');
ylabel('Power (kW)','FontSize',14,'FontWeight','bold');
legend('Box','off'); xlim([1 24]);
title('(a)','FontSize',14,'FontName','Times New Roman','FontWeight','bold');
subplot(2,1,2);
plot(1:24,data.load_kW(h_win),'-','Color',c_load,'DisplayName','Load'); hold on;
plot(1:24,sim_out.E_PV(h_win)*params.eta_inv,'-','Color',c_pv,'DisplayName','PV');
plot(1:24,sim_out.E_DG(h_win),'--','Color',c_dg,'DisplayName','DG');
ylabel('Power (kW)','FontSize',14,'FontWeight','bold'); xlabel('Hour','FontSize',14,'FontWeight','bold'); legend('Box','off'); xlim([1 24]);
title('(b)','FontSize',14,'FontName','Times New Roman','FontWeight','bold');
% Fig5: Battery SOC
figure('Name','Fig5 Battery SOC','Position',[50 50 700 280]);
BAT_cap=max(sim_out.S_batt)*1.05;
plot(1:24,sim_out.S_batt(h_sum)/BAT_cap*100,'-','Color',c_batt,'DisplayName','Summer'); hold on;
plot(1:24,sim_out.S_batt(h_win)/BAT_cap*100,'--','Color',c_dg,'DisplayName','Winter');
yline(params.SOC_min*100,'r:','SOC_{min}=20%','LineWidth',1.8);
xlabel('Hour','FontSize',14,'FontWeight','bold'); ylabel('SOC (%)','FontSize',14,'FontWeight','bold'); legend('Box','off'); xlim([1 24]);
% Fig6: Monthly energy
figure('Name','Fig6 Monthly Energy','Position',[760 50 800 320]);
dpm=[31,28,31,30,31,30,31,31,30,31,30,31];
mpv=zeros(12,1); mdg=zeros(12,1); mld=zeros(12,1); h=1;
for m=1:12, idx=h:h+dpm(m)*24-1;
    mpv(m)=sum(sim_out.E_PV(idx)); mdg(m)=sum(sim_out.E_DG(idx));
    mld(m)=sum(data.load_kW(idx)); h=h+dpm(m)*24; end
bar(1:12,[mpv,mdg]/1000,'stacked','FaceAlpha',0.85);
ylabel('Energy (MWh/month)','FontSize',14,'FontWeight','bold');
set(gca,'XTickLabel',{'J','F','M','A','M','J','J','A','S','O','N','D'});
legend('PV','DG','Location','northwest','Box','off');
% Fig7: Cost pie
figure('Name','Fig7 Cost Breakdown','Position',[50 50 520 400]);
pie(costs.YCC_vec,[0,1,0,0],...
    {sprintf('PV\n$%.0f/yr',costs.YCC_PV),...
     sprintf('Battery\n$%.0f (%.0f%%)',costs.YCC_BAT,costs.YCC_BAT/costs.YSC*100),...
     sprintf('Converter\n$%.0f/yr',costs.YCC_INV),...
     sprintf('DG\n$%.0f/yr',costs.YCC_DG)});
% Fig8: Sensitivity
figure('Name','Fig8 Sensitivity','Position',[580 50 1000 320]);
subplot(1,3,1);
yyaxis left; plot(sens.load_scales,sens.YSC_load/1000,'b-o','MarkerFaceColor','b');
ylabel('YSC (k$/yr)','FontSize',14,'FontWeight','bold');
yyaxis right; plot(sens.load_scales,sens.PV_load,'r--s','MarkerFaceColor','r');
ylabel('PV size (kW)','FontSize',14,'FontWeight','bold'); xlabel('Load Scale','FontSize',14,'FontWeight','bold');
legend('YSC','PV size','Location','northwest','Box','off');
subplot(1,3,2);
plot(sens.ACR_vals/1000,sens.YSC_acr/1000,'r-o','MarkerFaceColor','r');
xlabel('ACR Limit (t CO_2/yr)','FontSize',14,'FontWeight','bold'); ylabel('YSC (k$/yr)','FontSize',14,'FontWeight','bold');
subplot(1,3,3);
plot(sens.AUD_vals,sens.YSC_aud/1000,'g-o','MarkerFaceColor','g');
xlabel('AUD Limit (%)','FontSize',14,'FontWeight','bold'); ylabel('YSC (k$/yr)','FontSize',14,'FontWeight','bold');
fprintf('  Figures 1-8 generated.\n');
end