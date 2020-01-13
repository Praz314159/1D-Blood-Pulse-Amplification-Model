%creating directed graph representation of aretery segment with 4
%branchings 
S_7 = digraph;
P_i = 30; %amplitude 
c = 5; %mm/ms (average speed of pulse wave), we assume no velocity loss

% Each node has exactly one parent. Each node stores a reflection
% coefficient. Each edge stores a transmission  as well as a zone length. 
% We feed a pulse into the system and try to get a response back. S_4 will
% have sum 2^i for i = {0,1,2,3} = 15 nodes. 

d_ = [1 2 3 4 5 6 7];

S_7 = addedge(S_7, d_(1,1), d_(1,2)); 
S_7 = addedge(S_7, d_(1,1), d_(1,3));
S_7 = addedge(S_7, d_(1,2), d_(1,4));
S_7 = addedge(S_7, d_(1,2), d_(1,5));
S_7 = addedge(S_7, d_(1,3), d_(1,6));
S_7 = addedge(S_7, d_(1,3), d_(1,7));

gamma_ = zeros(1, S_7.numnodes); 
% we have random reflection coefficients for the first three branchings 
gamma_(1, 1:3) = .2*rand(1,3)+.1; 

% now we need 6 transmission coefficients. The first two transmission
% coefficients must sum to 1 when added to the first reflection coefficient
% The third and fourth transmission coefficients must sum to one when added
% to the second reflection coefficient. The fifth and sixth transmission
% coefficients must sum to 1 when added to the third reflection
% coefficient. First we define three transmission coefficients. 

lambda_W = 1 - gamma_(1,1:3);  

sigma_ = .2*rand(1,3)+.4; 
lambda_ = zeros(1,S_7.numedges); 

% split at d_1 
lambda_(1,1) = sigma_(1)*lambda_W(1,1); 
lambda_(1,2) = (1-sigma_(1))*lambda_W(1,1); 

% split at d_2 
lambda_(1,3) = sigma_(2)*lambda_W(1,2); 
lambda_(1,4) = (1-sigma_(2))*lambda_W(1,2); 

%split at d_3
lambda_(1,5) = sigma_(3)*lambda_W(1,3);
lambda_(1,6) = (1-sigma_(3))*lambda_W(1,3); 

S_7.Edges.Lambda = transpose(lambda_);
W_T_ = linspace(1,6,6); 
S_7.Edges.W_T = transpose(W_T_); 

%length of each zone <--> stored at edge  

%now that edges are taken care of (we have index of transmitted waves
%through each zone as well as transmission coefficients), we want to take
%care of the last 4 reflection coefficients. 

gamma_(1, 4:end) = .2*rand(1,4)+.1;
S_7.Nodes.Gamma = transpose(gamma_); 
S_7.Nodes.Branch = transpose(linspace(1,7,7)); 

%Note that we also want the length of each zone.  

L_ = 150*rand(1,S_7.numedges)+50; %random lengths (in mm) between branchings
S_7.Edges.L = transpose(L_); 
Z_0 = 130*rand+50; 
%We have speed of wave (mm/ms) as well as length (mm) of each zone. Using
%this, we can comput the time taken for a wave to travel through each zone 


%*** We have some problems here. A new pulse comes every 800 ms. For the
%new pulse to meet the reflected waves generated by its predecessor, those
%reflected waves have to have a measurement time > 800 ms. For reflected
%waves to have such a measuring time, the length of each zone must be
%unrealistically large. MUST RESOLVE. 

T_ = L_./c; 
S_7.Edges.T = transpose(T_); 
T_0 = Z_0/c; 
% we can use shortest path function from root to each node since nature of
% tree is that each node excepting the root node has precisely one parent.
% findshortestpath(src,dest) = findpath(src,dest)

%calculating reflected wave amplitudes and tracking time of measurement
%Time of measurement will be written in terms of {T_1,T_2 ... T_n} for
%generic S_n 

fprintf("Amplitude of incident wave P_i: %d\n", P_i);  
fprintf("Speed of wave: %d\n\n", c); 

