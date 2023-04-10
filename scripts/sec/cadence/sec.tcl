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

clear -all
set_proofmaster on

check_sec -setup -spec_top cv32e40p_core -imp_top cv32e40p_core \
        -spec_analyze  "-sv -f ../golden.src" \
        -imp_analyze "-sv -f ../revised.src"\
        -auto_map_cover_gated_clock_toggle \
        -exclude_undriven_mapping


clock -infer
reset ~rst_ni


check_sec -map -auto -cover_gated_clock_toggle

check_sec -unmap -spec scan_cg_en_i -global

check_sec -gen
check_sec -interface

set_proofgrid_mode local
set_proofgrid_per_engine_max_local_jobs 2
set_proofgrid_max_local_jobs 6


set_sec_autoprove_strategy design_style
set_sec_autoprove_design_style_type clock_gating
set_sec_prove_cex_threshold 2

assume {scan_cg_en_i == 0}                    -name "spec_cg_enable"
assume {cv32e40p_core_imp.scan_cg_en_i == 0}  -name "imp_cg_enable"

check_sec -prove

check_sec -signoff -get_valid_status -summary -file ./reports/result_verification.log

exit 0
