steps = {'Raw data load','Filter','Clean data with ASR',...
    'Interpolate','Average reference','Epoch','ICA','Reject Components'};
[idx,~] = listdlg('PromptString','Select step to start at',...
    'ListString',steps,'SelectionMode','single');

%% Load directories
previousOpts = questdlg('Would you like to use the directories from your previous run?');
if strcmp(previousOpts,'Yes')
    load(['opts_',mfilename,'.mat'],'eeglabDir','workingDir',...
        'dataDir','locFile','locFilePath');
    addpath(workingDir)
    addpath(workingDir,filesep,'altmany-export_fig-4703a84')
    addpath(dataDir)
    addpath(eeglabDir)
else
    disp('Please specify working directory (where your pipeline scripts are stored).')
    workingDir = uigetdir(path,'Select working directory.');
    addpath(workingDir)
    addpath(workingDir,filesep,'altmany-export_fig-4703a84')
    
    disp('Please specify eeglab directory (eeglab folder).')
    eeglabDir = uigetdir(path,'Select eeglab directory.');
    addpath(eeglabDir)
    eeglab
    close all
    
    disp('Please specify data directory (where folders are created).')
    dataDir = uigetdir(path,'Select file directory.');
    
    disp('Please specify channel location file.')
    % eeglab_chan32.locs
    [locFile,locFilePath] = uigetfile('*.locs','Select channel location file.');
    save(strcat(workingDir,filesep,['opts_',mfilename,'.mat']),'eeglabDir',...
        'workingDir', 'dataDir','locFile','locFilePath');
end

name = input('Please specify name to attach to files: ','s');
fileDir = strcat(dataDir,filesep,name);

if ~exist(fileDir,'dir')
    mkdir(fileDir)
end

pop_editoptions('option_single', 0);

close all
%% Load EEG data file
if idx == 1
disp('Please specify .set file from which you want to load data.')
[dataFile,dataFilePath] = uigetfile('*.set','Select EEG data file.');
EEG = pop_loadset('filename',strcat(dataFilePath,filesep,dataFile));

EEG.pipeline = mfilename;
%% Resample to 512 Hz
EEG = pop_resample(EEG, 512);
EEG = eeg_checkset(EEG);

EEG.comments = pop_comments(EEG.comments,'','Resampled to 512 Hz',1);
%% Load channel locations
EEG=pop_chanedit(EEG, 'load',strcat(locFilePath,locFile));

EEG.comments = pop_comments(EEG.comments,'','Channel locations loaded',1);

[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1,'setname',name,...
    'savenew',strcat(fileDir,filesep,name),'overwrite','on','gui','off'); 
end
%% Apply filters
if idx <= 2
if idx == 2
    EEG = pop_loadset('filename',strcat(fileDir,filesep,name,'.set'));
end
%EEG = pop_eegfiltnew(EEG, 1, 0, 1650, 0, [], 0);
EEG = pop_eegfiltnew(EEG, 'locutoff',1,'plotfreqz',1);
EEG = pop_eegfiltnew(EEG, 'hicutoff',30,'plotfreqz',1);

EEG.comments = pop_comments(EEG.comments,'','Filters applied, locutoff 1, hicutoff 30',1);

EEG = eeg_checkset(EEG);
originalEEG = EEG;

[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1,'setname',strcat(name,'_highpass'),...
    'savenew',strcat(fileDir,filesep,name,'_highpass'),'overwrite','on','gui','off');
end
%% Apply clean_rawdata() to reject bad channels and correct continuous data using Artifact Subspace Reconstruction (ASR)
if idx <= 3
if idx == 3
    EEG = pop_loadset('filename',strcat(fileDir,filesep,name,'_highpass.set'));
end

originalEEG = EEG;
flag = 0;
while flag == 0
    EEG = pop_clean_rawdata(originalEEG);
    pop_eegplot(EEG)

    disp(['The number of non-boundary events after cleaning is ', ...
        num2str(sum(cellfun(@(x) ~strcmp(x,'boundary'),{EEG.event(:).type})))]);
    uiwait()
    uiwait()

    redo = questdlg('Would you like to run cleanrawdata again?');
    if strcmp(redo,'No')
        flag = 1;
    end
end

EEG = eeg_checkset(EEG);

