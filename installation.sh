#!/bin/bash

##################################################
# installation.sh: It will include all the commands regarding installation of all the necessary services and tools. Also,all configuration scripts for LAMP.

# Written by Chris Yun
##################################################

# some colors so that echo statements are easily seen
green='\033[0;92m'
cyan='\033[0;96m'
reset='\033[0m'

##################################################

# "Run the following Command to upgrade your index first(recommended)"
# this part checks then updates packages and upgrades the system
echo -e "${green}Updating System..${reset}"
sudo apt-get update -y && sudo apt-get upgrade -y

##################################################

# IPTables come pre-installed in Ubuntu

##################################################

# "Install the LAMP Bundle"
# this will install the "AMP" of LAMP: Apache, MySQL, and PHP
echo -e "${green}Installing LAMP Bundle..${reset}"
sudo apt-get install lamp-server^ -y

##################################################

# OpenSSH installation:
echo -e "${green}Installing OpenSSH..${reset}"
sudo apt-get install openssh-server
echo -e "${green}Enabling SSH Service..${reset}"
sudo systemctl enable ssh

##################################################

# Snort3
echo -e "${green}Installing Snort3..${reset}"
# Snort3 installation uses cmake, but I don't think it's on ubuntu by default so we will install it here
echo -e "${green}Installing cmake..${reset}"
sudo snap install cmake --classic

# "We will be downloading a number of source tarballs and other source files, we want to store them inone folder:"
echo -e "${green}Creating snort_src directory..${reset}"
mkdir ~/snort_src
cd ~/snort_src

# "Install the Snort 3 prerequisites. Details of these packages can be found in the requirements section ofthe Snort3 Manual:"
echo -e "${green}Installing prerequsites..${reset}"
sudo apt-get install -y build-essential autotools-dev libdumbnet-dev \libluajit-5.1-dev libpcap-dev zlib1g-dev pkg-config libhwloc-dev \cmake

# "Next install the optional (but highly recommended software):"
echo -e "${green}Installing Optional Software..${reset}"
sudo apt-get install -y liblzma-dev openssl libssl-dev cpputest \libsqlite3-dev uuid-dev

# "Since we will install Snort from the github repository, we need a few tools (not necessary on Ubuntu19):"
echo -e "${green}Installing libtool git..${reset}"
sudo apt-get install -y libtool git autoconf

# "The Snort DAQ (Data Acquisition library)has a few pre-requisites that need to be installed:"
echo -e "${green}Installing DAQ prerequisites..${reset}"
sudo apt-get install -y bison flex

# "If you want to run Snort in inline mode using NFQ, install the required packages (not required for IDSmode or inline mode using afpacket). If you’re unsure, you should install this package."
echo -e "${green}Installing NFQ..${reset}"
sudo apt-get install -y libnetfilter-queue-dev libmnl-dev

# "Download and install safec for runtime bounds checks on certain legacy C-library calls (this is optionalbut recommended):"
echo -e "${green}Installing safec..${reset}"
cd ~/snort_src
wget https://github.com/rurban/safeclib/releases/download/v04062019/libsafec-04062019.0-ga99a05.tar.gz
tar -xzvf libsafec-04062019.0-ga99a05.tar.gz
cd libsafec-04062019.0-ga99a05/
./configure
make
sudo make install

# "Install PCRE: Perl Compatible Regular Expressions. We don’t use the Ubuntu repository because it hasan older version."
echo -e "${green}Installing PCRE..${reset}"
cd ~/snort_src
wget https://ftp.pcre.org/pub/pcre/pcre-8.43.tar.gz
tar -xzvf pcre-8.43.tar.gz
cd pcre-8.43
./configure
make
sudo make install

# "Download and install gperftools 2.7, google’s thread-caching malloc (used in chrome). Tcmalloc is amemory allocator that’s optimized for high concurrency situations which will provide better speedfor the trade-off of higher memory usage. We don’t want the version of tcmalloc from the Ubunturepository (version 2.5) as it is not compatible with Snort. Tcmalloc is optional but recommended:"
echo -e "${green}Installing gperftools 2.7..${reset}"
cd ~/snort_src
wget https://github.com/gperftools/gperftools/releases/download/gperftools-2.7/gperftools-2.7.tar.gz
tar xzvf gperftools-2.7.tar.gz
cd gperftools-2.7
./configure
make
sudo make install

