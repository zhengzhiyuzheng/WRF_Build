#!/bin/bash
root_path=$(pwd)
exec 2>> error.log
if which gcc 1> /dev/null
then
        echo "Your GCC configuration is normal"
else
        echo "Your GCC is not configured properly. Here is the configuration for you"
        if sudo apt install gcc > /dev/null
        then
                echo "Your GCC configuration is normal"
        else
                echo "Installation error caused by unknown reason. Please check GCC installation"
	fi
fi
if which cpp 1> /dev/null
then
        echo "Your CPP configuration is normal"
else
        echo "Your CPP is not configured properly. Here is the configuration for you"
        if sudo apt install gcc > /dev/null
        then
                echo "Your CPP configuration is normal"
        else
                echo "Installation error caused by unknown reason. Please check CPP installation"
        fi
fi

if which gfortran 1> /dev/null
then
        echo "Your gfortran configuration is normal"
else
        echo "Your gfortran is not configured properly. Here is the configuration for you"
        if sudo apt install gcc > /dev/null
        then
                echo "Your gfortran configuration is normal"
        else
                echo "Installation error caused by unknown reason. Please check gfortran installation"
        fi
fi
#Determine directory structure
if [ ! -d $root_path"/TESTS" ]
then
	mkdir $root_path"/TESTS"
fi

if [ ! -d $root_path"/Build_WRF" ]
then
	mkdir $root_path"/Build_WRF"
fi

#Test compilation environment
cd $root_path"/TESTS"
wget https://www2.mmm.ucar.edu/wrf/OnLineTutorial/compile_tutorial/tar_files/Fortran_C_tests.tar 1> /dev/null
tar -xf Fortran_C_tests.tar 1> /dev/null
rm Fortran_C_tests.tar
set -e
gfortran TEST_1_fortran_only_fixed.f
if ./a.out | grep SUCCESS 1> /dev/null
then
	echo "The first test was successful"
else
	echo "The first test failed, please check"
fi
gfortran TEST_2_fortran_only_free.f90
if ./a.out | grep SUCCESS 1> /dev/null
then
        echo "The second test was successful"
else
        echo "The second test failed, please check"
fi
gcc TEST_3_c_only.c
if ./a.out | grep SUCCESS 1> /dev/null
then
        echo "The third test was successful"
else
        echo "The third test failed, please check"
fi
gcc -c -m64 TEST_4_fortran+c_c.c
gfortran -c -m64 TEST_4_fortran+c_f.f90
gfortran -m64 TEST_4_fortran+c_f.o TEST_4_fortran+c_c.o
if ./a.out | grep SUCCESS 1> /dev/null
then
        echo "The fourth test was successful"
else
        echo "The fourth test failed, please check"
fi
if ./TEST_csh.csh | grep SUCCESS 1> /dev/null
then
        echo "The csh test was successful"
else
        echo "The csh test failed, please check"
fi
if ./TEST_perl.pl | grep SUCCESS 1> /dev/null
then
        echo "The perl test was successful"
else
        echo "The perl test failed, please check"
fi
if ./TEST_sh.sh | grep SUCCESS 1> /dev/null
then
        echo "The sh test was successful"
else
        echo "The sh test failed, please check"
fi
set +e
echo "Congratulations, your test is successful"
#The following is the dependent configuration
cd $root_path
IFS_OLD=$IFS
IFS=$'\n'
for line in $(<"envir")
do
	echo $line >> 666
done
IFS=IFS_OLD
source ~/.bashrc
Configure dependent Libraries
cd Build_WRF
mkdir LIBRARIES
cd LIBRARIES
function install_netcdf {
	wget https://www2.mmm.ucar.edu/wrf/OnLineTutorial/compile_tutorial/tar_files/netcdf-4.1.3.tar.gz
	tar xzvf netcdf-4.1.3.tar.gz
	cd netcdf-4.1.3
	./configure --prefix=$DIR/netcdf --disable-dap --disable-netcdf-4 --disable-shared
	make
	make install
	cd ..
}

function install_mpich {
	wget https://www2.mmm.ucar.edu/wrf/OnLineTutorial/compile_tutorial/tar_files/mpich-3.0.4.tar.gz
	tar xzvf mpich-3.0.4.tar.gz
	cd mpich-3.0.4
	./configure --prefix=$DIR/mpich
	make
	make install
	cd ..
}

function install_zlib {
	wget https://www2.mmm.ucar.edu/wrf/OnLineTutorial/compile_tutorial/tar_files/zlib-1.2.7.tar.gz
	tar xzvf zlib-1.2.7.tar.gz
	./configure --prefix=$DIR/grib2
	make
	make install
	cd ..
}

function install_libpng {
	wget https://www2.mmm.ucar.edu/wrf/OnLineTutorial/compile_tutorial/tar_files/libpng-1.2.50.tar.gz
	tar xzvf libpng-1.2.50.tar.gz
	cd libpng-1.2.50
	./configure --prefix=$DIR/grib2
	make
	make install
	cd ..
}

function install_jasper {
	wget https://www2.mmm.ucar.edu/wrf/OnLineTutorial/compile_tutorial/tar_files/jasper-1.900.1.tar.gz
	tar xzvf jasper-1.900.1.tar.gz
	cd jasper-1.900.1
	make
	make install
	cd ..
}
echo "Next, install the library for you. Please wait patiently"
install_netcfd &
install_mpich &
install_zlib &
install_libpng &
install_jasper &
wait
#Configuration environment test
cd $root_path
cd TESTS
wget https://www2.mmm.ucar.edu/wrf/OnLineTutorial/compile_tutorial/tar_files/Fortran_C_NETCDF_MPI_tests.tar
tar -xf Fortran_C_NETCDF_MPI_tests.tar
cp "$NETCDF/include/netcdf.inc" .
gfortran -c 01_fortran+c+netcdf_f.f
gcc -c 01_fortran+c+netcdf_c.c
gfortran 01_fortran+c+netcdf_f.o 01_fortran+c+netcdf_c.o -L"$NETCDF/lib" -lnetcdff -lnetcdf
if ./a.out | grep SUCCESS 1> /dev/null
then
	echo "Your NetCDF test was successful"
else
	echo "Your NetCDF test was failed"
fi
mpif90 -c 02_fortran+c+netcdf+mpi_f.f
mpicc -c 02_fortran+c+netcdf+mpi_c.c
mpif90 02_fortran+c+netcdf+mpi_f.o 02_fortran+c+netcdf+mpi_c.o -L"$NETCDF/lib" -lnetcdff -lnetcdf
if mpirun ./a.out | grep SUCCESS 1> /dev/null
then
	echo "Fortran + C + NetCDF + MPI test was successful"
else
	echo "Fortran + C + NetCDF + MPI test was failed"
fi