function classifier = trainAdaBoost(X,Y,T)
%% INPUT:
% X : n x 2 matrix where n is the number of training samples
% Y : n x 1 vector containing the labels of X, in {-1, 1}
% T : number of iterations for the training
%% OUTPUT: 
% classifier.alpha : weights of each weak classifier 
% classifier.tau   : threshold of each weak classifier
% classifier.p     : sign of each weak classifier
% classifier.idx   : index of feature that the weak classifier applies
%%

m=size(Y,1);
figure;
axis equal
xlim([-100 100])
ylim([-100 100])    
title('Adaboost', ...
          'fontsize',14)
xlabel('dim 1','fontsize',12)
ylabel('dim 2','fontsize',12)
hold on

errorsX=ones(1,m);
errors=ones(1,m);

for i=1:m
    color='g';
    if Y(i,1)==-1
        color='r';
    end
    plot(X(i,1),X(i,2),['.' color],'markersize',10)
    xlim([-100 100])
    ylim([-100 100])    
end

D=ones(1,m)/m;
classifier=[];
for t=1:T
    disp(t);
    newClassifier=findWeakHypothesis(X,Y,D);
    [err,newClassifier,absoluteErr]=testLine(newClassifier,X,Y,D);
    newClassifier.alpha=log((1-err)/err)/2;
    if newClassifier.axis==1
        line([-100,100],[newClassifier.tau,newClassifier.tau],'LineWidth',newClassifier.alpha*10)
    else
        line([newClassifier.tau,newClassifier.tau],[-100,100],'LineWidth',newClassifier.alpha*10)
    end
    for i=1:m
        D(i)=D(i)*exp( -newClassifier.alpha * Y(i,1) * newClassifier.h(i) );
    end
    D=D/sum(D); %normalize to sum of 1
    classifier=[classifier, newClassifier];
    
    Y_pred=runAdaBoost(X,classifier);
    incorrect=0;
    for i=1:m
        if Y_pred(i)~=Y(i)
            incorrect=incorrect+1;
        end
    end
    disp(incorrect);
    errors(t)=incorrect/m;
    errorsX(t)=t;
end

%errors plot
figure;

xlim([0 25])
ylim([0 1])    
title('Adaboost', ...
          'fontsize',14)
xlabel('dim 1','fontsize',12)
ylabel('dim 2','fontsize',12)
hold on
for i=1:m
    plot(errorsX(i),errors(i),['.' 'b'],'markersize',10)
end



    
%incredibly simple horizontal or vertical separator choice function that
%naively tests all lines and returns the one with the best performance
function classifier = findWeakHypothesis(X,Y,D)
best=intmax; classifier=struct;
dims=size(X,2);
for tau=-100:100
    for axis=1:dims
        c=struct; c.axis=axis; c.p=1; c.tau=tau;
        [tot,c,e]=testLine(c,X,Y,D);
        %disp(tot)
        if tot<best
            best=tot; classifier=c;
        end
        c=struct; c.axis=axis; c.p=-1; c.tau=tau;
        [tot,c,e]=testLine(c,X,Y,D);
        %disp(tot)
        if tot<best
            best=tot; classifier=c;
        end
    end
end

%axis=0 -> x, axis=1 -> y
%direction=1 -> -1 below, direction=-1 -> 1 below
function [tot,c,absoluteErr] = testLine(c,X,Y,D)
h=ones(1,size(Y,1));
absoluteErr=0;
tot=0;
for i=1:size(Y,1)
    if (X(i,c.axis)<c.tau && c.p==1) || (X(i,c.axis)>c.tau && c.p==-1)
        h(1,i)=-1;
    end
    if h(1,i)~=Y(i,1)
        tot=tot+D(1,i);
    end
end
c.h=h;


