import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hazri/features/sangat/data/account_repository.dart';
import 'package:hazri/features/sangat/data/group_credit.dart';
import 'package:hazri/features/sangat/data/group_repository.dart';
import 'package:hazri/features/sangat/domain/sangat_account.dart';
import 'package:hazri/features/sangat/domain/sangat_group.dart';

import '../fake_account_repository.dart';
import '../fake_group_repository.dart';

const _account = SangatAccount(id: 'uid-1', name: 'X', city: 'Y', email: 'a@b.c');

const _sukhmaniFamily = SangatGroup(
  id: 'g1',
  name: 'Nanda Family',
  kind: GroupKind.family,
  createdBy: 'uid-1',
  goal: GroupGoal(slug: 'sukhmani', target: 101),
);

const _japjiSangat = SangatGroup(
  id: 'g2',
  name: 'Gurdwara Sangat',
  kind: GroupKind.sangat,
  createdBy: 'somebody',
  goal: GroupGoal(slug: 'japji', target: 21000),
);

const _circle = SangatGroup(
  id: 'g3',
  name: 'Amrit Vela Circle',
  kind: GroupKind.circle,
  createdBy: 'uid-1',
  goal: GroupGoal(slug: 'simran', target: 300),
);

/// A paath actually read should not need logging by hand a second time.
void main() {
  late FakeGroupRepository groups;
  late ProviderContainer container;

  Future<void> setUpWith(List<SangatGroup> mine) async {
    final account = FakeAccountRepository(account: _account);
    groups = FakeGroupRepository(mine: mine);
    addTearDown(account.dispose);
    addTearDown(groups.dispose);
    container = ProviderContainer(overrides: [
      accountRepositoryProvider.overrideWithValue(account),
      groupRepositoryProvider.overrideWithValue(groups),
    ]);
    addTearDown(container.dispose);
    // Let the stream deliver before anything reads it.
    container.listen(myGroupsProvider, (_, _) {});
    await container.read(myGroupsProvider.future);
  }

  test('a finished bani is added to the group reciting it', () async {
    await setUpWith([_sukhmaniFamily]);
    await creditGroupsFor(container.read, 'sukhmani');
    expect(groups.logged, [('g1', 1)]);
  });

  test('and not to a group reciting something else', () async {
    await setUpWith([_sukhmaniFamily, _japjiSangat]);
    await creditGroupsFor(container.read, 'japji');
    expect(groups.logged, [('g2', 1)]);
  });

  test('two groups on the same bani both get it', () async {
    await setUpWith([
      _sukhmaniFamily,
      _japjiSangat.copyWith(goal: const GroupGoal(slug: 'sukhmani', target: 500)),
    ]);
    await creditGroupsFor(container.read, 'sukhmani');
    expect(groups.logged.length, 2);
  });

  test('a simran circle is never credited with a paath', () async {
    // Its unit is minutes. A bani is not minutes, and crediting one for the
    // other would be a number nobody did.
    await setUpWith([_circle]);
    await creditGroupsFor(container.read, 'simran');
    expect(groups.logged, isEmpty);
  });

  test('a group with no goal is left alone', () async {
    await setUpWith([
      const SangatGroup(id: 'g4', name: 'x', kind: GroupKind.family, createdBy: 'uid-1'),
    ]);
    await creditGroupsFor(container.read, 'japji');
    expect(groups.logged, isEmpty);
  });
}
