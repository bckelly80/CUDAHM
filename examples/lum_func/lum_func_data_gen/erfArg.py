# executing e.g. python erfArg.py --pdf_format False

import argparse as argp
import numpy as np
from matplotlib.pyplot import *
from scipy.special import erf

parser = argp.ArgumentParser()
parser.add_argument("--T", default = 5.0, help="The flux limit", type=float)
parser.add_argument("--sig0", default = 1.0, help="The sigma0", type=float)
parser.add_argument("--c", default = 6.0, help="The erf limit", type=float)
parser.add_argument("--pdf_format", default = 'True', help="Would you like pdf format and high resolution for the figure output(s)?", type=str)

args = parser.parse_args()
T = args.T
sig0 = args.sig0
c = args.c
pdf_format = eval(args.pdf_format)

execfile("rc_settings.py")
if(pdf_format!=True):
  rc('savefig', dpi=100)

def IE(flux):
  return (flux - T) / np.sqrt(2.0*(sig0**2 + (0.01*flux)**2))

xlin = np.linspace(-200, 1000, 300)

vals = []
for flux in xlin:
  vals.append(IE(flux))

fig = figure()
tit = r'The argument function of error function with flux limit: %5.2f, $\sigma_{0}$: %5.2f and c: %5.2f' % (T, sig0, c)
#fig.suptitle(tit, fontsize=18, fontweight='bold')

ax = fig.add_subplot(1,1,1,xlim = [-200,1000],ylim = [-80,80]) # one row, one column, first plot
ax.set_xlabel(r'$\chi$')
ax.axvline(x = 0, color='black', linewidth=2, linestyle='-')

lbl_0 = r'$\frac{\chi - T}{\sqrt{2\cdot(\sigma_{0}^2 + (0.01\chi)^2)}}$'
ax.plot(xlin, vals, 'b--', linewidth=3, linestyle='-', label=lbl_0, zorder=3)

lbl_1 = r'$\frac{1}{0.01\sqrt{2}}$'
ax.axhline(y = 1/(0.01*np.sqrt(2.0)), color='red', linewidth=2, linestyle='--', label=lbl_1)

lbl_2 = r'$c$'
ax.axhline(y = c, color='green', linewidth=2, linestyle='-', label=lbl_2)

lbl_3 = r'$\frac{T+\sqrt{2}c\cdot \sqrt{(1-2(0.01)^2 c^2)\sigma_{0}^2 + (0.01)^2 T^2}}{1-2(0.01)^2 c^2}$'
ax.axvline(x = (T + np.sqrt(2.0)*c*np.sqrt((1.0-2.0*((0.01)**2)*(c**2))*(sig0**2) + ((0.01)**2)*(T**2)))/(1.0-2.0*((0.01)**2)*(c**2)), color='m', linewidth=2, linestyle=':', label=lbl_3)

legend(loc=0)

xlinerf = np.linspace(-7.0, 7.0, 300)
erfvals = []
for erfinput in xlinerf:
  erfvals.append(erf(erfinput))

a = axes([.65, .65, .18, .18])
plot(xlinerf, erfvals, 'r--', linewidth=1, linestyle='-', zorder=3)
annotate('c', xy=(c, 0),  xycoords='data', xytext=(-20, -20), textcoords='offset points', color='green',
                arrowprops=dict(arrowstyle="->"), zorder=4, family='Computer Modern Roman', fontsize=12)
axvline(x = c, color='green', linewidth=1, linestyle='-') 

xlim([-7.0, 7.0]) 
lims = ylim()
ylim([lims[0]-0.5, lims[1]+0.5])

title('Error function', family='Computer Modern Roman', fontsize=12)
setp(a, xticks=[], yticks=[])

if(pdf_format):
  savefig('erfArg.pdf', format='pdf')
else:
  savefig('erfArg.png')