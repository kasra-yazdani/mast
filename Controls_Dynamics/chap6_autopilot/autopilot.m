function y = autopilot(uu,P)
%
% autopilot for mavsim
% 
% Modification History:
%   2/11/2010 - RWB
%   5/14/2010 - RWB
%   9/30/2014 - RWB
%   

    % process inputs
    NN = 0;
%    pn       = uu(1+NN);  % inertial North position
%    pe       = uu(2+NN);  % inertial East position
    h        = uu(3+NN);  % altitude
    Va       = uu(4+NN);  % airspeed
%    alpha    = uu(5+NN);  % angle of attack
   beta     = uu(6+NN);  % side slip angle
    phi      = uu(7+NN);  % roll angle
    theta    = uu(8+NN);  % pitch angle
    chi      = uu(9+NN);  % course angle
    p        = uu(10+NN); % body frame roll rate
    q        = uu(11+NN); % body frame pitch rate
    r        = uu(12+NN); % body frame yaw rate
%    Vg       = uu(13+NN); % ground speed
%    wn       = uu(14+NN); % wind North
%    we       = uu(15+NN); % wind East
%    psi      = uu(16+NN); % heading
%    bx       = uu(17+NN); % x-gyro bias
%    by       = uu(18+NN); % y-gyro bias
%    bz       = uu(19+NN); % z-gyro bias
    NN = NN+19;
    Va_c     = uu(1+NN);  % commanded airspeed (m/s)
    h_c      = uu(2+NN);  % commanded altitude (m)
    chi_c    = uu(3+NN);  % commanded course (rad)
    NN = NN+3;
    t        = uu(1+NN);   % time
    
    [delta, x_command] = autopilot_uavbook(Va_c,h_c,chi_c,Va,h,chi,phi,theta,p,q,r,t,beta,P);
    y = [delta; x_command];
end
    
   
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Autopilot versions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% autopilot_uavbook
%   - autopilot defined in the uavbook
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [delta, x_command] = autopilot_uavbook(Va_c,h_c,chi_c,Va,h,chi,phi,theta,p,q,r,t,beta, P)

    %----------------------------------------------------------
    % lateral autopilot
    if t==0,
        %reset all
        roll_hold(0,0,0,1,P);
        pitch_hold(0,0,0,1,P);
        airspeed_with_pitch_hold(0,0,1,P);
        airspeed_with_throttle_hold(0,0,1,P);
        altitude_hold(0,0,1,P);
        coordinated_turn_hold(0,0,P);
        
        % assume no rudder, therefore set delta_r=0
        delta_r = coordinated_turn_hold(beta, 1, P);
        phi_c   = course_hold(chi_c, chi, r, 1, P);

    else
        phi_c   = course_hold(chi_c, chi, r, 0, P);
        delta_r = coordinated_turn_hold(beta, 0, P);
    end
    delta_a = roll_hold(phi_c, phi, p,0, P);     
  
    
    %----------------------------------------------------------
    % longitudinal autopilot
    
    % define persistent variable for state of altitude state machine
    persistent altitude_state;
    % initialize persistent variable
    if h<=P.altitude_take_off_zone,     
        altitude_state = 1;
    elseif h<=h_c-P.altitude_hold_zone, 
        altitude_state = 2;
    elseif h>=h_c+P.altitude_hold_zone, 
        altitude_state = 3;
    else
        altitude_state = 4;
    end

    
    % implement state machine
    delta_t_trim = P.u_trim(4);
    awp = airspeed_with_pitch_hold(Va_c,Va,0,P);
    awt = delta_t_trim + airspeed_with_throttle_hold(Va_c,Va,0,P);
    ah = altitude_hold(h_c,h,0,P);
    switch altitude_state,
        
        case 1,  % in take-off zone
            delta_t = 1;
            theta_c = P.theta_takeoff;
        case 2,  % climb zone
             delta_t = 1;
             theta_c = awp;
        case 3, % descend zone
            delta_t = 0;
            theta_c = awp;
        case 4, % altitude hold zone
            delta_t = awt;
            theta_c = ah;
    end
    
    delta_e = pitch_hold(theta_c, theta, q, 0, P);
    % artificially saturation delta_t
 
    
    %----------------------------------------------------------
    % create outputs
    
    % control outputs
    delta = [delta_e; delta_a; delta_r; delta_t];
    % commanded (desired) states
    x_command = [...
        0;...                    % pn
        0;...                    % pe
        h_c;...                  % h
        Va_c;...                 % Va
        0;...                    % alpha
        0;...                    % beta
        phi_c;...                % phi
        %theta_c*P.K_theta_DC;... % theta
        theta_c;
        chi_c;...                % chi
        0;...                    % p
        0;...                    % q
        0;...                    % r
        ];
            
    y = [delta; x_command];
 
    end

