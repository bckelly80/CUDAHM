/*
 * DataAugmentation.cu
 *
 *  Created on: Jul 28, 2013
 *      Author: brandonkelly
 */

// local includes
#include "parameters.hpp"

// Global random number generator and distributions for generating random numbers on the host. The random number generator used
// is the Mersenne Twister mt19937 from the BOOST library.
boost::random::mt19937 rng;
boost::random::normal_distribution<> snorm(0.0, 1.0); // Standard normal distribution
boost::random::uniform_real_distribution<> uniform(0.0, 1.0); // Uniform distribution from 0.0 to 1.0

DataAugmentation::DataAugmentation(double** meas, double** meas_unc, int n, int m, int p, dim3& nB, dim3& nT) :
ndata(n), mfeat(m), pchi(p), nBlocks(nB), nThreads(nT)
{
	_SetArraySizes();

	// copy input data to data members
	for (int j = 0; j < mfeat; ++j) {
		for (int i = 0; i < ndata; ++i) {
			h_meas[ndata * j + i] = meas[i][j];
			h_meas_unc[ndata * j + i] = meas_unc[i][j];
		}
	}
	// copy data from host to device
	d_meas = h_meas;
	d_meas_unc = h_meas_unc;

	thrust::fill(h_cholfact.begin(), h_cholfact.end(), 0.0);
	d_cholfact = h_cholfact;

	// Allocate memory on GPU for RNG states
	CUDA_CHECK_RETURN(cudaMalloc((void **)&p_devStates, nThreads.x * nBlocks.x * sizeof(curandState)));
	// Initialize the random number generator states on the GPU
	initialize_rng<<<nBlocks,nThreads>>>(p_devStates);
	CUDA_CHECK_RETURN(cudaPeekAtLastError());
	// Wait until RNG stuff is done running on the GPU, make sure everything went OK
	CUDA_CHECK_RETURN(cudaDeviceSynchronize());

	// grab pointers to the device vector memory locations
	double* p_chi = thrust::raw_pointer_cast(&d_chi[0]);
	double* p_meas = thrust::raw_pointer_cast(&d_meas[0]);
	double* p_meas_unc = thrust::raw_pointer_cast(&d_meas_unc[0]);
	double* p_cholfact = thrust::raw_pointer_cast(&d_cholfact[0]);
	double* p_logdens = thrust::raw_pointer_cast(&d_logdens[0]);

	// set initial values for the characteristics. this will launch a CUDA kernel.
	initial_chi_value<<<nBlocks,nThreads>>>(p_chi, p_meas, p_meas_unc, p_cholfact, p_logdens, ndata,
			mfeat, pchi);
	CUDA_CHECK_RETURN(cudaDeviceSynchronize());

	// copy values from device to host
	h_chi = d_chi;

	h_cholfact = d_cholfact;
	h_logdens = d_logdens;

	thrust::fill(h_naccept.begin(), h_naccept.end(), 0);
	d_naccept = h_naccept;
	current_iter = 1;
}

void DataAugmentation::Update()
{
	// grab the pointers to the device memory locations
	double* p_chi = thrust::raw_pointer_cast(&d_chi[0]);
	double* p_meas = thrust::raw_pointer_cast(&d_meas[0]);
	double* p_meas_unc = thrust::raw_pointer_cast(&d_meas_unc[0]);
	double* p_cholfact = thrust::raw_pointer_cast(&d_cholfact[0]);
	double* p_logdens_meas = thrust::raw_pointer_cast(&d_logdens[0]);
	double* p_logdens_pop = p_Theta->GetDevLogDensPtr();
	double* p_devtheta = p_Theta->GetDevThetaPtr();
	int* p_naccept = thrust::raw_pointer_cast(&d_naccept[0]);
	int dim_theta = p_Theta->GetDim();

	// launch the kernel to update the characteristics on the GPU
	update_characteristic<<<nBlocks,nThreads>>>(p_meas, p_meas_unc, p_chi, p_devtheta, p_cholfact, p_logdens_meas,
			p_logdens_pop, p_devStates, current_iter, p_naccept, ndata, mfeat, pchi, dim_theta);
	CUDA_CHECK_RETURN(cudaPeekAtLastError());
    CUDA_CHECK_RETURN(cudaDeviceSynchronize());
    current_iter++;
}

