% add 3 new columns to DailyPromptSurvey:
% - TriggerUnaware if they selected trigger 21
% - TriggerNone if they selected trigger 22
% - TriggerNA if invalid answer

clc;clear all;
load DailyPromptSurvey;

numDailySurvey=size(DailyPromptSurvey,1);
for kd=1:height(DailyPromptSurvey)
    if mod(kd,1000)==0
        disp(['Processing Daily Survey Number: ',num2str(kd),' out of ',num2str(numDailySurvey)]);
    end
    tempArray=textscan(DailyPromptSurvey.get_worse(kd),'%s','Delimiter',',');
    
    % initialise all flags to zero
    DailyPromptSurvey.TriggerUnaware(kd,1)=0;
    DailyPromptSurvey.TriggerNone(kd,1)=0;
    DailyPromptSurvey.TriggerNA(kd,1)=0;
    
    for kt=1:size(tempArray{1},1)
        if(str2num(tempArray{1}{kt})==21)  % patient unaware what triggers asthma 
            DailyPromptSurvey.TriggerUnaware(kd,1)=1;
        end
        if(str2num(tempArray{1}{kt})==22) % none of those trigger their asthma
            DailyPromptSurvey.TriggerNone(kd,1)=1;
        end
        if((tempArray{1}{kt})=="NA") % invalid answer
            DailyPromptSurvey.TriggerNA(kd,1)=1;
        end
    end
    DailyPromptSurvey.TriggerNumber(kd,1)=size(tempArray{1},1) - ...
        (DailyPromptSurvey.TriggerUnaware(kd,1) + DailyPromptSurvey.TriggerNone(kd,1) + DailyPromptSurvey.TriggerNA(kd,1));
end

% save updated DailyPromptSurvey
save('DailyPromptSurvey_Augmented.mat','DailyPromptSurvey')
clc;
disp(['Processed ',num2str(numDailySurvey), ' Daily Survey entires']);

