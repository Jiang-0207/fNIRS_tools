clear all;
close all;

%load file
[getFile,getPath]=uigetfile('*.csv','select your data');
extractData=importdata([getPath,'/',getFile]);

%get info from user
z_method=input('z-scoring?, 0=off,1=by trial,2=by channel,3=both?  ');
plotting=input('Visualise the distribution?   ','s');
classification=input('SVM or correlation classifier? 1=SVM, 2=Correlational ');
channels=input('Select channels (NB. if no data in channel these will be dropped out) :');
cutOffCommonChannel=input('Proportion common weights across participants? e.g. 0.8 ');
perms=input('No. of permutations ');
topFilter=input('Percent top weights? e.g. 30 = 30% ');
analysisTag=input('Analysis name? ','s');

%get all patterns, labels and subject information
patterns=extractData.data(:,1:end-1);
labels=extractData.data(:,end);
subjects=extractData.rowheaders;

%intialise random seed
rng('shuffle');

%z score data - make sure check diff zscore types work
[zscorez]=classificationZScore(patterns,z_method);

clear patterns

plotWeights=1;

%empirical classification
[results]=runClassifier(zscorez,classification,subjects,labels,channels,cutOffCommonChannel,plotWeights,topFilter);
empiricalResults=results;
%house keeping - save so we know what we ran
empiricalResults.zMethod=z_method;
empiricalResults.classificationMethod=classification;
empiricalResults.channels=channels;
empiricalResults.cutOffCommonChannel=cutOffCommonChannel;
empiricalResults.perms=perms;
empiricalResults.topFilter=topFilter;
empiricalResults.file=[getPath,'_',getFile];


clear results;

for p=1:perms
%permuted classification to establish null
%permute pattern
[permuted_pattern]=runPermute(zscorez,subjects,labels);
permutations(p).pattern=permuted_pattern;

%switch off plotting of weights for permutations
plotWeights=0;

%send to classifier
[results]=runClassifier(permuted_pattern,classification,subjects,labels,channels,cutOffCommonChannel,plotWeights,topFilter);

permutations(p).results=results;
dist(p)=results.propCorrect;
clear permuted_pattern results
end

display(['Empirical Proportion correct: ',num2str(empiricalResults.propCorrect)])
display(['Empirical Binomical test, p: ',num2str(empiricalResults.binomialProbability)])

%takes the empirical result and adds it to the 'null distribution' and
%sorts the values
combine=[empiricalResults.propCorrect,dist];
sortedValues=sort(combine,'descend');

%take least optimistic in case of ties
empiricalResults.rank_empiricalValue=max(find(sortedValues>=empiricalResults.propCorrect));
empiricalResults.prob_empiricalValue=empiricalResults.rank_empiricalValue./(length(combine));

display(['Ranked value: ',num2str(empiricalResults.rank_empiricalValue)]);
display(['Permuted labels, p: ',num2str(empiricalResults.prob_empiricalValue)]);

ch=input('Do you want to see channel info? y/n ','s');

if strcmp(ch,'y')

for i=1:size(empiricalResults.noChannels,2)
   display(['no. chs: ',num2str(cell2mat(empiricalResults.noChannels(i))),' ; which : ',num2str(cell2mat(empiricalResults.whichChannel(i)))])
end
else
display('declined :)')
end

if strcmp(plotting,'y')  
figure
hist(dist,length(dist));
hold on
[oc v]=hist(dist,length(dist));
line(repmat(empiricalResults.propCorrect,1,max(oc)+1),0:max(oc),'color','r','LineWidth',4);
xlabel('Prop correct')
ylabel('observations')
else
end
empiricalResults.permutationsData=permutations;

timez=clock;
saveFileName=[analysisTag,'_',date,'_',num2str(timez(3)),'_',num2str(timez(2)),'_',num2str(timez(1)),'_',num2str(timez(4)),'_',num2str(timez(5)),'_',getFile,'.mat']

save([saveFileName],'empiricalResults')
