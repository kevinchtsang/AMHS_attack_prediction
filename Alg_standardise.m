function [X_new] = Alg_standardise(X)
%Alg_standardise Summary of this function goes here
%   Detailed explanation goes here
X_new = X-mean(X,1);
X_new = X_new./std(X_new);
if all(isnan(X))
    X_new = ones(size(X));
end
end

