
# Prayer Time Silent App Blueprint

## Overview

This application automatically silences the user's mobile device during specific prayer times and restores the normal ringer mode afterward. The user can set start and end times for five different prayer slots. The app will run continuously in the background to ensure the silent/normal mode is triggered at the correct times.

## Features

*   **Five Prayer Time Slots:** The UI will have five distinct sections, one for each prayer (Fajr, Dhuhr, Asr, Maghrib, Isha).
*   **Time Pickers:** Each section will feature "Start Time" and "End Time" pickers for the user to select the desired silent duration.
*   **Save Functionality:** A "Save" button will persist the selected times.
*   **Background Service:** The app will use a background service to run 24/7.
*   **Automatic Silent/Normal Mode:** The background service will monitor the current time and automatically switch the phone to silent mode at the start time and back to normal mode at the end time.
*   **Permission Handling:** The app will request the necessary "Do Not Disturb" permissions to control the ringer mode.

## Architecture

*   **State Management:** `provider` will be used for managing the application state, such as the selected times.
*   **Local Storage:** `shared_preferences` will be used to store the user-defined prayer times.
*   **Background Execution:** `android_alarm_manager_plus` will be used to schedule the tasks for silencing and un-silencing the phone.
*   **Ringer Mode Control:** `sound_mode` package will be used to change the device's ringer status.
*   **Permissions:** `permission_handler` will be used to request "Do Not Disturb" access.
*   **Notifications:** `flutter_local_notifications` will be used to show a persistent notification to keep the background service alive.

## Plan

1.  **Add Dependencies:** Add `provider`, `shared_preferences`, `android_alarm_manager_plus`, `sound_mode`, `permission_handler`, `flutter_local_notifications`, and `intl` to `pubspec.yaml`.
2.  **Configure Android:** Update `AndroidManifest.xml` to include necessary permissions for background execution and boot completion.
3.  **Implement UI:** Create the main screen with five sections for time inputs and a save button.
4.  **State Management:** Create a `ThemeProvider` to manage the app's theme and a `TimeProvider` to manage the prayer time state.
5.  **Background Service:**
    *   Define callback functions for `android_alarm_manager_plus` to handle the silent and normal mode logic.
    *   Initialize the background service in `main()`.
6.  **Save and Schedule:** Implement the logic for the "Save" button to store the times in `shared_preferences` and schedule the alarms with `android_alarm_manager_plus`.
7.  **Permission Request:** Implement a function to check and request "Do Not Disturb" permission when the app starts.
8.  **Refine and Test:** Ensure the UI is user-friendly and the background service works reliably.

