# First stage: Compile the C library
FROM gcc:latest AS builder

WORKDIR /src

RUN apt-get update && apt-get install -y cmake

RUN git clone --recurse-submodules https://github.com/couchbase/couchbase-lite-C.git

WORKDIR /src/couchbase-lite-C

#MKDIR build
#WORKDIR build
#
#RUN cmake -DCMAKE_BUILD_TYPE=MinSizeRel -DCMAKE_INSTALL_PREFIX=`pwd`/output ..
#
#RUN make

# Set environment variables
ENV VERSION="3.1.3"

RUN mkdir build && \
    cd build && \
    cmake -DCMAKE_BUILD_TYPE=MinSizeRel -DCMAKE_INSTALL_PREFIX=`pwd`/output .. && \
    make && \
    make install

# Instructions to build
## At the project directory, create a build directory:
#mkdir build && cd build
#
## Prepare project. Specify CMAKE_INSTALL_PREFIX for the installation directory when running `make install`.
## Add -DSTRIP_SYMBOLS=ON to generate a separate debug symbol file and strip private symbols from the built shared library.
#cmake -DCMAKE_BUILD_TYPE=MinSizeRel -DCMAKE_INSTALL_PREFIX=`pwd`/output ..
#
## Build:
#make


#RUN mkdir build && cd build && cmake .. && make

# Second stage: Build the Python project
FROM python:3.12

WORKDIR /app

# Install gcc
RUN apt-get update && apt-get install -y gcc

RUN pip install poetry

# Copy the C library from the first stage
COPY --from=builder /src/couchbase-lite-C/build /app/couchbase-lite-C/build
COPY --from=builder /src/couchbase-lite-C/include /app/couchbase-lite-C/include
#COPY --from=builder /src/couchbase-lite-C/lib /app/couchbase-lite-C/lib

# Copy the current directory contents into the container at /app
COPY . /app

# Looking for cbl/CouchbaseLite.h
#/app/couchbase-lite-C/include/cbl/CBLBase.h:24:10: fatal error: CBL_Edition.h: No such file or directory
#2024-07-06T02:19:00.233295421Z    24 | #include "CBL_Edition.h"



# Install any needed packages specified in requirements.txt
RUN poetry install

# Run build.py when the container launches
#CMD ["python", "./CouchbaseLite/build.py"]
#CMD ["python", "build.py"]
CMD ["./build.sh", "--library", "/app/couchbase-lite-C/build/libcblite.so", \
    "--include", "/app/couchbase-lite-C/include/", \
#    "--include", "/app/couchbase-lite-C/lib", \
    "--link", "/app/couchbase-lite-C/build/generated_headers/public/cbl/", \
    "--verbose"]

#RUN python ./build.py