# "Snort 3 uses Hyperscan for fast pattern matching. Hyperscan requires Ragel and the Boost headers:"
echo -e "${green}Installing Hyperscan..${reset}"
cd ~/snort_src
wget http://www.colm.net/files/ragel/ragel-6.10.tar.gz
tar -xzvf ragel-6.10.tar.gz
cd ragel-6.10
./configure
make
sudo make install

# "Hyperscan requires the Boost C++ Libraries. Note that we are not using the Ubuntu repository versionof the boost headers (libboost-all-dev) because Hyperscan requires boost libraries at or above version number 1.58, and the Ubuntu repository version is too old. Download the Boost 1.71.0 libraries, but do not install:"
echo -e "${green}Installing Boost C++ Libraries..${reset}"
cd ~/snort_src
wget https://dl.bintray.com/boostorg/release/1.71.0/source/boost_1_71_0.tar.gz
tar -xvzf boost_1_71_0.tar.gz

# "Install Hyperscan 5.2 from source, referencing the location of the Boost headers source directory:"
echo -e "${green}Installing Hyperscan 5.2 from source..${reset}"
cd ~/snort_src
wget https://github.com/intel/hyperscan/archive/v5.2.0.tar.gz
tar -xvzf v5.2.0.tar.gz
mkdir ~/snort_src/hyperscan-5.2.0-build
cd hyperscan-5.2.0-build/
cmake -DCMAKE_INSTALL_PREFIX=/usr/local-DBOOST_ROOT=~/snort_src/boost_1_71_0/ ../hyperscan-5.2.0
make
sudo make install

# "Snort has an optional requirement for flatbuffers, A memory efficient serialization library:"
echo -e "${green}Installing flatbuffers..${reset}"
cd ~/snort_src
wget https://github.com/google/flatbuffers/archive/v1.11.0.tar.gz \ -O flatbuffers-v1.11.0.tar.gz
tar -xzvf flatbuffers-v1.11.0.tar.gz
mkdir flatbuffers-build
cd flatbuffers-build
cmake ../flatbuffers-1.11.0
make
sudo make install

# "Next, download and install Data AcQuisition library (DAQ) from the Snort website. Note that Snort 3uses a different DAQ than the Snort 2.9.x.x series:"
echo -e "${green}Installing DAQ..${reset}"
cd ~/snort_src
git clone https://github.com/snort3/libdaq.git
cd libdaq
./bootstrap
./configure
make
sudo make install

# "Update shared libraries:"
echo -e "${green}Updating shared libraries..${reset}"
sudo ldconfig

# "Now we are ready to download, compile, and install Snort 3 from the github repository. If you areinterested in enabling additional compile-time functionality, such as the ability to process large (over 2GB) PCAP files, or the new command line shell, you should run./configure cmake.sh --helptolist all possible options. If you want to install to a different location, please see Appendix B. Download and install, with default settings:"
echo -e "${green}Installing Snort 3..${reset}"
cd ~/snort_src
git clone git://github.com/snortadmin/snort3.git
cd snort3
./configure_cmake.sh --prefix=/usr/local--enable-tcmalloc
cd build
make
sudo make install

##################################################

echo -e "${cyan}Installation Complete${reset}"

##################################################

# RESOURCES

# learning scripts:
# http://linuxcommand.org/lc3_writing_shell_scripts.php

# LAMP installation:
# https://www.geeksforgeeks.org/installing-php-and-configuring-it-on-ubuntu-14-04-trusty/

# changing colors:
# https://stackoverflow.com/questions/5947742/how-to-change-the-output-color-of-echo-in-linux

# Snort3 installation:
# https://snort-org-site.s3.amazonaws.com/production/document_files/files/000/000/211/original/Snort3.pdf?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=AKIAIXACIED2SPMSC7GA%2F20200319%2Fus-east-1%2Fs3%2Faws4_request&X-Amz-Date=20200319T194527Z&X-Amz-Expires=172800&X-Amz-SignedHeaders=host&X-Amz-Signature=27096940c889c56e20352507c114d335cdcdf12340d0af2e6438d16278762526

# OpenSSH installation:
# https://www.cyberciti.biz/faq/ubuntu-linux-install-openssh-server/

##################################################

