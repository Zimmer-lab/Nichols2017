function clusterData=wbGaussFit(valuesOrTTAStructFile,options)
%  wbGaussFit(valuesOrMatString)

if nargin<2
    options=[];
end

if ~isfield(options,'fitMethod')
    options.fitMethod='em';   %or vb for variational bayes
end

if ~isfield(options,'range')
    options.range=[-10 10];
end

if isnumeric(valuesOrTTAStructFile)
    
    values{1}=valuesOrTTAStructFile;  %one neuron
    
elseif iscell(valuesOrTTAStructFile)  % cell struct of value arrays
    
    values=valuesOrTTAStructFile;
    
else
    
    if ischar(valuesOrTTAStructFile)
    
       tta=load(valuesOrTTAStructFile);
    
    else
    
       tta=load('Quant/wbTTAstruct.mat');
    
    end

    neuronLabel1='AVAL';
    neuronLabel2={'RIML','OLQDL','AIBL','OLQVR','RMER','DB01'};

    n1=find(strcmpi(tta.neuronLabels,neuronLabel1));

    for i=1:length(neuronLabel2)

        n2=find(strcmpi(tta.neuronLabels,neuronLabel2{i}));
        values{i}=InBounds(tta.delayDistributionMatrix{n2,n1}/tta.fps,-10,10);
    end

end

assignin('base','values',values);
%%
tv=options.range(1):.1:options.range(2);

nr=size(values,2);

for numClusters=1:2

        clusterData(numClusters).neuron(nr).sigma=NaN(1,2);
        clusterData(numClusters).neuron(nr).weight=NaN(1,2);
        clusterData(numClusters).neuron(nr).mu=NaN(1,2);
        clusterData(numClusters).neuron(nr).modeltraces=NaN(length(tv),2);
        
        for nr=1:length(values)
        
            data=values{nr}';
            data(isnan(data))=[];
   
           if isempty(data)
               
               clusterData(numClusters).neuron(nr).sigma=0;
               clusterData(numClusters).neuron(nr).mu=0;
               clusterData(numClusters).neuron(nr).weight=0;
               clusterData(numClusters).neuron(nr).modeltraces=zeros(size(tv'));
               
           elseif isscalar(data)
               
               clusterData(numClusters).neuron(nr).sigma=0;
               clusterData(numClusters).neuron(nr).mu=data;
               clusterData(numClusters).neuron(nr).weight=1;
               clusterData(numClusters).neuron(nr).modeltraces=zeros(size(tv'));
           else
               % if isempty(find(data))  %add noise for zero delay neurons
                    data=data+.01*randn(size(data));
               % end



                if strcmp(options.fitMethod,'vb')

                    [clusterData(numClusters).assignment,model,L]=emgm(data,numClusters,false);  %vbgm

                else  %em

                   [clusterData(numClusters).neuron(nr).assignment,model,L]=emgm(data,numClusters,false);  %em mixture modeling

                end



                if strcmp(options.fitMethod,'vb')
                       clusterData(numClusters).neuron(nr).sigma(i)=sqrt(model.kappa(i)); 
                       clusterData(numClusters).neuron(nr).weight(i)= model.M(:,:,i);
                       clusterData(numClusters).neuron(nr).mu(i)=model.m(i);
                else %em
    % i     
    % model
    % size(model.Sigma)


                       clusterData(numClusters).neuron(nr).sigma(1:length(squeeze(model.Sigma)) )=squeeze(model.Sigma);
                       clusterData(numClusters).neuron(nr).weight(1:length(model.weight))=model.weight;
                       clusterData(numClusters).neuron(nr).mu(1:length(model.mu))=model.mu;
                end

                clusterData(numClusters).neuron(nr).tv=tv;
                for i=1:length(squeeze(model.Sigma))
                   clusterData(numClusters).neuron(nr).modeltraces(:,i)=clusterData(numClusters).neuron(nr).weight(i)*normpdf(tv,clusterData(numClusters).neuron(nr).mu(i),clusterData(numClusters).neuron(nr).sigma(i));

        %            plot(tv,modeltraces(:,i),'Color',color(i,1+length(model.mu)) );
        %            hold on;

                end



        %         for i=1:length(model.mu)
        %             
        %             vline(mu(i),color(i,3),[],[0 .15],2);
        %             vline(mu(i),'r',[],[0 .15]);
        %         end
        %         
        %         for i=1:length(data)
        %            vline(data(i),color(label(i),3),[],[0 .05]);
        %         end
        % 
        %         
        %  
        %         if tt==1
        %             title(['num gaussians=' num2str(nc)]);
        %         end
        %         
        %         ylim([0 .1]);
        %         intitle(neuronLabel2{tt});

           end
        end
    end

end

% mtit(['relative to ' neuronLabel1]);







