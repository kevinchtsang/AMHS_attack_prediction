% use after selecting training data with Filter_WeeklyEvents.m and
% selecting features with Model_LASSO.m

% parallel run of model fitting
% make box plot of AUC distribution

% name of features
% disp(X_names)

loopSize = 500;
numFold = 8; % 8 cores on laptop, so max parallel pool is 8

modelNames = {'Decision Tree','Logistic Regression','Naive Bayes','Support Vector Machine','Hybrid1','Hybrid2','Hybrid3'};
% hybrid1 = LR, SVM, NB, DT
% hybrid2 = LR, NB
% hybrid3 = LR, DT

TF = [true, false];

%% Feature selection
% for usePF=1:2
usePF = 2;
load trainingData
load best_features_lasso

usePeakflow = TF(usePF);
disp(['usePeakflow=', num2str(usePeakflow)])
% using best_features according to FitModels_Dec022019B
selected_features = double(best_features_lasso(1:optNumFeatures,3))';

% random_features = (best_features(:,3));
random_features = contains(best_features_lasso(:,2),"random");
gradAbs_features = contains(best_features_lasso(:,2),"gradAbs");
grad_features = contains(best_features_lasso(:,2),"grad")&~gradAbs_features;
peakflow_features = contains(best_features_lasso(:,2),"peakflow")&usePeakflow;
freq_features = contains(X_names,"Freq");

% select points with freq >1

selected_patients = X(:,freq_features)>=minFreq;
X = X(selected_patients,:);
Y = Y(selected_patients);

