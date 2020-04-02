FROM python:3.8.1

WORKDIR /usr/src/
ADD sources.list /etc/apt
ADD opencv-4.2.0 /usr/src/opencv
ADD opencv_contrib-4.2.0 /usr/src/opencv_contrib
ADD requirements.txt /root
ADD pip.conf /root/.pip/

# install developer tools
RUN     cp -r /usr/src/opencv/modules/features2d /usr/src/opencv/build && \
        apt-get update && \
        apt-get install -y \
        build-essential \
        cmake \
        libtbb2 \
        libtbb-dev \
        libjpeg-dev \
        libpng-dev \
        libtiff-dev \
        pkg-config \
        gcc \
        libsasl2-dev \
        python-dev \
        libldap2-dev \
        libssl-dev \
        default-libmysqlclient-dev \
        procps \
        build-essential \
        libxrender-dev \
        libglib2.0-0 \
        libxext6 \
        libsm6 && \
        CC="cc -mavx2" pip install -r /root/requirements.txt

RUN   dpkg -i /usr/src/opencv/multiarch-support_2.27-3ubuntu1_amd64.deb && \
      dpkg -i /usr/src/opencv/libjpeg-turbo8_1.5.2-0ubuntu5_amd64.deb && \
      dpkg -i /usr/src/opencv/libjpeg8_8c-2ubuntu8_amd64.deb && \
      dpkg -i /usr/src/opencv/libjasper1_1.900.1-debian1-2.4ubuntu1_amd64.deb && \
      dpkg -i /usr/src/opencv/libjasper-dev_1.900.1-debian1-2.4ubuntu1_amd64.deb

# OpenCV Version
ENV OPENCV_VERSION 4.2.0

WORKDIR /usr/src/opencv/build

# configure compilation options
RUN cmake \
    -D CMAKE_BUILD_TYPE=RELEASE \
    -D OPENCV_EXTRA_MODULES_PATH=/usr/src/opencv_contrib/modules \
    -D PYTHON3_LIBRARY=`python -c 'import subprocess ; import sys ; s = subprocess.check_output("python-config --configdir", shell=True).decode("utf-8").strip() ; (M, m) = sys.version_info[:2] ; print("{}/libpython{}.{}.dylib".format(s, M, m))'` \
    -D PYTHON3_INCLUDE_DIR=`python -c 'import distutils.sysconfig as s; print(s.get_python_inc())'` \
    -D PYTHON3_EXECUTABLE=/usr/local/bin/python3 \
    -D BUILD_opencv_python2=OFF \
    -D BUILD_opencv_python3=ON \
    -D INSTALL_PYTHON_EXAMPLES=OFF \
    -D INSTALL_C_EXAMPLES=OFF \
    -D OPENCV_ENABLE_NONFREE=ON \
    -D BUILD_EXAMPLES=OFF \
    -DBUILD_opencv_xfeatures2d=OFF \
    -DBUILD_TESTS=OFF \
    -DENABLE_AVX=ON \
    -DENABLE_AVX2=ON \
    -DENABLE_SSE41=ON \
    -DENABLE_SSE42=ON \
    -DENABLE_SSSE3=ON \
    -D CPU_DISPATCH=AVX512_SKX \
    #-DENABLE_AVX512=ON \
    #-DCPU_BASELINE=AVX512_SKX \ #强制启动AVX512可以得到10%的性能提升
    ..

RUN make -j8 && \
    make install && \
    ldconfig /etc/ld.so.conf.d && \
    rm -rf /usr/src/opencv/build
        

# land on a generic project directory
WORKDIR /usr/src/project

CMD bash
