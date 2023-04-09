"""
Plots flight data of my KSP-rockets.
(c) 2023 Janik-ux
Licensed under MIT
"""
import matplotlib.pyplot as plt
import pandas as pd

# file = "flightlog_f9_west.csv"
file0 = "c_d-vel-height.csv"
file1 = "entryflightlog_comp_1.csv"
# headers = ["time", "gheight", "fdist[0]", "bdist[0]", "P", "D"]

# plt.rcParams["figure.figsize"] = [7.50, 3.50]
# plt.rcParams["figure.autolayout"] = True


df0 = pd.read_csv(file0)
# df1 = pd.read_csv(file1)
x = 29805722
# print(df.loc[(df["time"] >= x-0.1) & (df["time"] <= x+0.1)])

# plot:
# df[["time", "c_d", "velo", "gheight"]].set_index("gheight").plot()
# df[["time", "c_d", "velo", "gheight"]].set_index("gheight").plot()
fig, axs = plt.subplots(2, 1)

axs[0].plot(df0["c_d"], df0["gheight"], marker="o") # , df0["gheight"], df0["velo"])
# axs[1].plot(df1["velo"], df1["c_d"]) # , df1["gheight"], df1["velo"])


# # df[["time", "D", "P", "fdist[0] (=x_fallend)"]].set_index("time").plot()
# plt.plot(df["time"], df["P"], "o", label="P")
# plt.plot(df["time"], df["D"], "o", label="D")
# plt.plot(df["time"], df["fdistx"], "o", label="fdistx")
# plt.plot(df["time"], df["fdisterr"], "o", label="fdist error")
# plt.plot(df["time"], df["bdisterr"], "o", label="bdist error")
# plt.plot(df["time"], df["bdisty"], "o", label="bdisty")
# plt.plot(df["time"], df["bdistx"], "o", label="bdistx")
# plt.plot(df["time"], df["gheight"], "o", label="gheight")
plt.legend()
plt.show()
