/*
 * lumfunchm.cu
 *
 *  Created on: July 22, 2014
 *      Author: Janos M. Szalai-Gindl
 *
 *
 */

// standard library includes
#include <iostream>
#include <time.h>

// local CUDAHM includes
#include "../../../mwg/src/GibbsSampler.hpp"
#include "../../../mwg/src/kernels.cu"
#include "../../../data_proc_util/src/input_output.cpp"
#include "LumFuncPopPar.cuh"
#include "LumFuncDaug.cuh"

// known dimensions of features, characteristics and population parameter
const int mfeat = 1;
const int pchi = 1;  // chi = flux
const int dtheta = 3;

// compute the conditional log-posterior density of the measurements given the characteristic
__device__
double LogDensityMeas(double* chi, double* meas, double* meas_unc)
{
	double chi_std = (meas[0] - chi[0]) / meas_unc[0];
	double logdens = -0.5 * chi_std * chi_std;
	return logdens;
}

__device__ __host__
double min_double()
{
	// const unsigned long long ieee754mindouble = 0xffefffffffffffff;
	// return __longlong_as_double(ieee754mindouble);
	// we choose the next double for minimal double because of technical reason:
	// (If we summarize (more than one) ieee754mindoubles we get NaN result.)
	return -1.797693e+250;
}

// helper funtion for used by LogDensityPop to compute the log-density of flux | theta
__device__ __host__
double computeFluxLogDensWithPopPars(double gamma, double lScale, double uScale,
									 double dist, double chiElem)
{
	double result;	
	double x = 4 * CR_CUDART_PI * dist * dist * chiElem;
	if (x > 0)
	{
		double logChiDependentPart = log(1 - exp(-x / lScale)) + gamma * (log(x) - log(uScale)) - (x / uScale);
		result = /*logCoef +*/ logChiDependentPart;
	}
	else
	{
		result = min_double();
	}
	return result;
}

// NOT USED
__device__
double LogDensityPop(double* chi, double* theta)
{
	// this function is not used in fact
	return 0.0;
}

/*
 * This function returns the logarithm of the conditional density of the characteristics given the
 * population parameter theta for a single data point, log p(chi_i | theta).
 */
__device__
double LogDensityPopAux(double* chi, double* theta, double dist)
{
	double result = computeFluxLogDensWithPopPars(theta[0], theta[1], theta[2], dist, chi[0]);
	return result;
}

/*
 * Pointers to the device-side functions used to compute the conditional log-densities. These functions must be defined by the
 * user, as above.
 */
__constant__ pLogDensMeas c_LogDensMeas = LogDensityMeas;  // log p(y_i|chi_i)
__constant__ pLogDensPop c_LogDensPop = LogDensityPop;  // log p(chi_i|theta)
__constant__ pLogDensPopAux c_LogDensPopAux = LogDensityPopAux;// log p(chi_i|theta)

extern __constant__ double c_theta[100];

int main(int argc, char** argv)
{
	DistDataAdapter dataAdapter;
	// allocate memory for measurement arrays
	vecvec meas;
	vecvec meas_unc;
	std::string filename(argv[1]);
	int ndata = dataAdapter.get_file_lines(filename);

	//ndata = 1000;

    // read in measurement data from text file
    dataAdapter.read_data(filename, meas, meas_unc, ndata, mfeat, false);
    std::cout << "Loaded " << ndata << " data points." << std::endl;
	
	std::string distFilename(argv[2]);
	std::vector<double> distData(ndata);
	dataAdapter.load_dist_data(distFilename,distData,ndata);

	// build the MCMC sampler
	int niter = 1000000;
    int nburnin = niter / 2;
    int nchi_samples = 50;  // only keep 50 samples for the chi values to control memory usage and avoid numerous reads from GPU
    int nthin_chi = niter / nchi_samples;

	// first create pointers to instantiated subclassed DataAugmentation and PopulationPar objects, since we need to give them to the
	// constructor for the GibbsSampler class.
	boost::shared_ptr<DataAugmentation<mfeat, pchi, dtheta> > LFD(new LumFuncDaug<mfeat, pchi, dtheta>(meas, meas_unc));
	thrust::device_vector<double> d_distData;
	d_distData.resize(ndata);
	thrust::copy(distData.begin(),distData.end(),d_distData.begin());
	boost::shared_ptr<PopulationPar<mfeat, pchi, dtheta> > LFPP(new LumFuncPopPar<mfeat, pchi, dtheta>(ndata,d_distData));

	// instantiate the Metropolis-within-Gibbs sampler object
    GibbsSampler<mfeat, pchi, dtheta> Sampler(LFD, LFPP, niter, nburnin, nthin_chi);

    // launch the MCMC sampler
    Sampler.Run();

    // grab the samples
    vecvec theta_samples = Sampler.GetPopSamples();  // vecvec is a typedef for std::vector<std::vector<double> >
    std::vector<vecvec> chi_samples = Sampler.GetCharSamples();

    std::cout << "Writing results to text files..." << std::endl;

    // write the sampled theta values to a file. Output will have nsamples rows and dtheta columns.
    std::string thetafile("lumfunc_thetas.dat");
    dataAdapter.write_thetas(thetafile, theta_samples);

    // write the posterior means and standard deviations of the characteristics to a file. output will have ndata rows and
    // 2 * pchi columns, where the column format is posterior mean 1, posterior sigma 1, posterior mean 2, posterior sigma 2, etc.
    std::string chifile("lumfunc_chi_summary.dat");
    dataAdapter.write_chis(chifile, chi_samples);
}