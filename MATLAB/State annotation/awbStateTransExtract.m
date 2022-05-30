%%Extracts neuron IDs and their state annotations

Neurons1 = {'AVAL','AQR','AUAL','AUAR','URXL','URXR','RMGL','RMGR','AVAR','RIML','RIMR','AVEL','AVER','AIBL','AIBR','RIS','URYDL','URYDR','URYVL','URYVR', 'VA01', 'AVBL', 'AVBR','RIBL', 'RIBR','SIBDL','SIBDR','SIBVL','SIBVR', 'RIVL','RIVR','SMDDL','SMDDR','SMDVL','SMDVR','RMED','RMEV','RMEL','RMER','VB02',}'; 
%Neurons1 = {'AQR','URXL','URXR','AVAL','AVAR','RIML','RIS',}'; 

options.version.awbStateTransNeu = 'v3_20160125';
%% 

if ~exist('Neurons','var');
    Neurons =Neurons1;
end
clearvars Neurons1

StateTrans.Neurons = Neurons;

wbload;
for ii= 1:length(StateTrans.Neurons);

     i=1; %this part finds the simpleID number of the neuron.
     SimpleN = 0;
     for i= 1:length(wbstruct.simple.ID);
         if ~isempty(wbstruct.simple.ID{1,i})
            if strcmp(wbstruct.simple.ID{1,i},StateTrans.Neurons{ii}) == 1;
                SimpleN = i;
            end
         end
     end

    %gets state values
    if ~exist('sc')
        sc=wbFourStateTraceAnalysis(wbstruct,'useSaved');
    end

    %gets state values for specified neurons
    if SimpleN == 0;
        %disp(strcat( StateTrans.Neurons{ii},' is not in this dataset'))
        StateTrans.StateValue(ii,:) = NaN(length(wbstruct.simple.deltaFOverF),1);
    else
    StateTrans.StateValue(ii,:) = sc(:,SimpleN);

    end
end

clearvars sc
% figure;imagesc(StateTrans.StateValue(:,(round(355*wbstruct.fps)):(round(380*wbstruct.fps))));
% set(gca,'YTick',1:length(StateTrans.Neurons),'YTickLabel',StateTrans.Neurons)
% clearvars SimpleN i ii sc wbstruct
