"""
landing.py
(c) 2022 Janik-ux
"""

import numpy             as np
import scipy.optimize
import matplotlib.pyplot as plt
from   numpy.linalg import svd
from   math         import sqrt

plt.style.use( 'dark_background' )

def land(k    = 20,
         dir  = -1,
         v0   = [0, 1],
         r0   = [0, 0],
         dt   = 0.01,
         maxt = 15000,
         g    = [0, -9.8066],
         plot = False):
    """
    Simulate Landing of a rocket at given r0 and v0.
    arg: k       -> Lift coeficient F/m
    arg: dir     -> brake (-1) or accelerate (1)
    arg: v0      -> initial velocity vector as list [x, y]
    arg: r0      -> initial position vector as list [x, y]
    arg: dt      -> step size for numerical integration
    arg: maxt    -> max runtime for numerical integration
    arg: g       -> interference v
    returns: res -> dict of acceleration, velocity, 
                    position, abs velocity and y-brakedistance
                    for every t.
    """
    # TODO add args to functext

    rounding = len(str(dt)) - str(dt).find(".") - 1
    # stores calc data maybe add t values
    res = {
        "acceleration": [[0], [0]],
        "velocity": [[v0[0]], [v0[1]]],
        "position": [[r0[0]], [r0[1]]],
        "absv": []
    }
    t = 0
    while t <= maxt - dt:
        t += dt
        t = round(t, rounding)
        # calc change in velocity
        lastv = [res["velocity"][i][-1] for i in range(len(res["velocity"]))]
        
        absv = sqrt(lastv[0]**2 + lastv[1]**2)
        res["absv"].append(absv)
        
        try:
            vunit = [(lastv[i]/absv)*dir for i in range(len(res["velocity"]))]
        except ZeroDivisionError:
            print("dont know where to point")
            res["yburndist"] = 0
            t = 0 # didnt do anything
            break
        

        for i in range(len(res["velocity"])):

            a = vunit[i]*k + g[i]
            res["acceleration"][i].append(a)
            res["velocity"][i].append(lastv[i] + a*dt)
            res["position"][i].append(res["position"][i][-1] + res["velocity"][i][-1]*dt)
        if -0.1 < absv < 0.1:
            res["yburndist"] = abs(r0[1] + res["position"][1][-1])
            break

    if plot:
        import matplotlib.pyplot as plt
        inp_map = {"v": "velocity", "a": "acceleration", "r": "position"}
        inp = input("What do you want to show? [a]cceleration, [v]elocity, [r]position or [q]uit")
        tmarks = [i*dt for i in range(round(t*1/dt)+1)]

        while inp != "q":
            
            # TODO catch KeyError!
            plt.close()
            plt.figure(1)
            plt.subplot(211)
            plt.plot(tmarks, res[inp_map[inp]][0])
            plt.subplot(212)
            plt.plot(tmarks, res[inp_map[inp]][1])
            plt.show()
            inp = input()
        else:
            plt.close()
        
    return res

def fit_quad(pnts, fitfnc=lambda x,y : [x**2, y**2]):
    """
    Calculate quadratic Function for given set of data, by solving system
    of linear equations.

    arg:   numpy array pnts of shape (>=6, 3)
    returns: numpy array coefs of shape (6, )
    """
    # TODO input überprüfen zB zwei gleiche x,y
    # print(pnts)
    rand = np.random.RandomState(1234556789)

    selctmeth = 1
    if selctmeth == 0:
        pnts = pnts[rand.choice(pnts.shape[0], size=6, replace=False)]
    
    # for unordered data:
    elif selctmeth == 1:
        xmax = np.max(pnts[:, 0])
        xmin = np.min(pnts[:, 0])
        ymax = np.max(pnts[:, 1])
        ymin = np.min(pnts[:, 1])
        indxs = np.empty((4,), dtype=np.int32)

        for i in range(pnts.shape[0]):
            if pnts[i][0] == xmax and pnts[i][1] == ymax:
                indxs[0] = i
            elif pnts[i][0] == xmin and pnts[i][1] == ymin:
                indxs[1] = i
            elif pnts[i][0] == xmax and pnts[i][1] == ymin:
                indxs[2] = i
            elif pnts[i][0] == xmin and pnts[i][1] == ymax:
                indxs[3] = i

        pnts = pnts[np.concatenate([indxs, rand.choice(np.delete(np.arange(pnts.shape[0]), indxs), size=2, replace=False)])]

    # pnts = np.array([[17, 4, 140], [25, 6, 203], [36, 31, 230], [42,34, 402], [45,18,520], [62,63,650]])
    pnts = pnts[0:len(fitfnc(0,0))]
    # pnts = pnts[rand.choice(pnts.shape[0], size=len(fitfnc(0,0)), replace=False)]

    print("[Info] points used for fit: \n", pnts)
    dataZ = pnts[:,2]
    # dataX = np.array([[x**2, y**2, x*y, x, y, 1] for x, y, z in pnts])
    # dataX = np.array([[x**2, y**2, 1] for x, y, z in pnts])
    dataX = np.array([fitfnc(x,y) for x, y, z in pnts])

    # print(dataX)
    dataXinv = np.linalg.inv(dataX)
    coefs = dataXinv.dot(dataZ)
    # print(coefs)
    return coefs

