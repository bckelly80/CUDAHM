# executing e.g. python plot_thetas_funcs.py lumfunc_thetas.dat b-1.2_l1.0_u100.0_init_b-1.3_l5.0_u110.0_ (--lower_scale_factor 10000000000.0 --upper_scale_factor 1000000000000.0)
import argparse as argp
import numpy as np
from matplotlib.pyplot import *

parser = argp.ArgumentParser()
parser.add_argument("file", help="The file name of theta data file.", type = str)
parser.add_argument("prefix", help="The prefic for created output files.", type = str)
parser.add_argument("--lower_scale_factor", default = 1.0, help="The factor which scales up the lower scale samples", type=float)
parser.add_argument("--upper_scale_factor", default = 1.0, help="The factor which scales up the upper scale samples", type=float)

args = parser.parse_args()
file = args.file
prefix = args.prefix
lower_scale_factor = args.lower_scale_factor
upper_scale_factor = args.upper_scale_factor

# Wider margins to allow for larger labels; may need to adjust left:
rc('figure.subplot', bottom=.125, top=.95, right=.95)  # left=0.125

# Optionally make default line width thicker:
#rc('lines', linewidth=2.0) # doesn't affect frame lines

rc('font', size=14)  # default for labels (not axis labels)
rc('font', family='serif')  # default for labels (not axis labels)
rc('axes', labelsize=18)
rc('xtick.major', pad=8)
rc('xtick', labelsize=14)
rc('ytick.major', pad=8)
rc('ytick', labelsize=14)

rc('savefig', dpi=150)  # mpl's default dpi is 100
rc('axes.formatter', limits=(-4,4))

# Use TeX labels with CMR font:
rc('text', usetex=True)
rc('font',**{'family':'serif','serif':['Computer Modern Roman']})

theta_data=np.loadtxt(file,delimiter=' ',usecols=(0,1,2))
theta_data_beta=theta_data[:,0]
theta_data_l=theta_data[:,1]
theta_data_u=theta_data[:,2]

theta_data_l *= lower_scale_factor
theta_data_u *= upper_scale_factor

color_list = range(0, theta_data.shape[0])

for idx in range(0, theta_data.shape[0]):
    blue_rate = idx/float(theta_data.shape[0])
    red_rate = (1.0 - idx/float(theta_data.shape[0]))
    color_list[idx]=(red_rate*1.0,0.0,blue_rate*1.0)
    
lbl_beta = r'$\beta$'
lbl_lowerscale = 'lower scale'
lbl_upperscale = 'upper scale'
lbl_iter= 'Iterations'
	
fig, ax = subplots()
ax.scatter(range(1, len(theta_data_beta) + 1),theta_data_beta, c=color_list, marker = ".", linewidth=0.01)
ax.set_xlabel(lbl_iter)
ax.set_ylabel(lbl_beta)
savefig(prefix + 'beta.png')

fig, ax = subplots()
ax.scatter(range(1, len(theta_data_u) + 1),theta_data_u, c=color_list, marker = ".", linewidth=0.01)
ax.set_xlabel(lbl_iter)
ax.set_ylabel(lbl_upperscale)
savefig(prefix + 'upperscale.png')

fig, ax = subplots()
ax.scatter(range(1, len(theta_data_l) + 1),theta_data_l, c=color_list, marker = ".", linewidth=0.01)
ax.set_xlabel(lbl_iter)
ax.set_ylabel(lbl_lowerscale)
savefig(prefix + 'lowerscale.png')

fig, ax = subplots()
ax.scatter(theta_data_beta,theta_data_l, c=color_list, marker = ".", linewidth=0.01)
ax.set_xlabel(lbl_beta)
ax.set_ylabel(lbl_lowerscale)
savefig(prefix + 'beta_lowerscale.png')

fig, ax = subplots()
ax.scatter(theta_data_beta,theta_data_u, c=color_list, marker = ".", linewidth=0.01)
ax.set_xlabel(lbl_beta)
ax.set_ylabel(lbl_upperscale)
savefig(prefix + 'beta_upperscale.png')

fig, ax = subplots()
ax.scatter(theta_data_l,theta_data_u, c=color_list, marker = ".", linewidth=0.01)
ax.set_xlabel(lbl_lowerscale)
ax.set_ylabel(lbl_upperscale)
savefig(prefix + 'lowerscale_upperscale.png')