#!/bin/bash
#
# Description: Exit with error, to force a failure in the program executing this script

set -o errexit
set -o nounset
set -o pipefail
# set -o xtrace # Uncomment this line for debugging purpose

exit 1