def fit_lin(pnts):
    # function not written by myself
    """
    lincfs = planeFit(points)

    Given an array, points, of shape (d,...)
    representing points in d-dimensional space,
    fit an d-dimensional plane to the points.
    Return linear coefficients of plane in coordinate form.
    """

    pnts = np.reshape(pnts, (np.shape(pnts)[0], -1)) # Collapse trialing dimensions
    assert pnts.shape[0] <= pnts.shape[1], "There are only {} points in {} dimensions.".format(pnts.shape[1], pnts.shape[0])
    ctr = pnts.mean(axis=1)
    x = pnts - ctr[:,np.newaxis]
    M = np.dot(x, x.T) # Could also use np.cov(x) here.
    normal = svd(M)[0][:,-1]
    lincfs = normal
    d = 0
    for i in range(3):
        d += ctr[i]*-normal[i]
    lincfs = np.append(lincfs, d)
    return lincfs

def yburnvsv0(vrng=[[0, 200], [-500, 0]], step=10, k=20, savefile=True):
    """
    Simulate hoverslam distance in y dir for given range of v0.
    arg: vrng -> Range of v0s to simulate. Index 0 is x, index 1 is y.
    arg: step -> v0 resolution of calculation.
    arg: k    -> lift coefficient of rocket. F/m
    arg: savefile -> save return values of this function to points.npy.
    return: vx, vy, yburn -> np arrays of, from vrng calced v0 and y 
                             burn distances.
    """
    
    from tqdm import tqdm
    
    # ensuring vrng values are right to make it easy with reshaping etc
    for i in [0, 1]:
        if vrng[i][1] < vrng[i][0]:
            print(f"[Warn]: vrng[0] > vrng[1] at axis {i}. Swapping them...")
            vrng[i][0], vrng[i][1] = vrng[i][1], vrng[i][0]
        if (vrng[i][1]-vrng[i][0])%step != 0:
            vrng[i][1] -= (vrng[i][1]-vrng[i][0])%step
            print(f"[Warn]: range at axis {i} is not dividible by step! Resetting vrng[1]")
    
    # prepare data storage
    vx = np.arange(vrng[0][0], vrng[0][1]+1, step) # horizontal
    vy = np.arange(vrng[1][0], vrng[1][1]+1, step) # veticalS
    vy, vx = np.meshgrid(vy, vx) # dont know why y has to come first
    vx, vy = vx.flatten(), vy.flatten()
    yburn = np.empty(shape=(len(vx)))

    # calculate yburn values
    print(f"[Info]: Calculating burn distances at k={k}:")
    for i, x in enumerate(tqdm(vx)):
        y = vy[i]
        res = land(v0=[x, y], k=k)
        try:
            yburn[i] = res["yburndist"]
        except KeyError:
            print("KeyError! ", x, y)

    yburn[np.isnan(yburn)] = 0

    # doesnt look very well
    reshx = ((vrng[0][1]-vrng[0][0])/step)+1
    reshy = ((vrng[1][1]-vrng[1][0])/step)+1
    reshx, reshy = int(reshx), int(reshy)
    vx = vx.reshape(reshx, reshy)
    vy = vy.reshape(reshx, reshy)
    yburn = yburn.reshape(reshx, reshy)

    if savefile == True:
        with open("points.npy", "wb") as f:
            np.save(f, np.array([vx, vy, yburn]))
    return vx, vy, yburn

def plot3d(vx, vy, z):
    """plot 3d data with matplotlib"""
    fig, ax = plt.subplots(subplot_kw={"projection": "3d"})
    for a in z:
        ax.plot_surface(vx, vy, a)
    ax.set_xlabel('$X$ (hori speed)')
    ax.set_ylabel('$Y$ (vert speed)')
    plt.show()

def arrmrg(*x):
    """
    Merges n numpy arrays of shape (i, j) to 1 of shape (i*j, n)
    """
    return np.array([x[i].flatten() for i in range(len(x))]).transpose()

