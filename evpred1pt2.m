function [op1, op2, op3, op4] = evpred1pt2(numevents,ev_n,ev_nplus1,pu,pw,parm,sim,showpred,showlearn) 
%
%v1.2 by Ap; 16/10/2019
%
%this function computes the wt change
%produced when predicting event n plus 1 from event n
%using a prediction unit pu row vector [1 x m]
%which is activated by the input vector for event n [1 x m]
%the prediction unit predicts the next event via all-to-all [m x m] prediction weights pw
%
%input parameters
%****************
%numevents       number of different events involved
%ev_n            the number code of the event on the current trial n
%ev_nplus1       the number code of the event on the next trial n+1
%pu              a vector coding the activity of the prediction units 
%pw              a weight matrix linking the pred units to vector coding
%                the next event
%parm            a structure array containing the simlation parameters
%                .alpha       the learning rate for weight increase/decrease
%to be added
%                .gamma       a discount parameter for learning rules involving 
%                             discounted future events
%                .alpha_minus a learning rate for weight decreases for learning rules
%                             with different + and - learning rates
%simsettings     a structure array controlling details of the simulation
%                .RLformat    a string controlling the precise form of the learning rule
%                             'classic'= classic q learning for active prediction units
%                .PREDformat  a string controlling the way predictions are made
%                .dolearn     1 or 0 to force learning or no learning
%showpred        A string controlling whether you want to show 
%                the predicted next event 'showp'=yes; 'other'=no
%showlearn       A string controlling whether you want to show various
%                features during learning 'showl'=yes; 'other'=no
%
%output parameters
%*****************
%op1 is a structure variable containing flags: flag values -1 error; 1 ok
%op2 is the prediction weight , pw; after weight update
%op3 is the prediction error
%op4 is the prediction choice made

%compute next predicted event vector, based on the activated prediction
%unit
pred_nplus1 = pu*pw;
if strcmp(showpred,'showp')
    disp(['Current event is ' num2str(ev_n)]);
    disp(['Predictions of next event: ' num2str(pred_nplus1)]);
end;
%compute prediction error
actual_nplus1=zeros(1,numevents);
actual_nplus1(ev_nplus1)=1; %vector of actual nplus1 event
op1PRED=0;
switch sim.PREDformat
    case 'nochoice'
        %do nothing
        %leave multiple predicted events simultaneously
        %predicted to varying strengths
        %the prediction choice response is a dummy variable here
        %used to make sure te learning rule works
        ch=ones(1,numevents); %as if you are choosing all the events
    case 'sm_choice'
        %to be added
        %we need to add a choice betwen the predicted events
        %using the softmax function to choose 1 predicted event
        %first compute probabilities
        prob_nplus1=exp(parm.beta.*pred_nplus1)./sum(exp(parm.beta.*pred_nplus1));
        %turn into cumulative probabilities
        cumprob_nplus1=cumsum(prob_nplus1);
        %now choose randomly according to above cum probabilities
        aa=rand; %pick a rand number between 0 and 1
        %select prediction choice
        ch=zeros(1,numevents);
        ch(numevents+1-sum(cumprob_nplus1>aa))=1; %make prediction choice according to probs
    otherwise
       %no rule specified so return an error message
       op1PRED=-1; 
end;
pred_err = actual_nplus1  - pred_nplus1;

%update weights, according to different rule types
%and using rate parameter alpha

del_pw=0.*pw; %this so that del_pw has the right dimensions
op1RL=0;
switch sim.RLformat
    case 'classic'
       %this is the classic reward prediction RL rule used in Q learning
       %without discount=0 so only the current prediction is used
       %and a single learning rate for positive and negative prediction
       %errors. Note there is a separate prediction error for each predicted event
       %and that each of these separate prediction errors is used to modify
       %ONLY the weights to the corresponding specific predicted event
       %note learning is only for active pred units
       %and only for active predicted events, irrespective of level of
       %activity, filtered by chosen response
       del_pw(pu>0,ch==1) = parm.alpha.*pred_err(1,ch==1).*(pred_nplus1(ch==1)>0); 
       %could make learning occur in proportion to activity of predicted event
       %del_pw(pu>0,ch==1) = parm.alpha.*pred_err(1,ch==1).*pred_nplus1(ch==1); 
    otherwise
       %no rule specified so return an error message
       op1RL=-1; 
end;

if strcmp(showlearn,'showl')
    disp(['Current event: ' num2str(ev_n)]);
    disp(['Activity of prediction units: ' num2str(pu)]);
    disp(['Actual next event: ' num2str(actual_nplus1)]);
    disp(['Prediction of next event: ' num2str(pred_nplus1)]);
    disp(['Prediction error: ' num2str(pred_err)]);
    disp(['Prediction choice: ' num2str(ch)]);
    disp(del_pw);
    disp('Hit Ctrl-C to quit, other key to continue');
    pause;
end;

%do learning only when required
if sim.dolearn==1
    pw = pw + del_pw; 
else
end;

op1=struct('RL',op1RL,'PRED',op1PRED);
op2=pw;
op3=pred_err;
switch sim.PREDformat
    case 'nochoice'
        op4=-1.*ch; %no choice was made
    otherwise
        op4=ch;
end;