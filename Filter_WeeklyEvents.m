% Select training data for machine learning algorithms
% use parameters to change the training data and patients chosen

%% (optional) load AllPatients

% load AllPatients;

% otherwise, first run Create_AllPatients.m 

%% Parameters

% number of sesssions that a patient should have for analysis
CO_Daily        = 0; 
CO_Weekly       = 0; 
PeakFlowDaily   = 2;

daysBeforeEvent = 14; % selecting initial blocks
daysAfterEvent  = 14; % can try [3,14] % will not use these data for training classifier
maxBlockSize    = 14; % for resizing and grouping blocks together
addSI_Freq      = true; % add SI and Freq to predictors list

% choose from peakflowNorm,quick_relief_puffs,TriggerNumber
% day_symptoms,night_symptoms,randomNoise,medicine,use_qr
predictors = {'peakflowNorm','quick_relief_puffs','TriggerNumberNorm',...
    'day_symptoms','night_symptoms','medicine','randomNoise'};

% choose from grad, r2, middle, gradAbs
extentions = {'grad','r2', 'middle','gradAbs'};

%% Select patients

IP = find((AllPatients.WeeklySurveySize > CO_Weekly)...
    & (AllPatients.DailySurveySize      > CO_Daily)...
    & (AllPatients.PeakFlowSize         > PeakFlowDaily));
IP_peakflow = IP;
counter     = 0;

% identify the patients who had an undesirable event (admission, doc visit,
% or emergency)

SelectedPatients = [];
for kp=1:length(IP)
    SI=IP(kp); % selected patient
    if(~isempty(find(AllPatients.WeeklySurvey{SI}.emergency_room == 'true', 1))...
            || (~isempty(find(AllPatients.WeeklySurvey{SI}.asthma_doc_visit == 'true', 1)))...
            || (~isempty(find(AllPatients.WeeklySurvey{SI}.admission == 'true', 1))))
        counter = counter + 1;
        SelectedPatients = [SelectedPatients;SI];
    end
end
    
%% For all patient
tic
for patientnumber = 1:length(IP)
    disp(['Patient number ',num2str(patientnumber)])
    SI = IP(patientnumber); 
    pdata=AllPatients.DailySurvey{SI};
    pdata_week = AllPatients.WeeklySurvey{SI};
    
    % identify when event happened
    EventWeek = [];
    counter = 0;
    for kp = 1:height(pdata_week)
        if(pdata_week.emergency_room(kp) == 'true')...
                || (pdata_week.asthma_doc_visit(kp) == 'true')...
                || (pdata_week.admission(kp) == 'true')
            day       = pdata_week.createdOn(kp);
            EventWeek = [EventWeek;day];
        end
    end


    % group 1 week of daily prompt data
    % and classify stable unstable

    pdata.Date=Convert_datetime(pdata.createdOn);
    pdata.weekNum = strings(height(pdata),1);
    pdata.nextEvent = max(pdata.Date)+daysBeforeEvent+daysAfterEvent+zeros(height(pdata),1);
    pdata.prevEvent = min(pdata.Date)-daysBeforeEvent+zeros(height(pdata),1);

    for kd=1:height(pdata)
        pdata.eventWeekNum(kd) = sum(pdata.createdOn(kd) < EventWeek);
        
        % create week number based on weekly prompt
        pdata.weekNumWP(kd) = sum(pdata.createdOn(kd) < pdata_week.createdOn);
        
        % create week number based on calandar
        pdata.weekNumCal(kd) = week(pdata.Date(kd));

        if pdata.eventWeekNum(kd) ~= 0
            pdata.nextEvent(kd) = Convert_datetime(EventWeek(1+length(EventWeek)-pdata.eventWeekNum(kd)));
        end
        if length(EventWeek)-pdata.eventWeekNum(kd) > 0
            pdata.prevEvent(kd) = Convert_datetime(EventWeek(length(EventWeek)-pdata.eventWeekNum(kd)));
        end
    end
    
    % flip weekNumWP and eventWeekNum
    pdata.weekNumWP = 1 + max(pdata.weekNumWP) - pdata.weekNumWP;
    pdata.eventWeekNum = 1 + max(pdata.eventWeekNum) - pdata.eventWeekNum;
    
    % stable if more than (14) daysAfterEvent
    % and more than (14) days before nextEvent
    % and after event
    pdata.Stable = ((pdata.nextEvent - daysBeforeEvent > pdata.Date)&...
        (pdata.prevEvent + daysAfterEvent <= pdata.Date));

    % data just after events will not be used in training data
    pdata.justAfterEvent = (pdata.prevEvent+daysAfterEvent>pdata.Date)&...
        (~(abs(pdata.prevEvent-pdata.Date)<0.5));
    disp('Column Stable added')


    for kd=1:height(pdata)
        % make string weekNum Calandar_WP_stable
