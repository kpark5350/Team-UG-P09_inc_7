# Digital Pet - In-Class Activity 07

A Flutter digital pet-care app where user actions and time change the pet's visible state.

## Team Members

| Name | Team | Pathway | Role |
|---|---|---|---|
| Ki Hyun Park | Team 1 - Care Systems | Undergraduate | Core game state, care actions, timers, win/loss logic, final testing, and APK build |
| Ernest Fistik | Team 2 - Pet Personality | Undergraduate | Session controls, visual polish, animations, pet feedback, and accessibility |

## Project Overview

The Digital Pet app allows the user to name and care for a virtual pet.

The application includes:

- Editable pet name
- Happiness meter
- Hunger meter
- Feed action
- Play action
- Reset
- Pause and Resume
- Mood feedback
- Pet speech
- Animated visual feedback
- Win and loss conditions

Happiness and Hunger are kept between 0 and 100.

---

## Setup, Run, Build, and Test

Run the following commands from the Flutter project folder:


```bash
flutter pub get
flutter run
Analyze the project:
flutter analyze

Run Flutter tests:
flutter test

Build the release APK:
flutter build apk --release

Final APK:
DigitalPet_UG-P09.apk
Game Rules
Rule	Behavior
Starting values	Happiness starts at 50 and Hunger starts at 50
Meter limits	Happiness and Hunger are clamped between 0 and 100
Feed	Hunger decreases by 10. If resulting Hunger is below 30, Happiness decreases by 20; otherwise Happiness increases by 10
Play	Happiness increases by 15 and Hunger increases by 5
Hunger timer	Hunger increases by 5 every 30 seconds
Hunger overflow	Going from 95 to 100 has no penalty. A later tick that would exceed 100 keeps Hunger at 100 and decreases Happiness by 20
Win	Happiness must stay strictly above 80 continuously for 3 minutes
Loss	Game Over occurs when Hunger is 100 and Happiness is 10 or lower
After an outcome	Feed, Play, and Pause are disabled and active timers stop until Reset
Reset	Restores starting values, clears outcome flags, resets timers, and starts a new game
Mood	Above 70 is Happy/green, 30-70 is Neutral/yellow, and below 30 is Unhappy/red


Selected Advanced Features
1. Session Controls
The application includes Pause and Resume controls.
When Pause is selected:
- The Hunger timer stops
- The active win countdown stops
- Feed and Play are disabled
- The remaining win countdown time is saved
When Resume is selected:
- The Hunger timer starts again
- The win countdown continues using the saved remaining time
- Feed and Play become available again
Reset clears the paused state and restores the full three-minute win timer.
2. Visual Polish and Accessible Motion
The app includes multiple visual feedback features.
Action Bounce
AnimatedScale creates a short bounce when Feed or Play is used.
Living Meters
TweenAnimationBuilder<double> animates the Happiness and Hunger progress bars as values change.
Expression / Pet Speech
AnimatedSwitcher changes the speech bubble when the pet's state changes.
Messages are derived from the current game state and include:
- Normal greeting
- Hungry message
- Unhappy message
- Paused message
- Win message
- Game Over message
Mood Tint and Size
ColorFiltered with BlendMode.modulate changes the pet color based on Happiness.
The pet also changes size slightly:
- Happiness below 30: red and smaller
- Happiness 30-70: yellow and normal size
- Happiness above 70: green and slightly larger
The mood text is always shown so color is not the only indicator.
Reduced Motion
The application checks the device's disableAnimations preference.
When reduced motion is enabled, animation durations become zero while all messages, meters, and controls remain usable.
Feature to Learning Outcome Map
Feature	Learning Outcome	Evidence
Pause and Resume	Timers are started, canceled, and restarted safely with the widget lifecycle and outcome state	Hunger timer stops during Pause and starts again on Resume. Remaining win time is saved and restored
Action Bounce	UI responds to state, and delayed callbacks respect mounted and cancellation	Feed and Play trigger AnimatedScale; the bounce timer checks mounted before updating state
Mood Tint and Size	Color and scale derive from Happiness using the same thresholds as the mood label	29 = red/smaller, 30 and 70 = yellow/normal, 71 = green/larger
Living Meters	Build reads state-derived values without side effects	Happiness and Hunger bars animate to their current values using TweenAnimationBuilder<double>
Reduced Motion	The app stays usable with motion disabled	disableAnimations is checked and animation durations become zero when reduced motion is enabled
Feed and Play	setState() updates related state values together	Happiness and Hunger values update immediately after actions
Reset	Related state and timers are restored together	Reset restores 50/50 values, clears Pause/Win/Loss state, and restarts the Hunger timer


Test Log
Scenario	Expected Result	Result
Feed at low and high Hunger values	Hunger remains between 0 and 100 and the Happiness rule uses the resulting Hunger	Implemented in code; meter values are clamped to 0-100
Play near Happiness 100	Happiness stays at or below 100	Implemented with _clampMeter()
Happiness 29, 30, 70, and 71	29 = Unhappy/red, 30 and 70 = Neutral/yellow, 71 = Happy/green	Implemented using the same Happiness thresholds for label, color, and size
Happiness above 80 for 2:59 then drops to 80	No win and the pending win timer is canceled	Implemented in _updateOutcome()
Happiness rises above 80 again and stays for 3:00	Win occurs and the Hunger timer stops	Implemented with the three-minute win timer
Hunger 95 to 100 then another Hunger tick	First tick has no penalty; next overflow tick reduces Happiness by 20	Implemented in the Hunger timer logic
Hunger 100 and Happiness 10 or lower	Game Over appears and care controls are disabled	Implemented in the loss condition
Pause while win timer is active, then Resume	Remaining win time is saved and continued after Resume	Implemented in Session Controls
Leave the screen while timers are active	Timers are canceled and no post-dispose state update should occur	Timers are canceled in dispose() and callbacks check mounted
Reduced motion enabled	Nonessential animation duration becomes zero while the app remains usable	Implemented with disableAnimations
App launches on Android emulator/device	Main Digital Pet screen appears and controls work	PASS
Play button	Happiness and Hunger values update correctly on screen	PASS
Pause / Resume controls	Pause and Resume controls are displayed and connected to session state	PASS
Reset control	Reset button is available to restore the initial state	PASS
Release APK installation	APK installs and launches successfully	PASS


Screenshots / Runtime Evidence
The application was launched successfully on an Android emulator/device during final testing.
Runtime testing confirmed:
- Digital Pet screen loads successfully
- Pet name field is displayed
- Happiness and Hunger meters are visible
- Feed, Play, Reset, and Pause controls are displayed
- Play changes Happiness and Hunger values
- Pet mood and speech feedback are displayed
- The final release APK installs and runs successfully
Collaboration
Both team members contributed to the shared GitHub repository.
Ki Hyun Park
Implemented:
- Main Flutter application structure
- Happiness and Hunger state
- Feed action
- Play action
- Reset
- Hunger timer
- Win and loss conditions
- Final app testing
- Release APK build
Ernest Fistik
Implemented:
- Pause and Resume controls
- Win countdown pause/resume handling
- Action bounce animation
- Animated meters
- Pet speech
- Mood-based visual changes
- Reduced-motion support
Both contributors are visible in the GitHub repository history.
Contribution evidence is available in the commit history.
GitHub Repository
https://github.com/kpark5350/Team-UG-P09_inc_7
Asset Attribution
The submitted application can run using Flutter's built-in pet icon as a fallback.
Because the current version does not require an external copyrighted pet image, no external image attribution is required.
Final Deliverables
Each student submits:
1. github_link.txt containing the shared GitHub repository URL
2. DigitalPet_UG-P09.apk
3. Their own Critical Thinking response document
Final Status
The Digital Pet application builds and runs successfully.
The final APK was generated and tested, the required core features are implemented, the selected advanced features are included, and both team members' contributions are visible in the GitHub repository.
