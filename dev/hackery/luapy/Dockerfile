FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    build-essential \
    cmake \
    python3 \
    python3-dev \
    luajit \
    libluajit-5.1-dev \
    libboost-all-dev \
    pybind11-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY . /app

# Compile C++ backend
RUN cmake -B build -S . && cmake --build build

# Run the POC
CMD ["python3", "test.py"]