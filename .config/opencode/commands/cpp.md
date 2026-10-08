---
name: cpp
description: C++ development workflow. Build, test, profile with sanitizers. Use for C++ projects.
agent: cpp-pro
---

# C++ Development Command

Run C++ development workflow.

## When to Use

- Implement C++ feature
- Build C++ project
- Run tests with sanitizers

## Workflow Options

### Debug Build
```bash
cmake -B build -DCMAKE_BUILD_TYPE=Debug
cmake --build build -j$(nproc)
ctest --test-dir build --output-on-failure
```

### Release Build
```bash
cmake -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build -j$(nproc)
```

### Sanitizers
```bash
cmake -B build -DCMAKE_BUILD_TYPE=Debug \
    -DCMAKE_CXX_FLAGS="-fsanitize=address,undefined,leak"
ctest --test-dir build --output-on-failure
```

### Profile
```bash
perf record -g ./build/app
perf report
```

## Quality Gates

- [ ] clang-tidy passes
- [ ] No warnings
- [ ] ASan/UBSan clean
- [ ] Tests pass