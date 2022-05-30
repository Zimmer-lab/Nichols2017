%Start in Quant folder
%Define the range to measure (in seconds into the experiment).

T1=0;

T2=1080;

%Define the neuron of interest
%NOTE: ideally this would search for neuron of interest. Need to figure
%this out.

aaa='RIS'

%Change this to input new info
%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%will need to change save subfields for different genotypes and conditions

NeuronNum=1;
NeID=mywbFindNeuron(aaa);

ResultsStructFilename = 'FullURXresponses20150624.mat';

MasterFolder = '/Users/nichols/Documents/Imaging/MasterFolder';

CurrentDirectory = pwd;

folders= dir;
directoryNames = {folders([folders.isdir]).name};
directoryNames = directoryNames(~ismember(directoryNames,{'.','..'}));

Final = (length(dir));

for runthrough = 1:Final

    neuronNum= 1
    cd (directoryNames{runthrough})
    
    WorkingFolder = cd;
    
    newPath = fullfile(cd, 'Quant');
    
    cd(newPath);
    
    load('wbstruct.mat');
    load('wbstruct.mat', 'simple');
    load('wbstruct.mat', 'fps');
    load('wbstruct.mat', 'trialname');
    
    cd(WorkingFolder)
    cd(MasterFolder);

    load(ResultsStructFilename);

    cd(CurrentDirectory);

    T1=T1*fps;

    T2=T2*fps;

    FullURXresponses20150624.ZIM575Pre(NeuronNum)=mean(simple.deltaFOverF(T1:T2,NeID));
    
    FullURXresponses20150624.ExperimentIDZIM575Pre{NeuronNum}= trialname

    FullURXresponses20150624.NeIDZIM575Pre(NeuronNum)= NeID

    save ('/Users/nichols/Documents/Imaging/MasterFolder/FullURXresponses20150624', 'FullURXresponses20150624');

clear all;