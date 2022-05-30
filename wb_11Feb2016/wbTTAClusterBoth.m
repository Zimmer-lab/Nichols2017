function wbTTAClusterBoth


tic
options.transitionTypes='SignedAllRises';
TTAClusterRiseStruct=wbTTACluster([],options);
toc

tic
options.transitionTypes='SignedAllFalls';
TTAClusterFallStruct=wbTTACluster([],options);
toc

end