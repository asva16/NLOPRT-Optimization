#install.packages(c("readxl", "openxlsx", "forecast", "ggplot2", "nloptr", "dplyr"))
library(readxl)
library(openxlsx)
library(forecast)
library(ggplot2)
library(nloptr)
library(dplyr)
theme_set(theme_minimal())

n_fc = 180 # number of forecast
Thn_fc = n_fc/36 # years of forecast
St_awal = 109000000.000 # initial value of St
elevasi <- read_excel("input.xlsx", sheet = "elevasi")
Inflow10 <- read_excel("input.xlsx", sheet = "debit andalan")
kolom_Inflow10 = expand.grid(1:3,c('Jan','Feb','Mar','Apr','Mei','Juni','Juli','Ags','Sept','Okt','Nov','Des'))
kolom_Inflow10 = paste(kolom_Inflow10[,2],kolom_Inflow10[,1], sep = "_")
colnames(Inflow10) = c('Tahun',kolom_Inflow10)
St_awal = c(109000000, 107801546.36, 107115782.34, 107115782.34, 107115782.34, 107115782.34) # 2 bulan sebelum januari, jangan di-run jika arima mulai di november

#### Input 2
debit <- read_excel("input.xlsx", range = "D1:D649")
data.opt <- read_excel("input.xlsx", sheet = "input_optimasi")

#### ARIMA
debit = ts(debit, frequency = 36)
plot(debit)
fit = arima(debit, order = c(1,0,0), seasonal = list(order = c(0,1,1), period = 36))
fit
pred = forecast(fit, h=n_fc)$mean
plot(forecast(fit, h=n_fc))
It = pred*3600*24*10
data.opt$It = It

