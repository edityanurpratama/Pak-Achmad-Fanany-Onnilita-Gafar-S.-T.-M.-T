% RiskLaptop_GUI_Octave.m
% GUI Octave untuk FIS Mamdani (tanpa toolkit)
% Jalankan: octave RiskLaptop_GUI_Octave.m  (jalankan Octave GUI)

clear; clc; close all;

% ------------------------
% DEFINISI MF PARAMS (trapmf [a b c d])
% ------------------------
suhu_params = [30 30 50 55; 50 60 70 75; 70 80 90 90];
suhu_names  = {'Rendah','Sedang','Tinggi'};
suhu_range = linspace(30,90,601)';

batt_params = [0 0 50 60; 50 65 80 85; 80 90 100 100];
batt_names  = {'Buruk','Sedang','Bagus'};
batt_range = linspace(0,100,601)';

pem_params = [0 0 3 4; 2 4 6 7; 6 8 12 12];
pem_names  = {'Ringan','Sedang','Berat'};
pem_range = linspace(0,12,601)';

out_params = [0 0 30 40; 30 50 60 70; 60 75 100 100];
out_names  = {'Rendah','Sedang','Tinggi'};
out_range = linspace(0,100,1001)';

% rules: [suhu_idx batt_idx pem_idx out_idx weight operator(1=AND,2=OR)]
rules = [
 1 3 1 1 1 1;
 2 2 2 2 1 1;
 3 1 3 3 1 2;
 2 3 1 1 1 1;
 1 2 3 2 1 1;
 3 3 2 2 1 1;
];

% ------------------------
% GUI layout
% ------------------------
h.fig = figure('Name','FIS Risiko Laptop - Octave GUI','NumberTitle','off','Position',[200 80 1200 760]);

% axes: MF inputs (left column, 3 stacked), aggregated (right top), rule activations (right bottom)
h.ax1 = axes('Parent',h.fig,'Position',[0.05 0.66 0.43 0.30]); % Suhu
h.ax2 = axes('Parent',h.fig,'Position',[0.05 0.36 0.43 0.28]); % Baterai
h.ax3 = axes('Parent',h.fig,'Position',[0.05 0.06 0.43 0.28]); % Pemakaian

h.axAgg = axes('Parent',h.fig,'Position',[0.52 0.52 0.45 0.42]); % aggregated
h.axRules = axes('Parent',h.fig,'Position',[0.52 0.06 0.45 0.38]); % rule activations

% Controls: sliders + numeric displays
uicontrol('Style','text','Parent',h.fig,'Position',[520 700 200 24],'String','Suhu (°C)','FontWeight','bold');
h.suhu_slider = uicontrol('Style','slider','Parent',h.fig,'Min',30,'Max',90,'Value',78,'Position',[520 680 380 20], 'Callback', @update_callback);
h.suhu_val_txt = uicontrol('Style','text','Parent',h.fig,'Position',[910 680 80 20],'String','78');

uicontrol('Style','text','Parent',h.fig,'Position',[520 640 200 24],'String','Baterai (%)','FontWeight','bold');
h.batt_slider = uicontrol('Style','slider','Parent',h.fig,'Min',0,'Max',100,'Value',55,'Position',[520 620 380 20], 'Callback', @update_callback);
h.batt_val_txt = uicontrol('Style','text','Parent',h.fig,'Position',[910 620 80 20],'String','55');

uicontrol('Style','text','Parent',h.fig,'Position',[520 580 200 24],'String','Pemakaian (jam)','FontWeight','bold');
h.pem_slider = uicontrol('Style','slider','Parent',h.fig,'Min',0,'Max',12,'Value',8,'Position',[520 560 380 20], 'Callback', @update_callback);
h.pem_val_txt = uicontrol('Style','text','Parent',h.fig,'Position',[910 560 80 20],'String','8');

h.predict_btn = uicontrol('Style','pushbutton','Parent',h.fig,'String','Predict','Position',[1020 700 120 40],'FontWeight','bold','Callback',@predict_button_cb);

% Result display
h.result_txt = uicontrol('Style','text','Parent',h.fig,'Position',[1020 640 160 40],'String','Risk: --','FontSize',12,'FontWeight','bold');

% Precompute MF grids
suhu_M = compute_mf_grid(suhu_range, suhu_params);
batt_M = compute_mf_grid(batt_range, batt_params);
pem_M  = compute_mf_grid(pem_range, pem_params);
out_M  = compute_mf_grid(out_range, out_params);

% Initial plots (store line handles for fast updates)
% Suhu MF
axes(h.ax1);
cla(h.ax1);
hold on;
for i=1:size(suhu_params,1)
    lh_suhu(i) = plot(suhu_range, suhu_M(:,i), 'LineWidth', 2);
end
vline_suhu = plot([78 78], ylim(h.ax1), 'r--','LineWidth',1.8);
title('Membership Functions - Suhu (°C)');
legend(suhu_names,'Location','northwest');
grid on;

