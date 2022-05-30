function EasyOverlayPlot(traces,tv,labels,legends)

if nargin<4
    legends={};
end

if nargin<2
    tv=cellfun(@(x) size(x,1),traces);
end

if nargin<3
    labels={};
end

nr=1;
nd=length(traces);
colr={'r','g','b'};
figure('Position',[0 0 800 1200]);

    
for n=1:nd    
    
    for tr=1:size(traces{n},2)
  
        subtightplot(nd,nr, nr*(n),[0.01 0.05],[0.05 0.05],[0.05 0.05])
        plot(tv{n},traces{n}(:,tr),colr{tr});
        hold on;
        SmartTimeAxis([tv{n}(1) tv{n}(end)]);

        
        if tr==size(traces{n},2)
            intitle(strrep(labels{n},'_','\_'));
            if ~isempty(legends)
                legend(arrayfun(@num2str,legends{n},'UniformOutput',false) );
            end
        end
        
        
    end
    
    
    
end