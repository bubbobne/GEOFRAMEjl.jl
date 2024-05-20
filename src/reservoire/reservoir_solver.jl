using DifferentialEquations
using Plots



function calculate_evaporation(S, P, E, s_rootzone_max)
    etpnet = E * min(1, 1.33 * S / s_rootzone_max)
    return min(etpnet, S + P)
end

"""
    solve_reservoir(S_initial, P, E, b, c, σ, Δt)

Solve the differential equation for a root zone reservoir storage over a given time period, incorporating stochastic elements to account for randomness and uncertainties.

# Arguments
- `S_initial::Float64`: Initial storage in the reservoir (in cubic meters).
- `P::Vector{Float64}`: Array of inflow (precipitation) values (in cubic meters per day).
- `E::Vector{Float64}`: Array of evaporation values (in cubic meters per day).
- `b::Float64`: Coefficient for the outflow function.
- `c::Float64`: Exponent for the outflow function.
- `σ::Float64`: Noise intensity for the stochastic term.
- `Δt::Float64`: Time step for solving the differential equation (in days).

# Returns
- `sol::ODESolution`: The solution object containing the time points and storage values over the time period.

# Example
```julia
using DifferentialEquations
using Plots

# Example usage
S_initial = 1000.0
P = [50.0, 45.0, 60.0, 70.0, 65.0, 55.0, 50.0, 45.0, 40.0, 35.0, 30.0, 25.0, 20.0, 15.0, 10.0, 5.0, 0.0, 5.0, 10.0, 15.0, 20.0, 25.0, 30.0, 35.0, 40.0, 45.0, 50.0, 55.0, 60.0, 65.0]
E = [5.0, 5.0, 5.0, 5.0, 5.0, 5.0, 5.0, 5.0, 5.0, 5.0, 5.0, 5.0, 5.0, 5.0, 5.0, 5.0, 5.0, 5.0, 5.0, 5.0, 5.0, 5.0, 5.0, 5.0, 5.0, 5.0, 5.0, 5.0, 5.0, 5.0]
b = 0.01
c = 1.5
σ = 10.0
Δt = 1.0

# Solve the reservoir equation
sol = solve_reservoir(S_initial, P, E, b, c, σ, Δt)

# Plot the results
plot(sol.t, sol.u, xlabel="Time (days)", ylabel="Storage (cubic meters)", title="Reservoir Storage Over Time", legend=false)



# Example usage
S_initial = 1000.0
s_max =1200
P = [50.0, 45.0, 60.0, 70.0, 65.0, 55.0, 50.0, 45.0, 40.0, 35.0, 30.0, 25.0, 20.0, 15.0, 10.0, 5.0, 0.0, 5.0, 10.0, 15.0, 20.0, 25.0, 30.0, 35.0, 40.0, 45.0, 50.0, 55.0, 60.0, 65.0]
E = [5.0, 5.0, 5.0, 5.0, 5.0, 5.0, 5.0, 5.0, 5.0, 5.0, 5.0, 5.0, 5.0, 5.0, 5.0, 5.0, 5.0, 5.0, 5.0, 5.0, 5.0, 5.0, 5.0, 5.0, 5.0, 5.0, 5.0, 5.0, 5.0, 5.0]
b = 0.0001
c = 1.5
σ = 1.0
Δt = 1.0

# Solve the reservoir equation
sol_t = 1:30
sol_u = []

# Initial condition for the first time step

for i in eachindex(sol_t)
    sol = solve_reservoir(S_initial,s_max, P[1:i], E[1:i], b, c, σ, Δt)
    push!(sol_u, sol.u[end][1])
    global S_initial = sol.u[end][1]
end

# Plot the results
plot(sol_t, sol_u, xlabel="Time (days)", ylabel="Storage (cubic meters)", title="Reservoir Storage Over Time", legend=false)





"""

function solve_reservoir(S_initial,s_rootzone_max, P, E, b, c, σ, n_iter)
    # Define the time period
    Δt = 1/n_iter
    time_period = 1:length(P)
    # Interpolate P and E to create continuous functions
    #P_func = t -> P[Int(clamp(floor(t)+1, 1, length(P)))]
    #E_func = t -> E[Int(clamp(floor(t)+1, 1, length(E)))]
    P_func = t -> P[1]
    E_func = t -> E[1]
    
    # Define the drift term (deterministic part of the SDE)
   # Define the drift term (deterministic part of the SDE)
   function drift!(dS, S, p, t)
        current_P = P_func(t)
        current_E = calculate_evaporation(S[1], current_P, E_func(t), s_rootzone_max)
        outflow = b * S[1]^c
        # Adjust outflow if storage is less than zero
        if S[1]+ current_P - current_E <= 0
            outflow = 0
        elseif S[1]+ current_P - current_E - outflow <=0
            outflow = S[1]+ current_P - current_E
        end

        dS[1] = current_P - current_E - outflow
    end

    # Define the diffusion term (stochastic part of the SDE)
    function diffusion!(dS, S, p, t)
        dS[1] = σ
    end
    
    # Initial condition
    S0 = [S_initial]

    # Time span
    tspan = (0.0, maximum(time_period))

    # Define the SDE problem
    prob = SDEProblem(drift!, diffusion!, S0, tspan)

    # Solve the SDE problem
    sol = solve(prob, SRIW1(), dt=Δt)

    return sol
end



