% RiskLaptop_GUI_Octave_save_images.m
% GUI Octave untuk FIS Mamdani (tanpa toolkit) + simpan per-gambar otomatis
% Jalankan: octave --gui RiskLaptop_GUI_Octave_save_images.m

clear; clc; close all;

% ------------------------
% KONFIGURASI PENYIMPANAN (ubah jika perlu)
% ------------------------
base_folder = 'E:/Pak-Achmad-Fanany-Onnilita-Gafar-S.-T.-M.-T/MP1_Kelompok02_5D/code/images';
save_png = true;      % Simpan format PNG
save_svg = true;      % Simpan format SVG (vektor)
save_gui = true;      % Simpan tangkapan layar GUI lengkap
use_timestamp = true; % Tambahkan timestamp ke nama file

% Buang folder jika sudah ada
mf_folder = fullfile(base_folder, 'mf_plots');
if ~exist(mf_folder, 'dir')
    mkdir(mf_folder);
end

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
 1 3 1 1 1 1;   % Jika Suhu Rendah DAN Baterai Bagus DAN Pemakaian Ringan MAKA Risiko Rendah
 2 2 2 2 1 1;   % Jika Suhu Sedang DAN Baterai Sedang DAN Pemakaian Sedang MAKA Risiko Sedang
 3 1 3 3 1 2;   % Jika Suhu Tinggi ATAU Baterai Buruk ATAU Pemakaian Berat MAKA Risiko Tinggi
 2 3 1 1 1 1;   % Jika Suhu Sedang DAN Baterai Bagus DAN Pemakaian Ringan MAKA Risiko Rendah
 1 2 3 2 1 1;   % Jika Suhu Rendah DAN Baterai Sedang DAN Pemakaian Berat MAKA Risiko Sedang
 3 3 2 2 1 1;   % Jika Suhu Tinggi DAN Baterai Bagus DAN Pemakaian Sedang MAKA Risiko Sedang
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

% Status bar
h.status_bar = uicontrol('Style','text','Parent',h.fig,'Position',[10 750 1180 20],...
                         'String','Status: Siap','HorizontalAlignment','left',...
                         'BackgroundColor',[0.8 0.8 0.8]);

% Precompute MF grids
suhu_M = compute_mf_grid(suhu_range, suhu_params);
batt_M = compute_mf_grid(batt_range, batt_params);
pem_M  = compute_mf_grid(pem_range, pem_params);
out_M  = compute_mf_grid(out_range, out_params);

% STORE in handles for reuse
h.suhu_params = suhu_params;
h.batt_params = batt_params;
h.pem_params = pem_params;
h.out_params = out_params;
h.suhu_range = suhu_range;
h.batt_range = batt_range;
h.pem_range = pem_range;
h.out_range = out_range;
h.rules = rules;
h.out_M = out_M;

h.suhu_M = suhu_M;
h.batt_M = batt_M;
h.pem_M  = pem_M;
h.suhu_names = suhu_names;
h.batt_names = batt_names;
h.pem_names  = pem_names;
h.out_names  = out_names;
h.mf_folder = mf_folder;
h.save_png = save_png;
h.save_svg = save_svg;
h.save_gui = save_gui;
h.use_timestamp = use_timestamp;

% Initial plots (store line handles for fast updates)
% Suhu MF
axes(h.ax1);
cla(h.ax1);
hold on;
for i=1:size(suhu_params,1)
    h.lh_suhu(i) = plot(suhu_range, suhu_M(:,i), 'LineWidth', 2);
end
h.vline_suhu = plot([78 78], ylim(h.ax1), 'r--','LineWidth',1.8);
title('Membership Functions - Suhu (°C)');
legend(suhu_names,'Location','northwest');
grid on;

% Baterai MF
axes(h.ax2);
cla(h.ax2);
hold on;
for i=1:size(batt_params,1)
    h.lh_batt(i) = plot(batt_range, batt_M(:,i), 'LineWidth', 2);
end
h.vline_batt = plot([55 55], ylim(h.ax2), 'r--','LineWidth',1.8);
title('Membership Functions - Baterai (%)');
legend(batt_names,'Location','northwest');
grid on;

% Pemakaian MF
axes(h.ax3);
cla(h.ax3);
hold on;
for i=1:size(pem_params,1)
    h.lh_pem(i) = plot(pem_range, pem_M(:,i), 'LineWidth', 2);
