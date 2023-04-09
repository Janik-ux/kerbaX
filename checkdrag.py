import pandas as pd
import matplotlib.pyplot as plt

file = "entryflightlogf9_0.csv"

df = pd.read_csv(file)
# print(df)
mass = df["mass"][0]
c_d_list = []

for i in range(len(df["time"])):
    # print(i)
    if i == 0: 
        c_d_list.append(None)
        continue
    v_avg = (df["velo"][i] + df["velo"][i-1])/2
    delta_v = df["velo"][i] + df["velo"][i-1]
    c_d = (2*delta_v*mass)/(df["rho"][i]*v_avg**2)
    c_d_list.append(c_d)

df["c_d"] = c_d_list
df.to_csv("entryflightlog_comp_0.csv")

# print(c_d_list)
plt.plot(df["time"], df["c_d"], "o", label="c_d")
plt.show()

