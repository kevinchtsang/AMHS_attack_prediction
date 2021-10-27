% Create AllPatients by combining the surveys

clc;clear all;
load DailyPromptSurvey_Augmented;
load WeeklyPromptSurvey;
load EQ5DSurvey;

% let us recode the patient IDs for easy reference
Patient.ID         = 1:length(unique(DailyPromptSurvey.healthCode));
Patient.HealthCode = unique(DailyPromptSurvey.healthCode);
numPatients        = length(Patient.ID);

for kp = 1:numPatients
    if mod(kp,500)==0
        disp(['Processing Record Number: ',num2str(kp),' out of ',num2str(numPatients)]);
    end
    AllPatients.ID(kp,1)=Patient.ID(kp);
    
    % get all the records for each patient
    I_DS   = find(DailyPromptSurvey.healthCode       == Patient.HealthCode(kp)); % daily survey
    I_WS   = find(WeeklyPromptSurvey.healthCode      == Patient.HealthCode(kp)); % weekly survey
    I_EQ5D = find(categorical(EQ5DSurvey.healthCode) == Patient.HealthCode(kp)); % EQ5D survey
    
    % assign the records in the new structure
    AllPatients.DailySurvey{kp,1}      = DailyPromptSurvey(I_DS,:);
    AllPatients.DailySurveySize(kp,1)  = length(I_DS);
    AllPatients.WeeklySurvey{kp,1}     = WeeklyPromptSurvey(I_WS,:);
    AllPatients.WeeklySurveySize(kp,1) = length(I_WS);
    AllPatients.EQ5D{kp,1}             = EQ5DSurvey(I_EQ5D,:);
    AllPatients.EQ5DSize(kp,1)         = length(I_WS);
    AllPatients.PeakFlowSize(kp,1)     = length(find(~isnan(DailyPromptSurvey.peakflow(I_DS))));
    
end

% (optional) save AllPatients - large file (around 20 GB)
% save('AllPatients.mat','AllPatients','-v7.3');

clc;
disp(['Finished processing ', num2str(numPatients),' patients']);

