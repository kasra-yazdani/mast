function u = coordinated_turn_hold(beta, flag,P)
Ts = P.Ts;
% Tau = P.Tau;
limit = 35*pi/180;
ki = P.k_i_beta;
kp = P.k_p_beta;

persistent integrator;
 persistent error_d1;
 if flag==1, % reset (initialize) persistent variables
     % when flag==1
     integrator = 0;
     error_d1 = 0; % _d1 means delayed by one time step
 end
 error = 0 - beta; % compute the current error
 integrator = integrator + (Ts/2)*(error + error_d1);
 % update integrator
 error_d1 = error; % update the error for next time through
 % the loop
 u = -sat(... % implement PID control
 kp * error +... % proportional term
 ki * integrator,... % integral term
 limit... % ensure abs(u)<=limit
 );
 % implement integrator anti-windup
 if ki~=0
     u_unsat = kp*error + ki*integrator;
     integrator = integrator + Ts/ki * (u - u_unsat);
 end
 
    function out = sat(in, limit)
         if in > limit, out = limit;
         elseif in < -limit; out = -limit;
         else out = in;
         end
    end
end