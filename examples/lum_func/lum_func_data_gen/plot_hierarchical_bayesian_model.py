# Using Daft python package (http://daft-pgm.org/)
# Executing: python plot_hierarchical_bayesian_model.py

import daft
from matplotlib import rc

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

pgm = daft.PGM([3.4, 1.9], origin=[0.5, 0.0])

pgm.add_node(daft.Node("theta", r"$\theta$", 1.0, 1.0))

pgm.add_node(daft.Node("characteristic", r"$\chi_i$", 2.0, 1.0))

pgm.add_node(daft.Node("data", r"$D_i$", 3.0, 1.0))

pgm.add_edge("theta", "characteristic")

pgm.add_edge("characteristic", "data")

pgm.add_plate(daft.Plate([1.5, 0.5, 2.0, 1.0], label=r"$N$", shift=-0.1, label_offset=[100,5]))

# Render and save.
pgm.render()
pgm.figure.savefig("hierarchical_bayesian_model.png")