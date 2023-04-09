import numpy as np
import scipy.optimize
import matplotlib.pyplot as plt

with open("points.npy", "rb") as file:
    datapoints = np.load(file)

# print(datapoints)

# P = np.random.rand(3,10) # given point set
ocfs = np.array([4, 4, 2, 2, 2, 10])
vx = np.arange(-10, 10, 1) # horizontal
vy = np.arange(-10, 10, 1) # veticalS
vx, vy = np.meshgrid(vx, vy)
Zorg = (ocfs[0]*vx**2
        + ocfs[1]*vy**2
        + ocfs[2]*vx*vy
        + ocfs[3]*vx
        + ocfs[4]*vy
        + ocfs[5])
# Zorg = datapoints[2]
print(np.shape(Zorg))
# print(np.shape(P), np.shape(datapoints))

def quadratic(x,y, a, b, c, d, e, f): 
    #fit quadratic surface
    return a*x**2 + b*y**2 + c*x*y + d*x + e*y + f

def residual(params, pnts):
    #total residual
    residuals = [
      p[2] - quadratic(p[0], p[1],
                       params[0], params[1], params[2], params[3], params[4], params[5]) for p in pnts]

    return np.linalg.norm(residuals)

def fit_quad(pnts):
    """
    Calculate quadratic Function for given set of data, by solving system
    of linear equations.

    param:   numpy array pnts of shape (>=6, 3)
    returns: numpy array coefs of shape (6, )
    """
    pnts = pnts[np.random.choice(pnts.shape[0], size=6, replace=False)]
    # np.random.shuffle(pnts)
    # print(pnts)
    dataZ = pnts[:,2]
    dataX = np.array([[x**2, y**2, x*y, x, y, 1] for x, y, z in pnts])
    # print(np.linalg.det(dataX))
    # print(dataX)
    # print(dataZ)
    # print("shape of X: ", np.shape(dataX))
    # print(dataX.dot(ocfs))
    dataXinv = np.linalg.inv(dataX)
    coefs = dataXinv.dot(dataZ)
    # print(coefs)
    return coefs

print(np.array([ar.flatten() for ar in datapoints]))
# quadcfs = fit_quad(np.transpose(np.array([vx.flatten(), vy.flatten(), Zorg.flatten()])))
quadcfs = fit_quad(np.array([ar.flatten() for ar in datapoints]).transpose())

vx = datapoints[0]
vy = datapoints[1]
Zorg = datapoints[2]

# args = [vx.flatten(), vy.flatten(), Zorg.flatten()]
# result = scipy.optimize.minimize(residual, 
#                                  (1, 1, 0, 0, 0, 0),#starting params
#                                  args=args)
# print(result)
# quadcfs = result["x"]

Znew = (quadcfs[0]*vx**2
         + quadcfs[1]*vy**2
         + quadcfs[2]*vx*vy
         + quadcfs[3]*vx
         + quadcfs[4]*vy
         + quadcfs[5])

print(np.shape(datapoints[2]))
fig, ax = plt.subplots(subplot_kw={"projection": "3d"})
ax.plot_surface(vx, vy, Zorg, color="blue")
ax.plot_surface(vx, vy, Znew, color="red")
ax.set_xlabel('$X$ (hori speed)')
ax.set_ylabel('$Y$ (vert speed)')

plt.show()
