%% Quick inverse and collection of Percent Quiescent

num = length(PercentQuiescent.stim);

All(1:num,1) = abs((PercentQuiescent.before(1:num,1)-1));
All(1:num,2) = abs((PercentQuiescent.stim(1:num,1)-1));
All(1:num,3) = abs((PercentQuiescent.after(1:num,1)-1));

