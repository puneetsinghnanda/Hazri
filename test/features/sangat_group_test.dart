import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hazri/core/backend/backend.dart';
import 'package:hazri/features/sangat/data/group_repository.dart';
import 'package:hazri/features/sangat/domain/sangat_group.dart';
import 'package:hazri/features/sangat/ui/group_invite_screen.dart';

/// The group model, and the arithmetic every screen reads off it.
void main() {
  group('a group with no server', () {
    test('has no groups and refuses politely', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      const repo = NoGroupRepository();

      expect(await repo.listed(), isEmpty);
      expect(await repo.create(name: 'Nanda Family', kind: GroupKind.family),
          isA<GroupUnavailable>());
      expect(await repo.join('anything'), isA<GroupUnavailable>());
      expect(await repo.logPaath('anything', 1), isA<GroupUnavailable>());
      expect(container.read(groupRepositoryProvider), isA<NoGroupRepository>());
    });
  });

  group('what a group counts', () {
    test('a circle counts minutes and everything else counts paath', () {
      expect(GroupKind.circle.countsMinutes, isTrue);
      expect(GroupKind.family.countsMinutes, isFalse);
      expect(GroupKind.sangat.countsMinutes, isFalse);
    });

    test('an unknown kind from the server does not crash the screen', () {
      // A kind added later, read by an older build. Falling back beats
      // throwing inside a list of cards.
      expect(GroupKind.parse('whatever'), GroupKind.family);
      expect(GroupKind.parse(null), GroupKind.family);
    });
  });

  group('progress', () {
    const goal = GroupGoal(slug: 'sukhmani', target: 101);
    const group = SangatGroup(
      id: 'g1',
      name: 'Nanda Family',
      kind: GroupKind.family,
      createdBy: 'uid-1',
      goal: goal,
      total: 68,
    );

    test('is the group total against the target', () {
      expect(group.percent, 67);
    });

    test('never runs past the goal', () {
      // A group that overshoots shows a full ring, not 140%.
      expect(group.copyWith(total: 141).percent, 100);
      expect(group.copyWith(total: 141).progress, 1.0);
    });

    test('is null with no goal, so the UI can say so rather than show 0%', () {
      const noGoal = SangatGroup(
        id: 'g2',
        name: 'x',
        kind: GroupKind.family,
        createdBy: 'uid-1',
        total: 9,
      );
      expect(noGoal.progress, isNull);
      expect(noGoal.percent, isNull);
    });

    test('a target of zero does not divide by it', () {
      const zero = SangatGroup(
        id: 'g3',
        name: 'x',
        kind: GroupKind.family,
        createdBy: 'uid-1',
        goal: GroupGoal(slug: 'japji', target: 0),
        total: 5,
      );
      expect(zero.progress, isNull);
    });
  });

  group('what a phone may write', () {
    test('a new group is never listed, whatever the UI asked for', () {
      // The rules refuse `listed` from a client; this is the same promise
      // one layer earlier, so a bug here fails in a test rather than in a
      // permission denial nobody can read.
      const group = SangatGroup(
        id: 'g1',
        name: 'Nanda Family',
        kind: GroupKind.family,
        createdBy: 'uid-1',
        listed: true,
      );
      expect(group.toFirestore()['listed'], false);
    });

    test('a member row never carries a count it did not earn', () {
      const member = GroupMember(uid: 'u1', name: 'Harjit Singh', count: 18);
      expect(member.toFirestore(), {
        'name': 'Harjit Singh',
        'role': 'member',
        'count': 18,
      });
    });

    test('the admin flag survives the round trip', () {
      const admin = GroupMember(uid: 'u1', name: 'X', isAdmin: true);
      expect(admin.toFirestore()['role'], 'admin');
      expect(
        GroupMember.fromFirestore('u1', const {'name': 'X', 'role': 'admin'}).isAdmin,
        isTrue,
      );
    });
  });

  group('the invite link', () {
    test('a whole pasted link gives the group id', () {
      expect(
        groupIdFromInvite(
            'https://hazri-dfcc1.web.app/j/abc123'),
        'abc123',
      );
    });

    test('the invite and the verification link share one host', () {
      // They were on two different hosts once, one of which served nothing.
      // Both now come from kSiteBase, so a change to the host cannot move
      // one and leave the other behind.
      expect(kInviteBase, startsWith(kSiteBase));
      expect(kVerificationUrl, startsWith(kSiteBase));
      expect(kInviteBase, isNot(contains('vercel')));
    });

    test('a bare code is a link too', () {
      expect(groupIdFromInvite('  abc123 '), 'abc123');
    });

    test('a trailing slash and a query do not become the id', () {
      expect(groupIdFromInvite('.../j/abc123/'), 'abc123');
      expect(groupIdFromInvite('.../j/abc123?from=whatsapp'), 'abc123');
    });

    test('nothing in gives nothing out rather than a request', () {
      expect(groupIdFromInvite('   '), '');
    });
  });
}
