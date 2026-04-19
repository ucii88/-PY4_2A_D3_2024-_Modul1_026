// test/module3_disk_storage_test.dart
// ========================================
// MODULE 3: SAVE DATA TO DISK TEST SUITE
// Test Cases untuk Persistent Storage (SharedPreferences)
// Total: 9 Test Cases (3 Test Functions × 3 Flows)
// ========================================

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:logbook_app/features/counter/counter_controller.dart';

void main() {
  var actual, expected;

  group('Module 3 - Persistent Storage to Disk (SharedPreferences)', () {
    late CounterController controller;
    const username = "test_user";

    setUp(() async {
      // (1) SETUP: Mock SharedPreferences and initialize controller
      SharedPreferences.setMockInitialValues({});
      controller = CounterController();
    });

    // ========================================
    // FUNCTION 1: loadCounter() / loadData()
    // Test 3 different flows for loading data from disk
    // ========================================

    group('Function 1: loadCounter() - Load Data From Disk', () {
      test(
        'Flow 1 - Load Existing Data: should load previously saved counter value from disk',
        () async {
          // (1) SETUP (Arrange)
          // Pre-save some data to SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          await prefs.setInt('counter_$username', 42);
          await prefs.setString('history_$username', jsonEncode(['Load test']));

          controller = CounterController();

          // (2) EXERCISE (Act)
          await controller.loadCounter(username);
          actual = controller.value;
          expected = 42;

          // (3) VERIFY (Assert)
          expect(
            actual,
            expected,
            reason:
                'Expected counter value $expected but got $actual when loading existing data',
          );
        },
      );

      test(
        'Flow 2 - Load Non-existent Data: should default to 0 when no data exists',
        () async {
          // (1) SETUP (Arrange)
          // Ensure SharedPreferences is empty
          SharedPreferences.setMockInitialValues({});
          controller = CounterController();

          // (2) EXERCISE (Act)
          await controller.loadCounter(username);
          actual = controller.value;
          expected = 0;

          // (3) VERIFY (Assert)
          expect(
            actual,
            expected,
            reason:
                'Expected default counter value $expected but got $actual when no data exists',
          );
        },
      );

      test(
        'Flow 3 - Load Data with History: should restore both counter value and history from disk',
        () async {
          // (1) SETUP (Arrange)
          final prefs = await SharedPreferences.getInstance();
          final historyList = [
            'User $username menambah +5 menjadi 15 (10:30)',
            'User $username mengurangi -3 menjadi 12 (10:25)',
            'User $username mereset ke 0 (10:20)',
          ];
          await prefs.setInt('counter_$username', 15);
          await prefs.setString('history_$username', jsonEncode(historyList));

          controller = CounterController();

          // (2) EXERCISE (Act)
          await controller.loadCounter(username);
          actual = controller.value;
          final actualHistory = controller.history;

          // (3) VERIFY (Assert)
          expected = 15;
          expect(
            actual,
            expected,
            reason:
                'Expected counter value $expected but got $actual after loading data with history',
          );
          expect(
            actualHistory.length,
            3,
            reason:
                'Expected 3 history entries but got ${actualHistory.length}',
          );
          expect(
            actualHistory[0],
            contains('menambah'),
            reason: 'Expected first history entry to contain increment action',
          );
        },
      );
    });

    // ========================================
    // FUNCTION 2: _saveData()
    // Test 3 different flows for saving data to disk
    // ========================================

    group('Function 2: _saveData() - Save Data To Disk', () {
      test(
        'Flow 1 - Save Counter Value: should persist counter to disk',
        () async {
          // (1) SETUP (Arrange)
          SharedPreferences.setMockInitialValues({});
          controller = CounterController();
          controller.setStep(5);

          // (2) EXERCISE (Act) - Increment and save
          await controller.increment(username);
          final prefs = await SharedPreferences.getInstance();
          actual = prefs.getInt('counter_$username');
          expected = 5;

          // (3) VERIFY (Assert)
          expect(
            actual,
            expected,
            reason:
                'Expected saved counter value $expected but got $actual on disk',
          );
        },
      );

      test(
        'Flow 2 - Save with History: should preserve history while saving',
        () async {
          // (1) SETUP (Arrange)
          SharedPreferences.setMockInitialValues({});
          controller = CounterController();
          controller.setStep(2);

          // (2) EXERCISE (Act) - Perform operations and save
          await controller.increment(username); // +2
          await controller.increment(username); // +2
          final prefs = await SharedPreferences.getInstance();
          final savedHistory = prefs.getString('history_$username');

          // (3) VERIFY (Assert)
          expect(
            controller.value,
            4,
            reason: 'Expected counter 4 after two increments',
          );
          expect(
            savedHistory,
            isNotNull,
            reason: 'Expected history to be saved',
          );
          expect(
            savedHistory!.contains('menambah'),
            true,
            reason: 'Expected history entry to contain increment action',
          );
        },
      );

      test(
        'Flow 3 - Save Preserves Previous Data: should not lose data on multiple saves',
        () async {
          // (1) SETUP (Arrange)
          final prefs = await SharedPreferences.getInstance();
          await prefs.setInt('counter_${username}_other', 100);
          controller = CounterController();
          controller.setStep(3);

          // (2) EXERCISE (Act) - Save new data
          await controller.increment(username);
          // Verify other data still exists
          actual = prefs.getInt('counter_${username}_other');
          expected = 100;

          // (3) VERIFY (Assert)
          expect(
            actual,
            expected,
            reason:
                'Expected other data to be preserved after saving new counter',
          );
          expect(
            controller.value,
            3,
            reason: 'Expected new counter value to be 3',
          );
        },
      );
    });

    // ========================================
    // FUNCTION 3: Persistent Operations
    // Test 3 different flows for persistence across operations
    // ========================================

    group('Function 3: Persistent Operations - Increment, Decrement, Reset', () {
      test(
        'Flow 1 - Increment Persistence: value should persist after increment and reload',
        () async {
          // (1) SETUP (Arrange)
          SharedPreferences.setMockInitialValues({});
          var controller1 = CounterController();
          controller1.setStep(7);

          // (2) EXERCISE (Act) - Increment and save
          await controller1.increment(username);
          actual = controller1.value;
          expected = 7;
          expect(
            actual,
            expected,
            reason: 'Expected counter 7 after increment',
          );

          // Simulate app reload by creating new controller and loading
          var controller2 = CounterController();
          await controller2.loadCounter(username);
          actual = controller2.value;

          // (3) VERIFY (Assert)
          expected = 7;
          expect(
            actual,
            expected,
            reason:
                'Expected counter to be $expected after reload, but got $actual',
          );
        },
      );

      test(
        'Flow 2 - Decrement Persistence: decremented value should persist',
        () async {
          // (1) SETUP (Arrange)
          SharedPreferences.setMockInitialValues({});
          var controller1 = CounterController();
          controller1.setStep(3);
          await controller1.increment(username); // Start at 3
          await controller1.increment(username); // Now at 6

          // (2) EXERCISE (Act) - Decrement and save
          await controller1.decrement(username); // 6 - 3 = 3
          actual = controller1.value;
          expected = 3;
          expect(
            actual,
            expected,
            reason: 'Expected counter 3 after decrement',
          );

          // Reload and verify persistence
          var controller2 = CounterController();
          await controller2.loadCounter(username);
          actual = controller2.value;

          // (3) VERIFY (Assert)
          expected = 3;
          expect(
            actual,
            expected,
            reason:
                'Expected decremented value to persist after reload: $expected, got $actual',
          );
        },
      );

      test(
        'Flow 3 - Reset Persistence: reset value should persist on reload',
        () async {
          // (1) SETUP (Arrange)
          SharedPreferences.setMockInitialValues({});
          var controller1 = CounterController();
          controller1.setStep(10);
          await controller1.increment(username); // 10
          await controller1.increment(username); // 20
          expect(controller1.value, 20, reason: 'Setup: counter should be 20');

          // (2) EXERCISE (Act) - Reset and save
          await controller1.reset(username);
          actual = controller1.value;
          expected = 0;
          expect(actual, expected, reason: 'Expected counter 0 after reset');

          // Reload and verify persistence
          var controller2 = CounterController();
          await controller2.loadCounter(username);
          actual = controller2.value;

          // (3) VERIFY (Assert)
          expected = 0;
          expect(
            actual,
            expected,
            reason:
                'Expected reset value to be $expected after reload, but got $actual',
          );
        },
      );
    });
  });
}
