% plots for EMBC
fontSize = 16;

%% select high quality patients
CO_Daily=30; 
CO_Weekly=3; 
PeakFlowDaily=30;

IP_special=find((AllPatients.DailySurveySize>CO_Daily)...
    & (AllPatients.WeeklySurveySize>CO_Weekly)...
    & (AllPatients.PeakFlowSize>PeakFlowDaily));

%% search for unstable
EventWeek=[];
ip=1;
while isempty(EventWeek)
    patientnumber = IP_special(ip);

    disp(['Patient number ',num2str(patientnumber)])
    SI = IP_special(patientnumber);%SelectedPatients(patientnumber);
    pdata=AllPatients.DailySurvey{SI};
    pdata_week = AllPatients.WeeklySurvey{SI};

    disp(['daily entries: ',num2str(size(pdata,1))])

    % identify when event happened
    EventWeek = [];
    counter = 0;
    for kp=1:height(pdata_week)
        if(pdata_week.emergency_room(kp)=='true')...
                || (pdata_week.asthma_doc_visit(kp)=='true')...
                || (pdata_week.admission(kp)=='true')
            day=pdata_week.createdOn(kp);
            EventWeek=[EventWeek;day];
        end
    end
    disp(['unstable events: ',num2str(size(EventWeek,1))])
    ip = ip + 1;
end
% 16 for unstable
%% select patient
% patientnumber = IP_special(2); %2 = 22 for stable

%% select data
disp(['Patient number ',num2str(patientnumber)])
SI = IP_special(patientnumber);%SelectedPatients(patientnumber);
% SI = IP(patientnumber);
pdata=AllPatients.DailySurvey{SI};
pdata_week = AllPatients.WeeklySurvey{SI};

disp(['daily entries: ',num2str(size(pdata,1))])

% identify when event happened
EventWeek=[];
counter=0;
for kp=1:height(pdata_week)
    if(pdata_week.emergency_room(kp)=='true')...
            || (pdata_week.asthma_doc_visit(kp)=='true')...
            || (pdata_week.admission(kp)=='true')
        day=pdata_week.createdOn(kp);
        EventWeek=[EventWeek;day];
    end
end
disp(['unstable events: ',num2str(size(EventWeek,1))])

% group 1 week of daily prompt data
% and classify stable unstable

pdata.Date=Convert_datetime(pdata.createdOn);
%     pdata.eventWeekNum = zeros(height(pdata),1);
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
pdata.weekNumWP = 1+ max(pdata.weekNumWP)-pdata.weekNumWP;
pdata.eventWeekNum = 1+ max(pdata.eventWeekNum)-pdata.eventWeekNum;

% stable if more than (3) daysAfterEvent
% and more than (7) days before nextEvent
% and after event
pdata.Stable = ((pdata.nextEvent-daysBeforeEvent>pdata.Date)&...
    (pdata.prevEvent+daysAfterEvent<=pdata.Date));

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

% weeks.block = Alg_bin_pack(weeks.weekNum, weeks.Freq, maxBlockSize);
[keySet, valueSet] = Alg_bin_pack(weeks.weekNum, weeks.Freq, maxBlockSize);

% keySet = weeks.weekNum;
% valueSet = weeks.block;
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

%% Plot
%% stable linear fit

plot_data = pdata(any(pdata.weekNumWP == [16:18],2),:); %16:18 %10:12

% cut into 2 week period:
plot_data = plot_data(3:end-1,:);
X = plot_data.createdOn;
% Y = plot_data.peakflow;
Y = plot_data.peakflowNorm*100;

% fit line
[c,S] = polyfit(X(~isnan(Y)), Y(~isnan(Y)),1);
gradient = c(1);
intercept = c(2);


xlin = linspace(min(X),max(X),5);
% figure('position', [10, 10, 610, 310])
% figure('DefaultAxesFontSize',fontSize, 'position', [10, 10, 410, 310])
figure('DefaultAxesFontSize',fontSize, 'position', [10, 10, 810, 310])
subplot(1,2,1)
hold on
scatter(Convert_datetime(X), Y, 'filled')
plot(Convert_datetime(xlin), xlin*gradient + intercept)
hold off
xlabel('Date')
ylabel('PEF (%)')
title('Stable Period')
datetick('x', 'dd mmm')
% ylim([500,600])
% xticklabels(Convert_datetime(xticklabels))

%% unstable linear fit


% plot_data = pdata(pdata.weekNumWP == 25,:);
plot_data = pdata(any(pdata.weekNumWP == [24:25],2),:);
X = plot_data.createdOn;
Y = plot_data.peakflowNorm*100;

% fit line
[c,S] = polyfit(X(~isnan(Y)), Y(~isnan(Y)),1);
gradient = c(1);
intercept = c(2);


xlin = linspace(min(X),max(X),5);
% figure('DefaultAxesFontSize',fontSize, 'position', [10, 10, 610, 310])
% figure('DefaultAxesFontSize',fontSize, 'position', [10, 10, 410, 310])
subplot(1,2,2)
hold on
scatter(Convert_datetime(X), Y, [], [1 0 0], 'filled', 'DisplayName','Unstable Class','marker','s')
plot(Convert_datetime(xlin), xlin*gradient + intercept)
hold off
xlabel('Date')
ylabel('PEF (%)')
title('Unstable Period')
datetick('x', 'dd mmm')
% ylim([500,600])
% xticklabels(Convert_datetime(xticklabels))

%% plot periods of stable and unstable

plot_data = pdata(any(pdata.weekNumWP == [21:27],2),:); %21:27
X = plot_data.createdOn;
Y = plot_data.peakflowNorm*100;

X_stable = X(plot_data.Stable==1 & plot_data.justAfterEvent~=1);
X_unstable = X(plot_data.Stable==0 & plot_data.justAfterEvent~=1);
X_buffer = X(plot_data.justAfterEvent==1);

Y_stable = Y(plot_data.Stable==1 & plot_data.justAfterEvent~=1);
Y_unstable = Y(plot_data.Stable==0 & plot_data.justAfterEvent~=1);
Y_buffer = Y(plot_data.justAfterEvent==1);

% rec_stable = ([xlin_stable(1), 1, xlin_stable(2), 1 ]);
figure('DefaultAxesFontSize',fontSize, 'position', [10, 10, 810, 410])
% figure
hold on
scatter(Convert_datetime(X_stable), Y_stable, 100, [0 0 1], 'filled', 'DisplayName','Stable class')
scatter(Convert_datetime(X_unstable), Y_unstable, 100, [1 0 0], 'filled', 'DisplayName','Unstable class','marker','s')
scatter(Convert_datetime(X_buffer), Y_buffer, 100, [0.3 0.7 0], 'filled', 'DisplayName','Transient','marker','d')

plot([pdata.nextEvent(1)-14 pdata.nextEvent(1)-14],[60,100],'LineStyle','--', 'color','red','LineWidth',2, 'DisplayName','Start of unstable period (T-14)')
plot([pdata.nextEvent(1) pdata.nextEvent(1)],[60,100], 'color','red','LineWidth',2, 'DisplayName','Unstable event (T)')
plot([pdata.nextEvent(1)+14 pdata.nextEvent(1)+14],[60,100], 'color','green','LineWidth',2, 'DisplayName','End of transition (T+14)')
% text(pdata.nextEvent(1),0.9,{' Unstable weekly',' survey entry'})
hold off
legend('location','best')
xlabel('Date')
ylabel('PEF (%)')
datetick('x', 'dd mmm')

