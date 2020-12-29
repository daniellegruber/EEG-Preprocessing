steps = {'Raw data load','Filter','Automatic rejection','Epoch','Reject bad channels','Interpolate',...
    'Average reference','ICA for epoch rejection','Reject epochs','ICA for comp rejection','Reject components'};
[idx,~] = listdlg('PromptString','Select step to start at',...
    'ListString',steps,'SelectionMode','single');
%% Get experiment info
trainingTimingInfo = readtable('threat_conditioning.csv');
testTimingInfo = readtable('designTbl.csv');
%% Load directories
previousOpts = questdlg('Would you like to use the directories from your previous run?');
if strcmp(previousOpts,'Yes')
    load(['opts_',mfilename,'.mat'],'allDataDir','eeglabDir','workingDir',...
        'dataDir','locFile','locFilePath');
    addpath(workingDir)
    addpath(allDataDir)
    addpath(eeglabDir)
else
    disp('Please specify working directory (where your pipeline scripts are stored).')
    workingDir = uigetdir(path,'Select working directory.');
    addpath(workingDir)

    disp('Please specify all data folder.')
    allDataDir = uigetdir(path,'Select all data directory.');
    addpath(allDataDir)

    disp('Please specify eeglab directory (eeglab folder).')
    eeglabDir = uigetdir(path,'Select eeglab directory.');
    addpath(eeglabDir)
    %eeglab('nogui')
    eeglab
    
    disp('Please specify data directory (where folders are created).')
    dataDir = uigetdir(path,'Select file directory.');
    
    disp('Please specify channel location file.')
    [locFile,locFilePath] = uigetfile('*.ced','Select channel location file.');
    save(strcat(workingDir,filesep,['opts_',mfilename,'.mat']),'allDataDir','eeglabDir',...
        'workingDir', 'dataDir','locFile','locFilePath');
end

name = input('Please specify name to attach to files: ','s');
fileDir = strcat(dataDir,filesep,name);

if ~exist(fileDir,'dir')
    mkdir(fileDir)
end

pop_editoptions('option_single', 0);

close all
%% Load bdf file
if idx == 1
disp('Please specify bdf file from which you want to load data.')
[bdfFile,bdfFilePath] = uigetfile('*.bdf','Select bdf file.');
initialRefChannel = 30;
EEG = pop_biosig(strcat(bdfFilePath,bdfFile),'channels',[1:65] ,'ref',initialRefChannel);
EEG.initialRefChannel = initialRefChannel;
EEG.setname = name;
EEG.comments = pop_comments(EEG.comments,'',['Reference set as channel ', ...
    EEG.chanlocs(EEG.initialRefChannel).labels],1);
EEG = eeg_checkset(EEG);

EEG.pipeline = mfilename;
%% Resample to 512 Hz
EEG = pop_resample(EEG, 512);
EEG = eeg_checkset(EEG);

EEG.comments = pop_comments(EEG.comments,'','Resampled to 512 Hz',1);
%% Load channel locations
EEG=pop_chanedit(EEG, 'lookup',strcat(locFilePath,locFile),...
    'headrad',85, 'settype',{'[1:65]' 'EEG'});

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
EEG = pop_eegfiltnew(EEG, 'locutoff',0.1,'plotfreqz',1);
EEG = pop_eegfiltnew(EEG, 'hicutoff',30,'plotfreqz',1);

EEG.comments = pop_comments(EEG.comments,'','Filters applied, locutoff 0.1, hicutoff 30',1);

EEG = eeg_checkset(EEG);
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1,'setname',strcat(name,'_highpass'),...
    'savenew',strcat(fileDir,filesep,name,'_highpass'),'overwrite','on','gui','off');
end
%% Perform automatic rejection of non-visual trials
if idx <= 3
if idx == 3
EEG = pop_loadset('filename',strcat(fileDir,filesep,name,'_highpass.set'));
end

[ALLEEG,EEG,visidx,target_indices] = autoRejectNewTask2(ALLEEG,EEG,trainingTimingInfo);

