function [lambda_star,designdirec,stateindex]...
    = SEARCH(funhandle,X,lowerlimit,upperlimit,designindex,stateindex,designdirec,statedirec)


direc = inf(numel(lowerlimit),1);
direc(designindex) = designdirec;
direc(stateindex) = statedirec;

lambdaupper = (upperlimit-X)./direc;
lambdalower = (lowerlimit-X)./direc;
lambda = max([lambdaupper,lambdalower],[],2);
lambda(lambda<0)=0;

[lambda1,lambda1_index] = min(lambda(designindex));
[lambda2,lambda2_index] = min(lambda(stateindex));
if lambda1<lambda2
    % lambda_index is neg, no need to switch variable
    lambda = lambda1;lambda_index = -lambda1_index;
else
    % lambda_index is positive, stateindex(lambda_index) needs to be 
    % switched to design variable if lambda_opt equals to lambda
    lambda = lambda2;lambda_index = lambda2_index;
end
    
[lambda_star,fval] = fminbnd(@(lam) funhandle(X+lam*direc),0,min(lambda,5));

end

