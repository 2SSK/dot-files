---
name: mobile
description: React Native development workflow. Build iOS/Android, run tests, bundle. Use for mobile app development.
agent: mobile-developer
---

# React Native Development Command

Run React Native development workflow.

## When to Use

- Build React Native app
- Run tests
- Build for release

## Workflow Options

### Development
```bash
# Start Metro
npm start

# Run on iOS
npm run ios

# Run on Android
npm run android
```

### Test
```bash
npm run test
npm run lint
npm run type-check
```

### Build iOS
```bash
cd ios && pod install && cd ..
npm run build:ios
```

### Build Android
```bash
cd android && ./gradlew assembleRelease
```

### Bundle
```bash
npx react-native bundle --platform ios --dev false --entry-file index.js --bundle-output ios/main.jsbundle
```

## Quality Gates

- [ ] Type check passes
- [ ] Tests pass
- [ ] iOS build succeeds
- [ ] Android build succeeds (if applicable)