### optimization process
for (i in 1:NROW(data.opt)) {
  # water outflow volume
  eval_f = function(par) {
    -par[1]*data.opt$RPt[i]-par[2]*data.opt$IRRt[i]-par[3]*data.opt$WSt[i]
  }
  
  lb = c(0,0,0) # parameter's lower bound
  ub = c(1,1,1) # parameter's upper bound
  x0 = lb # initial value
  
  if (i<=(n_fc-3)) {
    # limitations, i+1, i+2, and i+3 means that we are going to maintain the water outflow for the next 3 observations or 1 month
    eval_g_ineq_v1 = function(par) {
      constr = c(data.opt$min[i]-(data.opt$St[i]+data.opt$It[i]-par[1]*data.opt$RPt[i]-par[2]*data.opt$IRRt[i]-par[3]*data.opt$WSt[i]-data.opt$Et[i]),
                 data.opt$min[i+1]-(data.opt$St[i]+sum(data.opt$It[i:(i+1)])-par[1]*sum(data.opt$RPt[i:(i+1)])-par[2]*sum(data.opt$IRRt[i:(i+1)])-par[3]*sum(data.opt$WSt[i:(i+1)])-sum(data.opt$Et[i:(i+1)])),
                 data.opt$min[i+2]-(data.opt$St[i]+sum(data.opt$It[i:(i+2)])-par[1]*sum(data.opt$RPt[i:(i+2)])-par[2]*sum(data.opt$IRRt[i:(i+2)])-par[3]*sum(data.opt$WSt[i:(i+2)])-sum(data.opt$Et[i:(i+2)])),
                 data.opt$min[i+3]-(data.opt$St[i]+sum(data.opt$It[i:(i+3)])-par[1]*sum(data.opt$RPt[i:(i+3)])-par[2]*sum(data.opt$IRRt[i:(i+3)])-par[3]*sum(data.opt$WSt[i:(i+3)])-sum(data.opt$Et[i:(i+3)])),
                 data.opt$St[i]+data.opt$It[i]-par[1]*data.opt$RPt[i]-par[2]*data.opt$IRRt[i]-par[3]*data.opt$WSt[i]-data.opt$Et[i]-122000000)
      return(constr)
    }
    opts <- list( "algorithm" = "NLOPT_GN_ISRES",
                  "xtol_rel"= 1.0e-15,
                  "maxeval"= 100000,
                  "tol_constraints_ineq" = rep( 1.0e-10, 5))
  } else if (i==(n_fc-2)) {
    # limitations, i+1 and i+2 means that we are going to maintain the water outflow for the next 2 observations, because we are optimizing the last three obs
    eval_g_ineq_v1 = function(par) {
      constr = c(data.opt$min[i]-(data.opt$St[i]+data.opt$It[i]-par[1]*data.opt$RPt[i]-par[2]*data.opt$IRRt[i]-par[3]*data.opt$WSt[i]-data.opt$Et[i]),
                 data.opt$min[i+1]-(data.opt$St[i]+sum(data.opt$It[i:(i+1)])-par[1]*sum(data.opt$RPt[i:(i+1)])-par[2]*sum(data.opt$IRRt[i:(i+1)])-par[3]*sum(data.opt$WSt[i:(i+1)])-sum(data.opt$Et[i:(i+1)])),
                 data.opt$min[i+2]-(data.opt$St[i]+sum(data.opt$It[i:(i+2)])-par[1]*sum(data.opt$RPt[i:(i+2)])-par[2]*sum(data.opt$IRRt[i:(i+2)])-par[3]*sum(data.opt$WSt[i:(i+2)])-sum(data.opt$Et[i:(i+2)])),
                 data.opt$St[i]+data.opt$It[i]-par[1]*data.opt$RPt[i]-par[2]*data.opt$IRRt[i]-par[3]*data.opt$WSt[i]-data.opt$Et[i]-122000000)
      return(constr)
    } 
    opts <- list( "algorithm" = "NLOPT_GN_ISRES",
                  "xtol_rel"= 1.0e-15,
                  "maxeval"= 100000,
                  "tol_constraints_ineq" = rep( 1.0e-10, 4))
  } else if (i==(n_fc-1)) {
    # limitations, i+1  means that we are going to maintain the water outflow for the next observations, because we are optimizing the last two obs
    eval_g_ineq_v1 = function(par) {
      constr = c(data.opt$min[i]-(data.opt$St[i]+data.opt$It[i]-par[1]*data.opt$RPt[i]-par[2]*data.opt$IRRt[i]-par[3]*data.opt$WSt[i]-data.opt$Et[i]),
                 data.opt$min[i+1]-(data.opt$St[i]+sum(data.opt$It[i:(i+1)])-par[1]*sum(data.opt$RPt[i:(i+1)])-par[2]*sum(data.opt$IRRt[i:(i+1)])-par[3]*sum(data.opt$WSt[i:(i+1)])-sum(data.opt$Et[i:(i+1)])),
                 data.opt$St[i]+data.opt$It[i]-par[1]*data.opt$RPt[i]-par[2]*data.opt$IRRt[i]-par[3]*data.opt$WSt[i]-data.opt$Et[i]-122000000)
      return(constr)
      
    }
    opts <- list( "algorithm" = "NLOPT_GN_ISRES",
                  "xtol_rel"= 1.0e-15,
                  "maxeval"= 100000,
                  "tol_constraints_ineq" = rep( 1.0e-10, 3))
  } else {
    # limitations,  we are optimizing the obs
    eval_g_ineq_v1 = function(par) {
      constr = c(data.opt$min[i]-(data.opt$St[i]+data.opt$It[i]-par[1]*data.opt$RPt[i]-par[2]*data.opt$IRRt[i]-par[3]*data.opt$WSt[i]-data.opt$Et[i]),
                 data.opt$St[i]+data.opt$It[i]-par[1]*data.opt$RPt[i]-par[2]*data.opt$IRRt[i]-par[3]*data.opt$WSt[i]-data.opt$Et[i]-122000000)
      return(constr)
    }
    opts <- list( "algorithm" = "NLOPT_GN_ISRES",
                  "xtol_rel"= 1.0e-15,
                  "maxeval"= 100000,
                  "tol_constraints_ineq" = rep( 1.0e-10, 2))
  }
  
  res <- nloptr(
    x0          = x0,
    eval_f      = eval_f,
    lb          = lb,
    ub          = ub,
    eval_g_ineq = eval_g_ineq_v1,
    opts        = opts )
  data.opt$alpha[i] = res$solution[1]
  data.opt$beta[i] = res$solution[2]
  data.opt$gamma[i] = res$solution[3]
  data.opt$sum[i] = abs(res$objective)
  data.opt$St[i+1] = data.opt$St[i]+data.opt$It[i]-res$solution[1]*data.opt$RPt[i]-res$solution[2]*data.opt$IRRt[i]-res$solution[3]*data.opt$WSt[i]-data.opt$Et[i]
  print(paste(i,':',data.opt$St[i+1]))
}
data.opt$cek=ifelse(data.opt$St>=data.opt$min,'aman','tidak')
data.opt$a.Rpt = data.opt$alpha*data.opt$RPt
data.opt$b.IRRt = data.opt$beta*data.opt$IRRt
data.opt$g.WSt = data.opt$gamma*data.opt$WSt
data.opt$sum = data.opt$a.Rpt+data.opt$b.IRRt+data.opt$g.WSt
lines(1:181,data.opt$St)

