function [transitions transitionsType transitionsPreRunLength transitionsRunLength]=wbGetTransitions(transitionListCellArray,refNeuronIndex,transitionTypes,neuronSign,transitionPreRunLengthListArray,transitionRunLengthListArray)
%wbGetTransitions(transitionListCellArray,refNeuronIndex,transitionTypes,neuronSign,transitionPreRunLengthListArray)
%
%transitionTypes can be a string or a numerical array
%supported string: 'AllRises'
%
%state list:
%1=valley  (down state)
%2=rise
%3=plateau (up state)
%4=fall
%
%transitionListArray transition types: 
%col 1:    1->2  lo2rise
%col 2:    2->3  rise2hi
%col 3:    2->4  rise2fall
%col 4:    3->4  hi2fall
%col 5:    4->1  fall2lo
%col 6:    4->2  fall2rise
%col 7:    2->1  rise2lo   %outlier transition
%col 8:    3->2  hi2rise %outlier transition
%col 9:    4->3  fall2hi %outlier transition
%col 10:   1->4  lo2fall %outlier transition         
%col 11:   1->3  lo2hi  %pathlogical transition
%col 12:   3->1  hi2lo  %pathological transition

if nargin<4 || isempty(neuronSign)
    neuronSign=0;
end

%col 13:    all transitions
if nargin<3 || isempty(transitionTypes)
    transitionTypes='AllRises';
end

%convert descriptive transitionTypes string into numbers
if ischar(transitionTypes)
    if strcmpi(transitionTypes,'AllRises') || strcmpi(transitionTypes,'rises')
       transitionTypes=[1 6 8];
    elseif strcmpi(transitionTypes,'AllFalls') || strcmpi(transitionTypes,'falls')
        transitionTypes=[3 4 10];
    elseif strcmpi(transitionTypes,'AllGood')
        transitionTypes=[1 3 4 6 8 10];
    elseif strcmpi(transitionTypes,'SignedAllRises')
        if neuronSign<0
            transitionTypes=[3 4 10];
        else
            transitionTypes=[1 6 8];
        end
    elseif strcmpi(transitionTypes,'SignedAllFalls')
        if neuronSign<0
            transitionTypes=[1 6 8];
        else
            transitionTypes=[3 4 10];
        end
    else
       disp('wbGetTransitions> did not recognize transitionTypes. using AllRises.');
       transitionTypes=[1 6 8];
    end
end

transitions=[];
transitionsType=[];
transitionsPreRunLength=[];
transitionsRunLength=[];


for i=1:length(transitionTypes)
    
    [transitions, thisSortIndex]=sort([transitions transitionListCellArray{refNeuronIndex,transitionTypes(i)}]);
    
    transitionsType= [transitionsType i*ones(size(transitionListCellArray{refNeuronIndex,transitionTypes(i)}))];
    transitionsType=transitionsType(thisSortIndex);    
    
    if exist('transitionPreRunLengthListArray','var')
        transitionsPreRunLength=[transitionsPreRunLength transitionPreRunLengthListArray{refNeuronIndex,transitionTypes(i)}];
        transitionsPreRunLength=transitionsPreRunLength(thisSortIndex);
    end
    
    if exist('transitionRunLengthListArray','var')
        transitionsRunLength=[transitionsRunLength transitionRunLengthListArray{refNeuronIndex,transitionTypes(i)}];
        transitionsRunLength=transitionsRunLength(thisSortIndex);
    end
    
end