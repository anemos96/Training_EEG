%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%% EEG Training - TF Analysis %%%%%%%%%%%
%%%%%%%%%%%%%% Ettore Napoli %%%%%%%%%%%%%%%%%%% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Activate EEGLAB
addpath('C:\Users\ettor\OneDrive - Università degli Studi di Padova\Desktop\PhD\Matlab_plugins\eeglab_current\eeglab2024.0')
eeglab
% Set relevant folders
input_folder  = 'C:\Users\ettor\OneDrive - Università degli Studi di Padova\Desktop\EEG_Training\Preproc_Output\Epoch_Rej\';
output_folder = 'C:\Users\ettor\OneDrive - Università degli Studi di Padova\Desktop\EEG_Training\TF';
% Create output folder
if ~exist(output_folder, 'dir')
    mkdir(output_folder);
end
% Get file list
file_list = dir(fullfile(input_folder, '*.set'));
for i = 1:length(file_list)
    file_name = file_list(i).name;
    fprintf('Elaborando: %s\n', file_name);
% Extract subject, group and condition
    parts     = strsplit(file_name(1:end-4), '_');
    ID        = parts{2};
    group     = parts{3};
    condition = parts{4};
    EEG = pop_loadset('filename', file_name, 'filepath', input_folder);
    EEG = eeg_checkset(EEG);
% Find electrode indices and save tf vectors (only on first iteration)
    if i == 1
        idx_Pz = find(strcmpi({EEG.chanlocs.labels}, 'Pz')); % Theta P300
        idx_Fz = find(strcmpi({EEG.chanlocs.labels}, 'Fz')); % Frontal theta
        fprintf('Elettrodi: Pz=%d | Fz=%d\n', idx_Pz, idx_Fz);
    end
% Compute ERSP and ITC for Pz
    [ersp, itc, ~, tf_times, tf_freqs] = newtimef( ...
        EEG.data(idx_Pz, :, :), ...
        EEG.pnts, ...
        [EEG.times(1) EEG.times(end)], ...
        EEG.srate, ...
        0, ...
        'freqs',    [4 40], ...
        'nfreqs',   30, ...
        'baseline', [-200 0], ...
        'plotersp', 'off', ...
        'plotitc',  'off', ...
        'verbose',  'off');
    TF.(group).(condition).(strcat('s', ID)).Pz.ersp = ersp;
    TF.(group).(condition).(strcat('s', ID)).Pz.itc  = abs(itc);
% Compute ERSP and ITC for Fz
    [ersp, itc, ~, ~, ~] = newtimef( ...
        EEG.data(idx_Fz, :, :), ...
        EEG.pnts, ...
        [EEG.times(1) EEG.times(end)], ...
        EEG.srate, ...
        0, ...
        'freqs',    [4 40], ...
        'nfreqs',   30, ...
        'baseline', [-200 0], ...
        'plotersp', 'off', ...
        'plotitc',  'off', ...
        'verbose',  'off');
    TF.(group).(condition).(strcat('s', ID)).Fz.ersp = ersp;
    TF.(group).(condition).(strcat('s', ID)).Fz.itc  = abs(itc);
% Save tf_times and tf_freqs only on first iteration
    if i == 1
        tf_times_out = tf_times;
        tf_freqs_out = tf_freqs;
    end
end
% Compute grand average by groups
GA.O.rare.Pz.ersp     = mean(cat(3, TF.O.rare.s07.Pz.ersp,     TF.O.rare.s09.Pz.ersp),     3);
GA.O.rare.Pz.itc      = mean(cat(3, TF.O.rare.s07.Pz.itc,      TF.O.rare.s09.Pz.itc),      3);
GA.O.standard.Pz.ersp = mean(cat(3, TF.O.standard.s07.Pz.ersp, TF.O.standard.s09.Pz.ersp), 3);
GA.O.standard.Pz.itc  = mean(cat(3, TF.O.standard.s07.Pz.itc,  TF.O.standard.s09.Pz.itc),  3);

