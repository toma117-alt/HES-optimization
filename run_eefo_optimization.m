function [best_sol, best_fit, history] = run_eefo_optimization(params, data)
% RUN_EEFO_OPTIMIZATION
%   Enhanced Electromagnetic Field Optimization (EEFO) algorithm.
%   Implements Section 3 of Zhu et al. (2024):
%     - EFO base algorithm (Eqs. 23-26)
%     - Levy flight enhancement (Eqs. 27-30)
%     - Sinusoidal chaotic map for diversity (Eq. 32)
%     - Latin Hypercube Sampling initialisation
%
%   Outperforms iHOGA/HOMER because:
%     1. Continuous search space (not discrete grid)
%     2. Joint optimization of cost + carbon + unmet demand
%     3. Levy flight avoids local optima (heavy-tailed exploration)
%     4. Chaos map prevents premature convergence

N   = params.N_pop;
D   = params.n_dim;
Nit = params.N_iter;
phi = params.phi;
a_c = params.a_chaos;
tau = params.tau_lf;

% Bounds
if isfield(params,'resilient_mode') && params.resilient_mode
    lb = [params.PV_min_r,  params.BAT_min_r,  params.DG_min_r];
    ub = [params.PV_max_r,  params.BAT_max_r,  params.DG_max_r];
else
    lb = [params.PV_min,  params.BAT_min,  params.DG_min];
    ub = [params.PV_max,  params.BAT_max,  params.DG_max];
end

% Field partitions
n_pos = max(2, round(params.pos_frac * N));
n_neg = max(2, round(params.neg_frac * N));
n_neu = N - n_pos - n_neg;
if n_neu < 2
    n_pos = floor(N/3); n_neg = floor(N/3); n_neu = N-n_pos-n_neg;
end

%% Latin Hypercube Sampling initialisation (better coverage than random)
X = zeros(N, D);
for d = 1:D
    perm   = randperm(N);
    X(:,d) = lb(d) + (ub(d)-lb(d)) * ((perm'-rand(N,1)) / N);
end

% Evaluate initial population
fit = zeros(N,1);
for i = 1:N
    fit(i) = objective_function(X(i,:), params, data);
end
[fit, idx] = sort(fit);
X = X(idx,:);

best_sol = X(1,:);
best_fit = fit(1);
history  = zeros(Nit, 1);

% Pre-compute Levy flight sigma (Eq. 29)
num_lf   = gamma(1+tau) * sin(pi*tau/2);
den_lf   = gamma((1+tau)/2) * tau * 2^((tau-1)/2);
sigma_lf = (num_lf/den_lf)^(1/tau);

% Initialise chaotic seeds
r_chaos = 0.1 + 0.8*rand(1,D);

fprintf('  Init best: YSC=$%.2f | PV=%.1f kW | BAT=%.1f kWh | DG=%.1f kW\n', ...
    best_fit, best_sol(1), best_sol(2), best_sol(3));

%% Main EEFO loop
for iter = 1:Nit

    pos_idx = 1 : n_pos;
    neg_idx = (N-n_neg+1) : N;
    neu_idx = (n_pos+1) : (N-n_neg);

    X_new = zeros(1, D);
    for j = 1:D

        %% Update chaotic variable (Eq. 32: sinusoidal map)
        r_chaos(j) = abs(sin(pi * r_chaos(j)) * a_c * r_chaos(j)^2);
        if r_chaos(j) < 1e-8 || r_chaos(j) > 1-1e-8
            r_chaos(j) = 0.1 + 0.8*rand();
        end
        r_c = r_chaos(j);

        % Random indices from each field
        ki  = neu_idx(randi(numel(neu_idx)));
        pi_ = pos_idx(randi(numel(pos_idx)));
        ni  = neg_idx(randi(numel(neg_idx)));

        % Inter-field distances (Eqs. 24-25)
        d_PK = X(pi_,j) - X(ki,j);
        d_NK = X(ni, j) - X(ki,j);

        %% Levy flight step (Eqs. 27-28)
        A_lf = randn() * sigma_lf;
        B_lf = randn();
        if abs(B_lf) < 1e-10, B_lf = sign(B_lf + eps) * 1e-10; end
        LF_w = abs(A_lf / abs(B_lf)^(1/tau));

        %% Enhanced position update (Eq. 30)
        if rand() > 0.5
            X_new(j) = X(ki,j) - (LF_w*r_c*d_NK) + (phi*LF_w*r_c*d_PK);
        else
            X_new(j) = X(ki,j) - (LF_w*r_c*d_NK) - (phi*LF_w*r_c*d_PK);
        end

        % Random injection for global exploration
        if rand() < params.rand_frac
            X_new(j) = lb(j) + rand()*(ub(j)-lb(j));
        end

        % Enforce bounds
        X_new(j) = max(lb(j), min(ub(j), X_new(j)));
    end

    % Evaluate and replace worst if better
    f_new = objective_function(X_new, params, data);
    if f_new < fit(end)
        X(end,:) = X_new;
        fit(end)  = f_new;
        [fit, idx] = sort(fit);
        X = X(idx,:);
    end

    if fit(1) < best_fit
        best_fit = fit(1);
        best_sol = X(1,:);
    end
    history(iter) = best_fit;

    if mod(iter,100) == 0
        fprintf('  Iter %3d | YSC=$%9.2f | PV=%6.1f kW | BAT=%6.1f kWh | DG=%5.1f kW\n', ...
            iter, best_fit, best_sol(1), best_sol(2), best_sol(3));
    end
end
fprintf('  Final   | YSC=$%9.2f | PV=%6.1f kW | BAT=%6.1f kWh | DG=%5.1f kW\n', ...
    best_fit, best_sol(1), best_sol(2), best_sol(3));
end