[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1,'setname',strcat(name,'_cleanrawdata'),...
    'savenew',strcat(fileDir,filesep,name,'_cleanrawdata'),'overwrite','on','gui','off'); 
end
%% Get number of channels before interpolation
if idx <= 4
if idx == 4
    EEG = pop_loadset('filename',strcat(fileDir,filesep,name,'_cleanrawdata.set'));
    originalEEG = pop_loadset('filename',strcat(fileDir,filesep,name,'_highpass.set'));
end
numChannelsBeforeInterp = EEG.nbchan;

chans1 = {originalEEG.chanlocs.labels};
chans2 = {EEG.chanlocs.labels};
interpIdx = ~ismember(chans1,chans2);
interpChans = {originalEEG.chanlocs(interpIdx).labels};
interpTbl = table(find(interpIdx)',interpChans','VariableNames',{'ChannelIdx','ChannelName'});
writetable(interpTbl,strcat(fileDir,filesep,name,'_interp.txt'))

%% Interpolate channels

EEG = pop_interp(EEG, originalEEG.chanlocs, 'spherical');
EEG.comments = pop_comments(EEG.comments,'',['Interpolated channels ' strjoin(interpChans,', ')],1);

[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1,'setname',strcat(name,'_interp'),...
    'savenew',strcat(fileDir,filesep,name,'_interp'),'overwrite','on','gui','off'); 
end
%% Change reference to average
if idx <= 5
if idx == 5
EEG = pop_loadset('filename',strcat(fileDir,filesep,name,'_interp','.set'));
end

EEG = pop_reref(EEG, []);

EEG.comments = pop_comments(EEG.comments,'','Changed to average reference',1);

[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1,'setname',strcat(name,'_averef'),...
    'savenew',strcat(fileDir,filesep,name,'_averef'),'overwrite','on','gui','off'); 
EEG = eeg_checkset(EEG);
end
%% Epoch events
if idx <= 6
if idx == 6
EEG = pop_loadset('filename',strcat(fileDir,filesep,name,'_averef.set'));
end
EEG = pop_epoch(EEG, unique({EEG.event(:).type}), [-1 2], 'newname', strcat(name,'_epochs'), ...
'epochinfo', 'yes');

EEG.comments = pop_comments(EEG.comments,'','Epoched from -1 to 2',1);

[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1,'setname',strcat(name,'_epochs'),...
    'savenew',strcat(fileDir,filesep,name,'_epochs'),'overwrite','on','gui','off'); 
EEG = eeg_checkset(EEG);

end
%% ICA
if idx <= 7
if idx == 7
    EEG = pop_loadset('filename',strcat(fileDir,filesep,name,'_epochs.set'));
end

EEG = pop_runica(EEG, 'icatype', 'runica', 'extended',1,'interrupt','on','pca',numChannelsBeforeInterp-1);
EEG = eeg_checkset(EEG, 'ica');

EEG.comments = pop_comments(EEG.comments,'','Performed ICA',1);

[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1,'setname',strcat(name,'_ica'),...
    'savenew',strcat(fileDir,filesep,name,'_ica'),'overwrite','on','gui','off'); 
end
%% Reject components by map
if idx <= 8
if idx == 8
EEG = pop_loadset('filename',strcat(fileDir,filesep,name,'_ica.set'));
end
EEG = pop_selectcomps(EEG, [1:size(EEG.icaweights,1)]);
[ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);

export_fig(strcat(fileDir,filesep,name,'_icacomps'),'-png');
uiwait

rejectIdx = find(EEG.reject.gcompreject);
EEG.comments = pop_comments(EEG.comments,'',strcat("Rejected independent components ", ...
    strjoin(string(rejectIdx),', ')),1);
EEG = pop_subcomp(EEG);

writematrix(rejectIdx,strcat(fileDir,filesep,name,'_rejected_comps.txt'))

[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1,'setname',strcat(name,'_comps_rejected'),...
    'savenew',strcat(fileDir, filesep,name,'_comps_rejected'),'overwrite','on','gui','off'); 
EEG = eeg_checkset(EEG);

%% Save to all data folder
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1,'setname',strcat('final_',name),...
    'savenew',strcat(dataDir,filesep,'final_',name),'overwrite','on','gui','off'); 
EEG = eeg_checkset(EEG);
end