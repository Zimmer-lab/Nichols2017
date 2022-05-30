%This script retrieves a range of a neuron of interest
%Start in Quant folder
%Define the range to measure (in seconds into the experiment).

T1=0;

T2=1079;

%Define the neuron of interest
%NOTE: ideally this would search for neuron of interest. Need to figure
%this out.
NeID=493;

%Change this to input new info

count=4;
condition = npr1Post %i.e.npr1Post

%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%will need to change save subfields for different genotypes and conditions
ResultsStructFilename = 'FullURXresponses20150914.mat';

MasterFolder = '/Users/nichols/Documents/Imaging/URX_responses';

CurrentDirectory = pwd;

cd(MasterFolder);

load(ResultsStructFilename);

cd(CurrentDirectory);


load('wbstruct.mat', 'deltaFOverF');
load('wbstruct.mat', 'fps');
load('wbstruct.mat', 'trialname');
load('wbstruct.mat', 'tv');

T1=T1*fps;

T2=T2*fps;
tvi = ((0:5399)/5)';

NameO1 = char(strcat('ExpID_',condition));
NameO2 = char(strcat('NeID_',condition));
NameO3 = char(strcat('IndeltaFOverF_',condition));

FullURXresponses20150914.tv= (0:0.2:1079.8);

FullURXresponses20150914.(NameO1){count}= trialname;

FullURXresponses20150914.(NameO2)(count)= NeID;

FullURXresponses20150914.(NameO3)(:,count)=interp1(tv,deltaFOverF(:,NeID),tvi) %'extrap'

save ('/Users/nichols/Documents/Imaging/URX_responses/FullURXresponses20150914', 'FullURXresponses20150914');

clear all;