% Baterai MF
axes(h.ax2);
cla(h.ax2);
hold on;
for i=1:size(batt_params,1)
    lh_batt(i) = plot(batt_range, batt_M(:,i), 'LineWidth', 2);
end
vline_batt = plot([55 55], ylim(h.ax2), 'r--','LineWidth',1.8);
title('Membership Functions - Baterai (%)');
legend(batt_names,'Location','northwest');
grid on;

% Pemakaian MF
axes(h.ax3);
cla(h.ax3);
hold on;
for i=1:size(pem_params,1)
    lh_pem(i) = plot(pem_range, pem_M(:,i), 'LineWidth', 2);
end
vline_pem = plot([8 8], ylim(h.ax3), 'r--','LineWidth',1.8);
title('Membership Functions - Pemakaian (jam/hari)');
legend(pem_names,'Location','northwest');
grid on;

% Aggregated initial
axes(h.axAgg);
cla(h.axAgg);
agg_line = plot(out_range, zeros(size(out_range)),'LineWidth',2); hold on;
agg_area = area(out_range, zeros(size(out_range))); agg_area.FaceAlpha = 0.35; agg_area.FaceColor = [0.9 0.9 0.2];
% overlay output MF outlines
for k=1:size(out_params,1)
   out_mf_lines(k) = plot(out_range, out_M(:,k),'--','LineWidth',1);
end
centroid_line = plot([nan nan], ylim(h.axAgg), 'r-','LineWidth',2);
title('Aggregated Output & Defuzzification (centroid)');
grid on;

% Rule activations initial
axes(h.axRules);
cla(h.axRules);
barh_handle = barh(1:length(rules), zeros(length(rules),1));
yticks(1:length(rules));
yticklabels(compose("Rule %d",1:length(rules)));
xlim([0 1]);
title('Rule Activations');
grid on;

% Run initial update to show correct values
update_all();

% ============================
% CALLBACKS & FUNCTIONS
% ============================
function update_callback(src, ~)
    % Called when slider changes - update display values and plots live
    hs = guidata(gcbf);
    suhu_val = get(hs.suhu_slider, 'Value');
    batt_val = get(hs.batt_slider, 'Value');
    pem_val  = get(hs.pem_slider,  'Value');
    % update numeric text
    set(hs.suhu_val_txt, 'String', sprintf('%.1f', suhu_val));
    set(hs.batt_val_txt, 'String', sprintf('%.1f', batt_val));
    set(hs.pem_val_txt,  'String', sprintf('%.1f', pem_val));
    % update vertical lines
    set(vline_suhu, 'XData', [suhu_val suhu_val]);
    set(vline_batt, 'XData', [batt_val batt_val]);
    set(vline_pem,  'XData', [pem_val pem_val]);
    % recompute and update aggregated + rules
    update_agg_and_rules(suhu_val, batt_val, pem_val);
    guidata(gcbf, hs);
endfunction

function predict_button_cb(~, ~)
    hs = guidata(gcbf);
    suhu_val = get(hs.suhu_slider, 'Value');
    batt_val = get(hs.batt_slider, 'Value');
    pem_val  = get(hs.pem_slider,  'Value');
    % compute final value and show
    [centroid, cat] = evaluate_fis_and_return(suhu_val, batt_val, pem_val);
    set(hs.result_txt, 'String', sprintf('Risk: %.2f (%s)', centroid, cat));
endfunction

function update_all()
    % update everything once at start
    hs = guidata(gcbf);
    if isempty(hs)
        hs = h; % capture handles defined in base workspace
    end
    % set initial numeric labels to slider defaults
    set(hs.suhu_val_txt, 'String', sprintf('%.1f', get(hs.suhu_slider,'Value')));
    set(hs.batt_val_txt, 'String', sprintf('%.1f', get(hs.batt_slider,'Value')));
    set(hs.pem_val_txt,  'String', sprintf('%.1f', get(hs.pem_slider,'Value')));
    % call update for current values
    update_callback([],[]);
endfunction

