---
name: react-native-best-practices
description: React Native development. Cross-platform code, native modules, performance. Use when building mobile apps.
compatibility: opencode
---

# React Native Best Practices

Cross-platform mobile development with React Native.

## Core Principles

- **Cross-platform first**: 80%+ shared code
- **Native when needed**: Platform-specific modules
- **Performance**: Cold start < 1.5s, memory < 120MB
- **Offline-first**: Local data, sync later

## Cross-Platform Code

```typescript
// Platform.select for different implementations
import { Platform } from 'react-native';

const styles = Platform.select({
  ios: { paddingTop: 48 },
  android: { paddingTop: 24 },
});
```

## Navigation

```typescript
// React Navigation
import { NavigationContainer } from '@react-navigation/native';

<NavigationContainer>
  <Stack.Navigator>
    <Stack.Screen name="Home" component={HomeScreen} />
  </Stack.Navigator>
</NavigationContainer>
```

## State Management

```typescript
// Zustand for simple state
import { create } from 'zustand';

const useStore = create((set) => ({
  count: 0,
  increment: () => set((s) => ({ count: s.count + 1 })),
}));
```

## Offline Storage

```typescript
// WatermelonDB for offline-first
import { Database } from '@nozbe/watermelondb';

const database = new Database({
  schema: appSchema,
  modelClasses: [User, Post],
});
```

## Native Modules

```typescript
// TurboModule for New Architecture
import type { TurboModule } from 'react-native';
import { TurboModuleRegistry } from 'react-native';

export interface Spec extends TurboModule {
  startActivity(options: string): Promise<void>;
}
export default TurboModuleRegistry.getEnforcing<Spec>('CameraModule');
```

## Push Notifications

```typescript
// @notifee/react-native
import messaging from '@react-native-firebase/messaging';

await messaging().requestPermission();
const token = await messaging().getToken();
```

## Build Commands

```bash
# iOS
cd ios && pod install && cd ..
npm run build:ios

# Android
cd android && ./gradlew assembleRelease
```

## Quality Gates

- [ ] 80%+ cross-platform code
- [ ] Cold start < 1.5s
- [ ] Memory baseline < 120MB
- [ ] Battery drain < 4%/hour
- [ ] 60+ FPS (120 for ProMotion)
- [ ] Crash rate < 0.1%