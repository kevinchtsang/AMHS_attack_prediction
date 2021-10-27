function [X_new] = Alg_standardise(X)
%Alg_standardise Standarise vector
%   Standardise by substracting mean and divide by standard deviation
X_new = X-mean(X,1);
X_new = X_new./std(X_new);
if all(isnan(X))
    X_new = ones(size(X));
end
end