EEG.comments = pop_comments(EEG.comments,'','Rejected trials with shocks',1);
%% Rename events based on stimulus properties
visidx2 = find(ismember(visidx,target_indices)==1);
labels = cell(1, length(visidx2));
visTable = testTimingInfo;
visTable.Stimulus = string(visTable.Stimulus);
ambigStrings = cellfun(@(x) strsplit(x,','), cellstr(visTable.Stimulus),...
    'UniformOutput',false);

for v = 1:length(visidx2)
    EEG.event(v).type = str2double([ambigStrings{visidx2(v)}{1},'9',ambigStrings{visidx2(v)}{2}]);
end

EEG.comments = pop_comments(EEG.comments,'','Renamed trials based on stimulus',1);

[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1,'setname',strcat(name,'_autoreject'),...
    'savenew',strcat(fileDir,filesep,name,'_autoreject'),'overwrite','on','gui','off'); 
EEG = eeg_checkset(EEG);
end
%% Epoch events
if idx <= 4
if idx == 4
EEG = pop_loadset('filename',strcat(fileDir,filesep,name,'_autoreject.set'));
end
EEG = pop_epoch( EEG, num2cell(unique([EEG.event(:).type])), [-0.2 1.5], 'newname', strcat(name,'_epochs'), ...
'epochinfo', 'yes');

EEG.comments = pop_comments(EEG.comments,'','Epoched from -0.2 to 1.5',1);

[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1,'setname',strcat(name,'_epochs'),...
    'savenew',strcat(fileDir,filesep,name,'_epochs'),'overwrite','on','gui','off'); 
EEG = eeg_checkset(EEG);

end
%% Use channels stats to reject bad channels 
if idx <= 5
if idx == 5
    EEG = pop_loadset('filename',strcat(fileDir,filesep,name,'_epochs.set'));
end

% Remove eye channel
EEG = pop_select( EEG, 'nochannel',{'EXG1'});
EEG.comments = pop_comments(EEG.comments,'','Removed eye channel',1);

originalEEG = EEG;

% First remove bad channels by eye
disp('Identify bad channels by eye and remember their names.')
pop_eegplot(EEG); % view channels and write down bad channel names
uiwait()
EEG = pop_select(EEG); 
removedChansIdx = ~ismember({originalEEG.chanlocs(:).labels},...
    {EEG.chanlocs(:).labels});
if ~isempty(find(removedChansIdx))
    removedChans = strjoin({EEG.chanlocs(removedChansIdx).labels},', ');
    EEG.comments = pop_comments(EEG.comments,'',['Removed channels ', removedChans, 'by eye']);
end

originalEEG2 = EEG;

flag = 0;
while flag == 0
    
    if isempty(EEG.epoch) % if data is continuous
        rejectionMethod = questdlg('Would you like to use cleanrawdata, pop_rejchan, or proceed?',...
        'Choose channel rejection method','cleanrawdata','pop_rejchan','proceed','cleanrawdata');
    else
        rejectionMethod = questdlg('Would you like to use pop_rejchan or proceed?',...
        'Choose channel rejection method','pop_rejchan','proceed','pop_rejchan');
    end
    
    if strcmp(rejectionMethod,'cleanrawdata')
        disp('Remember to deselect everything but bad channel selection in the cleanrawdata window!')

        EEG = pop_clean_rawdata(EEG);
        pop_eegplot(EEG)
        
        removedChans = strjoin({EEG.chanlocs(~ismember({originalEEG2.chanlocs(:).labels},...
            {EEG.chanlocs(:).labels})).labels},', ');
        disp(['The removed channels are ', removedChans])
        
        uiwait()
        uiwait()
        close all
        
        load('cleanrawdata_options.mat')
        disp(options)
        
        comments = 'Bad channel rejection using cleanrawdata';
        
        redo = questdlg('Would you like to redo your channel rejection?');
        if strcmp(redo,'No')
            flag = 1;
        end
    elseif strcmp(rejectionMethod,'pop_rejchan')

        [EEG, indelec] = pop_rejchan(EEG);
        uiwait()
        close all
        
        removedChans = strjoin({EEG.chanlocs(~ismember({originalEEG2.chanlocs(:).labels},...
            {EEG.chanlocs(:).labels})).labels},', ');
        disp(['The removed channels are ', removedChans])
        
        comments = 'Bad channel rejection using pop_rejchan';
        
        redo = questdlg('Would you like to redo your channel rejection?');
        if strcmp(redo,'No')
            flag = 1;
        end
    end
