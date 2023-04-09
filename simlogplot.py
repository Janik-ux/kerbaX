"""
Plots the realtime simulation data of the rocket controller.
(c) 2023 Janik-ux
Licensed under MIT
"""
import matplotlib.pyplot as plt
import re

file = "simlog.log"

sims = []
burnstart = []

with open(file, "r") as file:
    for line in file:
        line = line.strip("\n")
        if line == "begin":
            sims.append({"height": [], "vel": [], "vel_mag": [], "pos": [], "g": [], "a_drag": [], "dv": [], "dv_mag": []})
        elif line == burnstart:
            burnstart.append(sims[-1]["height"])
        elif line.startswith("height"): sims[-1]["height"].append(float(re.findall("\d+\.?\d*", line)[0]))
        elif line.startswith("a_drag"): sims[-1]["a_drag"].append(float(re.findall("\d+\.?\d*", line)[0]))
        elif line.startswith("vel"): 
            sims[-1]["vel"].append([float(n) for n in list(re.findall("\d+\.?\d*", line))])
            sims[-1]["vel_mag"].append((sims[-1]["vel"][-1][0]**2 + sims[-1]["vel"][-1][1]**2 + sims[-1]["vel"][-1][2]**2)**0.5)
        elif line.startswith("pos"): sims[-1]["pos"].append([float(n) for n in list(re.findall("\d+\.?\d*", line))])
        elif line.startswith("g: "): sims[-1]["g"].append([float(n) for n in list(re.findall("\d+\.?\d*", line))])
        elif line.startswith("dv"): 
            sims[-1]["dv"].append([float(n) for n in list(re.findall("\d+\.?\d*", line))])
            sims[-1]["dv_mag"].append((sims[-1]["dv"][-1][0]**2+sims[-1]["dv"][-1][1]**2+sims[-1]["dv"][-1][2]**2)**0.5)

# print(sims)

# --- all in one: ---
# for i in range(1):
#     plt.plot(range(len(sims[i]["a_drag"])), sims[i]["a_drag"])

# --- single iteration: ---
plt.plot(range(len(sims[0]["a_drag"])), sims[0]["a_drag"], label="a_drag")
plt.plot(range(len(sims[0]["dv_mag"])), sims[0]["dv_mag"], label="dv_mag")
plt.plot(range(len(sims[0]["vel_mag"])), sims[0]["vel_mag"], label="vel_mag")
plt.plot(range(len(sims[0]["height"])), sims[0]["height"], label="height")

# --- endposition ---
# endposx, endposy, endposz = [], [], []
# for sim in sims:
#     endposx.append(sim["pos"][-1][0])
#     endposy.append(sim["pos"][-1][1]) 
#     endposz.append(sim["pos"][-1][2])
# fig, axs = plt.subplots(3, 1)
# fig.suptitle("predicted Landingposition with each simulation (on y-axis), now dt=0.2")

# axs[0].set_title("x")
# axs[1].set_title("y")
# axs[2].set_title("z")
# axs[0].plot(range(len(endposx)), endposx, "o")
# axs[1].plot(range(len(endposy)), endposy, "o")
# axs[2].plot(range(len(endposz)), endposz, "o")

plt.legend()
plt.show()