def simplot(loadf=True, whatplot=3, fitfnc=lambda x,y : [x**2, y**2]):
    """ 
    Sim yburn in dependance of v0, fit quad and lin func 
    and plot data.

    arg loadf: sim with yburnvsv0 (False) or load data from file (True)  
    arg whatplot: print 3d (3) or heatmap (2) or nothing (any)
    """
    if loadf:
        with open("points.npy", "rb") as file:
            vx, vy, yburn = np.load(file)
    else:
        vx, vy, yburn = yburnvsv0(k=60)

    # lincfs = fit_lin([vx.flatten(), vy.flatten(), yburn.flatten()])
    quadcfs = fit_quad(arrmrg(vx, vy, yburn), fitfnc=fitfnc)

    # Zlin  = (-lincfs[3] - lincfs[0]*vx - lincfs[1]*vy) / lincfs[2]
    Zquad = np.array([(np.array(fitfnc(x,y))*quadcfs).sum() for x, y in arrmrg(vx, vy)])
    Zquad = Zquad.reshape(vx.shape)

    if whatplot == 3:
        plot3d(vx, vy, [yburn, Zquad])

    elif whatplot == 2:
        diff = abs(Zquad-yburn)
        # print(np.nanmax(yburn), np.nanmin(yburn))
        # clev = np.arange(np.nanmin(yburn), np.nanmax(yburn),10) #Adjust the .001 to get finer gradient
        # plt.contourf(vx, vy, yburn, clev, cmap=plt.cm.coolwarm)
        clev = np.arange(np.nanmin(diff), np.nanmax(diff),5) #Adjust the .001 to get finer gradient
        plt.contourf(vx, vy, diff, levels=clev)
        titlestr = f"Quadratic function fitted to numeric data\ncoefs: {quadcfs}"
        # titlestr = titlestr.join([ []])
        plt.title(titlestr)
        plt.colorbar()
        plt.show()

def k_sim(fitfnc=lambda x,y : [x**2, y**2, x*y, x, y]): # TODO besseren Namen einfalllen lassen
    """
    Simulate suicide burn for different F/m values at different 
    initial velocities and fit functions to it.
    arg: fitfnc -> A function on x and y. returns list e.g. [x**2, y**2] 
    """
    plotcfsmode = 1
    k_list = [15, 20, 25, 30, 40, 50, 60, 70]
    # k_list = [20, 40, 70]
    #        datao, cfs, data
    resdict = {"datao": [],
                "cfs": [],
                "datan": [],
                "k": [],
                "diff": [],
                "avgdiff": []
            }
    
    # calculate suicide burn for different ks at different v0s
    for k in k_list:
        # not begin vrange with zero here because of singular matrix err in quadfit
        vx, vy, yburn = yburnvsv0(vrng=[[1, 200], [-400, -1]], step=20, k=k)
        arg = np.array([vx.flatten(), vy.flatten(), yburn.flatten()]).transpose()
        cfs = fit_quad(arg, fitfnc=fitfnc)
        Z = np.array([(np.array(fitfnc(x,y))*cfs).sum() for x, y in arrmrg(vx, vy)])
        Z = Z.reshape(vx.shape)
        resdict["datao"].append(yburn)
        resdict["cfs"].append(cfs)
        resdict["datan"].append(Z)
        resdict["k"].append(k)
        resdict["diff"].append(abs(Z-yburn))
        resdict["avgdiff"].append(np.average(abs(Z-yburn)))

    with open("hslamcoefs.csv", "w") as f:
        f.write("F/m,x**2,y**2,x*y,x,y,avgError\n")
        for i, k in enumerate(resdict["k"]):
            f.write(",".join([str(k)]
                            +[str(cf) for cf in resdict["cfs"][i]]
                            +[str(resdict["avgdiff"][i])])
                        +"\n")

    print(resdict["k"])
    print(resdict["cfs"])
    
    if plotcfsmode == 1:
        fig, ax = plt.subplots(2,3)
        # x²
        ax[0, 0].plot(resdict["k"], [c[0] for c in resdict["cfs"]])
        ax[0, 0].set_title("coefficient for x² vs k (F/m)")
        # y²
        ax[0, 1].plot(resdict["k"], [c[1] for c in resdict["cfs"]])
        ax[0, 1].set_title("coefficient for y² vs k (F/m)")
        # xy
        ax[0, 2].plot(resdict["k"], [c[2] for c in resdict["cfs"]])
        ax[0, 2].set_title("coefficient for xy vs k (F/m)")
        # x
        ax[1, 0].plot(resdict["k"], [c[3] for c in resdict["cfs"]])
        ax[1, 0].set_title("coefficient for x vs k (F/m)")
        # y
        ax[1, 1].plot(resdict["k"], [c[4] for c in resdict["cfs"]])
        ax[1, 1].set_title("coefficient for y vs k (F/m)")

        ax[1, 2].plot(resdict["k"], resdict["avgdiff"])
        ax[1, 2].set_title("Error to real data")
        plt.show()
    else:
        plot3d(vx, vy, 
            resdict["datao"] + resdict["datan"])
    
# simplot(loadf=False, whatplot=3)
k_sim()
