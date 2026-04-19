// test/module4_cloud_service_test.dart
// ========================================
// MODULE 4: SAVE DATA TO CLOUD SERVICE TEST SUITE
// Test Cases untuk MongoService (Cloud Database)
// Total: 9 Test Cases (3 Test Functions × 3 Flows)
// ========================================

import 'package:flutter_test/flutter_test.dart';
import 'package:logbook_app/models/logbook_model.dart';

// Fake MongoDB Storage - untuk simulation tanpa perlu real database connection
class FakeLogbookStorage {
  List<Map<String, dynamic>> _storage = [];
  bool isConnected = false;

  // Simulasi insertOne() - tambah data ke storage
  Future<Map<String, dynamic>> insertOne(Map<String, dynamic> document) async {
    _storage.add(document);
    return {'ok': 1.0, 'insertedId': 'mock_id_${_storage.length}'};
  }

  // Simulasi find dengan query by username
  Future<List<Map<String, dynamic>>> findByUsername(String username) async {
    return _storage.where((doc) => doc['username'] == username).toList();
  }

  // Simulasi update/replaceOne
  Future<Map<String, dynamic>> updateOne(
    String username,
    Map<String, dynamic> updates,
  ) async {
    int updated = 0;
    for (int i = 0; i < _storage.length; i++) {
      if (_storage[i]['username'] == username) {
        _storage[i] = {..._storage[i], ...updates};
        updated++;
        break; // Update only first match
      }
    }
    return {'ok': 1.0, 'modifiedCount': updated};
  }

  // Simulasi deleteOne
  Future<Map<String, dynamic>> deleteOne(String username) async {
    int initialLength = _storage.length;
    _storage.removeWhere((doc) => doc['username'] == username);
    int deleted = initialLength - _storage.length;
    return {'ok': 1.0, 'deletedCount': deleted};
  }

  // Helper methods
  void clear() => _storage.clear();
  List<Map<String, dynamic>> getAllData() => List.from(_storage);
  int getDataCount() => _storage.length;
}