peakflow_patients = any(X(:,1)'==IP_peakflow,1);
X = X(peakflow_patients,:);
Y = Y(peakflow_patients);


if usePeakflow
    top_peakflow = best_features_lasso(~random_features&peakflow_features,:);
    top_peakflow = double(top_peakflow(1,3));
    if ~any(selected_features == top_peakflow)
        selected_features = [selected_features, top_peakflow];
    end
end
X = X(:, selected_features);


%% standardise features
X = X - mean(X,1);
X = X ./ std(X);

%% Loop

% ROC_loop = cell(loopSize,5); % 5 methods
ROC_loop_glm = cell(loopSize,1);
ROC_loop_svm = cell(loopSize,1);
ROC_loop_nb = cell(loopSize,1);
ROC_loop_dt = cell(loopSize,1);
ROC_loop_hyb1 = cell(loopSize,1);
ROC_loop_hyb2 = cell(loopSize,1);
ROC_loop_hyb3 = cell(loopSize,1);

tic
for Nloop = 1:loopSize 

    %% Fit models

%     GLM_pred = nan(size(X,1),1);
%     SVM_pred = nan(size(X,1),1);
%     NB_pred = nan(size(X,1),1);
%     DT_pred = nan(size(X,1),1);


    indices = crossvalind('Kfold',size(X,1),numFold);
    parfor kfold = 1:numFold
%         disp([num2str(kfold),' fold of ',num2str(numFold)])
        % make train and test set
%         ind_train = find(indices~=kfold);
%         ind_test = find(indices==kfold);
        X_train = X(indices~=kfold,:);
        X_test = X(indices==kfold,:);
        Y_train = Y(indices~=kfold,:);
        Y_test = Y(indices==kfold,:);

        %% train the models
        GLM_model = fitglm(X_train,Y_train,'Distribution','binomial','Link','logit');
        SVM_model = fitcsvm(X_train,Y_train,'Standardize',true);
        NB_model = fitcnb(X_train,Y_train);
    %     DT_model = fitctree(X_train,Y_train,'MinLeafSize',minleaf,'PredictorNames',X_names(selected_features));
        DT_model = fitctree(X_train,Y_train,'PredictorNames',X_names(selected_features));


        % score is posterior probabilities
        [~,score_glm] = predict(GLM_model,X_test);
        [~,score_svm] = predict(SVM_model,X_test);
        [~,score_nb] = predict(NB_model,X_test);
        [~,score_dt] = predict(DT_model,X_test);

        % store result
        Pred(kfold).score_glm = score_glm(:,2);
        Pred(kfold).score_svm = score_svm(:,2);
        Pred(kfold).score_nb = score_nb(:,2);
        Pred(kfold).score_dt = score_dt(:,2);
        Pred(kfold).Y = Y_test;

    end
    
    %% unparallel
    GLM_pred = [];
    SVM_pred = [];
    NB_pred = [];
    DT_pred = [];
    Y_reorder = [];
    for kfold = 1:numFold
        GLM_pred = [GLM_pred; Pred(kfold).score_glm];
        SVM_pred = [SVM_pred; Pred(kfold).score_svm];
        NB_pred = [NB_pred; Pred(kfold).score_nb];
        DT_pred = [DT_pred; Pred(kfold).score_dt];
        Y_reorder = [Y_reorder; Pred(kfold).Y];
    end
    
    %% create hybrid model
    GLM_pred = Alg_standardise(GLM_pred);
    SVM_pred = Alg_standardise(SVM_pred);
    NB_pred = Alg_standardise(NB_pred);
    DT_pred = Alg_standardise(DT_pred);
    hyb1_pred = 1 ./ (1 + exp(-GLM_pred)) + 1 ./ (1 + exp(-SVM_pred)) + 1 ./ (1 + exp(-NB_pred)) + 1 ./ (1 + exp(-DT_pred));
    hyb2_pred = 1 ./ (1 + exp(-GLM_pred)) + 1 ./ (1 + exp(-NB_pred));
    hyb3_pred = 1 ./ (1 + exp(-GLM_pred)) + 1 ./ (1 + exp(-DT_pred));

    [X_glm,Y_glm,T_glm,AUC_glm] = perfcurve(Y_reorder,GLM_pred,1);
    [X_svm,Y_svm,T_svm,AUC_svm] = perfcurve(Y_reorder,SVM_pred,1);
    [X_nb,Y_nb,T_nb,AUC_nb] = perfcurve(Y_reorder,NB_pred,1);
    [X_dt,Y_dt,T_dt,AUC_dt] = perfcurve(Y_reorder,DT_pred,1);
    [X_hyb1,Y_hyb1,T_hyb1,AUC_hyb1] = perfcurve(Y_reorder,hyb1_pred,1);
    [X_hyb2,Y_hyb2,T_hyb2,AUC_hyb2] = perfcurve(Y_reorder,hyb2_pred,1);
    [X_hyb3,Y_hyb3,T_hyb3,AUC_hyb3] = perfcurve(Y_reorder,hyb3_pred,1);

    % store AUC and ROC
    ROC_loop_glm{Nloop} = {X_glm,Y_glm,T_glm,AUC_glm};
    ROC_loop_svm{Nloop} = {X_svm,Y_svm,T_svm,AUC_svm};
    ROC_loop_nb{Nloop} = {X_nb,Y_nb,T_nb,AUC_nb};
    ROC_loop_dt{Nloop} = {X_dt,Y_dt,T_dt,AUC_dt};
    ROC_loop_hyb1{Nloop} = {X_hyb1,Y_hyb1,T_hyb1,AUC_hyb1};
    ROC_loop_hyb2{Nloop} = {X_hyb2,Y_hyb2,T_hyb2,AUC_hyb2};
    ROC_loop_hyb3{Nloop} = {X_hyb3,Y_hyb3,T_hyb3,AUC_hyb3};
    
    if mod(Nloop,10)==0
        disp(['loop number ',num2str(Nloop),' of ',num2str(loopSize)])
        toc
    end
end
% clc;
disp([num2str(loopSize),' loops completed'])
toc

%% save
ROC_loop = [ROC_loop_dt, ROC_loop_glm, ROC_loop_nb, ROC_loop_svm, ROC_loop_hyb1, ROC_loop_hyb2, ROC_loop_hyb3];
AUC_loop=zeros(size(ROC_loop));
GMA_loop=zeros(size(ROC_loop));

for loopIndex = 1:size(ROC_loop,1)
    for modelIndex = 1:length(modelNames)
        if isempty(ROC_loop{loopIndex,modelIndex})
            AUC_loop(loopIndex,modelIndex) = 0;
        else
            AUC_loop(loopIndex,modelIndex) = ROC_loop{loopIndex,modelIndex}{4};
            GMA_loop(loopIndex,modelIndex) = max(Alg_GMA(ROC_loop{loopIndex,modelIndex}{1},ROC_loop{loopIndex,modelIndex}{2}));
        end
    end
end

if usePeakflow
    disp('With PEF saved')
    AUC_loop_peakflow = AUC_loop;
    GMA_loop_peakflow = GMA_loop;
    ROC_loop_peakflow = ROC_loop;
    save AUC_GMA_loop AUC_loop_peakflow GMA_loop_peakflow ROC_loop_peakflow loopSize modelNames 
else
    disp('Without PEF saved')
    AUC_loop_nopeakflow = AUC_loop;
    GMA_loop_nopeakflow = GMA_loop;
    ROC_loop_nopeakflow = ROC_loop;
    save AUC_GMA_loop AUC_loop_nopeakflow GMA_loop_nopeakflow ROC_loop_nopeakflow loopSize modelNames
end

% end

% save AUC_GMA_loop AUC_loop_peakflow AUC_loop_nopeakflow GMA_loop_peakflow GMA_loop_nopeakflow ROC_loop_peakflow ROC_loop_nopeakflow loopSize modelNames 
 

