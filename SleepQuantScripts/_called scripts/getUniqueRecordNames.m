%Find the different unique recording names
[r,~] = size(CollectedTrksInfo.alsName);

datePosition = strfind(CollectedTrksInfo.alsName,'201');
RecordNames2 = {};

for iii = 1:r;
    CurrDatePosition = datePosition{iii,1}(1,1);
    RecordNames2{iii,1} = CollectedTrksInfo.alsName{iii}(1:(CurrDatePosition+10));
end

SingleRecordNames = unique(RecordNames2);
