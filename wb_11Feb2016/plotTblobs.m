function plotTblobs(tblobs,z)
%
%%plot bonding in time

figure;
%imagesc(TMontage);
hold on;
colormap('hot');

for t=1:size(tblobs,2)

    plot(tblobs(z,t).Tx,tblobs(z,t).Ty,'.','MarkerSize',6,'Marker','o','Color','c');
    
    for j=1:length(tblobs(z,t).Tx)
        %text(1+tblobs(z,t).Tx(j),1+tblobs(z,t).Ty(j),num2str(j));
    end

    if t>1

        for j=1:length(tblobs(z,t).x)
                if ~isnan(tblobs(z,t).tparents(j))
                    line([tblobs(z,t).Tx(j) tblobs(z,t-1).Tx(tblobs(z,t).tparents(j))],[tblobs(z,t).Ty(j) tblobs(z,t-1).Ty(tblobs(z,t).tparents(j))],'Color','k');
                end
        end
    end
    
end
    
for t=1:size(tblobs,2)
    %label childless blobs
    for k=1:tblobs(z,t).n
       if tblobs(z,t).childlessTag(k)
            ex(tblobs(z,t).Tx(k),tblobs(z,t).Ty(k),[],'g');
       end
           
       if tblobs(z,t).parentlessTag(k)==1
            ex(tblobs(z,t).Tx(k),tblobs(z,t).Ty(k),[],'k');
       end

       if tblobs(z,t).parentlessTag(k)==2
            ex(tblobs(z,t).Tx(k),tblobs(z,t).Ty(k),[],'b');
       end
       
       
%        if tblobs(z,t).markedForDeath(k)==1
%             ex(tblobs(z,t).Tx(k),tblobs(z,t).Ty(k),[],'r');
%        end
       
      
    end
    
end