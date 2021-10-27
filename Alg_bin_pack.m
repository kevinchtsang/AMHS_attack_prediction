function [weekNumSorted, bins] = Alg_bin_pack(weekNum,weight,maxCapacity)
%ALG_BIN_PACK Use bin packing algorithm to package nearby periods
%   weekNum is calendar week number 
%   weight is a vector of weights for bin packing. In this application, it
%   is frequency (the number of points in the period)
%   maxCapacity is the maximum capacity of each bin

bins    = zeros(size(weekNum));
binLoad = 0;
binNum  = 1;

binCalWeek = 0;
binStable  = 0;

longStr = sprintf('%s_', weekNum);
dataMat = sscanf(longStr, '%g_', [3, inf]).';
dataMat = [dataMat, weight];
dataMat = sortrows(dataMat,[1,2,3],{'ascend','descend','ascend'});



weekNumSorted = cellstr(num2str(dataMat(:,1:3)));
weekNumSorted = strtrim(weekNumSorted); %white space start and end
weekNumSorted = regexprep(weekNumSorted,' +','_'); %reformat

for i =1:length(weekNum)
    % define current and next weekNum
    wn = dataMat(i,:);
    f  = dataMat(i,4);
    
    % dont combine stable and unstable
    % dont allow combination if beyond 2 weeks apart
    if (i>1)&&((wn(2)~=binStable) || ...
            ((abs(wn(3)-binCalWeek)>=3) && ...
            (abs(wn(3)-binCalWeek)<=49)))
        binNum = binNum + 1;
        binLoad = 0;
    end
    
    if (f + binLoad) <= maxCapacity
        bins(i)      = binNum;
        binLoad      = f + binLoad;
    else
        binNum  = binNum + 1;
        bins(i) = binNum;
        binLoad = f;
    end
    
    
    binStable = wn(2);
    binCalWeek = wn(3);
end
end

