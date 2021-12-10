# TODO: Remove debug outputs.
# TODO: Remove TEST_WAIT input before submission?

set -uo pipefail

SOURCE_DIR=${1:-rtl}
TEST_INSTR=${2-}
TEST_WAIT=${3:-1}
TEST_FILES=$([[ -z "$TEST_INSTR" ]] && echo "test/mips/**/*.asm" || echo "test/mips/${TEST_INSTR}/*.asm")

EXIT_CODE=0

for file in $TEST_FILES; do
    base_name=$(basename $file)
    dir_name=$(basename $(dirname $file))
    unique_name="${dir_name}_${base_name%.asm}"

    mkdir -p ./test/bin

    # Logging/Output Files
    out="./test/bin/${unique_name}.out"
    buildlog="./test/bin/${unique_name}.build.log"
    testlog="./test/bin/${unique_name}.test.log"

    fail_file() {
        echo "${unique_name} ${dir_name} Fail # $1"
        EXIT_CODE=1
    }

    # Extract Expect Value
    expected_value=$(head -n 1 "$file" | sed -n -e 's/^# Expect: //p')
    if [[ -z $expected_value ]]; then
        fail_file "Did not find expected value in test case"
        continue
    fi

    #Build TB
    iverilog -DDEBUG -Wall -g 2012 \
        ${SOURCE_DIR}/mips_cpu/*.v ${SOURCE_DIR}/mips_cpu_*.v ./test/rtl/*.v \
        -pfileline=1 \
        -s mips_cpu_bus_tb \
        -P mips_cpu_bus_tb.EXPECTED_VALUE="$expected_value" \
        -P mips_cpu_bus_tb.RAM_FILE=\"${file}.hex\" \
        -P mips_cpu_bus_tb.RAM_WAIT="$TEST_WAIT" \
        -o "$out" >"${buildlog}" 2>&1
    if [[ $? -ne 0 ]]; then
        fail_file "Failed to build test bench"
        continue
    fi

    # Run
    timeout 15s ./$out >"${testlog}" 2>&1
    if [[ $? -ne 0 ]]; then
        got_value=$(grep -i -m 1 "Testbench expected 0x" "${testlog}" | tr -d '\n')
        fail_file "Test bench exited with non-zero status code: ${got_value}"
        continue
    fi

    # Error
    grep -q -i -v "^ERROR:" "${testlog}" >/dev/null 2>&1
    if [[ $? -ne 0 ]]; then
        fail_file "Test bench found 'ERROR:' within log output"
        continue
    fi

    echo "${unique_name} ${dir_name} Pass"
done

exit ${EXIT_CODE}