### fungsi vlookup
my_lookup = function(data) {
  output = rep(0,NROW(data))
  for (i in 1:NROW(data)) {
    selisih.min=which.min(abs(elevasi$`Volum Tampungan (m3)`-data[i]))
    output[i] = elevasi$Elevasi[selisih.min]
  }
  return(output)
}

elevasi.St = my_lookup(data.opt$St)
elevasi.RPt = my_lookup(data.opt$a.Rpt[1:180])
elevasi.IRRt = my_lookup(data.opt$b.IRRt[1:180])
elevasi.WSt = my_lookup(data.opt$g.WSt[1:180])
FWL = rep(max(elevasi$Elevasi), length(elevasi.St))
HWL = rep(elevasi$Elevasi[64], length(elevasi.St))

Inflow_baru = data.frame('Tahun'= c(2022:2026),matrix(pred, ncol = 36, byrow = T))
colnames(Inflow_baru) = colnames(Inflow10)
Inflow_baru = rbind(Inflow10, Inflow_baru)
Inflow_sort = Inflow_baru %>%
  mutate_at(1:NCOL(Inflow_baru), funs(sort(., decreasing = TRUE)))
Inflow_sort$Tahun = 1:NROW(Inflow_sort)
colnames(Inflow_sort)[1] = 'id'
Inflow_sort$persen = Inflow_sort$id/max(Inflow_sort$id)

thn_basah = Inflow_sort[which.min(abs(Inflow_sort$persen-0.222)),-c(1,38)]
thn_normal = Inflow_sort[which.min(abs(Inflow_sort$persen-0.5)),-c(1,38)]
thn_kering = Inflow_sort[which.min(abs(Inflow_sort$persen-0.833)),-c(1,38)]

thn_lengkap = t(as.matrix(rbind(thn_basah, thn_normal, thn_kering)))
colnames(thn_lengkap) = c('Basah','Normal','Kering')
#awal_tahun = which(rownames(thn_lengkap)=='Nov_1')
#thn_lengkap = rbind(thn_lengkap[awal_tahun:NROW(thn_lengkap),], thn_lengkap[-c(awal_tahun:NROW(thn_lengkap)),])
Inflow_final = thn_lengkap*3600*24*10+min.debit
Inflow_final = do.call(rbind, replicate(Thn_fc, Inflow_final, simplify=FALSE))

elevasi.basah = my_lookup(Inflow_final[,1])
elevasi.normal = my_lookup(Inflow_final[,2])
elevasi.kering = my_lookup(Inflow_final[,3])

write.xlsx(data.frame('St'=elevasi.St,
                      'RPt'=elevasi.RPt,
                      'IRRt'=elevasi.IRRt,
                      'WSt'=elevasi.WSt,
                      'FWL'=FWL,
                      'HWL'=HWL,
                      'Thn_Basah'=elevasi.basah,
                      'Thn_Normal'=elevasi.normal,
                      'Thn_Kering'=elevasi.kering,
                      'alpha'=data.opt$alpha,
                      'beta'=data.opt$beta,
                      'gamma'=data.opt$gamma),
           'Elevasi NLOPTR.xlsx', overwrite = T)
write.xlsx(data.frame('St'=c(data.opt$St),
                      'RPt'=c(data.opt$a.Rpt),
                      'IRRt'=c(data.opt$b.IRRt),
                      'WSt'=c(data.opt$g.WSt),
                      'FWL'=max(elevasi$`Volum Tampungan (m3)`),
                      'HWL'=elevasi$`Volum Tampungan (m3)`[64],
                      'Thn_Basah'=c(Inflow_final[,1]),
                      'Thn_Normal'=c(Inflow_final[,2]),
                      'Thn_Kering'=c(Inflow_final[,3]),
                      'alpha'=data.opt$alpha,
                      'beta'=data.opt$beta,
                      'gamma'=data.opt$gamma),
           'Debit NLOPTR.xlsx', overwrite = T)
getwd()
