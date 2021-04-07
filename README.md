# Biological sequences comparison
This project intend to perform biological sequences alignment using FASTA format in different cloud services such as on-demand instances (AWS EC2) and function as a service (Lambda). 

## Alghorithm

- Hirschberg

## Scripts
 - **generate_test_cases.sh**
  - Reads files with FASTAs in a passed directory and generates files (.json) containing 2 sequences to be used as "test cases".
 - **raffle.sh**
  - Since the test case set is generated, this script generates subsets of test cases collected randomly from the main set of test cases. This creates sets that can be run concurrently on different types of services.
