function gk = Grad(fun,xk)
%% Gradient function
% fun is either a funtion handle or a list of functions handles (cell
% array) like f={@sin,@cos,@(x) x.^2}
% xk is a column vector
N = size(xk,1);step = eps^(1/3);%0.001;%
if isa(fun,'function_handle')
    %% case 1: fun is a funtion handle
    gk = zeros(N,1);
    for i = 1:N
        temp = zeros(N,1);
        temp(i)= step;
        fkup = fun(xk+temp);
        fkdn = fun(xk-temp);
        gk(i) = (fkup - fkdn)/(2*step);
    end
else
    %% case 2: fun is a list of funtion handles
    gk = zeros(numel(fun),N);
    for i = 1:N
        temp = zeros(N,1);
        temp(i)= step;        
        for f_ind = 1:numel(fun)
            fkup = fun{f_ind}(xk+temp);
            fkdn = fun{f_ind}(xk-temp);
            gk(f_ind,i) = (fkup - fkdn)/(2*step);  
        end
    end
end
end