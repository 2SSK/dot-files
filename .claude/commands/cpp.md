---
description: C++ development workflow
---
Run the C++ development workflow:

Debug build:
1. cmake -B build -DCMAKE_BUILD_TYPE=Debug
2. cmake --build build -j$(nproc)
3. ctest --test-dir build --output-on-failure

Then run sanitizers:
1. cmake -B build-san -DCMAKE_BUILD_TYPE=Debug -DCMAKE_CXX_FLAGS="-fsanitize=address,undefined,leak"
2. cmake --build build-san -j$(nproc)
3. ctest --test-dir build-san --output-on-failure

Report results for each step.
