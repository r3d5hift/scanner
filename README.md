# scanner

scanner v0.0.1

The program scans for used 'eval' function, Scanner performs a comprehensive search of eval function throughout the JS file in the given directory, One can use flag '-node' to perform only scanning of node_modules. By default  it scans all JS files as well as node_modules. Tested on macOS Sierra v10.12.6.

Usage 1: If you only want to include node_modules 
         
         bash scanner.sh -d <path/to/Node/Project> -r <path/to/generate/report> -node
    
Usage 2: If you want to include Entire Directory including node_modules 
         
         bash scanner.sh -d <path/to/Node/Project> -r <path/to/generate/report> 
         