end

removedChansIdx = ~ismember({originalEEG2.chanlocs(:).labels},...
    {EEG.chanlocs(:).labels});
if ~isempty(removedChansIdx)
    removedChans = strjoin({EEG.chanlocs(removedChansIdx).labels},', ');
    EEG.comments = pop_comments(EEG.comments,'',['Removed channels ', removedChans, ' with ', rejectionMethod]);
end
EEG = eeg_checkset(EEG);

[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1,'setname',strcat(name,'_rejchans'),...
    'savenew',strcat(fileDir,filesep,name,'_rejchans'),'overwrite','on','gui','off'); 
end
%% Get number of channels before interpolation
if idx <= 6
if idx == 6
    EEG = pop_loadset('filename',strcat(fileDir,filesep,name,'_rejchans.set'));
    originalEEG = pop_loadset('filename',strcat(fileDir,filesep,name,'_autoreject.set'));
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
if idx <= 7
if idx == 7
EEG = pop_loadset('filename',strcat(fileDir,filesep,name,'_interp','.set'));
end

EEG = pop_reref(EEG, []);
% Remove the initial reference channel, which contains only zeros
EEG = pop_select(EEG,'nochannel',EEG.initialRefChannel);

EEG.comments = pop_comments(EEG.comments,'','Changed to average reference',1);

[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1,'setname',strcat(name,'_averef'),...
    'savenew',strcat(fileDir,filesep,name,'_averef'),'overwrite','on','gui','off'); 
EEG = eeg_checkset(EEG);
end
%% ICA for bad epoch rejection
if idx <= 8
if idx == 8
    EEG = pop_loadset('filename',strcat(fileDir,filesep,name,'_averef.set'));
end

% runamica15(EEG.data, 'num_chans', EEG.nbchan,...
%     'outdir', '/Users/daniellegruber/Documents/MATLAB/ControlCircuits/Jolien/amicaresults',...
%     'num_models', 1, 'pcakepp',numChannelsBeforeInterp,...
%     'do_reject', 1, 'numrej', 15, 'rejsig', 3, 'rejint', 1);
%  
% EEG.etc.amica  = loadmodout15('/Users/daniellegruber/Documents/MATLAB/ControlCircuits/Jolien/amicaresults');
% EEG.etc.amica.S = EEG.etc.amica.S(1:EEG.etc.amica.num_pcs, :); % Weirdly, I saw size(S,1) be larger than rank. This process does not hurt anyway.
% EEG.icaweights = EEG.etc.amica.W;
% EEG.icasphere  = EEG.etc.amica.S;
EEG = pop_runica(EEG, 'icatype', 'runica', 'extended',1,'interrupt','on','pca',numChannelsBeforeInterp);
EEG = eeg_checkset(EEG, 'ica');

EEG.comments = pop_comments(EEG.comments,'','Performed ICA for bad epoch rejection',1);

[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1,'setname',strcat(name,'_ica_for_epoch_rej'),...
    'savenew',strcat(fileDir,filesep,name,'_ica_for_epoch_rej'),'overwrite','on','gui','off'); 
end
%% Reject bad epochs
if idx <= 9
if idx == 9
EEG = pop_loadset('filename',strcat(fileDir,filesep,name,'_ica_for_epoch_rej.set'));
end

events1 = [EEG.event(:).urevent];