R_ = zeros(1,S_7.numnodes); 
T_generated_ = zeros(1,S_7.numnodes); 
T_measured_ = zeros(1,S_7.numnodes); 
for i = 1: S_7.numnodes %since num_reflected_waves = num_nodes  
    if i == 1
        R_(1,i) = P_i*S_7.Nodes.Gamma(1); 
        T_generated_(1,i) = T_0; 
        T_measured = 2*T_0; 
        T_measured_(1,i) = T_measured; 
        
        fprintf("Wave transmitted into Z_%d: %e\n", i-1, P_i); 
        fprintf("Reflected Wave R_%d back through Z_%d: %e\n", i, i-1,R_(1,i));
        fprintf("R_%d measured at time: %e ms\n", i, T_0);
        fprintf("R_%d measured at time: %e ms\n\n", i, T_measured); 
    else %i > 1
        T = 0;
        path = shortestpath(S_7,1,i); 
        final_lambda = 1; 
        for j = 1: length(path)-1 
            final_lambda = final_lambda*S_7.Edges.Lambda(findedge(S_7,path(j),path(j+1))); 
            T = T + S_7.Edges.T(findedge(S_7,path(j),path(j+1))); 
        end
        T_measured = 2*T; 
        W_t = P_i*final_lambda;
        R_(1,i) = W_t*S_7.Nodes.Gamma(path(length(path)));
        T_generated_(1,i) = T; 
        T_measured_(1,i) = T_measured;
        
        fprintf("Wave transmitted into Z_%d: %e\n", i-1, W_t);
        fprintf("Reflected Wave R_%d back through Z_%d: %e\n", i, i-1,R_(1,i));
        fprintf("R_%d generated at time: %e ms\n", i, T); 
        fprintf("R_%d measured at time: %e ms\n\n", i, T_measured); 
    end
end

%we know have the amplitude of each reflected wave
%we sum them to get the amplitude of of the effective reflected wave 

S_7.Nodes.A = transpose(R_); 
S_7.Nodes.T_g = transpose(T_generated_);
S_7.Nodes.T_m = transpose(T_measured_); 
R_E = sum(R_); 
fprintf("\n\n Amplitude of effected reflective wave: %e\n", R_E); 
disp(S_7.Nodes); 
disp(S_7.Edges); 
%plot(S_7,'NodeLabel',S_7.Nodes.Gamma,'EdgeLabel',S_7.Edges.Lambda); 

%Now, we want to see whether or not, using the phase shifts obtained from
%the measured time delay between reflected waves and their measurement as
%well as the amplitudes of individual reflected waves, it's possible to
%produce something graphically approximating a cardiac pulse 

%Note that the second incident pulse will have a phase shift of 800 ms,
%giving the form: 40sin(t - 800)+80. Reflected waves will be shifted by the
%time at which they were generated. 

f = @(t,a,b,c,d) (a*sin((b*t)-c)+d).*((a*sin((b*t)-c)+d)>=d) + d*((a*sin(b*t-c)+d)<d);   
t = linspace(1,2000,2500); 
%first, we check which reflected waves are measured after 800 ms. 
F = f(t,30,pi/400,800,80); 
%plot(F)
G = 0;
G_ = zeros(1,7); 
for i = 1: S_7.numnodes 
    %if S_7.Nodes.T_m(i)> 800
        G = G + f(t,S_7.Nodes.A(i), pi/400, 800-1*S_7.Nodes.T_g(i),0);
        plot(G); 
        hold on 
    %end
end

subplot(1,2,1)
plot(S_7,'EdgeLabel',S_7.Edges.Lambda,'NodeLabel',S_7.Nodes.Gamma);
title("Abstract Tree Structure of Full Arterial Scheme");
subplot(1,2,2);
plot(F+G);
hold on
plot(F);
hold on 
plot(G);
xlabel("time");
title("Blood Pulse Wave Amplification");
legend("Amplified Pulse Wave","Incident Pulse Wave","Effective Reflected Wave");
xlabel("Time");
ylabel("Amplitude");
