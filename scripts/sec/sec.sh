#!/bin/bash

# Copyright 2021 OpenHW Group
#
# Licensed under the Solderpad Hardware Licence, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://solderpad.org/licenses/
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

usage() {                                 # Function: Print a help message.
  echo "Usage: $0 [ -t SIMULATOR ]" 1>&2
}
exit_abnormal() {                         # Function: Exit with error.
  usage
  exit 1
}

while getopts ":t:" flag
do
    case "${flag}" in
        t) target_tool=${OPTARG}
            ;;
        :)                                    # If expected argument omitted:
        echo "Error: -${OPTARG} requires an argument."
        exit_abnormal                       # Exit abnormally.
        ;;
        *)                                  # If unknown (any other) option:
        exit_abnormal                       # Exit abnormally.
        ;;
        ?)                                  # If unknown (any other) option:
        exit_abnormal                       # Exit abnormally.
        ;;
    esac
done

if [[ "${target_tool}" != "cadence" && "${target_tool}" != "synopsys" ]]; then
    exit_abnormal
fi

if [[ -z "${GOLDEN_RTL}" ]]; then
  echo "The env variable GOLDEN_RTL is empty."
  echo "Cloning Golden Design...."
  sh clone_reference.sh
  export GOLDEN_RTL=$(pwd)/golden_reference_design/cv32e40p/rtl
else
  echo "Using ${GOLDEN_RTL} as reference design"
fi

REVISED_RTL=$(pwd)/../../rtl


var_golden_rtl=$(awk '{ if ($0 ~ "sv" && $0 !~ "incdir" && $0 !~ "wrapper" && $0 !~ "tracer") print $0 }' $GOLDEN_RTL/../cv32e40p_manifest.flist | awk -v rtlpath=$GOLDEN_RTL -F "/" '{$1=rtlpath} OFS="/"')

var_revised_rtl=$(awk '{ if ($0 ~ "sv" && $0 !~ "incdir" && $0 !~ "wrapper" && $0 !~ "tracer") print $0 }' $REVISED_RTL/../cv32e40p_manifest.flist | awk -v rtlpath=$REVISED_RTL -F "/" '{$1=rtlpath} OFS="/"')

echo $var_golden_rtl > golden.src
echo $var_revised_rtl > revised.src

report_dir="${target_tool}/reports"

if [[ -d ${report_dir} ]]; then
    rm -rf ${report_dir}
fi
mkdir -p ${report_dir}

cd ${target_tool}

if [[ "${target_tool}" == "cadence" ]]; then
    echo "Running Cadence Jaspergold"
    jg -sec -tcl sec.tcl -no_gui

    #TODO SEC results
else
    echo "Running Synopsys Formality"
fi
cd ../

if [[ $NonSec == "0" ]]; then
    echo "The DESIGN IS LOGICALLY EQUIVALENT"
else
    NonSec="-1"
    echo "The DESIGN IS NOT LOGICALLY EQUIVALENT"
fi

echo "$0 returns $NonSec"

exit $NonSec