void DataAugmentation::SetChi(dvector& chi, bool update_logdens)
{
	d_chi = chi;
	h_chi = d_chi;
	if (update_logdens) {
		// update the posteriors for the new values of the characteristics
		double* p_meas = thrust::raw_pointer_cast(&d_meas[0]);
		double* p_meas_unc = thrust::raw_pointer_cast(&d_meas_unc[0]);
		double* p_chi = thrust::raw_pointer_cast(&d_chi[0]);
		double* p_logdens_meas = thrust::raw_pointer_cast(&d_logdens[0]);
		// first update the posteriors of measurements | characteristics
		logdensity_meas<<<nBlocks,nThreads>>>(p_meas, p_meas_unc, p_chi, p_logdens_meas, ndata, mfeat, pchi);
		CUDA_CHECK_RETURN(cudaPeekAtLastError());
		double* p_theta = p_Theta->GetDevThetaPtr();
		int dim_theta = p_Theta->GetDim();
		double* p_logdens_pop = p_Theta->GetDevLogDensPtr();
		// no update the posteriors of the characteristics | population parameter
		logdensity_pop<<<nBlocks,nThreads>>>(p_theta, p_chi, p_logdens_pop, ndata, pchi, dim_theta);
		CUDA_CHECK_RETURN(cudaPeekAtLastError());
		CUDA_CHECK_RETURN(cudaDeviceSynchronize());
	}
}

vecvec DataAugmentation::GetChi()
{
	vecvec chi(ndata);
	// grab values of characteristics from host vector
	for (int i = 0; i < ndata; ++i) {
		std::vector<double> chi_i(pchi);
		for (int j = 0; j < pchi; ++j) {
			chi_i[j] = h_chi[ndata * j + i];
		}
		chi[i] = chi_i;
	}
	return chi;
}

void DataAugmentation::_SetArraySizes()
{
	h_meas.resize(ndata * mfeat);
	d_meas.resize(ndata * mfeat);
	h_meas_unc.resize(ndata * mfeat);
	d_meas_unc.resize(ndata * mfeat);
	h_logdens.resize(ndata);
	d_logdens.resize(ndata);
	h_chi.resize(ndata * pchi);
	d_chi.resize(ndata * pchi);
	int dim_cholfact = pchi * pchi - ((pchi - 1) * pchi) / 2;
	h_cholfact.resize(ndata * dim_cholfact);
	d_cholfact.resize(ndata * dim_cholfact);
	h_naccept.resize(ndata);
	d_naccept.resize(ndata);
}

PopulationPar::PopulationPar(int dtheta, dim3& nB, dim3& nT) : dim_theta(dtheta), nBlocks(nB), nThreads(nT)
{
	// don't do anything with the GPU for this constructor
	h_theta.resize(dim_theta);
	snorm_deviate.resize(dim_theta);
	scaled_proposal.resize(dim_theta);
	int dim_cholfact = dim_theta * dim_theta - ((dim_theta - 1) * dim_theta) / 2;
	cholfact.resize(dim_cholfact);
	// set initial value of theta to zero
	thrust::fill(h_theta.begin(), h_theta.end(), 0.0);

	// set initial covariance matrix of the theta proposals as the identity matrix
	thrust::fill(cholfact.begin(), cholfact.end(), 0.0);
	int diag_index = 0;
	for (int k=0; k<dim_theta; k++) {
		cholfact[diag_index] = 1.0;
		diag_index += k + 2;
	}
	// reset the number of MCMC iterations
	current_iter = 1;
	naccept = 0;
}

PopulationPar::PopulationPar(int dtheta, DataAugmentation* D, dim3& nB, dim3& nT) :
	dim_theta(dtheta), Daug(D), nBlocks(nB), nThreads(nT)
{
	h_theta.resize(dim_theta);
	d_theta = h_theta;
	snorm_deviate.resize(dim_theta);
	scaled_proposal.resize(dim_theta);
	int dim_cholfact = dim_theta * dim_theta - ((dim_theta - 1) * dim_theta) / 2;
	cholfact.resize(dim_cholfact);

	int ndata = Daug->GetDataDim();
	pchi = Daug->GetChiDim();
	h_logdens.resize(ndata);
	d_logdens = h_logdens;

	InitialValue();

	// make sure that the data augmentation object knows about the population parameter object
	Daug->SetPopulationPtr(this);
}

virtual void PopulationPar::InitialValue()
{
	// set initial value of theta to zero
	thrust::fill(h_theta.begin(), h_theta.end(), 0.0);
	d_theta = h_theta;

	// set initial covariance matrix of the theta proposals as the identity matrix
	thrust::fill(cholfact.begin(), cholfact.end(), 0.0);
	int diag_index = 0;
	for (int k=0; k<dim_theta; k++) {
		cholfact[diag_index] = 1.0;
		diag_index += k + 2;
	}

	// get initial value of conditional log-posterior for theta|chi
	double* p_theta = thrust::raw_pointer_cast(&d_theta[0]);
	double* p_chi = Daug->GetDevChiPtr(); // grab pointer to Daug.d_chi
	double* p_logdens = thrust::raw_pointer_cast(&d_logdens[0]);
	int ndata = Daug->GetDataDim();
	logdensity_pop<<<nBlocks,nThreads>>>(p_theta, p_chi, p_logdens, ndata, pchi, dim_theta);
	CUDA_CHECK_RETURN(cudaPeekAtLastError());
    CUDA_CHECK_RETURN(cudaDeviceSynchronize());

    // copy initial values of logdensity to host
    h_logdens = d_logdens;

	// reset the number of MCMC iterations
	current_iter = 1;
	naccept = 0;
}

