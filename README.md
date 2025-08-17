Docker container for building FujiNet software, including firmware, libraries, applications.

Compilers included:

  * cc65
  * cmoc
  * open watcom

To use:

# Copy defoogi script (symlink to start) to a folder that is in your $PATH.
` copy defoogi /usr/local/bin `

# Pull the latest docker image
`docker pull fozztexx/defoogi`

# Build 
  * cd into the directory with the FujiNet software you want to build
  * prefix your build commands with `defoogi`:
    * `defoogi make`
