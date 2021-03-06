% clear
% close all
% clc
% 
% param_chap6

simOn = 0;

%% Tune Roll Hold

delta_a_max = 45*pi/180;
phi_max = 45*pi/180;
e_phi_max = phi_max;
Va = 35; % m/s

a_phi_1 = -(1/2)*P.rho * Va^2 * P.S_wing * P.b * P.C_p_p * P.b / (2*Va);
a_phi_2 = (1/2)*P.rho * Va^2 * P.S_wing * P.b * P.C_p_delta_a;

% Tuning Params

zeta_phi = 1.3;
k_i_phi = 0.2;

% Derived Params
k_p_phi = delta_a_max/e_phi_max * sign(a_phi_2);

w_n_phi = sqrt(abs(a_phi_2) * delta_a_max/e_phi_max);

k_d_phi = (2*zeta_phi*w_n_phi - a_phi_1)/a_phi_2;

% Simulate
if(simOn)
    simm = sim('roll_loop.slx');

    plot(simout.Time, simout.Data);
end

%% Tune Course Hold

% Tuning Params
zeta_chi = 1.5;
W_chi = 15.5;

% Derived Params
w_n_chi = w_n_phi / W_chi;

Vg = Va;
k_p_chi = 2*zeta_chi*w_n_chi*Vg/P.gravity;
k_i_chi = w_n_chi^2 *Vg/P.gravity;



% Simulate
if(simOn)
    simm = sim('course_loop.slx',30);

    plot(simout.Time, simout.Data);
end


%% Tune Sideslip Hold

% Input Params

a_beta_1 = -P.rho*Va*P.S_wing/(2*P.mass) * P.C_Y_beta;
a_beta_2 = P.rho*Va*P.S_wing/(2*P.mass) * P.C_Y_delta_r;

delta_r_max = 45*pi/180;
e_beta_max = 15*pi/180;

% Tuning Params
zeta_beta = 1;


% Derived Params

k_p_beta = delta_r_max/e_beta_max * sign(a_beta_2);
k_i_beta = (1/a_beta_2) * ((a_beta_1 + a_beta_2*k_p_beta)/(2*zeta_beta))^2;

% Simulate
if(simOn)
    simm = sim('sideslip_loop.slx',300);

    plot(simout.Time, simout.Data);
end


%% Tune Pitch Altitude Hold

% Input Params

a_theta_1 = -P.rho*Va^2*P.c*P.S_wing / (2*P.Jy)*P.C_m_q*P.c/(2*Va);
a_theta_2 = -P.rho*Va^2*P.c*P.S_wing / (2*P.Jy)*P.C_m_alpha;
a_theta_3 = P.rho*Va^2*P.c*P.S_wing / (2*P.Jy)*P.C_m_delta_e;

delta_e_max = 45*pi/180;
e_theta_max = 10*pi/180;

% Tuning Params

zeta_theta = 2.2;

% Derived Params

k_p_theta = delta_e_max/e_theta_max * sign(a_theta_3);
w_n_theta = sqrt(a_theta_2 + abs(k_p_theta));
k_d_theta = (2*zeta_theta*w_n_theta - a_theta_1)/a_theta_3;

K_theta_DC = k_p_theta*a_theta_3/(a_theta_2 + k_p_theta * a_theta_3);

% Simulate
if(simOn)
    simm = sim('pitch_loop.slx',10);

    plot(simout.Time, simout.Data);
end


%% Tune Altitude Hold by Pitch Loop


% Input Params

% Tuning Params

W_h = 5;
zeta_h = 0.7;

% Derived Params

w_n_h = (1/W_h)*w_n_theta;
k_i_h = w_n_h^2 / (K_theta_DC * Va);
k_p_h = 2*zeta_h*w_n_h / (K_theta_DC * Va);

% Simulate
if(simOn)
    simm = sim('altitude_by_pitch_loop.slx',10);

    plot(simout.Time, simout.Data);
end

%% Tune Airspeed Hold by Pitch Loop

% Input Params

delta_e_trim = P.u_trim(1);
delta_a_trim = P.u_trim(2);
delta_r_trim = P.u_trim(3);
delta_t_trim = P.u_trim(4);

u = P.x_trim(4);
v = P.x_trim(5);
w = P.x_trim(6);
phi     = P.x_trim(7);
theta   = P.x_trim(8);
psi     = P.x_trim(9);

Va_trim = sqrt(u^2 + v^2 + w^2);
alpha_trim = atan2(w,u);
chi_trim = 180/pi*atan2(Va_trim*sin(psi) + 0, Va_trim*cos(psi) + 0); % we = 0, wn = 0

a_V1 = P.rho*Va_trim*P.S_wing/P.mass * ...
    (P.C_D(alpha_trim) + P.C_D_delta_e*delta_e_trim)...
    + P.rho*P.S_prop/P.mass*P.C_prop*Va_trim;
a_V2 = P.rho*P.S_prop/P.mass*P.C_prop*P.k_motor^2*delta_t_trim;
a_V3 = P.gravity*cos(theta-chi_trim);


% Tuning Params

W_V2 = 5.9;
zeta_V2 = 2.5;

% Derived Params

w_n_V2 = (1/W_V2)*w_n_theta;
k_i_V2 = -w_n_V2^2 / (K_theta_DC*P.gravity);
k_p_V2 = (a_V1-2*zeta_V2*w_n_V2)/(K_theta_DC*P.gravity);

% Simulate
if(simOn)
    simm = sim('airspeed_by_pitch_loop.slx',10);

    plot(simout.Time, simout.Data);
end
%% Tune Airspeed Hold by Throttle Loop


% Tuning Params

w_n_V = 6;
zeta_V = 6.5;

% Derived Params

k_i_V = w_n_V^2 / a_V2;
k_p_V = (2*zeta_V*w_n_V - a_V1)/a_V2;

% Simulate
if(simOn)
    simm = sim('airspeed_by_throttle_loop.slx',10);

    plot(simout.Time, simout.Data);
end
