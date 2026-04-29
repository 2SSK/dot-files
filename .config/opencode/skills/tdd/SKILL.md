---
name: tdd
description: Test-Driven Development workflow. Write failing test first, implement code to pass, then refactor. Essential for all languages: Go, TypeScript, C++, Python. Use before any implementation task.
compatibility: opencode
---

# Test-Driven Development Skill

Enforce TDD for every implementation task. This skill ensures quality throughtests first.

## Workflow

### Step 1 — Write Failing Test
- Identify the smallest unit of behavior
- Write test that fails because feature doesn't exist
- Use language-specific testing framework
- Keep test focused and simple

### Step 2 — Write Minimal Code
- Implement only what's needed to pass test
- No optimization yet
- No additional features
- Get to green quickly

### Step 3 — Refactor
- Clean up code while tests pass
- Improve structure, names, organization
- Ensure tests still pass
- No new functionality

## Testing Patterns by Language

### Go
```go
func TestUnitName(t *testing.T) {
    t.Run("should do thing", func(t *testing.T) {
        // arrange
        input := ...
        expected := ...
        
        // act
        result := DoThing(input)
        
        // assert
        assert.Equal(t, expected, result)
    })
}
```

### TypeScript
```typescript
describe('UnitName', () => {
  it('should do thing', () => {
    const input = ...;
    const expected = ...;
    
    const result = doThing(input);
    
    expect(result).toEqual(expected);
  });
});
```

### C++
```cpp
TEST_F(UnitNameTest, ShouldDoThing) {
    auto input = ...;
    auto expected = ...;
    
    auto result = doThing(input);
    
    EXPECT_EQ(expected, result);
}
```

## Quality Gates

- All tests must pass before commit
- Coverage ≥ 80% for new code
- No flaky tests
- Fast execution (< 30s for unit tests)