end
h.vline_pem = plot([8 8], ylim(h.ax3), 'r--','LineWidth',1.8);
title('Membership Functions - Pemakaian (jam/hari)');
legend(pem_names,'Location','northwest');
grid on;

% Aggregated initial
axes(h.axAgg);
cla(h.axAgg);
h.agg_line = plot(out_range, zeros(size(out_range)),'LineWidth',2); hold on;
h.agg_area = area(out_range, zeros(size(out_range))); 
h.agg_area.FaceAlpha = 0.35; 
h.agg_area.FaceColor = [0.9 0.9 0.2];
% overlay output MF outlines
for k=1:size(out_params,1)
   h.out_mf_lines(k) = plot(out_range, out_M(:,k),'--','LineWidth',1);
end
h.centroid_line = plot([nan nan], ylim(h.axAgg), 'r-','LineWidth',2);
title('Aggregated Output & Defuzzification (centroid)');
grid on;

% Rule activations initial
axes(h.axRules);
cla(h.axRules);
h.barh_handle = barh(1:length(rules), zeros(length(rules),1));
yticks(1:length(rules));
yticklabels(compose("Rule %d",1:length(rules)));
xlim([0 1]);
title('Rule Activations');
grid on;

% Store handles
guidata(h.fig, h);

% Run initial update to show correct values and save initial images
update_all(h.fig);

% ============================
% CALLBACKS & FUNCTIONS
% ============================
function update_callback(src, ~)
    h = guidata(gcbf);
    suhu_val = get(h.suhu_slider, 'Value');
    batt_val = get(h.batt_slider, 'Value');
    pem_val  = get(h.pem_slider,  'Value');
    set(h.suhu_val_txt, 'String', sprintf('%.1f', suhu_val));
    set(h.batt_val_txt, 'String', sprintf('%.1f', batt_val));
    set(h.pem_val_txt,  'String', sprintf('%.1f', pem_val));
    set(h.vline_suhu, 'XData', [suhu_val suhu_val]);
    set(h.vline_batt, 'XData', [batt_val batt_val]);
    set(h.vline_pem,  'XData', [pem_val pem_val]);
    update_agg_and_rules(h, suhu_val, batt_val, pem_val);
end

function predict_button_cb(~, ~)
    h = guidata(gcbf);
    set(h.status_bar, 'String', 'Status: Memproses...');
    drawnow;
    
    suhu_val = get(h.suhu_slider, 'Value');
    batt_val = get(h.batt_slider, 'Value');
    pem_val  = get(h.pem_slider,  'Value');
    [centroid, cat] = evaluate_fis_and_return(h, suhu_val, batt_val, pem_val);
    set(h.result_txt, 'String', sprintf('Risk: %.2f (%s)', centroid, cat));
    
    % Simpan gambar saat Predict ditekan
    save_all_plots(h);
    
    set(h.status_bar, 'String', 'Status: Selesai. Gambar tersimpan.');
end

function update_all(fig)
    h = guidata(fig);
    set(h.suhu_val_txt, 'String', sprintf('%.1f', get(h.suhu_slider,'Value')));
    set(h.batt_val_txt, 'String', sprintf('%.1f', get(h.batt_slider,'Value')));
    set(h.pem_val_txt,  'String', sprintf('%.1f', get(h.pem_slider,'Value')));
    suhu_val = get(h.suhu_slider, 'Value');
    batt_val = get(h.batt_slider, 'Value');
    pem_val  = get(h.pem_slider,  'Value');
    update_agg_and_rules(h, suhu_val, batt_val, pem_val);
    % Simpan initial images
    save_all_plots(h);
end

