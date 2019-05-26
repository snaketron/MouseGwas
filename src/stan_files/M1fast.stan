functions {
  int num_matches(int[] x, int a) {
    int n = 0;
    for (i in 1:size(x))
      if (x[i] == a)
       n += 1;
    return n;
  }

  int[] which_equal(int[] x, int a) {
    int len = num_matches(x, a);
    // vector[len] match_positions;
    int match_positions[len];
    int pos = 1;
    for (i in 1:size(x)) {
      if (x[i] == a) {
        match_positions[pos] = x[i];
        pos += 1;
      }
    }
    return match_positions;
  }
}


data {
  int N; // number of all entries
  int Ntq; // number of traits
  int Ntd; // number of traits
  int Ns; // number of all SNPs
  int Nk; // number of all strains
  real Yq[N, Ntq] ; // number of hits response
  int Yd[N, Ntd] ; // number of hits response
  // vector [Ns] X [N]; // index of all individuals
  matrix [Ns, N] X; // index of all individuals
  int K[N]; //index to all strains
}

parameters {
  vector [Ntq+Ntd] alpha;
  vector [Ntq+Ntd] grand_mu_beta;
  vector <lower = 0> [Ntq] sigma;
  vector <lower = 0> [Ntq+Ntd] sigma_beta;
  vector <lower = 0> [Ntq+Ntd] nu;
  vector <lower = 2> [Ntq+Ntd] nu_help;
  matrix [Ns, Nk] z [Ntq+Ntd];
  matrix [Ntq+Ntd, Ns] grand_z;

}

transformed parameters {
  matrix [Ns, Nk] beta [Ntq+Ntd];
  matrix [Ntq+Ntd, Ns] mu_beta;

  for(s in 1:Ns) {
    for(t in 1:(Ntq+Ntd)) {
      mu_beta[t, s] = grand_mu_beta[t] + sqrt(nu_help[t]/nu[t])*grand_z[t,s];
    }
  }


  for(k in 1:Nk) {
    for(s in 1:Ns) {
      for(t in 1:(Ntq+Ntd)) {
        beta[t][s, k] = mu_beta[t, s] + z[t][s, k]*sigma_beta[t];
      }
    }
  }
}
//Exception: elt_multiply: Columns of m1 (5) and columns of m2 (1) must match in size  (in 'model1a48b7b95_M1fast' at line 78)
model {
  for(k in 1:Nk) {
    int ks_len = num_matches(K, k);
    int ks [ks_len] = which_equal(K, k);
    if(Ntq > 0) {
      for(t in 1:Ntq) {
        real Ytemp [ks_len] = Yq[ks, t];
        Ytemp ~ normal(to_vector((alpha[t] + X[, ks] .* to_matrix(beta[t][, k]))'), sigma[t]);
      }
    }
  }

  alpha ~ student_t(1, 0, 100);
  to_vector(grand_mu_beta) ~ student_t(1, 0, 10);

  sigma ~ cauchy(0, 5);
  sigma_beta ~ cauchy(0, 5);
  (nu_help-2) ~ exponential(0.5);
  nu ~ chi_square(nu_help);

  // priors on the dummy z's
  for(t in 1:(Ntq+Ntd)) {
    to_vector(z[t]) ~ normal(0, 1);
    grand_z[t, ] ~ normal(0, 1);
  }
}
