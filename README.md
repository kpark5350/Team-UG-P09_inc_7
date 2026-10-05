# Digital Pet INC_07

A Flutter pet-care app where user actions and time change visible state.

## Teams and members

| Name | Team | Pathway | Role |
|---|---|---|---|
| Ki Hyun Park | Team 1 (Care Systems) | Undergraduate | Building the core care system for the app |
| Ernest Fistik | Team 2 (Pet Personality) | Undergraduate | Add personality features and polishing the app |

Team 1 owns the care loop (feed, play, reset, meters, timers, outcomes). Team 2 owns pet personality (messages, mood feedback, assets, motion and accessibility polish).

## Setup, run, build and test

```
flutter pub get
flutter run
flutter analyze
flutter test
flutter build apk --release
```

The release APK is named `DigitalPet_TeamName.apk`

## Game rules

| Rule | Behavior |
|---|---|
| Meters | Happiness and hunger stay within 0 to 100 (clamped). Start at 50 and 50. |
| Feed | Hunger -10. If the resulting hunger is below 30, happiness -20, otherwise +10. |
| Play | Happiness +15 and hunger +5. |
| Hunger timer | Hunger +5 every 30 seconds. Going from 95 to 100 has no penalty. A tick that would exceed 100 clamps hunger to 100 and reduces happiness by 20. |
| Win | Happiness strictly above 80 continuously for 3 minutes. Exactly 80 does not qualify. The timer starts on the first value above 80 and is canceled and cleared when happiness returns to 80 or below. |
| Loss | Hunger is 100 and happiness is 10 or lower. |
| After an outcome | Feed, Play and Pause are disabled and timers stop until Reset. |
| Reset | Restores meters and flags, cancels the win timer, and ensures exactly one hunger timer is active. |
| Mood | Above 70 is Happy (green), 30 to 70 is Neutral (yellow), below 30 is Unhappy (red). A text mood label is always shown so color is not the only signal. |

## Selected advanced features

### 1. Session controls
- Pause cancels the hunger timer and freezes the win countdown, saving the time remaining.
- Resume restarts the hunger timer and restarts the win timer with the saved remaining time.
- Feed and Play are disabled while paused. Reset still works and clears the paused state.
- Dropping to 80 or below, a loss, or a reset restores the full 3 minute countdown.

### 2. Visual polish and accessible motion
- **Action bounce:** `AnimatedScale` on Feed and Play. Delayed resets check `mounted` and a newer bounce replaces an older pending reset.
- **Living meters:** `TweenAnimationBuilder<double>` glides each progress bar to the current state value.
- **Expression switch:** `AnimatedSwitcher` with a `ValueKey` cross-fades the speech bubble. The message is derived from game state, not stored separately.
- **Mood tint and size:** `ColorFiltered` with `BlendMode.modulate`, plus a restrained scale (0.94 below 30, 1.0 from 30 to 70, 1.06 above 70) derived from the same happiness bands as the label.
- **Reduced motion:** `MediaQuery.of(context).disableAnimations` makes all animation durations zero. Messages and meter values stay visible.

## Feature to learning outcome map

| Feature | Learning outcome | Evidence |
|---|---|---|
| Pause and Resume | Timers are started, canceled and restarted safely with the widget lifecycle and outcome state. | TODO |
| Action bounce | UI responds to state, and delayed callbacks respect `mounted` and cancellation. | TODO |
| Mood tint and size | Color and scale derive from happiness using the same thresholds as the label. | TODO: results for 29, 30, 70, 71 |
| Living meters | Build reads state-derived values without side effects. | TODO |
| Reduced motion | The app stays usable with motion disabled. | TODO (tested with motion on and off) |

## Test log

| Scenario | Expected | Result |
|---|---|---|
| Feed at hunger 5 and hunger 95 | Hunger stays in 0 to 100 and the happiness rule uses the resulting hunger | TODO |
| Play at happiness 95 | Happiness stays at or below 100 | TODO |
| Happiness 29, 30, 70, 71 | Unhappy/red, Neutral/yellow, Neutral/yellow, Happy/green, text label always visible | TODO |
| Happiness above 80 for 2:59 then drops to 80 | No win and the timer is canceled | TODO |
| Happiness rises above 80 again and stays for 3:00 | Win and the hunger timer stops | TODO |
| Hunger 95 to 100 then another tick | First tick has no penalty, next tick reduces happiness by 20 | TODO |
| Hunger 100 and happiness 10 or lower | Game over and controls disabled | TODO |
| Pause with win timer running, wait, resume | Win arrives about 3 minutes after the countdown began, not 3 minutes after resuming | TODO |
| Leave the screen while timers are active | No post-dispose errors in the console | TODO |
| Reduced motion on and off | Animations removed when on, still usable | TODO |
| Release APK installed on a device | App launches and core actions work | TODO |

## Screenshots

TODO

## Collaboration

- Issues: N/A
- Contributions: see the commit history

## Asset attribution
 
No attribution is needed as the app runs with the fallback icon
