import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Whether this install belongs to at least one Sangat group. Decides the
/// Sangat notification switch (02-notifications §9) and whether paath goes to
/// the outbox (08-sangat §5.1). False until the Sangat is rebuilt (step 6).
final sangatMemberProvider = Provider<bool>((ref) => false);
