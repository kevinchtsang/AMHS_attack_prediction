% use after selecting weekly events
% use best features from lasso 
% parallel run of model fitting
% make box plot of AUC distribution

% train base model

load trainingData
load best_features_lasso
% name of features
% disp(X_names)

loopSize = 500;
numFold = 8; 

modelNames = {'Base'};
% Base = LogReg with only mean

%% Feature selection
%usePeakflow=true;
% using best_features according to FitModels_Dec022019B
% selected_features = double(best_features_lasso(1:optNumFeatures,3))';

% random_features = (best_features(:,3));
random_features = contains(best_features_lasso(:,2),"random");
gradAbs_features = contains(best_features_lasso(:,2),"gradAbs");
grad_features = contains(best_features_lasso(:,2),"grad")&~gradAbs_features;
peakflow_features = contains(best_features_lasso(:,2),"peakflow")&usePeakflow;
middle_features = contains(best_features_lasso(:,2),"middle");

selected_features = double(best_features_lasso(middle_features&~random_features,3));

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
X = X-mean(X,1);
X = X./std(X);

%% Loop

% ROC_loop = cell(loopSize,5); % 5 methods
ROC_loop_base = cell(loopSize,1);

tic
for Nloop = 1:loopSize 

    %% Fit models

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

        %% train the model
        GLM_model = fitglm(X_train,Y_train,'Distribution','binomial','Link','logit');

        % score is posterior probabilities
        [~,score_glm] = predict(GLM_model,X_test);

        % store result
        Pred(kfold).score_glm = score_glm(:,2);
        Pred(kfold).Y = Y_test;

    end
    
    %% unparallel
    GLM_pred = [];
    Y_reorder = [];
    for kfold = 1:numFold
        GLM_pred = [GLM_pred; Pred(kfold).score_glm];
        Y_reorder = [Y_reorder; Pred(kfold).Y];
    end
    
    GLM_pred = Alg_standardise(GLM_pred);

    [X_glm,Y_glm,T_glm,AUC_glm] = perfcurve(Y_reorder,GLM_pred,1);

    % store AUC and ROC
    ROC_loop_glm{Nloop} = {X_glm,Y_glm,T_glm,AUC_glm};

    if mod(Nloop,10)==0
        disp(['loop number ',num2str(Nloop),' of ',num2str(loopSize)])
        toc
    end
end
clc;
disp([num2str(loopSize),' loops completed'])
toc

%% save
ROC_loop_base = ROC_loop_glm;
AUC_loop=zeros(size(ROC_loop_base));
GMA_loop=zeros(size(ROC_loop_base));

for loopIndex = 1:length(ROC_loop_base)
    if isempty(ROC_loop_base{loopIndex})
        AUC_loop(loopIndex) = 0;
        disp('empty')
    else
        AUC_loop(loopIndex) = ROC_loop_base{loopIndex}{4};
        GMA_loop(loopIndex) = max(Alg_GMA(ROC_loop_base{loopIndex}{1},ROC_loop_base{loopIndex}{2}));
    end
end

AUC_loop_base = AUC_loop;
GMA_loop_base = GMA_loop;

loopSize_base = loopSize;
modelNames_base = modelNames;

save AUC_GMA_loop_base AUC_loop_base GMA_loop_base loopSize_base modelNames_base ROC_loop_base


