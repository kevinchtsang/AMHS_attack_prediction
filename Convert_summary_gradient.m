function [gradient, r2, middle] = Convert_summary_gradient(dates, values)
%CONVERT_SUMMARY_GRADIENT takes an array of values and output the fitted
%line
%   Use polyfit to summarise data
r2=1;

if (size(dates,1) ~= size(values,1))
% if (length(dates) ~= length(values))
    disp('different lengths')
    return
% elseif (sum(isnan(values)) == length(values))

elseif (sum(ismissing(values)) == size(values,1))
    gradient = 0;
    middle = 0;
%     intercept = 0;
else
    if class(values) == "categorical"
        values = values=="true";
    end
    if (size(values,1) > 1) 
%         c = polyfit(dates(~ismissing(values)),values(~ismissing(values)),1);
        inputValues = values(~isnan(values));
        [c,S] = polyfit(dates(~isnan(values)),inputValues,1);
        gradient = c(1);
%         intercept = c(2);
        if norm(inputValues - mean(inputValues))>10^-20
            r2=1 - (S.normr/norm(inputValues - mean(inputValues)))^2;
        end
        middle = mean(inputValues);
    else
        gradient = 0;
        middle = values(~ismissing(values));
%         intercept = values(~isnan(values));
    end
end 

end