% to visualize ICA components
pop_selectcomps(EEG,1:size(EEG.icaact,1))

% reject epochs based on ICA component stats
pop_rejmenu(EEG,0)

f = figure('menubar','none') ;
ah = gca ;
th = text(1,1,'Close this figure when you are done rejecting epochs.','FontSize',18) ;
set(ah,'visible','off','xlim',[0 2],'ylim',[0 2],'Position',[0 0 1 1]) ;
set(th,'visible','on','HorizontalAlignment','center','VerticalAlignment','middle')
uiwait(f)

events2 = [EEG.event(:).urevent];

% tempHistory = splitlines(EEG.history);
% [~,idx] = ismember(['EEG.setname=''',name,'_averef'';'], tempHistory);
% EEG.comments = pop_comments(EEG.comments,'','Rejected epochs using the following methods:',1);
% EEG.comments = pop_comments(EEG.comments,'',tempHistory(idx+1:end),1);
EEG.comments = pop_comments(EEG.comments,'',...
    strcat("Rejected epochs ", strjoin(string(find(~ismember(events1,events2))),', ')),1);

[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1,'setname',strcat(name,'_epochs_rejected'),...
    'savenew',strcat(fileDir,filesep,name,'_epochs_rejected'),'overwrite','on','gui','off'); 
EEG = eeg_checkset(EEG);
end
%% ICA for bad component rejection
if idx <= 10
if idx == 10
    EEG = pop_loadset('filename',strcat(fileDir,filesep,name,'_epochs_rejected.set'));
end

% runamica15(EEG.data, 'num_chans', EEG.nbchan,...
%     'outdir', '/Users/daniellegruber/Documents/MATLAB/ControlCircuits/Jolien/amicaresults',...
%     'num_models', 1, 'pcakepp',numChannelsBeforeInterp,...
%     'do_reject', 1, 'numrej', 15, 'rejsig', 3, 'rejint', 1);
%  
% EEG.etc.amica  = loadmodout15('/Users/daniellegruber/Documents/MATLAB/ControlCircuits/Jolien/amicaresults');
% EEG.etc.amica.S = EEG.etc.amica.S(1:EEG.etc.amica.num_pcs, :); % Weirdly, I saw size(S,1) be larger than rank. This process does not hurt anyway.
% EEG.icaweights = EEG.etc.amica.W;
% EEG.icasphere  = EEG.etc.amica.S;
EEG = pop_runica(EEG, 'icatype', 'runica', 'extended',1,'interrupt','on','pca',numChannelsBeforeInterp);
EEG.comments = pop_comments(EEG.comments,'','Performed ICA for bad component rejection',1);
EEG = eeg_checkset(EEG, 'ica');
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1,'setname',strcat(name,'_ica_for_comp_rej'),...
    'savenew',strcat(fileDir,filesep,name,'_ica_for_comp_rej'),'overwrite','on','gui','off'); 
end
%% Reject components by map
if idx <= 11
if idx == 11
EEG = pop_loadset('filename',strcat(fileDir,filesep,name,'_ica_for_comp_rej.set'));
end
EEG = pop_selectcomps(EEG, [1:size(EEG.icaweights,1)]);
[ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);
uiwait
uiwait
rejectIdx = find(EEG.reject.gcompreject);
EEG.comments = pop_comments(EEG.comments,'',['Rejected independent components ', ...
    strjoin(string(rejectIdx)),', '],1);
EEG = pop_subcomp(EEG);

writematrix(rejectIdx,strcat(fileDir,filesep,name,'_rejected_comps.txt'))

[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1,'setname',strcat(name,'_comps_rejected'),...
    'savenew',strcat(fileDir, filesep,name,'_comps_rejected'),'overwrite','on','gui','off'); 
EEG = eeg_checkset(EEG);
%% Save to all data folder
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1,'setname',strcat('final_',name),...
    'savenew',strcat(allDataDir,filesep,'final_',name),'overwrite','on','gui','off'); 
EEG = eeg_checkset(EEG);
end