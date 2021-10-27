function [GMA] = Alg_GMA(FPR,TPR)
%ALG_GMA Calculates Geometric mean accuracy
%   Geometric mean accuracy = sqrt((TP/(TP+FN))*(TN/(TN+FP)))
%   = sqrt(TPR*(1-FPR))
% FPR = OPTROCPT(1); X
% TPR = OPTROCPT(2); Y
if any(size(FPR)~=size(TPR))
    disp('not same size')
    return
elseif length(FPR)==1 
    GMA = sqrt(TPR*(1-FPR));
else
    GMA = sqrt(TPR.*(1-FPR));
end
end

