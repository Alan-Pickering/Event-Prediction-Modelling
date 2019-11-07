function  [mean_acc, mean_ws, mean_ls, mean_lsuc] = ballscorer(numsubjects, nballs, ntrials, mypred, mycolour, printsubs, lstype )
%a function to score the balls task from a single array holding choice
%responses

%defines filter for the balls in each bag
ballinbag=zeros(ntrials,nballs);
for b=1:nballs
    if b<nballs
        ballinbag(:,b)=(mod(1:ntrials,nballs)==b)';
    else
        ballinbag(:,b)=(mod(1:ntrials,nballs)==0)';
    end;
end;
%now define a segment of task filter (each with 270/9 trials)
nsegs=9; %segments of task
seglength=ntrials/nsegs;
segnums=zeros(ntrials,1);
segctr=1;
i=0;
while segctr<nsegs+1
    i=i+1;
    segnums((segctr-1)*seglength+i,1)=segctr;
    if i==seglength
        segctr=segctr+1;
        i=0;
    end;
end;

%create arrays for storing trials data for each subject
mypredacc=zeros(ntrials,numsubjects);
wsls_score=zeros(ntrials,numsubjects); %win stay lose shift score (was response consistent with wsls strategy)
ls_score=zeros(ntrials,numsubjects); %lose shift score (was response consistent with ls strategy)
lsuc_score=zeros(ntrials,numsubjects); %lose shift use current score (was response consistent with ls strategy and using the current colour for prediction)
ws_score=zeros(ntrials,numsubjects); %win stay score (was response consistent with ws strategy)
%create arrays for storing subject data average over balls and segments
mean_acc=zeros(numsubjects,nsegs,nballs);
mean_ws=zeros(numsubjects,nsegs,nballs);
mean_ls=zeros(numsubjects,nsegs,nballs);
mean_lsuc=zeros(numsubjects,nsegs,nballs);

for s=1:numsubjects
    
    %is prediction correct?
    for i=1:ntrials-1 %can't test accuracy of final prediction
        if mypred(i,s)==mycolour(i+1,s)
            mypredacc(i,s)=1;
        end;
    end;
    %does prediction follow a wsls strategy?
    for i=2:ntrials    
        %if prediction on this trial is same as prediction on last trial
        %and the prediction made on the last trial was correct = WIN STAY
        if (mypred(i,s)==mypred(i-1,s)) && mypredacc(i-1,s)==1
            wsls_score(i,s)=1;
            ws_score(i,s)=1;
        end;
        %if prediction on this trial is diff from prediction on last trial
        %and the prediction made on the last trial was incorrect = LOSE SHIFT
        %also lose shift use current means that they shift their
        %prediction after making a wrong prediction but do so by using the current ball colour as
        %prediction for next ball: abbreviated as lsuc (lose shift use current)
        if (mypred(i,s)~=mypred(i-1,s)) && mypredacc(i-1,s)==0
            wsls_score(i,s)=1;
            ls_score(i,s)=1;
            if mypred(i,s)==mycolour(i,s)
                lsuc_score(i,s)=1;
            end;
       end;
    end;
    
    if printsubs==1
        disp(['Subject code# ' num2str(s)]);
        disp(['Overall accuracy= ' num2str(mean(mypredacc(:,s))) ]);
        for b=1:nballs
            disp(['Ball ' num2str(b) ' accuracy= ' num2str(mean(mypredacc(ballinbag(:,b)==1,s))) ]);
        end;
    end;
    
    for k=1:nsegs
        for b=1:nballs
            %disp(['Ball ' num2str(b) ' accuracy in seg# ' num2str(k) ' = ' num2str(mean(mypredacc(ballinbag(:,b)==1 & segnums==k,s))) ]);
            mean_acc(s,k,b)=mean(mypredacc(ballinbag(:,b)==1 & segnums==k,s));
        end;
    end;

    if printsubs==1
        disp(['Overall WS score= ' num2str(mean(ws_score(:,s))) ]);
        disp(['Overall LS score= ' num2str(mean(ls_score(:,s))) ]);
        disp(['Overall LS-UC score= ' num2str(mean(lsuc_score(:,s))) ]);
        for b=1:nballs
            disp(['Ball ' num2str(b) ' ws score = ' num2str(mean(ws_score(ballinbag(:,b)==1,s))) ]);
            disp(['Ball ' num2str(b) ' ls score = ' num2str(mean(ls_score(ballinbag(:,b)==1,s))) ]);
            disp(['Ball ' num2str(b) ' ls-uc score = ' num2str(mean(lsuc_score(ballinbag(:,b)==1,s))) ]);
        end;
        disp(' ');
    end;
        
    for k=1:nsegs
        for b=1:nballs
            %disp(['Ball ' num2str(b) ' wsls score in seg# ' num2str(k) ' = ' num2str(mean(wsls_score(ballinbag(:,b)==1 & segnums==k,s))) ]);
            mean_ws(s,k,b)=mean(ws_score(ballinbag(:,b)==1 & segnums==k,s));
            mean_ls(s,k,b)=mean(ls_score(ballinbag(:,b)==1 & segnums==k,s));
            mean_lsuc(s,k,b)=mean(lsuc_score(ballinbag(:,b)==1 & segnums==k,s));
        end;
    end;
    
end;

%now do some plotting
plotaccdata=zeros(nballs,nsegs);
plotwsdata=zeros(nballs,nsegs);
plotlsdata=zeros(nballs,nsegs);
plotlsucdata=zeros(nballs,nsegs);
for b=1:nballs
    plotaccdata(b,:)=mean(mean_acc(:,:,b));
    plotwsdata(b,:)=mean(mean_ws(:,:,b));
    plotlsdata(b,:)=mean(mean_ls(:,:,b));
    plotlsucdata(b,:)=mean(mean_lsuc(:,:,b));
end;

figure;
for b=1:nballs
    subplot(nballs,1,b);
    if lstype==1
        plot(1:9, plotaccdata(b,:),'x-k',1:9, plotwsdata(b,:),'g-o',1:9, plotlsdata(b,:),'r-*');
    elseif lstype==2
        plot(1:9, plotaccdata(b,:),'x-k',1:9, plotwsdata(b,:),'g-o',1:9, plotlsucdata(b,:),'r-*');
    end;
    xlabel('Blocks of trials');
    ylab={'Ave. Score', ['Ball #' num2str(b)]};
    ylabel(ylab);
    if lstype==1
        mytitle={'All subjects', 'Accuracy scores (black); WS Scores (green)', 'LS scores (red)'};
    elseif lstype==2
        mytitle={'All subjects', 'Accuracy scores (black); WS Scores (green)', 'LS-UC scores (red)'};
    end;
    if b==1
        title(mytitle);
    end;
    %legend('Accuracy','WSLS Score','Location','best');
end;


end

