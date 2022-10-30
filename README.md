# NLOPRT-Optimization
Optimizing water outflow distribution for the next 5 years

### Variables
	RPt = maximum outflow for the hydropower turbine during the time interval t
	IRRt = maximum outflow for irrigation during time interval t
	Et = evaporation over time interval t
	WSt = maximum demand for clean water at time t
	DSt = Dead Storage (Tampungan Mati)
	It = inflow during the time interval t
	St = water available at time t

### Process
Water enters the reservoir (It) thereby increasing the current water level (St). The water is used to turn hydropower turbines (RPt), meet irrigation needs (IRRt), and supply clean water (WSt). Some of the water will evaporate (Et) and be used to fill the dead storage (DSt). Mathematically, the equation to calculate the remaining water level is:
![image](https://user-images.githubusercontent.com/48485276/198865721-8808bb5a-9c5a-40e1-ae43-0091526af693.png)

### Optimization
NLopt is a free/open-source library for nonlinear optimization. We need to optimize α,β, and γ such that S_(t+1)>min⁡(S_(t+1)). NLopt is chosen because it has built-in algorithms for unconstrained optimization, bound-constrained optimization, and general nonlinear inequality/equality constraints. We added a limitation on these three parameters such that for the next three observations, S_(t+1)>min⁡(S_(t+1) ),S_(t+2)>min⁡(S_(t+2) ), and S_(t+3)>min⁡(S_(t+3) ) are satisfied even we use the same parameters. Even NLopt is a nonlinear optimization, it can solve linear optimization too.

To optimize the water outflow distribution for the next five years, we need to have an initial value of  S_t, predictions of I_t, and historical value of RP_t,IRR_t,WS_t,E_t, and DS_t. The I_t variable has 690 observations. I_t is calculated by taking the average the inflow for 10 days. We create a time-series model of I_t using Seasonal ARIMA and predict the value for the next 180 observations.
 
![image](https://user-images.githubusercontent.com/48485276/198869425-46833a46-625d-48ad-a1f2-3320e2232aac.png)


### Result
It worked like a charm. The graph below describes the distribution of water over 5 years. All variables have a yearly pattern. 

![image](https://user-images.githubusercontent.com/48485276/198869451-b1fd0b18-8189-4692-94a0-f1192b8db1ad.png)

With all the distribution of outflow water, the water in the reservoir is still abundant. *Note : Time in year
![image](https://user-images.githubusercontent.com/48485276/198869440-568b7017-cdac-4b48-8473-7aaabc263ad1.png)





