function [Cor,Beta,Const]=Univaranalysis(X,Y,mask,C)
%% X and Y should have been standarized already, each column in C is a contrast
% Y is the dataset after mask applied
% compare with v1: F statistics has replaced t statistics

[Nreg,Ncon]=size(C);
[tdim,N]=size(Y);

beta=pinv(X)*Y;
Yest=X*beta;

cor=zeros(N,1);
const=zeros(N,Ncon);
for i=1:N
    cor(i)=corr(Y(:,i),Yest(:,i));
    const(i,:)=lambdastatistic(X,Y(:,i),1,C,1);
    %Tstatistic(X,Y(:,i),C,beta(:,i));
end

if exist('mask','var')&& isempty(mask)==0
    sz=size(mask);
    Cor=zeros(prod(sz),1);
    Const=zeros([prod(sz),Ncon]);
    Beta=zeros([prod(sz),Nreg]);
    Cor(mask(:)==1)=cor;
    Const(mask(:)==1,:)=const;
    Beta(mask(:)==1,:)=beta';
    Cor=reshape(Cor,sz);
    Const=reshape(Const,[sz,Ncon]);
    Beta=reshape(Beta,[sz,Nreg]);
else
    Cor=cor;Const=const;Beta=beta';
end
end
    
    
