function [ALLEEG,EEG,visidx,target_indices] = autoRejectNewTask2(ALLEEG,EEG,trainingTimingInfo)
%%
if ischar(EEG.event(1).type)
    for e = 1:length(EEG.event)
        EEG.event(e).type = str2double(EEG.event(e).type);
    end
end
 
latencyInPoints = [EEG.event(:).latency]; % latency in sample points
%latencyInSec = (cell2mat({latencyInPoints})-1)/EEG.srate; % latency in seconds
latencyInSec = (latencyInPoints-1)/EEG.srate; % latency in seconds

events = EEG.event;
badviscount = 0;
goodviscount = 0;
visidx = [];
e = 1;
while e <= length(EEG.event)
   if e <= length(EEG.event)-2 && ...
           EEG.event(e).type == 64703 && ...
           EEG.event(e+1).type == 64703 && ...
           EEG.event(e+2).type == 64703 && ...
           latencyInSec(e+2)-latencyInSec(e) < 0.5
      
       EEG.event(e).type = 'block';
       EEG.event(e+1).type = 'block';
       EEG.event(e+2).type = 'block';
       if e+3 > length(EEG.event)
           break
       else
           e = e+3;
       end
   elseif e <= length(EEG.event)-1 && ...
           EEG.event(e).type == 64703 && ...
           EEG.event(e+1).type == 64703 && ...
           latencyInSec(e+1)-latencyInSec(e) < 0.5
      
       EEG.event(e).type = 'block';
       EEG.event(e+1).type = 'block';
       if e+2 > length(EEG.event)
           break
       else
           e = e+2;
       end
   elseif EEG.event(e).type == 64703 && badviscount < size(trainingTimingInfo,1)
       EEG.event(e).type = 'nan';
       e = e+1;
       badviscount = badviscount + 1;
   elseif EEG.event(e).type == 64751
       EEG.event(e).type = 'elec';
       EEG.event(e-1).type = 'elec';
       e = e+1;
   elseif EEG.event(e).type == 64703
       goodviscount = goodviscount + 1;
       EEG.event(e).type = 'vis';
       visidx = [visidx,e];
       e = e+1;
   else
       EEG.event(e).type = 'nan';
       if e+1 > length(EEG.event)
           break
       else
           e = e+1;
       end
   end
end
%%
[EEG,target_indices] = pop_selectevent( EEG, 'type',{'vis'},'omittype',{'block','nan','elec'},...
    'deleteevents','on','deleteepochs','on');
end