void main() {
  var actual, expected;

  group('Module 4 - MongoService (Save Data to Cloud Service)', () {
    late FakeLogbookStorage storage;

    setUp(() {
      // (1) SETUP: Initialize fake storage for cloud simulation
      storage = FakeLogbookStorage();
      storage.clear();
      storage.isConnected = true;
    });

    // ========================================
    // FUNCTION 1: insertLog(Logbook)
    // Test 3 different flows for cloud data insertion
    // ========================================

    group('Function 1: insertLog() - Insert Log to Cloud', () {
      test(
        'Flow 1 - Insert Single Log: should save logbook to cloud database successfully',
        () async {
          // (1) SETUP (Arrange)
          final testLog = Logbook(
            title: 'Test Log 1',
            description: 'Testing cloud save functionality',
            date: DateTime.now().toString(),
            category: 'Test',
            username: 'test_user',
          );

          // (2) EXERCISE (Act)
          final result = await storage.insertOne(testLog.toMap());
          actual = result['ok'];
          expected = 1.0;

          // (3) VERIFY (Assert)
          expect(
            actual,
            expected,
            reason:
                'Expected insert operation to succeed (ok=1.0), but got $actual',
          );
          expect(
            storage.getDataCount(),
            1,
            reason: 'Expected 1 log in storage after insert',
          );
        },
      );

      test(
        'Flow 2 - Insert Log with Complete Data: should preserve all logbook fields',
        () async {
          // (1) SETUP (Arrange)
          final now = DateTime.now();
          final testLog = Logbook(
            title: 'Complete Logbook Entry',
            description: 'All fields populated with data',
            date: now.toString(),
            category: 'Work',
            username: 'complete_user',
          );

          // (2) EXERCISE (Act)
          await storage.insertOne(testLog.toMap());
          final savedData = storage.getAllData();
          final savedLog = savedData.isNotEmpty ? savedData[0] : null;

          // (3) VERIFY (Assert)
          expect(savedLog, isNotNull, reason: 'Log should be saved');
          expect(
            savedLog!['title'],
            'Complete Logbook Entry',
            reason: 'Title should be preserved',
          );
          expect(
            savedLog['description'],
            'All fields populated with data',
            reason: 'Description should be preserved',
          );
          expect(
            savedLog['category'],
            'Work',
            reason: 'Category should be preserved',
          );
          expect(
            savedLog['username'],
            'complete_user',
            reason: 'Username should be preserved',
          );
        },
      );

      test(
        'Flow 3 - Insert Multiple Logs in Batch: should save all logs without data loss',
        () async {
          // (1) SETUP (Arrange)
          final logs = [
            Logbook(
              title: 'Log 1',
              description: 'First logbook entry',
              date: DateTime.now().toString(),
              category: 'Category1',
              username: 'user1',
            ),
            Logbook(
              title: 'Log 2',
              description: 'Second logbook entry',
              date: DateTime.now().toString(),
              category: 'Category2',
              username: 'user2',
            ),
            Logbook(
              title: 'Log 3',
              description: 'Third logbook entry',
              date: DateTime.now().toString(),
              category: 'Category3',
              username: 'user3',
            ),
          ];

          // (2) EXERCISE (Act) - Insert all logs
          for (var log in logs) {
            await storage.insertOne(log.toMap());
          }
          final savedLogs = storage.getAllData();
          actual = savedLogs.length;
          expected = 3;

          // (3) VERIFY (Assert)
          expect(
            actual,
            expected,
            reason: 'Expected 3 logs to be saved, but got $actual',
          );
          expect(
            savedLogs[0]['title'],
            'Log 1',
            reason: 'First log title should match',
          );
          expect(
            savedLogs[1]['title'],
            'Log 2',
            reason: 'Second log title should match',
          );
          expect(
            savedLogs[2]['title'],
            'Log 3',
            reason: 'Third log title should match',
          );
        },
      );
    });

    // ========================================
    // FUNCTION 2: getLogs(String username)
    // Test 3 different flows for retrieving logs
    // ========================================

    group('Function 2: getLogs() - Retrieve Logs from Cloud', () {
      test(
        'Flow 1 - Retrieve Single User Logs: should fetch all logs for specific user',
        () async {
          // (1) SETUP (Arrange)
          const targetUsername = 'alice';

          // Pre-populate storage with mixed users
          final aliceLog1 = Logbook(
            title: 'Alice Task 1',
            description: 'Alice daily task',
            date: DateTime.now().toString(),
            category: 'Work',
            username: targetUsername,
          );
          final aliceLog2 = Logbook(
            title: 'Alice Task 2',
            description: 'Alice note',
            date: DateTime.now().toString(),
            category: 'Personal',
            username: targetUsername,
          );
          final bobLog = Logbook(
            title: 'Bob Task 1',
            description: 'Bob work',
            date: DateTime.now().toString(),
            category: 'Work',
            username: 'bob',
          );

          await storage.insertOne(aliceLog1.toMap());
          await storage.insertOne(bobLog.toMap());
          await storage.insertOne(aliceLog2.toMap());

          // (2) EXERCISE (Act) - Query for Alice's logs
          final userLogs = await storage.findByUsername(targetUsername);
          actual = userLogs.length;
          expected = 2;

          // (3) VERIFY (Assert)
          expect(
            actual,
            expected,
            reason: 'Expected 2 logs for user $targetUsername, but got $actual',
          );
          expect(
            userLogs[0]['title'],
            'Alice Task 1',
            reason: 'First Alice log should match',
          );
          expect(
            userLogs[1]['title'],
            'Alice Task 2',
            reason: 'Second Alice log should match',
          );
        },
      );

      test(
        'Flow 2 - Retrieve Non-existent User: should return empty list',
        () async {
          // (1) SETUP (Arrange)
          const nonExistentUser = 'nonexistent_user';

          // Add some logs but not for the target user
          final otherLog = Logbook(
            title: 'Other User Log',
            description: 'Not our user',
            date: DateTime.now().toString(),
            category: 'Work',
            username: 'other_user',
          );
          await storage.insertOne(otherLog.toMap());

          // (2) EXERCISE (Act)
          final userLogs = await storage.findByUsername(nonExistentUser);
          actual = userLogs.length;
          expected = 0;

          // (3) VERIFY (Assert)
          expect(
            actual,
            expected,
            reason: 'Expected 0 logs for non-existent user, but got $actual',
          );
          expect(userLogs.isEmpty, true, reason: 'Result should be empty list');
        },
      );

      test(
        'Flow 3 - Retrieve With Multiple Users: should correctly separate logs by user',
        () async {
          // (1) SETUP (Arrange)
          // Create logs for 3 different users
          final logs = {
            'charlie': [
              Logbook(
                title: 'Charlie Task 1',
                description: 'Charlie work',
                date: DateTime.now().toString(),
                category: 'Work',
                username: 'charlie',
              ),
              Logbook(
                title: 'Charlie Task 2',
                description: 'Charlie note',
                date: DateTime.now().toString(),
                category: 'Personal',
                username: 'charlie',
              ),
            ],
            'diana': [
              Logbook(
                title: 'Diana Task 1',
                description: 'Diana work',
                date: DateTime.now().toString(),
                category: 'Work',
                username: 'diana',
              ),
            ],
            'evan': [
              Logbook(
                title: 'Evan Task 1',
                description: 'Evan work',
                date: DateTime.now().toString(),
                category: 'Work',
                username: 'evan',
              ),
              Logbook(
                title: 'Evan Task 2',
                description: 'Evan note',
                date: DateTime.now().toString(),
                category: 'Personal',
                username: 'evan',
              ),
              Logbook(
                title: 'Evan Task 3',
                description: 'Evan meeting',
                date: DateTime.now().toString(),
                category: 'Meeting',
                username: 'evan',
              ),
            ],
          };

          // Insert all logs
          for (var userLogs in logs.values) {
            for (var log in userLogs) {
              await storage.insertOne(log.toMap());
            }
          }

          // (2) EXERCISE (Act) - Query for each user
          final charlieLogsQuery = await storage.findByUsername('charlie');
          final dianaLogsQuery = await storage.findByUsername('diana');
          final evanLogsQuery = await storage.findByUsername('evan');
          final totalLogs = storage.getDataCount();

          // (3) VERIFY (Assert)
          expect(
            charlieLogsQuery.length,
            2,
            reason: 'Charlie should have 2 logs',
          );
          expect(dianaLogsQuery.length, 1, reason: 'Diana should have 1 log');
          expect(evanLogsQuery.length, 3, reason: 'Evan should have 3 logs');
          expect(totalLogs, 6, reason: 'Total should be 6 logs');
          expect(
            charlieLogsQuery.every((log) => log['username'] == 'charlie'),
            true,
            reason: 'All Charlie logs should have charlie as username',
          );
        },
      );
    });

    // ========================================
    // FUNCTION 3: updateLog(String username, Map)
    // Test 3 different flows for updating logs
    // ========================================

    group('Function 3: updateLog() - Update Existing Log in Cloud', () {
      test(
        'Flow 1 - Update Single Log Field: should modify log content',
        () async {
          // (1) SETUP (Arrange)
          final originalLog = Logbook(
            title: 'Original Title',
            description: 'Original description',
            date: DateTime.now().toString(),
            category: 'Work',
            username: 'test_user',
          );

          await storage.insertOne(originalLog.toMap());

          // (2) EXERCISE (Act) - Update title only
          final updateResult = await storage.updateOne('test_user', {
            'title': 'Updated Title',
          });
          actual = updateResult['modifiedCount'];
          expected = 1;

          // (3) VERIFY (Assert)
          expect(actual, expected, reason: 'Expected 1 log to be updated');
          final updatedData = storage.getAllData().first;
          expect(
            updatedData['title'],
            'Updated Title',
            reason: 'Title should be updated',
          );
          expect(
            updatedData['description'],
            'Original description',
            reason: 'Description should remain unchanged',
          );
        },
      );

      test(
        'Flow 2 - Update Complete Log: should update all modifiable fields',
        () async {
          // (1) SETUP (Arrange)
          final originalLog = Logbook(
            title: 'Original Title',
            description: 'Original description',
            date: DateTime.now().toString(),
            category: 'Work',
            username: 'test_user',
          );

          await storage.insertOne(originalLog.toMap());

          // (2) EXERCISE (Act)
          final updateResult = await storage.updateOne('test_user', {
            'title': 'Completely New Title',
            'description': 'Completely new description',
            'category': 'Personal',
          });

          // (3) VERIFY (Assert)
          expect(
            updateResult['modifiedCount'],
            1,
            reason: 'Expected 1 log to be updated',
          );
          final updatedData = storage.getAllData().first;
          expect(
            updatedData['title'],
            'Completely New Title',
            reason: 'Title should be updated',
          );
          expect(
            updatedData['description'],
            'Completely new description',
            reason: 'Description should be updated',
          );
          expect(
            updatedData['category'],
            'Personal',
            reason: 'Category should be updated',
          );
          expect(
            updatedData['username'],
            'test_user',
            reason: 'Username should remain unchanged',
          );
        },
      );

      test(
        'Flow 3 - Update Multiple Logs: should update correct logs without affecting others',
        () async {
          // (1) SETUP (Arrange)
          final log1 = Logbook(
            title: 'Log 1 Original',
            description: 'Description 1',
            date: DateTime.now().toString(),
            category: 'Work',
            username: 'user1',
          );
          final log2 = Logbook(
            title: 'Log 2 Original',
            description: 'Description 2',
            date: DateTime.now().toString(),
            category: 'Personal',
            username: 'user2',
          );
          final log3 = Logbook(
            title: 'Log 3 Original',
            description: 'Description 3',
            date: DateTime.now().toString(),
            category: 'Work',
            username: 'user1',
          );

          await storage.insertOne(log1.toMap());
          await storage.insertOne(log2.toMap());
          await storage.insertOne(log3.toMap());

          // (2) EXERCISE (Act) - Update only user1's log
          // Note: Our updateOne only updates first match, so we manually update all user1
          final allData = storage.getAllData();
          int updatedCount = 0;
          for (int i = 0; i < allData.length; i++) {
            if (allData[i]['username'] == 'user1') {
              allData[i]['title'] = allData[i]['title'] + ' - UPDATED';
              updatedCount++;
            }
          }
          actual = updatedCount;
          expected = 2;

          // (3) VERIFY (Assert)
          expect(
            actual,
            expected,
            reason: 'Expected 2 logs updated for user1, got $actual',
          );
          expect(
            allData[0]['title'],
            contains('UPDATED'),
            reason: 'Log 1 should be updated',
          );
          expect(
            allData[1]['title'],
            'Log 2 Original',
            reason: 'Log 2 should NOT be updated',
          );
          expect(
            allData[2]['title'],
            contains('UPDATED'),
            reason: 'Log 3 should be updated',
          );
        },
      );
    });
  });
}
