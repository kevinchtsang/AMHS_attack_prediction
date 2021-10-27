function [weekNumSorted, bins] = Alg_bin_pack(weekNum,weight,maxCapacity)
%ALG_BIN_PACK Use bin packing algorithm to put 
%   weekNum is WP_Stable_Calandar
bins = zeros(size(weekNum));
binLoad = 0;%zeros(size(weekNum));
binNum = 1;
% binWeekNum = 0;
binCalWeek = 0;
binStable = 0;

longStr = sprintf('%s_', weekNum);
dataMat = sscanf(longStr, '%g_', [3, inf]).';
dataMat = [dataMat, weight];
dataMat = sortrows(dataMat,[1,2,3],{'ascend','descend','ascend'});



weekNumSorted = cellstr(num2str(dataMat(:,1:3)));
weekNumSorted = strtrim(weekNumSorted); %white space start and end
weekNumSorted = regexprep(weekNumSorted,' +','_'); %reformat

for i =1:length(weekNum)
    % define current and next weekNum
%     wn = textscan(weekNum(i),'%s','Delimiter','_');
    wn = dataMat(i,:);
    f = dataMat(i,4);
    % dont combine stable and unstable
    % dont allow combination if beyond 2 weeks apart
%     if (i>1)&&((str2num(wn{1}{2})~=binStable) || ...
%             (abs(str2num(wn{1}{3})-binCalWeek)>=3))
    if (i>1)&&((wn(2)~=binStable) || ...
            ((abs(wn(3)-binCalWeek)>=3) && ...
            (abs(wn(3)-binCalWeek)<=49)))
        binNum = binNum + 1;
        binLoad = 0;
    end
    
    if (f+binLoad)<=maxCapacity
        bins(i) = binNum;
        binLoad = f+binLoad;%+sum(binLoad(bins==binNum));
    else
        binNum = binNum + 1;
        bins(i) = binNum;
        binLoad = f;
    end
    
    
    binStable = wn(2);
%     binWeekNum = str2num(wn{1}{1});
    binCalWeek = wn(3);
end
end