virtual hvector PopulationPar::Propose()
{
    // get the unit proposal
    for (int k=0; k<dim_theta; k++) {
        snorm_deviate[k] = snorm(rng);
    }

    // transform unit proposal so that is has a multivariate normal distribution
    hvector proposed_theta(dim_theta);
    thrust::fill(scaled_proposal.begin(), scaled_proposal.end(), 0.0);
    int cholfact_index = 0;
    for (int j=0; j<dim_theta; j++) {
        for (int k=0; k<(j+1); k++) {
        	// cholfact is lower-diagonal matrix stored as a 1-d array
            scaled_proposal[j] += cholfact[cholfact_index] * snorm_deviate[k];
            cholfact_index++;
        }
        proposed_theta[j] = h_theta[j] + scaled_proposal[j];
    }

    return proposed_theta;
}

virtual void PopulationPar::AdaptProp(double metro_ratio)
{
	double unit_norm = 0.0;
    for (int j=0; j<dim_theta; j++) {
    	unit_norm += snorm_deviate[j] * snorm_deviate[j];
    }
    unit_norm = sqrt(unit_norm);
    double decay_sequence = 1.0 / std::pow(current_iter, decay_rate);
    double scaled_coef = sqrt(decay_sequence * fabs(metro_ratio - target_rate)) / unit_norm;
    for (int j=0; j<dim_theta; j++) {
        scaled_proposal[j] *= scaled_coef;
    }

    bool downdate = (metro_ratio < target_rate);
    double* p_cholfact = thrust::raw_pointer_cast(&cholfact[0]);
    double* p_scaled_proposal = thrust::raw_pointer_cast(&scaled_proposal[0]);
    // rank-1 update of the cholesky factor
    chol_update_r1(p_cholfact, p_scaled_proposal, dim_theta, downdate);
}

virtual void PopulationPar::Update()
{
	// get current conditional log-posterior of population
	double logdens_current = thrust::reduce(d_logdens.begin(), d_logdens.end());
	logdens_current += LogPrior(h_theta);

	// propose new value of population parameter
	hvector h_proposed_theta = Propose();
	dvector d_proposed_theta = h_proposed_theta;
	double* p_proposed_theta = thrust::raw_pointer_cast(&d_proposed_theta[0]);

	// calculate log-posterior of new population parameter in parallel on the device
	int ndata = Daug->GetDataDim();
	//std::cout << "ndata: " << ndata << std::endl;
	dvector d_proposed_logdens(ndata);
	//std::cout << "size of d_proposed_logdens: " << d_proposed_logdens.size() << std::endl;
	//double* p_logdens_current = thrust::raw_pointer_cast(&d_logdens[0]);
	double* p_logdens_prop = thrust::raw_pointer_cast(&d_proposed_logdens[0]);

	logdensity_pop<<<nBlocks,nThreads>>>(p_proposed_theta, Daug->GetDevChiPtr(), p_logdens_prop, ndata,
			pchi, dim_theta);
	CUDA_CHECK_RETURN(cudaPeekAtLastError());
    CUDA_CHECK_RETURN(cudaDeviceSynchronize());
	double logdens_prop = thrust::reduce(d_proposed_logdens.begin(), d_proposed_logdens.end());

	logdens_prop += LogPrior(h_proposed_theta);

	// accept the proposed value?
	double metro_ratio = 0.0;
	bool accept = AcceptProp(logdens_prop, logdens_current, metro_ratio);
	if (accept) {
		h_theta = h_proposed_theta;
		d_theta = d_proposed_theta;
		d_logdens = d_proposed_logdens;
		naccept++;
	}

	// adapt the covariance matrix of the proposals
	AdaptProp(metro_ratio);
	current_iter++;
}

bool PopulationPar::AcceptProp(double logdens_prop, double logdens_current, double& ratio, double forward_dens,
		double backward_dens)
{
    double lograt = logdens_prop - forward_dens - (logdens_current - backward_dens);
    lograt = std::min(lograt, 0.0);
    ratio = exp(lograt);
    double unif = uniform(rng);
    bool accept = (unif < ratio) && isfinite(ratio);
    return accept;
}


void PopulationPar::SetTheta(dvector& theta, bool update_logdens)
{
	d_theta = theta;
	h_theta = theta;
	if (update_logdens) {
		// update value of conditional log-posterior for theta|chi
		double* p_theta = thrust::raw_pointer_cast(&d_theta[0]);
		double* p_chi = Daug->GetDevChiPtr(); // grab pointer to Daug.d_chi
		double* p_logdens = thrust::raw_pointer_cast(&d_logdens[0]);
		h_logdens = d_logdens;
		logdensity_pop<<<nBlocks,nThreads>>>(p_theta, p_chi, p_logdens, Daug->GetDataDim(), pchi, dim_theta);
		CUDA_CHECK_RETURN(cudaPeekAtLastError());
		h_logdens = d_logdens;
	}
}

