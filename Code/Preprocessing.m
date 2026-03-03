%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%% EEG Training - Preprocessing %%%%%%%%%
%%%%%%%%%%%%%% Ettore Napoli %%%%%%%%%%%%%%%%%%% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 1 - Import

% Activate EEGLAB
addpath('C:\Users\ettor\OneDrive - Università degli Studi di Padova\Desktop\PhD\Matlab_plugins\eeglab_current\eeglab2024.0')
eeglab

% Set relevant folders
input_folder = 'C:\Users\ettor\OneDrive - Università degli Studi di Padova\Desktop\EEG_Training\Raw_Data\';
output_folder = 'C:\Users\ettor\OneDrive - Università degli Studi di Padova\Desktop\EEG_Training\Preproc_Output\Import';

% Create output folder
if ~exist(output_folder, "dir")
    mkdir(output_folder);
end

% Get file list
file_list = dir(fullfile(input_folder, '*hdf5'));

for i = 1:length(file_list)

    % Get file name
    file_name = file_list(i).name;

    % Load on EEGLAB
    EEG = pop_loadhdf5('filename', file_name, 'filepath', input_folder)

    % Load channel location
    EEG = pop_chanedit(EEG, 'load', {'C:\\Users\\ettor\\OneDrive - Università degli Studi di Padova\\Desktop\\EEG_Training\\Raw_Data\\channel_locs_32set.locs', 'filetype', 'autodetect'});

    % Save
    EEG = pop_saveset(EEG, 'filename', file_name, 'filepath',  output_folder);
end


%% 2 - Visual Scroll and manual channel rejection

%% 3 - Resampling, Filtering, ICA

clear all; close all;

% Activate EEGLAB
addpath('C:\Users\ettor\OneDrive - Università degli Studi di Padova\Desktop\PhD\Matlab_plugins\eeglab_current\eeglab2024.0')
eeglab

% Set relevant folders
input_folder = 'C:\Users\ettor\OneDrive - Università degli Studi di Padova\Desktop\EEG_Training\Preproc_Output\Visual_Scroll\';
output_folder = 'C:\Users\ettor\OneDrive - Università degli Studi di Padova\Desktop\EEG_Training\Preproc_Output\pre_ICA_Rej';

% Create output folder
if ~exist(output_folder, "dir")
    mkdir(output_folder);
end

% Get File list
file_list = dir(fullfile(input_folder, '*set'));

for i = 1:length(file_list)

    file_name = file_list(i).name

    % Load on EEGLAB
    EEG = pop_loadset('filename', file_name, 'filepath', input_folder);

    % Resample
    EEG = pop_resample(EEG, 250);
    EEG = eeg_checkset(EEG);

    % Filter (ERP Analysis)
    EEG = pop_eegfiltnew(EEG, 0.1, []); % High pass 0.1 Hz
    EEG = pop_eegfiltnew(EEG, [], 40); % Low pass 40 Hz
    EEG = eeg_checkset(EEG);
    
    % Filter (dummy ICA)
    EEG_dummy = pop_eegfiltnew(EEG, 1, []); % High pass 1 Hz
    EEG_dummy = eeg_checkset(EEG_dummy);

    % ICA
    EEG_dummy = pop_runica(EEG_dummy, 'icatype', 'runica', 'extended', 1);
    EEG_dummy = eeg_checkset(EEG_dummy);
    
    % Copy the weights of ICA on dummy dataset on original one
    EEG.icaweights = EEG_dummy.icaweights;
    EEG.icasphere  = EEG_dummy.icasphere;
    EEG.icawinv    = EEG_dummy.icawinv;
    EEG.icachansind = EEG_dummy.icachansind;
    EEG = eeg_checkset(EEG);
    
    % Run ICLabel and ICFlag
    EEG = iclabel(EEG);
    EEG = pop_icflag(EEG, ...
    [NaN NaN; 0.8 1; 0.8 1; NaN NaN; NaN NaN; NaN NaN; NaN NaN]); %Thresholds: Brain, Muscle, Eye, Heart, Line, Channel, Other
    
    % Save
    EEG = pop_saveset(EEG, 'filename', [file_name(1:end-4) '_Pre_ICA_Rej.set'], 'filepath', output_folder);
end

%% 4 - Manual ICA Rejection

%% 5 - Re-referencing, Epoching, Baseline Correction, Epoch Rejection

clear all; close all;

% Activate EEGLAB
addpath('C:\Users\ettor\OneDrive - Università degli Studi di Padova\Desktop\PhD\Matlab_plugins\eeglab_current\eeglab2024.0')
eeglab

% Set relevant folders
input_folder = 'C:\Users\ettor\OneDrive - Università degli Studi di Padova\Desktop\EEG_Training\Preproc_Output\post_ICA_Rej\';
output_folder = 'C:\Users\ettor\OneDrive - Università degli Studi di Padova\Desktop\EEG_Training\Preproc_Output\Epoch_Rej';

% Create output folder
if ~exist(output_folder, "dir")
    mkdir(output_folder);
end

% Get File list
file_list = dir(fullfile(input_folder, '*set'));

for i = 1:length(file_list)

    file_name = file_list(i).name;
    short_filename = file_name(1:7)

    % Load on EEGLAB
    EEG = pop_loadset('filename', file_name, 'filepath', input_folder);

    % Re-referencing (CAR)
    EEG = pop_reref(EEG, []);
    EEG = eeg_checkset(EEG);
    
    % Epoching around Trigger 3 (rare) and Trigger 4 (standard)
    EEG_standard = pop_epoch(EEG, {'Trigger 4'}, [-0.2 0.8]);
    EEG_rare = pop_epoch(EEG, {'Trigger 3'}, [-0.2 0.8]);

    % Baseline Correction
    EEG_standard = pop_rmbase(EEG_standard, [-200 0]);
    EEG_rare = pop_rmbase(EEG_rare, [-200 0]);

    % Epoch Rejection
    [EEG_standard, idx_std] = pop_eegthresh(EEG_standard, ...
        1, ... % Epoch on raw data
        1:EEG.nbchan, ... % All channels considered
        -100, ... %Low threshold
        100, ... % High threshold
        EEG_standard.times(1)/1000, ... %Epoch Start time
        EEG_standard.times(end)/1000, ... %Epoch End time
        1, ... %Superpose 
        0); % Do not automatically reject
    
    [EEG_rare, idx_rare] = pop_eegthresh(EEG_rare, ...
        1, ... % Epoch on raw data
        1:EEG.nbchan, ... % All channels considered
        -100, ... %Low threshold
        100, ... % High threshold
        EEG_rare.times(1)/1000, ... %Epoch Start time
        EEG_rare.times(end)/1000, ... %Epoch End time
        1, ... %Superpose 
        0); % Do not automatically reject
    
    % Plot channel scroll for epoch visual inspection
    pop_eegplot(EEG_standard, 1, 1, 1);
    pause;
    pop_eegplot(EEG_rare, 1, 1, 1);
    pause;

    % Save
    EEG_standard = pop_saveset(EEG_standard, 'filename', [short_filename '_standard.set'], 'filepath', output_folder);
    EEG_rare = pop_saveset(EEG_rare, 'filename', [short_filename '_rare.set'], 'filepath', output_folder);
end


