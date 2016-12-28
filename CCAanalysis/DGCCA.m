function [cor,Alp,Beta,opt_Yind] = DGCCA(S,D,mode)
%% [cor,Alp,Beta,opt_Yind] = ccaFlexConstraint_GRG(S,mode)
% v2.1
% ccaFlexConstraint_GRG is supported by following functions:
% GRGmain()
% NEWTON()
% REDGRA()
% SEARCH()
[dimy,dimx]=size(S.Syx);
if dimy==1
    Alp=1;Beta=S.Sxx\S.Sxy;cor=S.Syx*Beta/sqrt(Beta'*S.Sxx*Beta);opt_Yind=1;return;
end

S.Sxy = (S.Syx)';
E = S.Syx*(S.Sxx\S.Sxy);
p = mode(1); phi = mode(2);
funlist = cell(2,1);

funlist{1} = @(alpha) alpha(1)*D(1)-(phi*sum((alpha(2:end-1).*D(2:end)).^p))^(1/p)-alpha(end);

funlist{2} = @(alpha) -(alpha(1:end-1).*D)'*E*(alpha(1:end-1).*D)...
    /((alpha(1:end-1).*D)'*S.Syy*(alpha(1:end-1).*D));
ub = inf*ones(dimy+1,1);lb = zeros(dimy+1,1);

designindex = (2:dimy+1)';stateindex = 1;
% alpha_init = [1/2;ones(9,1)/18];
% alpha_init = [1/(2^(1/p));ones(8,1)/(18*phi)^(1/p);1/18];
alpha_init = [1;ones(dimy-1,1)/((dimy-1)*phi)^(1/p);0];
[Alp,record_fun,converge,RedObjGra]=GRGmain(funlist,alpha_init,lb,ub,designindex,stateindex);
record_fun(:,2) = sqrt(-record_fun(:,2));
Alp = Alp(1:end-1);
Alp = Alp.*D;  % yang
Alp = Alp./sqrt(Alp'*S.Syy*Alp);
Alp(Alp<1e-4)=0;Beta = inv(S.Sxx)*S.Sxy*Alp;
cor = record_fun(end,2);
opt_Yind = (Alp>0);
end
