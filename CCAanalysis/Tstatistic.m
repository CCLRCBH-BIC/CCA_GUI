function t = Tstatistic(X,Y,C,beta)
%% t statistic is applied to general linear model
if exist('beta','var')==0 || isempty(beta);beta = pinv(X)*Y;end

Y = Y(:,1);
[tdim,m] = size(X);
error = Y-X*beta;
RSS = error'*error;
df = tdim - m;
MRSS = RSS/df;

NoConst = size(C,2);
t = zeros(NoConst,1);
for i = 1:NoConst
    t(i) = C(:,i)'*beta/sqrt(MRSS*C(:,i)'*inv(X'*X)*C(:,i));
end

end