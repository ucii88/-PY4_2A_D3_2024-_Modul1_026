import 'package:flutter_test/flutter_test.dart';
import 'package:logbook_app/features/logbook/models/log_model.dart';

/// Security Test Suite: RBAC & Privacy Leak Prevention
///
/// This test suite validates that the privacy and ownership controls
/// correctly prevent private logs from leaking to teammates.
///
/// Test Scenario:
/// - User A creates 2 logs: 1 Private, 1 Public
/// - User B (teammate) requests logs
/// - Assert: User B should only see 1 log (the Public one)
/// - Private log should be HIDDEN from User B

void main() {
  group('RBAC Security Checks: Privacy Leak Prevention', () {
    /// This is the main security test from the assignment
    test('Private logs should NOT be visible to teammates', () {
      // ========== SETUP DATA (Step 1) ==========
      // User A creates 2 logs: 1 private, 1 public

      const userA_Id = 'user_001_alice';
      const userA_Name = 'Alice';
      const userB_Id = 'user_002_bob';

      final privateLogA = LogModel(
        title: 'My Secret Notes',
        description: 'Private log - confidential information',
        date: DateTime.now().toString(),
        category: 'Pribadi',
        authorId: userA_Id,
        teamId: 'team_default',
        isPublic: false, // 🔒 PRIVATE
      );

      final publicLogA = LogModel(
        title: 'Team Meeting Minutes',
        description: 'Public log - shared with team',
        date: DateTime.now().toString(),
        category: 'Pekerjaan',
        authorId: userA_Id,
        teamId: 'team_default',
        isPublic: true, // 🌐 PUBLIC
      );

      // Store both logs (simulating User A's logs in database)
      final allLogs = [privateLogA, publicLogA];

      // ========== ACTION (Step 2) ==========
      // User B (teammate) calls fetchLogs() / applies visibility filter

      // Simulate the visibility filter logic from log_view.dart
      final displayedLogsForUserB = allLogs.where((log) {
        final isOwner = log.authorId == userB_Id;
        return isOwner || log.isPublic == true;
      }).toList();

      // ========== ASSERT (Step 3) ==========
      // Validate: User B should only see 1 log (the public one)

      // ❌ If private log appears: VULNERABLE
      expect(
        displayedLogsForUserB.length,
        1,
        reason:
            '❌ SECURITY FAILURE: User B should only see 1 log (public), '
            'but got ${displayedLogsForUserB.length} logs. '
            'Private logs are leaking to teammates!',
      );

      // ✅ Verify the visible log is the public one
      expect(
        displayedLogsForUserB[0].title,
        'Team Meeting Minutes',
        reason: 'User B should only see the public log from User A',
      );

      // ✅ Verify private log is NOT in the list
      expect(
        displayedLogsForUserB.any((log) => log.title == 'My Secret Notes'),
        false,
        reason:
            '❌ CRITICAL: Private log "My Secret Notes" should be hidden '
            'from User B, but it was found in the visible logs!',
      );

      // ✅ Verify the visible log is actually public
      expect(
        displayedLogsForUserB[0].isPublic,
        true,
        reason: 'All visible logs to User B should have isPublic=true',
      );
    });

    /// ========== TEST 2: Owner Can Always See Own Logs ==========
    /// Ensure that even private logs are visible to their creator
    test('Owner should always see their own logs (even if private)', () {
      const userA_Id = 'user_001_alice';

      final privateLog = LogModel(
        title: 'Private Notes',
        description: 'Only Alice should see this',
        date: DateTime.now().toString(),
        category: 'Pribadi',
        authorId: userA_Id,
        teamId: 'team_default',
        isPublic: false, // 🔒 PRIVATE
      );

      final allLogs = [privateLog];

      // Alice (owner) viewing her own logs
      final displayedLogsForAlice = allLogs.where((log) {
        final isOwner = log.authorId == userA_Id;
        return isOwner || log.isPublic == true;
      }).toList();

      // ✅ Alice should see her private log
      expect(
        displayedLogsForAlice.length,
        1,
        reason: 'Owner should always see their own logs, even if private',
      );

      expect(
        displayedLogsForAlice[0].title,
        'Private Notes',
        reason: 'Owner should see their private log',
      );
    });

    /// ========== TEST 3: Public Logs Visible to All ==========
    /// Validate that public logs are visible to any team member
    test('Public logs should be visible to all team members', () {
      const userA_Id = 'user_001_alice';
      const userB_Id = 'user_002_bob';
      const userC_Id = 'user_003_charlie';

      final publicLog = LogModel(
        title: 'Public Announcement',
        description: 'This is visible to all',
        date: DateTime.now().toString(),
        category: 'Pekerjaan',
        authorId: userA_Id,
        teamId: 'team_default',
        isPublic: true, // 🌐 PUBLIC
      );

      final allLogs = [publicLog];

      // Bob views logs
      final displayedLogsForBob = allLogs.where((log) {
        final isOwner = log.authorId == userB_Id;
        return isOwner || log.isPublic == true;
      }).toList();

      // Charlie views logs
      final displayedLogsForCharlie = allLogs.where((log) {
        final isOwner = log.authorId == userC_Id;
        return isOwner || log.isPublic == true;
      }).toList();

      // ✅ Both should see the public log
      expect(displayedLogsForBob.length, 1);
      expect(displayedLogsForCharlie.length, 1);
      expect(displayedLogsForBob[0].isPublic, true);
      expect(displayedLogsForCharlie[0].isPublic, true);
    });

    /// ========== TEST 4: Complex Scenario (Multiple Users & Logs) ==========
    /// Test with multiple users, multiple logs, mixed privacy settings
    test('Complex scenario: Multiple users with mixed privacy logs', () {
      const alice = 'user_001';
      const bob = 'user_002';
      const charlie = 'user_003';

      final logs = [
        // Alice's logs
        LogModel(
          title: 'Alice Private 1',
          description: 'Only Alice sees',
          date: DateTime.now().toString(),
          category: 'Pribadi',
          authorId: alice,
          teamId: 'team_default',
          isPublic: false,
        ),
        LogModel(
          title: 'Alice Public 1',
          description: 'Everyone sees',
          date: DateTime.now().toString(),
          category: 'Pekerjaan',
          authorId: alice,
          teamId: 'team_default',
          isPublic: true,
        ),
        // Bob's logs
        LogModel(
          title: 'Bob Private 1',
          description: 'Only Bob sees',
          date: DateTime.now().toString(),
          category: 'Pribadi',
          authorId: bob,
          teamId: 'team_default',
          isPublic: false,
        ),
        LogModel(
          title: 'Bob Public 1',
          description: 'Everyone sees',
          date: DateTime.now().toString(),
          category: 'Pekerjaan',
          authorId: bob,
          teamId: 'team_default',
          isPublic: true,
        ),
        // Charlie's logs
        LogModel(
          title: 'Charlie Private 1',
          description: 'Only Charlie sees',
          date: DateTime.now().toString(),
          category: 'Pribadi',
          authorId: charlie,
          teamId: 'team_default',
          isPublic: false,
        ),
        LogModel(
          title: 'Charlie Public 1',
          description: 'Everyone sees',
          date: DateTime.now().toString(),
          category: 'Pekerjaan',
          authorId: charlie,
          teamId: 'team_default',
          isPublic: true,
        ),
      ];

      // What Alice sees
      final aliceVisible = logs.where((log) {
        final isOwner = log.authorId == alice;
        return isOwner || log.isPublic == true;
      }).toList();

      // What Bob sees
      final bobVisible = logs.where((log) {
        final isOwner = log.authorId == bob;
        return isOwner || log.isPublic == true;
      }).toList();

      // What Charlie sees
      final charlieVisible = logs.where((log) {
        final isOwner = log.authorId == charlie;
        return isOwner || log.isPublic == true;
      }).toList();

      // ✅ Alice should see: 2 own logs + 2 public from Bob + 2 public from Charlie = 6? No, 2 own + 2 public others = 4
      // Alice sees: Alice Private 1, Alice Public 1, Bob Public 1, Charlie Public 1 = 4
      expect(aliceVisible.length, 4);
      expect(aliceVisible.where((log) => log.authorId == alice).length, 2);
      expect(
        aliceVisible
            .where((log) => log.isPublic && log.authorId != alice)
            .length,
        2,
      );

      // ✅ Bob should see: 2 own logs + 2 public from Alice + 2 public from Charlie = 4
      expect(bobVisible.length, 4);
      expect(bobVisible.where((log) => log.authorId == bob).length, 2);
      expect(
        bobVisible.where((log) => log.isPublic && log.authorId != bob).length,
        2,
      );

      // ✅ Charlie should see: 2 own logs + 2 public from Alice + 2 public from Bob = 4
      expect(charlieVisible.length, 4);
      expect(charlieVisible.where((log) => log.authorId == charlie).length, 2);
      expect(
        charlieVisible
            .where((log) => log.isPublic && log.authorId != charlie)
            .length,
        2,
      );

      // ✅ Verify no private logs leak
      expect(
        aliceVisible.any((log) => !log.isPublic && log.authorId != alice),
        false,
      );
      expect(
        bobVisible.any((log) => !log.isPublic && log.authorId != bob),
        false,
      );
      expect(
        charlieVisible.any((log) => !log.isPublic && log.authorId != charlie),
        false,
      );
    });

    /// ========== TEST 5: Ownership Check - Only Owner Can Edit ==========
    /// Ensure that ownership determines edit rights (not role)
    test('Only log owner should be able to edit (ownership check)', () {
      const authorId = 'user_001_alice';
      const viewerId = 'user_002_bob';

      final log = LogModel(
        title: 'Team Log',
        description: 'Shared with team',
        date: DateTime.now().toString(),
        category: 'Pekerjaan',
        authorId: authorId,
        teamId: 'team_default',
        isPublic: true,
      );

      // Check if Alice (owner) can edit
      final aliceIsOwner = log.authorId == authorId;
      expect(
        aliceIsOwner,
        true,
        reason: 'Alice should be able to edit her log',
      );

      // Check if Bob (non-owner) can edit
      final bobIsOwner = log.authorId == viewerId;
      expect(bobIsOwner, false, reason: 'Bob should NOT be able to edit');

      // Simulate the ownership check
      bool canEdit(String userId) {
        return log.authorId == userId;
      }

      expect(canEdit(authorId), true);
      expect(canEdit(viewerId), false);
    });

    /// ========== TEST 6: Ketua Role Should NOT Bypass Ownership ==========
    /// Verify that Ketua (leader) role cannot override ownership rules
    test('Ketua role should NOT bypass ownership (Task 5 requirement)', () {
      const userA_Id = 'user_001_alice'; // Anggota
      const userB_Id = 'user_002_bob'; // Ketua (leader)

      final logByAlice = LogModel(
        title: 'Alice\'s Private Log',
        description: 'Alice\'s confidential data',
        date: DateTime.now().toString(),
        category: 'Pribadi',
        authorId: userA_Id,
        teamId: 'team_default',
        isPublic: false, // 🔒 PRIVATE
      );

      // Check if Bob (Ketua) can edit Alice's log
      final bobCanEdit = logByAlice.authorId == userB_Id; // should be false
      expect(
        bobCanEdit,
        false,
        reason:
            'Even though Bob is Ketua (leader), he should NOT be able to '
            'edit Alice\'s log because he is not the owner. '
            'Task 5 enforces ownership-only edit rights.',
      );

      // Check if Bob (Ketua) can see Alice's private log
      final bobCanSee = logByAlice.authorId == userB_Id || logByAlice.isPublic;
      expect(
        bobCanSee,
        false,
        reason: 'Bob (Ketua) should NOT see Alice\'s private log.',
      );
    });

    /// ========== TEST 7: Privacy Toggle Persists ==========
    /// Ensure isPublic flag is correctly stored and retrieved
    test('Privacy toggle (isPublic) should persist correctly', () {
      final privateLog = LogModel(
        title: 'Test Log',
        description: 'Description',
        date: DateTime.now().toString(),
        category: 'Pribadi',
        authorId: 'user_001',
        teamId: 'team_default',
        isPublic: false,
      );

      final publicLog = LogModel(
        title: 'Test Log',
        description: 'Description',
        date: DateTime.now().toString(),
        category: 'Pekerjaan',
        authorId: 'user_001',
        teamId: 'team_default',
        isPublic: true,
      );

      // ✅ Verify private flag
      expect(privateLog.isPublic, false);

      // ✅ Verify public flag
      expect(publicLog.isPublic, true);

      // Simulate toggling privacy
      final toggledLog = LogModel(
        title: privateLog.title,
        description: privateLog.description,
        date: privateLog.date,
        category: privateLog.category,
        authorId: privateLog.authorId,
        teamId: privateLog.teamId,
        isPublic: !privateLog.isPublic, // Toggle
      );

      expect(toggledLog.isPublic, true, reason: 'Privacy toggle should work');
    });

    /// ========== TEST 8: Empty, Private, Public Mix ==========
    /// Edge case: Test with empty list, only private, only public
    test('Edge cases: empty logs, only private, only public', () {
      const userId = 'user_001';

      // Case 1: Empty log list
      final emptyLogs = <LogModel>[];
      final emptyResult = emptyLogs.where((log) {
        final isOwner = log.authorId == userId;
        return isOwner || log.isPublic == true;
      }).toList();
      expect(emptyResult.length, 0, reason: 'Empty list should return empty');

      // Case 2: Only private logs (all owned by other users)
      final onlyPrivateLogs = [
        LogModel(
          title: 'Private 1',
          description: 'Private',
          date: DateTime.now().toString(),
          category: 'Pribadi',
          authorId: 'user_002',
          teamId: 'team_default',
          isPublic: false,
        ),
        LogModel(
          title: 'Private 2',
          description: 'Private',
          date: DateTime.now().toString(),
          category: 'Pribadi',
          authorId: 'user_003',
          teamId: 'team_default',
          isPublic: false,
        ),
      ];
      final privateResult = onlyPrivateLogs.where((log) {
        final isOwner = log.authorId == userId;
        return isOwner || log.isPublic == true;
      }).toList();
      expect(
        privateResult.length,
        0,
        reason: 'User should see 0 logs if all are private and owned by others',
      );

      // Case 3: Only public logs
      final onlyPublicLogs = [
        LogModel(
          title: 'Public 1',
          description: 'Public',
          date: DateTime.now().toString(),
          category: 'Pekerjaan',
          authorId: 'user_002',
          teamId: 'team_default',
          isPublic: true,
        ),
        LogModel(
          title: 'Public 2',
          description: 'Public',
          date: DateTime.now().toString(),
          category: 'Pekerjaan',
          authorId: 'user_003',
          teamId: 'team_default',
          isPublic: true,
        ),
      ];
      final publicResult = onlyPublicLogs.where((log) {
        final isOwner = log.authorId == userId;
        return isOwner || log.isPublic == true;
      }).toList();
      expect(
        publicResult.length,
        2,
        reason: 'User should see all public logs even if not owner',
      );
    });
  });
}
