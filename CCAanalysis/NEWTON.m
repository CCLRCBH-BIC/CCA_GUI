function [X_new,dY,dZ,designindex,stateindex]=NEWTON(funlist,X,lambda_star,designindex,stateindex,designdirec,statedirec)

Y_old = X(designindex);
Z_old = X(stateindex);
dY = lambda_star*designdirec;
dZ = lambda_star*statedirec;
X_new = zeros(size(X)); X_new(designindex) = Y_old+dY; X_new(stateindex) = Z_old+dZ;
W = funlist{1}(X_new);
% W = cellfun(@(fun) fun(X_new),funlist(1:end-1));

% if norm(W)>1e-4
while norm(W)>1e-5    
    [~,~,C,invD,~,designindex,stateindex]= REDGRA(funlist,X,designindex,stateindex);
    
    dZ = -invD*W;
    X_new(stateindex) = X(stateindex)+dZ;
    X = X_new;
%     [Z_new,iii,f] = BFGS(@(z) tempfun(z,funlist{1},X_new,stateindex),sqrt(X_new(stateindex)));
%     while f(end)>1
%         lambda_star = lambda_star/2;
%         dY = lambda_star*designdirec;
%         dZ = lambda_star*statedirec;
%         X_new = zeros(size(X)); X_new(designindex) = Y_old+dY; X_new(stateindex) = Z_old+dZ;        
%         [Z_new,iii,f] = BFGS(@(z) tempfun(z,funlist{1},X_new,stateindex),rand(size(stateindex)));
%     end
%     X_new(stateindex) = Z_new^2;
    
    W = funlist{1}(X_new);
end
X_new = real(X_new);
end

% function f = tempfun(sq_z,funhandle,X,stateindex)
% X(stateindex) = sq_z.^2;
% f = funhandle(X); f= f^2;
% end
