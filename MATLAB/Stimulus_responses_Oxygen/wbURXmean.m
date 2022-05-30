%Start in Quant folder
%Define the range to measure (in seconds into the experiment).

T1=366;

T2=375;

%Define the neuron of interest
%NOTE: ideally this would search for neuron of interest. Need to figure
%this out.

NeID=272;

%Change this to input new info

count=9;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%will need to change save subfields for different genotypes and conditions
ResultsStructFilename = 'URXres366to375_20150625.mat';

MasterFolder = '/Users/nichols/Documents/Imaging/MasterFolder';

CurrentDirectory = pwd;

cd(MasterFolder);

load(ResultsStructFilename);

cd(CurrentDirectory);


load('wbstruct.mat', 'deltaFOverF');
load('wbstruct.mat', 'fps');
load('wbstruct.mat', 'trialname');

T1=T1*fps;

T2=T2*fps;

URXres366to375_20150625.ZIM504LetMean(count)=mean(deltaFOverF(T1:T2,NeID));

URXres366to375_20150625.ExIDZIM504Let{count}= trialname

URXres366to375_20150625.NeIDZIM504Let(count)= NeID

save ('/Users/nichols/Documents/Imaging/MasterFolder/URXres366to375_20150625', 'URXres366to375_20150625');

clear all;