GA.Y.rare.Pz.ersp     = mean(cat(3, TF.Y.rare.s10.Pz.ersp,     TF.Y.rare.s35.Pz.ersp),     3);
GA.Y.rare.Pz.itc      = mean(cat(3, TF.Y.rare.s10.Pz.itc,      TF.Y.rare.s35.Pz.itc),      3);
GA.Y.standard.Pz.ersp = mean(cat(3, TF.Y.standard.s10.Pz.ersp, TF.Y.standard.s35.Pz.ersp), 3);
GA.Y.standard.Pz.itc  = mean(cat(3, TF.Y.standard.s10.Pz.itc,  TF.Y.standard.s35.Pz.itc),  3);

GA.O.rare.Fz.ersp     = mean(cat(3, TF.O.rare.s07.Fz.ersp,     TF.O.rare.s09.Fz.ersp),     3);
GA.O.rare.Fz.itc      = mean(cat(3, TF.O.rare.s07.Fz.itc,      TF.O.rare.s09.Fz.itc),      3);
GA.O.standard.Fz.ersp = mean(cat(3, TF.O.standard.s07.Fz.ersp, TF.O.standard.s09.Fz.ersp), 3);
GA.O.standard.Fz.itc  = mean(cat(3, TF.O.standard.s07.Fz.itc,  TF.O.standard.s09.Fz.itc),  3);

GA.Y.rare.Fz.ersp     = mean(cat(3, TF.Y.rare.s10.Fz.ersp,     TF.Y.rare.s35.Fz.ersp),     3);
GA.Y.rare.Fz.itc      = mean(cat(3, TF.Y.rare.s10.Fz.itc,      TF.Y.rare.s35.Fz.itc),      3);
GA.Y.standard.Fz.ersp = mean(cat(3, TF.Y.standard.s10.Fz.ersp, TF.Y.standard.s35.Fz.ersp), 3);
GA.Y.standard.Fz.itc  = mean(cat(3, TF.Y.standard.s10.Fz.itc,  TF.Y.standard.s35.Fz.itc),  3);
%% TF parameters
electrodes  = {'Pz', 'Fz'};
elec_labels = {'Pz — Theta P300', 'Fz — Frontal Theta'};
group_names = {'OLD', 'YOUNG'};
group_codes = {'O', 'Y'};
col_titles  = {'ERSP — Rare', 'ERSP — Standard', 'ITC — Rare', 'ITC — Standard'};
%% Visualization
% One figure per electrode
% Layout: 2 rows (old/young) x 4 columns (ERSP rare, ERSP std, ITC rare, ITC std)
for e = 1:length(electrodes)
    elec = electrodes{e};
    figure('Name', sprintf('TF Analysis — %s', elec), 'Position', [100 100 1600 700]);
    for g = 1:2
        grp = group_codes{g};
        data_to_plot = { ...
            GA.(grp).rare.(elec).ersp, ...
            GA.(grp).standard.(elec).ersp, ...
            GA.(grp).rare.(elec).itc, ...
            GA.(grp).standard.(elec).itc};
        for col = 1:4
            subplot(2, 4, (g-1)*4 + col);
            imagesc(tf_times_out, tf_freqs_out, data_to_plot{col});
            axis xy;
            colorbar;
            if col <= 2
                colormap(gca, 'jet');
                clim([-3 3]);
            else
                colormap(gca, 'hot');
                clim([0 0.8]);
            end
            xline(0, '--w', 'LineWidth', 1.2);
            xlabel('Time (ms)');
            ylabel('Frequency (Hz)');
            title(sprintf('%s — %s\n%s', group_names{g}, col_titles{col}, elec));
            grid off;
        end
    end
    sgtitle(sprintf('Time-Frequency Analysis — %s', elec_labels{e}), 'FontSize', 14);
end
fprintf('\nDone.\n');