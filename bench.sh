#!/bin/bash

echo "Python"
python python/main.py

echo "Cython"
python cython/main.py

echo "C++"
./cpp/litmus

echo "Rust"
./rust/target/release/litmus
