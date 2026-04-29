---
name: cpp-best-practices
description: C++ development best practices. Modern C++20/23, RAII, zero-overhead abstractions, safety. Use when writing C++ code.
compatibility: opencode
---

# C++ Best Practices

Modern C++20/23 with zero-overhead abstractions and safety.

## Core Principles

- **RAII**: Resource Acquisition Is Initialization — always
- **Zero-cost**: Don't pay for what you don't use
- **Safety**: Memory safety without garbage collection
- **Modern**: Use C++20/23 features

## Memory Management

```cpp
// Smart pointers — always
auto ptr = std::make_unique<Resource>();
auto shared = std::make_shared<Cache>();

// No raw new/delete
// std::vector for dynamic arrays
// std::string for strings
```

## Modern C++ Features

```cpp
// Concepts (C++20)
template<typename T>
concept Hashable = requires(T a) {
    { std::hash<T>{}(a) } -> std::convertible_to<std::size_t>;
};

// Ranges (C++20)
auto results = range | std::views::filter(pred)
                   | std::views::transform(func)
                   | std::views::take(10);

// std::expected (C++23)
std::expected<int, Error> divide(int a, int b) {
    if (b == 0) return std::unexpected{DivisionByZero{}};
    return a / b;
}
```

## Concurrency

```cpp
// std::jthread for cancellation
std::jthread worker([](stop_token) {
    while (!stop_token.stop_requested()) {
        // work
    }
});
```

## Error Handling

```cpp
// Exceptions for exceptional cases
// noexcept for functions that shouldn't throw
// std::expected for fallible operations
```

## Build Commands

```bash
cmake -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build -j$(nproc)
cmake -B build -DCMAKE_BUILD_TYPE=Debug -DCMAKE_CXX_FLAGS="-fsanitize=address,undefined"
ctest --output-on-failure
```

## Quality Gates

- [ ] clang-tidy passes
- [ ] Cppcheck passes
- [ ] Zero warnings with -Wall -Wextra -Wpedantic
- [ ] AddressSanitizer clean
- [ ] UndefinedBehaviorSanitizer clean
- [ ] Coverage ≥ 80%