#include "cuda_runtime.h"
#include "device_launch_parameters.h"

#include <thrust/device_vector.h>
#include <thrust/host_vector.h>

#include <thrust/random/linear_congruential_engine.h>
#include <thrust/random/normal_distribution.h>

#include <thrust/generate.h>
#include <thrust/sort.h>
#include <thrust/copy.h>

//#include <thrust/transform_reduce.h>
//#include <thrust/functional.h>

//#include <algorithm>
//#include <cstdlib>

#include <vector>

typedef thrust::device_vector<double> dvec;
typedef std::vector<dvec> vdvec;

struct wrapvec
{
	vdvec v;

	wrapvec(int m, int n) : v(m)
	{
		for (int i=0; i<m; i++)	{			
			v[i].reserve(n);
		}
	}

	double** ptrs()
	{
		thrust::host_vector<double*> h_ptr(v.size());
		for (unsigned int i=0; i<v.size(); i++)	
			h_ptr[i] = (double*) thrust::raw_pointer_cast(&(v[i][0]));

		thrust::device_vector<double*> d_ptr = h_ptr;
		return (double**) thrust::raw_pointer_cast(&d_ptr[0]); 
	}
};



// constants for integration
static __constant__ double c_absc[] = {
	-3.4361591188377352, -2.5327316742327906, -1.756683649299881, -1.0366108297895147,
	-0.34290132722370503, 0.34290132722370431, 1.0366108297895129, 1.7566836492998816,
	2.5327316742327901, 3.4361591188377369 }; 

static __constant__ double c_wts[] = { 
	4.3106526307180023e-06, 0.00075807093431224217, 0.01911158050077038, 0.13548370298026716,
	0.34464233493201829, 0.34464233493201879, 0.13548370298026738, 0.019111580500770171,
	0.00075807093431222135, 4.3106526307190323e-06 }; 


__device__ __host__
double rho(double r)
{
	return 1;
}


__global__
void marginals(double *theta, int d, double **features, double **sigmas, int m, int n, double *marg)
{
	int i = blockDim.x * blockIdx.x + threadIdx.x;
	if (i<n)
	{
		double mu = theta[0];
		marg[i] = mu * c_wts[3] * rho(mu);
	}
}
	  
/*
struct log_marginal
{
	double mu, var;
	
	log_marginal(double m, double v) {
		mu = m;
		var = v;
	}

    __host__ __device__
    double operator()(double fhat) const { 
		double l = 0;
		double sigma = 1;

		for (int i=0; i<10; i++)
		{
			double f = fhat + sigma * 1; //absc[i];
			double d = f - mu;
			l += exp(-d*d/var/2) / sigma * 1; // * wts[i];
		}

		return log(l);
    }
};
*/

int main(void)
{
	// measurements
	int n = 10; // # of items
	int m = 2; // # of features
	wrapvec d_features(m,n);
	wrapvec d_sigmas(m,n);
	/*
	unsigned int seed = 9872498732;
	static thrust::minstd_rand rng(seed);
	thrust::random::experimental::normal_distribution<double> dist(0.0, 1.0);
	// thrust::generate(d_vec.begin(), d_vec.end(), dist(rng));
	*/

	// alloc mem for marginals
	thrust::device_vector<double> d_marg(n);

	// theta (shd be broadcasted, too?)
	thrust::device_vector<double> d_theta(2);

	// init, etc
	d_theta[0] = 1;
	d_theta[1] = 2;
	// cudaMemcpyToSymbol(c_theta, p_theta, d_theta.size() * sizeof(*p_theta));
	{
		// log marginal likelhoods in parallel on all threads independently
		//thrust::transform(d_fhat.begin(), d_fhat.end(), d_marg.begin(), log_marginal(mu,var));	  
		double* p_marg = thrust::raw_pointer_cast(&d_marg[0]);
		double* p_theta = thrust::raw_pointer_cast(&d_theta[0]);
		double** p_features = d_features.ptrs();
		double** p_sigmas = d_sigmas.ptrs();

		// cuda grid launch
		int nThreads = 256;
		int nBlocks = (n + nThreads-1) / nThreads;
		marginals<<<nBlocks,nThreads>>>(p_theta,d_theta.size(), p_features,p_sigmas,m,n, p_marg);
		// wait for it to finish
		cudaError_t err = cudaDeviceSynchronize();

		// sum up
		double log_marg = thrust::reduce(d_marg.begin(), d_marg.end());

		std::cout << log_marg << std::endl;
	}
	  
	return 0;

}

/*
int main(void)
{
    // initialize host array
    float x[4] = {1.0, 2.0, 3.0, 4.0};

    // transfer to device
    thrust::device_vector<float> d_x(x, x + 4);

    // setup arguments
    square<float>        unary_op;
    thrust::plus<float> binary_op;
    float init = 0;

    // compute norm
    float norm = std::sqrt( thrust::transform_reduce(d_x.begin(), d_x.end(), unary_op, init, binary_op) );

    std::cout << norm << std::endl;

    return 0;
}
*/