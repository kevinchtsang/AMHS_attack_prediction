% use after selecting weekly events
% lasso reg to rank features

load trainingData

% name of features
% disp(X_names)
%% Feature selection

usePeakflow = true;
minFreq = 1;

selected_features = 1:size(X,2);

peakflow_features = contains(X_names, "peakflow");
freq_features = contains(X_names, "Freq");

% select points with freq > 1
selected_entries = X(:,freq_features) >= minFreq;
X = X(selected_entries,:);
Y = Y(selected_entries,:);


peakflow_patients = any(X(:,1)' == IP_peakflow,1);
if usePeakflow    
    X = X(peakflow_patients, selected_features);
    Y = Y(peakflow_patients);
else
    selected_features = selected_features(~peakflow_features);
    X = X(peakflow_patients, selected_features);
    Y = Y(peakflow_patients);
end
X_names_used = X_names(selected_features);

%% standardise features
X = X - mean(X,1);
X = X ./ std(X);

%% LASSO

loopSize = 150;
B_all = zeros(size(X,2),1);
numFold = 3;

tic
parfor Nloop=1:loopSize
    disp(['loop ',num2str(Nloop),' of ',num2str(loopSize)])
    indices = crossvalind('Kfold',size(X,1),numFold);
    kfold = randi(numFold);
    X_train = X(indices~=kfold,:);
    Y_train = Y(indices~=kfold,:);
    [B,FitInfo] = lassoglm(X_train,Y_train,'binomial','NumLambda',100,'CV',10);%,'PredictorNames',string(X_names));
    Index=FitInfo.Index1SE;
    B_all = B_all + sum(B~=0,2);
    optimal_model = B(:,Index);
    optimalModel(Nloop).weight = nonzeros(optimal_model);
    optimalModel(Nloop).name = string(X_names_used(optimal_model~=0));
    optimalModel(Nloop).features = selected_features(optimal_model~=0);
end
clc;
toc
B_all = B_all/loopSize;

%% distribution of optimal model size
counts = zeros(size(X_names));
for Nloop=1:loopSize
    counts(length(optimalModel(Nloop).weight)) = counts(length(optimalModel(Nloop).weight)) + 1;
end
figure
bar(counts)
title('distribution of optimal model size')
[~,optNumFeatures] = max(counts);

%%
optWeight = 0;
count = 0;
optNames = '';
for Nloop=1:loopSize
    if length(optimalModel(Nloop).weight) == round(optNumFeatures)
        optWeight = optWeight + optimalModel(Nloop).weight;
        count = count + 1;
        optNames_old = optNames;
        optNames = optimalModel(Nloop).name;
        if optNames_old ~= optNames
            if count ~=1
                disp('changed optNames')
                disp(count)
            end
        end
    end
end
optWeight = optWeight/count;
[optNames',optWeight]

% optimalModel=B(:,Index);
% optimalModel = [string(X_names_used(optimalModel~=0))', optimalModel(optimalModel~=0)];
% optimal_model = B(:,Index);
% optimalModel.weight = nonzeros(optimal_model);
% optimalModel.name = string(X_names_used(optimal_model~=0));
% optimalModel.features = selected_features(optimal_model~=0);

disp(['optimalModel used ',num2str(optNumFeatures),' features'])

% lassoPlot(B,FitInfo,'PlotType','CV');
% legend('show')

best_features_lasso = sortrows([B_all, string(X_names_used)', selected_features'],'descend');
if any(best_features_lasso(:,1)=="100")
    disp('check best features lasso')
end

%% coefficient path
% figure
% plot(1:size(B,2),B)
% legend(X_names_used,'Location','Best','NumColumns',2)
% xlabel('\lambda')
% ylabel('Coefficients')
% title('Coefficient Path - LASSO')

%% save
save best_features_lasso best_features_lasso optimalModel usePeakflow minFreq optNumFeatures