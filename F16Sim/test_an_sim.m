function [] = test_an_sim()
clear all;
altitude = 15000;
velocity = 500;
% weird behaviour otherwise
global fi_flag_Simulink
fi_flag_Simulink = 0;
% trim settings
thrust = 5000;          % thrust, lbs
elevator = -0.09;       % elevator, degrees
alpha = 8.49;              % AOA, degrees
rudder = -0.01;             % rudder angle, degrees
aileron = 0.01;            % aileron, degrees

[trim_state, trim_thrust, trim_control, dLEF, UX] = trim_steady_state(thrust, elevator, alpha, aileron, rudder, velocity, altitude);
load_system('Lin_F16Block_lo');

% params for linear model

deltaT = 0.01;
TStart = 0; 
TFinal = 5;
time = linspace(0, 5, 5/deltaT + 1);
u = -1 * ones(size(time));
thrust = 0;  % Since this a linear model
accelerometer_pos = [0, 5, 5.9, 6, 7, 15];


for x_a = accelerometer_pos

    [A, B, C, D] = linmod('LIN_F16Block_lo', [trim_state; trim_thrust; trim_control; dLEF; -trim_state(8)*180/pi], ... 
                                              [trim_thrust; trim_control]);
    % initial states are already set in the model
    system = ss(A, B, C, D);
    H_mimo = tf(system);
    H_an_el = H_mimo(19, 2);
    [y, t, x] = lsim(H_an_el, u, time);
    sim('SS_F16_Block_lo', [TStart ,TFinal]);
    % output from simulink model
    if any(abs(y - a_n_data.Data) > 0.01)
        error("Results from transfer function and state model differ!");
    end
end

end

