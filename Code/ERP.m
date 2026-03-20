%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%% EEG Training - ERP Analaysis %%%%%%%%%
%%%%%%%%%%%%%% Ettore Napoli %%%%%%%%%%%%%%%%%%% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Activate EEGLAB
addpath('C:\Users\ettor\OneDrive - Università degli Studi di Padova\Desktop\PhD\Matlab_plugins\eeglab_current\eeglab2024.0')
eeglab

% Set relevant folders
input_folder = 'C:\Users\ettor\OneDrive - Università degli Studi di Padova\Desktop\EEG_Training\Preproc_Output\Epoch_Rej\';
output_folder = 'C:\Users\ettor\OneDrive - Università degli Studi di Padova\Desktop\EEG_Training\ERP';

% Create output folder
if ~exist(output_folder, "dir")
    mkdir(output_folder);
end

% Get file list
file_list = dir(fullfile(input_folder, '*set'));

for i = 1:length(file_list)

    file_name = file_list(i).name;

    % Extract subject, group and condition
    parts = strsplit(file_name(1:end-4), '_');
    ID = parts{2};
    group = parts{3};
    condition = parts{4};


    EEG = pop_loadset('filename', file_name, 'filepath', input_folder);
    
    % Compute ERP on the whole dataset
    ERP.(group).(condition).(strcat('s', ID)) = mean(EEG.data, 3);
end

% Extract time points
times = EEG.times;

% Extract electrode-of-interest's ids
idx_P1 = find(strcmpi({EEG.chanlocs.labels}, 'Oz')); % We expect P1 component to be maximally visible in Oz
idx_N2 = find(strcmpi({EEG.chanlocs.labels}, 'Fz')); % We expect N2 component to be meximally visible in Fz
idx_P3 = find(strcmpi({EEG.chanlocs.labels}, 'Pz')); % We expect P3 component to be maximally visible in Pz

% Compute grand average by groups
GA.O.rare = mean(cat(3, ERP.O.rare.s07, ERP.O.rare.s09), 3);
GA.O.standard = mean(cat(3, ERP.O.standard.s07, ERP.O.standard.s09), 3);
GA.Y.rare = mean(cat(3, ERP.Y.rare.s10, ERP.Y.rare.s35), 3);
GA.Y.standard = mean(cat(3, ERP.Y.standard.s10, ERP.Y.standard.s35), 3);

%% Components parameters
% Time window
P1_win = [80 130];
N2_win = [200 300];
P3_win = [300 500];

components = {'P1', 'N2', 'P3'};
electrode_idx = [idx_P1, idx_N2, idx_P3];
electrode_names = {'Oz', 'Fz', 'Pz'};
time_windows = {P1_win, N2_win, P3_win};

color_rare = [0.85 0.15 0.15] % red
color_standard = [0.15 0.35 0.75] % blue

%% Visualization

group_names = {'OLD', 'YOUNG'};
GA_rare = {GA.O.rare, GA.Y.rare};
GA_standard = {GA.O.standard, GA.Y.standard};

figure('Name', 'Grand Average ERP', 'Position', [100 100 1400 700]);

for g = 1:2
    for comp = 1:3

        subplot(2, 3, (g-1)*3 + comp);

        plot(times, GA_rare{g}(electrode_idx(comp),:), ...
            'Color', color_rare, 'LineWidth', 2); hold on;
        plot(times, GA_standard{g}(electrode_idx(comp),:), ...
            'Color', color_standard,  'LineWidth', 2);

        xline(0, '--k', 'LineWidth', 0.8);
        yline(0, '-k',  'LineWidth', 0.5);

        % Finestra componente in grigio
        patch([time_windows{comp}(1) time_windows{comp}(2) time_windows{comp}(2) time_windows{comp}(1)], ...
              [-15 -15 15 15], ...
              [0.7 0.7 0.7], 'FaceAlpha', 0.2, 'EdgeColor', 'none');

        set(gca, 'YDir', 'reverse', 'XLim', [-200 800], 'YLim', [-15 15]);
        xlabel('Time (ms)');
        ylabel('Amplitude (µV)');
        title(sprintf('%s — %s (%s)', group_names{g}, components{comp}, electrode_names{comp}));

        if comp == 1
            legend('Rare','Standard', 'Location', 'southeast');
        end
        grid on;

    end
end

sgtitle('Grand Average ERP — Old vs Young | Rare vs Standard', 'FontSize', 14);
