%         pdata.weekNum(kd) = num2str(pdata.weekNumCal(kd))+...
%             "_"+num2str(pdata.weekNumWP(kd))+"_"+num2str(pdata.Stable(kd));
        % make string weekNum WP_Stable_Calandar
        pdata.weekNum(kd) = num2str(pdata.weekNumWP(kd))+...
            "_"+num2str(pdata.Stable(kd))+"_"+num2str(pdata.weekNumCal(kd));
    end
       
    
    % normalised PEF values and reported trigger number to maximum of patient
    % normalised as batch, take max over all pdata
    pdata.peakflowNorm = pdata.peakflow/max(pdata.peakflow);
    pdata.TriggerNumberNorm = pdata.TriggerNumber/max(pdata.TriggerNumber);
    
    % set 4 medicine to nan
    pdata.medicine(pdata.medicine==4)=nan;
    
    % set NaN quick_relief_puffs to zero
    pdata.quick_relief_puffs(isnan(pdata.quick_relief_puffs)) = zeros(sum(isnan(pdata.quick_relief_puffs)),1);
    
    % make a random number feature
    pdata.randomNoise = rand(height(pdata),1);
    
    % trainDataFull is to be summarised to trainData
    trainDataFull =  pdata(~pdata.justAfterEvent,[{'weekNum','createdOn','Stable'}, predictors]);
    disp('train data selected')
    
    % create block number, a block a some nearby weeks put together
    % Linear fit summary of training data
    % if the weekly prompt number is within 1, they may also combine
    [WN,weekNum] = findgroups(trainDataFull.weekNum);
    weeks = table(weekNum);
    weeks.Freq = splitapply(@length,trainDataFull.Stable,WN);
    weeks.createdOn = splitapply(@max,trainDataFull.createdOn,WN);
    
    [keySet, valueSet] = Alg_bin_pack(weeks.weekNum, weeks.Freq, maxBlockSize);
    
%     keySet = weeks.weekNum;
%     valueSet = weeks.block;
    weekNum_block_map = containers.Map(keySet,valueSet);
    
    for kd=1:height(trainDataFull)
        trainDataFull.block(kd) = weekNum_block_map(trainDataFull.weekNum(kd));
    end
    
    [B,block] = findgroups(trainDataFull.block);
    
    trainData = table(block);
    trainData.SI = SI+zeros(height(trainData),1);
    
    % summarise over each block
    for i=1:length(predictors)
        % loop over variables used for model
%         column = trainDataFull.Properties.VariableNames{3+i}; % 3 other info
        column = predictors{i};
        %tried /10^12 no significant effect
        DT = table(trainDataFull.createdOn, trainDataFull{:,column});
        table_func = @(dates,values)Convert_summary_gradient(dates, values);
       
        % add to training data
        [grad, r2, middle]=splitapply(table_func,DT,B);
        gradAbs = abs(grad);
        T = table(grad,r2, middle,gradAbs);
        for ep = 1:length(extentions)
            trainData = [trainData T(:,extentions{ep})];
            varName = [column, extentions{ep}];
            trainData.Properties.VariableNames{end} = varName;
        end
    end
    trainData.Stable = (splitapply(@mean,trainDataFull.Stable,B)>0.5);
    trainData.Freq = splitapply(@length,trainDataFull.Stable,B);
    disp('train data summarised')
    
    
    % make table of all patients training data
    if patientnumber==1
        trainDataAll = trainData;
    else
        trainDataAll = [trainDataAll; trainData];
    end
    
    
end
clc;
disp('trainDataAll formed')
toc
disp(['total training data: ',num2str(length(trainDataAll.Stable))])
disp(['total training data (Stable): ',num2str(sum(trainDataAll.Stable))])
disp(['mean data points in each block (Stable): ',num2str(mean(trainDataAll.Freq(trainDataAll.Stable)))])
disp(['total training data (Unstable): ',num2str(sum(~trainDataAll.Stable))])
disp(['mean data points in each block (Unstable): ',num2str(mean(trainDataAll.Freq(~trainDataAll.Stable)))])


figure
histogram(trainDataAll.Freq, 'NumBins', 50)
title("Histogram of data points in each block")


%% Predictor
% preds = ismember(trainDataAll.Properties.VariableNames,predictors);
% contains chooses all predictors with their extensions
predictors2 = predictors;
if addSI_Freq
    predictors2 = [{'SI','Freq'}, predictors2]; % add SI and Freq into the model
end
preds = contains(trainDataAll.Properties.VariableNames,predictors2);

X = trainDataAll{:,preds};
Y = trainDataAll.Stable;

X_names = trainDataAll.Properties.VariableNames(preds);

save trainingData X Y X_names IP IP_peakflow