function update_agg_and_rules(h, suhu_val, batt_val, pem_val)
    % compute degrees
    deg_s = zeros(1,size(h.suhu_params,1));
    for i=1:size(h.suhu_params,1)
        deg_s(i)=trapmf_scalar(suhu_val, h.suhu_params(i,:)); 
    end
    deg_b = zeros(1,size(h.batt_params,1));
    for i=1:size(h.batt_params,1)
        deg_b(i)=trapmf_scalar(batt_val, h.batt_params(i,:)); 
    end
    deg_p = zeros(1,size(h.pem_params,1));
    for i=1:size(h.pem_params,1)
        deg_p(i)=trapmf_scalar(pem_val, h.pem_params(i,:)); 
    end

    % firing strengths
    firing = zeros(size(h.rules,1),1);
    for r=1:size(h.rules,1)
        s_idx = h.rules(r,1); b_idx = h.rules(r,2); p_idx = h.rules(r,3); op = h.rules(r,6);
        ds = 1; db = 1; dp = 1;
        if s_idx>0, ds = deg_s(s_idx); end
        if b_idx>0, db = deg_b(b_idx); end
        if p_idx>0, dp = deg_p(p_idx); end
        if op==1
            firing(r)=min([ds,db,dp]); 
        else
            firing(r)=max([ds,db,dp]); 
        end
    end

    % aggregated output
    agg_vals = zeros(size(h.out_range));
    for r=1:size(h.rules,1)
        out_idx = h.rules(r,4);
        if out_idx==0, continue; end
        truncated = min(firing(r), h.out_M(:,out_idx));
        agg_vals = max(agg_vals, truncated);
    end

    % centroid
    if sum(agg_vals)==0
        centroid = NaN;
    else
        centroid = sum(h.out_range .* agg_vals) / sum(agg_vals);
    end

    % update aggregated plot lines & area
    set(h.agg_line, 'YData', agg_vals);
    set(h.agg_area, 'YData', agg_vals);
    yl = ylim(h.axAgg);
    if ~isnan(centroid)
        set(h.centroid_line, 'XData', [centroid centroid], 'YData', yl);
    else
        set(h.centroid_line, 'XData', [NaN NaN]);
    end

    % update rule-activation bars
    axes(h.axRules);
    cla(h.axRules);
    barh(firing);
    yticks(1:size(h.rules,1)); 
    yticklabels(compose("Rule %d",1:size(h.rules,1)));
    xlim([0 1]); grid on; title('Rule Activations');

    % update result text
    cat = 'Unknown';
    if ~isnan(centroid)
        if centroid < 40
            cat='Rendah';
        elseif centroid < 70
            cat='Sedang';
        else
            cat='Tinggi';
        end
    end
    set(h.result_txt, 'String', sprintf('Risk: %.2f (%s)', centroid, cat));

    % store latest aggregated & firing into h for potential saving
    h._last_agg = agg_vals;
    h._last_firing = firing;
    h._last_centroid = centroid;
    guidata(h.fig, h);
end

function [centroid, category] = evaluate_fis_and_return(h, suhu_val, batt_val, pem_val)
    % compute degs
    deg_s = zeros(1,size(h.suhu_params,1));
    for i=1:size(h.suhu_params,1)
        deg_s(i)=trapmf_scalar(suhu_val, h.suhu_params(i,:)); 
    end
    deg_b = zeros(1,size(h.batt_params,1));
    for i=1:size(h.batt_params,1)
        deg_b(i)=trapmf_scalar(batt_val, h.batt_params(i,:)); 
    end
    deg_p = zeros(1,size(h.pem_params,1));
    for i=1:size(h.pem_params,1)
        deg_p(i)=trapmf_scalar(pem_val, h.pem_params(i,:)); 
    end

    firing = zeros(size(h.rules,1),1);
    for r=1:size(h.rules,1)
        s_idx = h.rules(r,1); b_idx = h.rules(r,2); p_idx = h.rules(r,3); op = h.rules(r,6);
        ds = 1; db = 1; dp = 1;
        if s_idx>0, ds = deg_s(s_idx); end
        if b_idx>0, db = deg_b(b_idx); end
        if p_idx>0, dp = deg_p(p_idx); end
        if op==1
            firing(r)=min([ds,db,dp]); 
        else
            firing(r)=max([ds,db,dp]); 
        end
    end

    % aggregated
    agg_vals = zeros(size(h.out_range));
    for r=1:size(h.rules,1)
        out_idx = h.rules(r,4);
        if out_idx==0, continue; end
        truncated = min(firing(r), h.out_M(:,out_idx));
        agg_vals = max(agg_vals, truncated);
    end

    if sum(agg_vals)==0
        centroid = NaN;
    else
        centroid = sum(h.out_range .* agg_vals) / sum(agg_vals);
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
end