function update_agg_and_rules(suhu_val, batt_val, pem_val)
    % recompute firing, aggregated, centroid and update plots
    % compute degrees
    deg_s = zeros(1,size(suhu_params,1));
    for i=1:size(suhu_params,1), deg_s(i)=trapmf_scalar(suhu_val, suhu_params(i,:)); end
    deg_b = zeros(1,size(batt_params,1));
    for i=1:size(batt_params,1), deg_b(i)=trapmf_scalar(batt_val, batt_params(i,:)); end
    deg_p = zeros(1,size(pem_params,1));
    for i=1:size(pem_params,1), deg_p(i)=trapmf_scalar(pem_val, pem_params(i,:)); end

    % firing strengths
    firing = zeros(size(rules,1),1);
    for r=1:size(rules,1)
        s_idx = rules(r,1); b_idx = rules(r,2); p_idx = rules(r,3); op = rules(r,6);
        ds = 1; db = 1; dp = 1;
        if s_idx>0, ds = deg_s(s_idx); endif
        if b_idx>0, db = deg_b(b_idx); endif
        if p_idx>0, dp = deg_p(p_idx); endif
        if op==1, firing(r)=min([ds,db,dp]); else firing(r)=max([ds,db,dp]); endif
    endfor

    % aggregated output
    agg_vals = zeros(size(out_range));
    out_mf_grid = compute_mf_grid(out_range, out_params);
    for r=1:size(rules,1)
        out_idx = rules(r,4);
        if out_idx==0, continue; endif
        truncated = min(firing(r), out_mf_grid(:,out_idx));
        agg_vals = max(agg_vals, truncated);
    endfor

    % centroid
    if sum(agg_vals)==0
        centroid = NaN;
    else
        centroid = sum(out_range .* agg_vals) / sum(agg_vals);
    end

    % update aggregated plot lines & area
    set(agg_line, 'YData', agg_vals);
    set(agg_area, 'YData', agg_vals);
    for k=1:length(out_mf_lines)
        set(out_mf_lines(k), 'YData', out_M(:,k));
    end
    yl = ylim(h.axAgg);
    if ~isnan(centroid)
        set(centroid_line, 'XData', [centroid centroid], 'YData', yl);
    else
        set(centroid_line, 'XData', [NaN NaN]);
    end

    % update rule-activation bars
    axes(h.axRules);
    cla(h.axRules);
    barh(firing);
    yticks(1:size(rules,1)); yticklabels(compose("Rule %d",1:size(rules,1)));
    xlim([0 1]); grid on; title('Rule Activations');

    % update result text
    cat = 'Unknown';
    if ~isnan(centroid)
        if centroid < 40, cat='Rendah'; elseif centroid < 70, cat='Sedang'; else cat='Tinggi'; endif
    end
    set(h.result_txt, 'String', sprintf('Risk: %.2f (%s)', centroid, cat));
endfunction

function [centroid, category] = evaluate_fis_and_return(suhu_val, batt_val, pem_val)
    % convenience function returning centroid and category
    % compute degs
    deg_s = zeros(1,size(suhu_params,1));
    for i=1:size(suhu_params,1), deg_s(i)=trapmf_scalar(suhu_val, suhu_params(i,:)); end
    deg_b = zeros(1,size(batt_params,1));
    for i=1:size(batt_params,1), deg_b(i)=trapmf_scalar(batt_val, batt_params(i,:)); end
    deg_p = zeros(1,size(pem_params,1));
    for i=1:size(pem_params,1), deg_p(i)=trapmf_scalar(pem_val, pem_params(i,:)); end

    firing = zeros(size(rules,1),1);
    for r=1:size(rules,1)
        s_idx = rules(r,1); b_idx = rules(r,2); p_idx = rules(r,3); op = rules(r,6);
        ds = 1; db = 1; dp = 1;
        if s_idx>0, ds = deg_s(s_idx); endif
        if b_idx>0, db = deg_b(b_idx); endif
        if p_idx>0, dp = deg_p(p_idx); endif
        if op==1, firing(r)=min([ds,db,dp]); else firing(r)=max([ds,db,dp]); endif
    endfor

    % aggregated
    agg_vals = zeros(size(out_range));
    out_mf_grid = compute_mf_grid(out_range, out_params);
    for r=1:size(rules,1)
        out_idx = rules(r,4);
        if out_idx==0, continue; endif
        truncated = min(firing(r), out_mf_grid(:,out_idx));
        agg_vals = max(agg_vals, truncated);
    endfor

    if sum(agg_vals)==0
        centroid = NaN;
    else
        centroid = sum(out_range .* agg_vals) / sum(agg_vals);
    end

    if isnan(centroid)
        category = 'Unknown';
    elseif centroid < 40
        category = 'Rendah';
    elseif centroid < 70
        category = 'Sedang';
    else
        category = 'Tinggi';
    end
endfunction

% ------------------------
% Utility functions (end of file)
% ------------------------
function mu = trapmf_scalar(x, params)
    a = params(1); b = params(2); c = params(3); d = params(4);
    mu = 0;
    if x >= a && x < b
        if b > a, mu = (x - a) / (b - a); endif
    elseif x >= b && x <= c
        mu = 1;
    elseif x > c && x <= d
        if d > c, mu = (d - x) / (d - c); endif
    else
        mu = 0;
    end
endfunction

function M = compute_mf_grid(xgrid, params_mat)
    n = size(params_mat,1);
    M = zeros(length(xgrid), n);
    for i = 1:n
        for j = 1:length(xgrid)
            M(j,i) = trapmf_scalar(xgrid(j), params_mat(i,:));
        endfor
    endfor
endfunction

% store gui handles so callbacks can access them
guidata(h.fig, h);
