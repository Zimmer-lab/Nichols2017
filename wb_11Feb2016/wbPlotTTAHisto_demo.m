%wbPlotTTAHisto_demo.m

clear options;
neuron1='RIBL';
neuron2='AVAL';
options.neuron1Sign=-1;
options.neuron2Sign=1;
options.savePDFFlag=true;
options.transitionTypes='SignedAllRises'; %or SignedAllFalls  %this tracks rise from inphase neurons and falls from anti-phase neurons
options.plotTraces=false;
options.plotRefTrace=false;
options.hideOutliers=false;
options.timeWindowSize=40;

TTAStruct=wbPlotTTAHisto([],neuron1,neuron2,options);


%%


clear options;
    
rootfolder=pwd;
folders=listfolders;

neuron2List={'AIBL','AIBR','RIML','RIMR','RIVL','RIVR'};
neuron2SignList=[1 1 1 1 -1 -1];
TransitionTypeList={'SignedAllRises','SignedAllRises','SignedAllRises','SignedAllRises','SignedAllFalls','SignedAllFalls'};


% neuron2List={'RIVL','RIVR'};
% neuron2SignList=[-1 -1];

    
for j=1:length(folders)
    
    cd([rootfolder filesep folders{j}]);
    folders{j}
    
    for i=5:6 %1:length(neuron1List)
    
        neuron2List{i}

        neuron1='AVAL';
        neuron2=neuron2List{i};
        options.neuron2Sign=neuron2SignList(i);
        options.neuron1Sign=1;
        options.savePDFFlag=true;
        options.transitionTypes=TransitionTypeList{i}; %or SignedAllFalls  %this tracks rise from inphase neurons and falls from anti-phase neurons
        options.plotTraces=false;
        options.plotRefTrace=false;
        options.hideOutliers=false;
        options.timeWindowSize=20;
        options.savePDFDirectory='/Users/skato/Desktop/Dropbox/SaulHarrisTinaManuel/ForMinibrains';

        TTAStruct=wbPlotTTAHisto([],neuron1,neuron2,options);

    end
end

cd('..');


%% %L/R neuron combined, compilation across datafolders


clear options;
    
neuron2List={{'AIBL','AIBR'},{'RIML','RIMR'},{'RIVL','RIVR'},{'RIBL','RIBR'}}; 
neuron2SignList=[1 1 -1 -1];
TransitionTypeList={'SignedAllRises','SignedAllRises','SignedAllFalls','SignedAllRises'};

rootfolder=pwd;
folders=listfolders;

for i=1:3 % 1:length(neuron2list)
               
        neuron2=neuron2List{i};
        neuron1='AVAL';
        options.neuron2Sign=neuron2SignList(i);
        options.neuron1Sign=1;
        options.savePDFFlag=true;
        options.transitionTypes=TransitionTypeList{i}; %or SignedAllFalls  %this tracks rise from inphase neurons and falls from anti-phase neurons
        options.plotTraces=false;
        options.plotRefTrace=false;
        options.hideOutliers=true;
        options.timeWindowSize=20;
        options.savePDFDirectory='/Users/skato/Desktop/Dropbox/SaulHarrisTinaManuel/ForMinibrains';

        TTAStruct=wbPlotTTAHisto([],neuron1,neuron2,options);

end