% ------------------------
% SAVE PLOTS (per-gambar)
% ------------------------
function save_all_plots(h)
    % Generate timestamp jika diperlukan
    if h.use_timestamp
        timestamp = datestr(now, 'yyyy-mm-dd_HH-MM-SS');
        timestamp_str = ['_' timestamp];
    else
        timestamp_str = '';
    end
    
    folder = h.mf_folder;
    saved_files = {};
    
    % 1) Suhu MF
    if h.save_png || h.save_svg
        f1 = figure('Visible','off','Position',[100 100 900 500]);
        ax = axes('Parent',f1);
        hold(ax,'on');
        for i=1:size(h.suhu_params,1)
            plot(ax, h.suhu_range, h.suhu_M(:,i), 'LineWidth',2);
        end
        xline(get(h.suhu_slider,'Value'), '--r');
        title(ax,'Membership Functions - Suhu (°C)');
        legend(h.suhu_names,'Location','northwest');
        grid(ax,'on');
        
        if h.save_png
            filename = fullfile(folder, ['mf_suhu' timestamp_str '.png']);
            print(filename, '-dpng', '-r150');
            saved_files{end+1} = filename;
        end
        
        if h.save_svg
            filename = fullfile(folder, ['mf_suhu' timestamp_str '.svg']);
            print(filename, '-dsvg');
            saved_files{end+1} = filename;
        end
        
        close(f1);
    end

    % 2) Baterai MF
    if h.save_png || h.save_svg
        f2 = figure('Visible','off','Position',[100 100 900 500]);
        ax = axes('Parent',f2);
        hold(ax,'on');
        for i=1:size(h.batt_params,1)
            plot(ax, h.batt_range, h.batt_M(:,i), 'LineWidth',2);
        end
        xline(get(h.batt_slider,'Value'), '--r');
        title(ax,'Membership Functions - Baterai (%)');
        legend(h.batt_names,'Location','northwest');
        grid(ax,'on');
        
        if h.save_png
            filename = fullfile(folder, ['mf_batt' timestamp_str '.png']);
            print(filename, '-dpng', '-r150');
            saved_files{end+1} = filename;
        end
        
        if h.save_svg
            filename = fullfile(folder, ['mf_batt' timestamp_str '.svg']);
            print(filename, '-dsvg');
            saved_files{end+1} = filename;
        end
        
        close(f2);
    end

    % 3) Pemakaian MF
    if h.save_png || h.save_svg
        f3 = figure('Visible','off','Position',[100 100 900 500]);
        ax = axes('Parent',f3);
        hold(ax,'on');
        for i=1:size(h.pem_params,1)
            plot(ax, h.pem_range, h.pem_M(:,i), 'LineWidth',2);
        end
        xline(get(h.pem_slider,'Value'), '--r');
        title(ax,'Membership Functions - Pemakaian (jam/hari)');
        legend(h.pem_names,'Location','northwest');
        grid(ax,'on');
        
        if h.save_png
            filename = fullfile(folder, ['mf_pemakaian' timestamp_str '.png']);
            print(filename, '-dpng', '-r150');
            saved_files{end+1} = filename;
        end
        
        if h.save_svg
            filename = fullfile(folder, ['mf_pemakaian' timestamp_str '.svg']);
            print(filename, '-dsvg');
            saved_files{end+1} = filename;
        end
        
        close(f3);
    end

    % 4) Aggregated output + centroid
    if h.save_png || h.save_svg
        agg_vals = zeros(size(h.out_range));
        if isfield(h,'_last_agg') && ~isempty(h._last_agg)
            agg_vals = h._last_agg;
        else
            % fallback: compute from current sliders
            [~, ~] = evaluate_fis_and_return(h, get(h.suhu_slider,'Value'), get(h.batt_slider,'Value'), get(h.pem_slider,'Value'));
            if isfield(h,'_last_agg'), agg_vals = h._last_agg; end
        end
        centroid = NaN;
        if isfield(h,'_last_centroid'), centroid = h._last_centroid; end

        f4 = figure('Visible','off','Position',[100 100 1000 450]);
        ax = axes('Parent',f4); hold(ax,'on');
        area(ax, h.out_range, agg_vals); alpha(ax,0.35);
        for k=1:size(h.out_M,2)
            plot(ax, h.out_range, h.out_M(:,k), '--','LineWidth',1);
        end
        if ~isnan(centroid)
            xline(ax, centroid, '-r', 'LineWidth',2);
        end
        title(ax,'Aggregated Output & Defuzzification (centroid)');
        grid(ax,'on');
        
        if h.save_png
            filename = fullfile(folder, ['mf_aggregated_output' timestamp_str '.png']);
            print(filename, '-dpng', '-r150');
            saved_files{end+1} = filename;
        end
        
        if h.save_svg
            filename = fullfile(folder, ['mf_aggregated_output' timestamp_str '.svg']);
            print(filename, '-dsvg');
            saved_files{end+1} = filename;
        end
        
        close(f4);
    end

    % 5) Rule activations
    if h.save_png || h.save_svg
        firing = zeros(size(h.rules,1),1);
        if isfield(h,'_last_firing') && ~isempty(h._last_firing)
            firing = h._last_firing;
        else
            % compute fallback
            deg_s = zeros(1,size(h.suhu_params,1));
            for i=1:size(h.suhu_params,1)
                deg_s(i)=trapmf_scalar(get(h.suhu_slider,'Value'), h.suhu_params(i,:)); 
            end
            deg_b = zeros(1,size(h.batt_params,1));
            for i=1:size(h.batt_params,1)
                deg_b(i)=trapmf_scalar(get(h.batt_slider,'Value'), h.batt_params(i,:)); 
            end
            deg_p = zeros(1,size(h.pem_params,1));
            for i=1:size(h.pem_params,1)
                deg_p(i)=trapmf_scalar(get(h.pem_slider,'Value'), h.pem_params(i,:)); 
            end
            for r=1:size(h.rules,1)
                s_idx = h.rules(r,1); b_idx = h.rules(r,2); p_idx = h.rules(r,3); op = h.rules(r,6);
                ds = 1; db = 1; dp = 1;
                if s_idx>0, ds = deg_s(s_idx); end
                if b_idx>0, db = deg_b(b_idx); end
                if p_idx>0, dp = deg_p(p_idx); end
                if op==1
                    firing(r)=min([ds,db,dp]); 
                else
                    firing(r)=max([ds,db,dp]); 
                end
            end
        end

        f5 = figure('Visible','off','Position',[100 100 900 500]);
        ax = axes('Parent',f5); hold(ax,'on');
        barh(ax, firing);
        yticks(ax, 1:size(h.rules,1));
        yticklabels(ax, compose("Rule %d",1:size(h.rules,1)));
        xlim(ax, [0 1]); grid(ax,'on');
        title(ax,'Rule Activations');
        
        if h.save_png
            filename = fullfile(folder, ['mf_rule_activations' timestamp_str '.png']);
            print(filename, '-dpng', '-r150');
            saved_files{end+1} = filename;
        end
        
        if h.save_svg
            filename = fullfile(folder, ['mf_rule_activations' timestamp_str '.svg']);
            print(filename, '-dsvg');
            saved_files{end+1} = filename;
        end
        
        close(f5);
    end

    % 6) Save GUI screenshot if requested
    if h.save_gui && (h.save_png || h.save_svg)
        if h.save_png
            filename = fullfile(folder, ['gui_screenshot' timestamp_str '.png']);
            print(h.fig, filename, '-dpng', '-r150');
            saved_files{end+1} = filename;
        end
        
        if h.save_svg
            filename = fullfile(folder, ['gui_screenshot' timestamp_str '.svg']);
            print(h.fig, filename, '-dsvg');
            saved_files{end+1} = filename;
        end
    end

    % Tampilkan notifikasi dengan daftar file yang disimpan
    if ~isempty(saved_files)
        fprintf('\n=== %d FILE DISIMPAN ===\n', length(saved_files));
        for i = 1:length(saved_files)
            [~, name, ext] = fileparts(saved_files{i});
            fprintf('%d. %s%s\n', i, name, ext);
        end
        fprintf('Folder: %s\n\n', folder);
    else
        fprintf('Tidak ada file yang disimpan (format penyimpanan dinonaktifkan).\n');
    end
end

% ------------------------
% Utility functions (end of file)
% ------------------------
function mu = trapmf_scalar(x, params)
    a = params(1); b = params(2); c = params(3); d = params(4);
    mu = 0;
    if x >= a && x < b
        if b > a, mu = (x - a) / (b - a); end
    elseif x >= b && x <= c
        mu = 1;
    elseif x > c && x <= d
        if d > c, mu = (d - x) / (d - c); end
    else
        mu = 0;
    end
end

function M = compute_mf_grid(xgrid, params_mat)
    n = size(params_mat,1);
    M = zeros(length(xgrid), n);
    for i = 1:n
        for j = 1:length(xgrid)
            M(j,i) = trapmf_scalar(xgrid(j), params_mat(i,:));
        end
    end
end