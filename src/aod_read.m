function [GM,ae,nmax, aod_Cnm, aod_Snm, aod_atm_Cnm, aod_atm_Snm, aod_ocn_Cnm, aod_ocn_Snm, aod_glo_Cnm, aod_glo_Snm, aod_oba_Cnm, aod_oba_Snm] = aod_read(aod_filename)


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Function :: aod_read 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Purpose:
%  Read the Atmosphere and Ocean De-Aliasing (AOD) Level-1B (AOD1B) product 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Input arguments:
% - aod_filename:       AOD filename
%
% Output arguments:
% - GM:                 Earth gravity constant  (m^3/sec^2)
% - ae:                 radius  (meters)
% - nmax:               Cnm and Snm matrices maximum degree
% - Cnm, Snm:           normalized spherical harmonics coefficients
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Dr. Thomas Loudis Papanikolaou                             2 October 2022
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Read .gfc file and format Cnm,Snm and sCnm,sSnm lower triangular matrices
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Remark:
% Coefficient Cnm corresponds to matrix element Cnm(n+1,m+1)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
fid = fopen(aod_filename);
while (~feof(fid))
    line_ith = fgetl(fid);
    str_test = sscanf(line_ith,'%s%1c%s %*');

    test = strcmp(str_test,'MAXIMUM DEGREE');
    if test == 1
      Nmax_aod = sscanf(line_ith,'%*s %*s %*s %d %*');
    end
    
    test = strcmp(str_test,'CONSTANT GM');
    if test == 1
      GM = sscanf(line_ith,'%*s %*s %*s %*s %f %*');
    end

    test = strcmp(str_test,'CONSTANT A');
    if test == 1
      constant_a = sscanf(line_ith,'%*s %*s %*s %*s %f %*');
    end
    
    test = strcmp(str_test,'CONSTANT FLAT');
    if test == 1
      constant_flat = sscanf(line_ith,'%*s %*s %*s %*s %f %*');
    end

    test = strcmp(str_test,'CONSTANT OMEGA');
    if test == 1
      constant_omega = sscanf(line_ith,'%*s %*s %*s %*s %f %*');
    end

    keyword_test = sscanf(line_ith,'%s%1c%s%1c%s%1c%s %*');
    test = strcmp(keyword_test,'NUMBER OF DATA SETS');
    if test == 1
      data_sets_number = sscanf(line_ith,'%*s %*s %*s %*s %*s %d %*');
    end
    
end
fclose(fid);
clear fid line_ith str1 test

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Ellipsoid variables
a = constant_a;
f = constant_flat;
e = sqrt(2*f - f^2);

ae = constant_a;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Arrays initialization
n_sz = Nmax_aod;
m_sz = Nmax_aod;

%data_sets_number

Cnm = zeros(n_sz+1,n_sz+1, data_sets_number);
Snm = zeros(n_sz+1,n_sz+1, data_sets_number);

aod_Cnm = zeros(n_sz+1,n_sz+1, data_sets_number);
aod_Snm = zeros(n_sz+1,n_sz+1, data_sets_number);

effect_data_sets_no = data_sets_number / 4;

aod_atm_Cnm = zeros(n_sz+1,n_sz+1, effect_data_sets_no);
aod_atm_Snm = zeros(n_sz+1,n_sz+1, effect_data_sets_no);

aod_ocn_Cnm = zeros(n_sz+1,n_sz+1, effect_data_sets_no);
aod_ocn_Snm = zeros(n_sz+1,n_sz+1, effect_data_sets_no);

aod_glo_Cnm = zeros(n_sz+1,n_sz+1, effect_data_sets_no);
aod_glo_Snm = zeros(n_sz+1,n_sz+1, effect_data_sets_no);

aod_oba_Cnm = zeros(n_sz+1,n_sz+1, effect_data_sets_no);
aod_oba_Snm = zeros(n_sz+1,n_sz+1, effect_data_sets_no);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Read Stokes coefficients
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
fid = fopen(aod_filename);
header_status = 1;
while (header_status == 1)
    line_ith = fgetl(fid);
    str_test = sscanf(line_ith,'%s%1c%s%1c%s %*');
    test = strcmp(str_test,'END OF HEADER');
    if test == 1
      header_status = 0;
    end    
end

while (~feof(fid))
    line_ith = fgetl(fid);
    keyword_data_set = sscanf(line_ith,'%s%1c%s %*');
    
    % Read individual data set information
    test_data_set_new = strcmp(keyword_data_set,'DATA SET');
    if test_data_set_new == 1
        data_set_No   = sscanf(line_ith,'%*s %*s %d %*');
        %data_set_coefficients_effect = sscanf(line_ith,'%s%c');
        [n1, Nchar] = size(line_ith);
        data_set_coefficients_effect = line_ith(1, Nchar-2 : Nchar);
    end    

    % Read and store Stokes coeffiecients of all data sets effects
    if test_data_set_new == 0
      n_i   = sscanf(line_ith,'%d %*');
      m_i   = sscanf(line_ith,'%*d %d %*');
      Cnm_i = sscanf(line_ith,'%*d %*d %f %*');
      Snm_i = sscanf(line_ith,'%*d %*d %*f %f %*');
      
      % Store coefficientsto overall 3dimensional matrices
      Cnm(n_i + 1, m_i + 1, data_set_No) = Cnm_i; 
      Snm(n_i + 1, m_i + 1, data_set_No) = Snm_i;  

      effect_data_set_i = fix(data_set_No / 4) + 1;
      
      % Store coeffiecients for ATM effect data set
      test_data_set_effect = strcmp(data_set_coefficients_effect,'atm');
      if test_data_set_effect == 1
          aod_atm_Cnm(n_i + 1, m_i + 1, effect_data_set_i) = Cnm_i; 
          aod_atm_Snm(n_i + 1, m_i + 1, effect_data_set_i) = Snm_i; 
      end
          
      % Store coeffiecients for OCN effect data set
      test_data_set_effect = strcmp(data_set_coefficients_effect,'ocn');
      if test_data_set_effect == 1
          aod_ocn_Cnm(n_i + 1, m_i + 1, effect_data_set_i) = Cnm_i; 
          aod_ocn_Snm(n_i + 1, m_i + 1, effect_data_set_i) = Snm_i; 
      end
    
      % Store coeffiecients for GLO effect data set
      test_data_set_effect = strcmp(data_set_coefficients_effect,'glo');
      if test_data_set_effect == 1
          aod_glo_Cnm(n_i + 1, m_i + 1, effect_data_set_i) = Cnm_i; 
          aod_glo_Snm(n_i + 1, m_i + 1, effect_data_set_i) = Snm_i;
      end
    
      % Store coeffiecients for OBA effect data set
      test_data_set_effect = strcmp(data_set_coefficients_effect,'oba');
      if test_data_set_effect == 1
          aod_oba_Cnm(n_i + 1, m_i + 1, effect_data_set_i) = Cnm_i; 
          aod_oba_Snm(n_i + 1, m_i + 1, effect_data_set_i) = Snm_i; 
      end
      
    end    
end
fclose(fid);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Overall matrices
aod_Cnm = Cnm;
aod_Snm = Snm;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% maximum degree (n) and order (m)
[nmax n2] = size(Cnm);
nmax = nmax-1;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
